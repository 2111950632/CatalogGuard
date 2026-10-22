///|
pub(all) struct ConsistencyOptions {
  enabled : Bool
  ignore_context : Bool
  inverse : Bool
  max_entries : Int32
} derive(Debug)

///|
pub fn default_consistency_options() -> ConsistencyOptions {
  {
    enabled: false,
    ignore_context: false,
    inverse: false,
    max_entries: 100000,
  }
}

///|
pub(all) struct ProjectFinding {
  file_index : Int32
  diagnostic : Diagnostic
  related_file : String?
  related_span : Span?
  related_entry : Int32?
} derive(Debug)

///|
priv struct ConsistencyReference {
  file_index : Int32
  entry_index : Int32
}

///|
priv struct ConsistencySource {
  reference : ConsistencyReference
  plural : String?
  translation : String
  flags : String
}

///|
priv struct ConsistencyTargets {
  first : ConsistencyReference
  outside_first_file : Array[ConsistencyReference]
  outside_first_source : Array[ConsistencyReference]
}

///|
fn consistency_remember_target(
  group : ConsistencyTargets,
  current : ConsistencyReference,
  catalogs : Array[Catalog],
) -> Unit {
  let first = group.first
  let source = catalogs[current.file_index].entries[current.entry_index].id
  let first_source = catalogs[first.file_index].entries[first.entry_index].id
  // For a query in the first file, two distinct sources outside it suffice.
  if current.file_index != first.file_index &&
    group.outside_first_file.length() < 2 &&
    !group.outside_first_file.any(p => {
      catalogs[p.file_index].entries[p.entry_index].id == source
    }) {
    group.outside_first_file.push(current)
  }
  // For a query with the first source, two distinct other files suffice.
  // All remaining queries can use first itself: at most five witnesses total.
  if source != first_source &&
    group.outside_first_source.length() < 2 &&
    !group.outside_first_source.any(p => p.file_index == current.file_index) {
    group.outside_first_source.push(current)
  }
}

///|
fn consistency_locale(catalog : Catalog) -> String? {
  let value = match read_header(catalog).get("Language") {
    None => return None
    Some(value) => trim_text(value)
  }
  if value == "" ||
    value
    .to_array()
    .any(c => {
      !((c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_')
    }) {
    return None
  }
  let normalized = value
    .to_lower()
    .split("_")
    .map(s => s.to_owned())
    .to_array()
    .join("-")
  let parts = normalized.split("-").map(s => s.to_owned()).to_array()
  if parts.any(part => part == "") ||
    parts[0].to_array().any(c => !(c >= 'a' && c <= 'z')) {
    return None
  }
  // This is a grouping syntax check, not an ISO/BCP-47 registry validator.
  Some(normalized)
}

///|
fn consistency_context(entry : Entry, options : ConsistencyOptions) -> String {
  if options.ignore_context {
    ""
  } else {
    (if entry.context is Some(_) { "1" } else { "0" }) +
    markup_part(entry.context.unwrap_or(""))
  }
}

///|
fn consistency_translation(entry : Entry) -> String {
  let values = entry.translations.map(t => {
    t.index.to_string() + ":" + markup_part(t.value)
  })
  values.sort()
  join_strings(values, "")
}

///|
fn consistency_flags(entry : Entry) -> String {
  let flags = entry.flags.filter(flag => flag.has_suffix("-format"))
  flags.sort()
  join_strings(unique_strings(flags).map(markup_part), "")
}

///|
fn project_finding(
  catalogs : Array[Catalog],
  file_index : Int32,
  entry_index : Int32,
  code : String,
  severity : Severity,
  message : String,
  previous : ConsistencyReference?,
) -> ProjectFinding {
  let catalog = catalogs[file_index]
  let span = if entry_index >= 0 {
    catalogs[file_index].entries[entry_index].id_span
  } else {
    header_span(catalog)
  }
  let related_file = previous.map(p => catalogs[p.file_index].file)
  let related_span = previous.map(p => {
    catalogs[p.file_index].entries[p.entry_index].id_span
  })
  let hint = match previous {
    None =>
      "Consistency checks require valid Language metadata; no locale is guessed from a filename."
    Some(p) =>
      "Compare with " +
      catalogs[p.file_index].file +
      ":" +
      catalogs[p.file_index].entries[p.entry_index].id_span.start.line.to_string() +
      "; review deliberate translation differences before changing text."
  }
  let diagnostic = if entry_index < 0 {
    issue(code, severity, message, catalog.file, span, hint~)
  } else {
    issue(code, severity, message, catalog.file, span, entry=entry_index, hint~)
  }
  {
    file_index,
    diagnostic,
    related_file,
    related_span,
    related_entry: previous.map(p => p.entry_index),
  }
}

///|
/// Compare exact translated strings across separate catalogs in the same locale.
pub fn check_consistency(
  catalogs : Array[Catalog],
  options~ : ConsistencyOptions = {
    ..default_consistency_options(),
    enabled: true,
  },
) -> Array[ProjectFinding] {
  let result : Array[ProjectFinding] = []
  if !options.enabled {
    return result
  }
  if catalogs.is_empty() {
    return result
  }
  if options.max_entries < 1 || options.max_entries > 1000000 {
    return [
      project_finding(
        catalogs,
        0,
        -1,
        "O001",
        Error,
        "consistency max_entries must be in 1..1000000",
        None,
      ),
    ]
  }
  let mut total = 0
  for catalog in catalogs {
    total += catalog.entries.length()
    if total > options.max_entries {
      return [
        project_finding(
          catalogs,
          0,
          -1,
          "X009",
          Error,
          "Project entry resource limit exceeded; consistency comparison was not run",
          None,
        ),
      ]
    }
  }
  let sources : Map[String, ConsistencySource] = Map([])
  let targets : Map[String, ConsistencyTargets] = Map([])
  for file_index, catalog in catalogs {
    // Damaged catalogs already fail parsing; never infer conflicts from partial data.
    if catalog.entries.is_empty() ||
      catalog.diagnostics.any(d => d.severity == Error) {
      continue
    }
    let language = match consistency_locale(catalog) {
      Some(value) => value
      None => {
        result.push(
          project_finding(
            catalogs,
            file_index,
            -1,
            "X001",
            Warning,
            "Catalog omitted from consistency groups because Language metadata is missing or invalid",
            None,
          ),
        )
        continue
      }
    }
    for entry_index, entry in catalog.entries {
      if entry.obsolete ||
        entry.is_header() ||
        entry.has_flag("fuzzy") ||
        !entry.is_translated() {
        continue
      }
      let prefix = markup_part(language) +
        markup_part(consistency_context(entry, options))
      let key = prefix + markup_part(entry.id)
      let current = { file_index, entry_index, }
      let translation = consistency_translation(entry)
      let flags = consistency_flags(entry)
      if sources.get(key) is Some(previous) {
        if previous.reference.file_index != file_index {
          if previous.plural != entry.plural {
            result.push(
              project_finding(
                catalogs,
                file_index,
                entry_index,
                "X003",
                Error,
                "Same locale/context/source key has a different plural source across files",
                Some(previous.reference),
              ),
            )
          } else if previous.translation != translation {
            result.push(
              project_finding(
                catalogs,
                file_index,
                entry_index,
                "X002",
                Warning,
                "Same locale/context/source has conflicting translations across files",
                Some(previous.reference),
              ),
            )
          }
          if previous.flags != flags {
            result.push(
              project_finding(
                catalogs,
                file_index,
                entry_index,
                "X004",
                Warning,
                "Format flags differ for the same source key across files",
                Some(previous.reference),
              ),
            )
          }
        }
      } else {
        sources.set(key, {
          reference: current,
          plural: entry.plural,
          translation,
          flags,
        })
      }
      if options.inverse {
        let target_key = prefix + markup_part(translation)
        if targets.get(target_key) is Some(group) {
          let witnesses = [group.first]
          for p in group.outside_first_file {
            witnesses.push(p)
          }
          for p in group.outside_first_source {
            witnesses.push(p)
          }
          let mut previous : ConsistencyReference? = None
          for p in witnesses {
            if p.file_index != file_index &&
              catalogs[p.file_index].entries[p.entry_index].id != entry.id {
              previous = Some(p)
              break
            }
          }
          if previous is Some(previous) {
            result.push(
              project_finding(
                catalogs,
                file_index,
                entry_index,
                "X005",
                Warning,
                "Different sources share one translation across files (inverse review)",
                Some(previous),
              ),
            )
          }
          consistency_remember_target(group, current, catalogs)
        } else {
          targets.set(target_key, {
            first: current,
            outside_first_file: [],
            outside_first_source: [],
          })
        }
      }
    }
  }
  result
}

///|
pub fn project_finding_json(finding : ProjectFinding) -> Json {
  {
    "diagnostic": diagnostic_json(finding.diagnostic),
    "file_index": Json(finding.file_index),
    "related": match finding.related_file {
      None => Json::null()
      Some(file) =>
        {
          "file": Json(file),
          "span": match finding.related_span {
            None => Json::null()
            Some(span) => span_json(span)
          },
          "entry": optional_json(finding.related_entry),
        }
    },
  }
}
