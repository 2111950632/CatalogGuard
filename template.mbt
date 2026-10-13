///|
pub(all) struct TemplateDelta {
  missing : Array[String]
  extra : Array[String]
  changed_plural : Array[String]
  changed_flags : Array[String]
  diagnostics : Array[Diagnostic]
} derive(Debug)

///|
fn display_key(entry : Entry) -> String {
  match entry.context {
    None => entry.id
    Some(context) => "[" + context + "] " + entry.id
  }
}

///|
fn active_index(catalog : Catalog) -> Map[String, Int32] {
  let index : Map[String, Int32] = Map([])
  for i, entry in catalog.entries {
    if !entry.obsolete && !entry.is_header() {
      index.set(entry_key(entry), i)
    }
  }
  index
}

///|
/// Match exact context/id keys; this does not guess fuzzy matches or edit files.
pub fn compare_template(
  template : Catalog,
  translation : Catalog,
) -> TemplateDelta {
  let missing : Array[String] = []
  let extra : Array[String] = []
  let changed_plural : Array[String] = []
  let changed_flags : Array[String] = []
  let diagnostics : Array[Diagnostic] = []
  let expected = active_index(template)
  let actual = active_index(translation)
  for entry in template.entries {
    if entry.obsolete || entry.is_header() {
      continue
    }
    let key = entry_key(entry)
    match actual.get(key) {
      None => {
        missing.push(display_key(entry))
        diagnostics.push(
          issue(
            "T001",
            Error,
            "Missing template entry: " + display_key(entry),
            translation.file,
            line_span(1, 1, 0),
            hint="Template source: " +
              template.file +
              ":" +
              entry.id_span.start.line.to_string(),
          ),
        )
      }
      Some(index) => {
        let translated = translation.entries[index]
        if entry.plural != translated.plural {
          changed_plural.push(display_key(entry))
          diagnostics.push(
            issue(
              "T003",
              Error,
              "Plural source differs from the template",
              translation.file,
              translated.plural_span.unwrap_or(translated.id_span),
              entry=index,
              hint="Template source: " +
                template.file +
                ":" +
                entry.id_span.start.line.to_string(),
            ),
          )
        }
        let mut flags_differ = false
        for flag in entry.flags {
          if flag.has_suffix("-format") && !translated.has_flag(flag) {
            flags_differ = true
          }
        }
        for flag in translated.flags {
          if flag.has_suffix("-format") && !entry.has_flag(flag) {
            flags_differ = true
          }
        }
        if flags_differ {
          changed_flags.push(display_key(entry))
          diagnostics.push(
            issue(
              "T004",
              Error,
              "Format flags differ from the template",
              translation.file,
              translated.span,
              entry=index,
            ),
          )
        }
      }
    }
  }
  for index, entry in translation.entries {
    if entry.obsolete || entry.is_header() {
      continue
    }
    if expected.get(entry_key(entry)) is None {
      extra.push(display_key(entry))
      diagnostics.push(
        issue(
          "T002",
          Warning,
          "Entry is absent from the template: " + display_key(entry),
          translation.file,
          entry.id_span,
          entry=index,
        ),
      )
    }
  }
  { missing, extra, changed_plural, changed_flags, diagnostics, }
}

///|
pub fn check_against_template(
  template : Catalog,
  translation : Catalog,
  options~ : Options = default_options(),
) -> Report {
  let report = check_catalog(translation, options~)
  let diagnostics = report.diagnostics.copy()
  let template_report = check_catalog(template, options~, template=true)
  for diagnostic in template_report.diagnostics {
    diagnostics.push(diagnostic)
  }
  if template_report.stats.errors == 0 {
    for diagnostic in compare_template(template, translation).diagnostics {
      diagnostics.push(diagnostic)
    }
  }
  report_with(translation, diagnostics, options, report.plural_checked_through)
}
