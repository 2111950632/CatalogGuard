///|
pub(all) struct ContextSummary {
  context : String?
  active : Int32
  translated : Int32
  fuzzy : Int32
  plural : Int32
  characters : Int32
} derive(Eq, Debug)

///|
pub(all) struct Reference {
  path : String
  line : Int32?
} derive(Eq, Debug)

///|
/// Split a terminal :line without confusing a Windows drive letter.
pub fn parse_reference(value : String) -> Reference {
  let chars = value.to_array()
  let mut colon = -1
  for i, c in chars {
    if c == ':' {
      colon = i
    }
  }
  if colon > 0 && colon + 1 < chars.length() {
    match
      decimal_text(char_slice(chars, colon + 1, chars.length()), 2147483647) {
      Some(line) =>
        if line > 0 {
          return { path: char_slice(chars, 0, colon), line: Some(line), }
        }
      None => ()
    }
  }
  { path: value, line: None, }
}

///|
/// Group workload by exact context, retaining null versus empty context.
pub fn context_summaries(catalog : Catalog) -> Array[ContextSummary] {
  let positions : Map[String, Int32] = Map([])
  let groups : Array[ContextSummary] = []
  for entry in catalog.entries {
    if entry.obsolete || entry.is_header() {
      continue
    }
    let key = match entry.context {
      None => "none"
      Some(value) => "some:" + value
    }
    let position = match positions.get(key) {
      Some(position) => position
      None => {
        let position = groups.length()
        positions.set(key, position)
        groups.push({
          context: entry.context,
          active: 0,
          translated: 0,
          fuzzy: 0,
          plural: 0,
          characters: 0,
        })
        position
      }
    }
    let previous = groups[position]
    groups[position] = {
      context: previous.context,
      active: previous.active + 1,
      translated: previous.translated +
      (if entry.is_translated() { 1 } else { 0 }),
      fuzzy: previous.fuzzy + (if entry.has_flag("fuzzy") { 1 } else { 0 }),
      plural: previous.plural + (if entry.plural is Some(_) { 1 } else { 0 }),
      characters: previous.characters + entry.id.to_array().length(),
    }
  }
  groups
}

///|
pub fn catalog_summary_json(catalog : Catalog) -> Json {
  let reference_files : Map[String, Int32] = Map([])
  let mut unreferenced = 0
  for entry in catalog.entries {
    if entry.obsolete || entry.is_header() {
      continue
    }
    if entry.references.is_empty() {
      unreferenced += 1
    }
    let seen : Map[String, Bool] = Map([])
    for reference in entry.references {
      let path = parse_reference(reference).path
      if seen.get(path) is None {
        reference_files.set(path, reference_files.get(path).unwrap_or(0) + 1)
        seen.set(path, true)
      }
    }
  }
  let paths = reference_files.keys().to_array()
  paths.sort()
  let header = read_header(catalog)
  {
    "language": Json(header.get("Language")),
    "project": Json(header.get("Project-Id-Version")),
    "unreferenced": Json(unreferenced),
    "contexts": Json(
      context_summaries(catalog).map(group => {
        "context": Json(group.context),
        "active": Json(group.active),
        "translated": Json(group.translated),
        "fuzzy": Json(group.fuzzy),
        "plural": Json(group.plural),
        "source_characters": Json(group.characters),
      }),
    ),
    "references": Json(
      paths.map(path => {
        "path": Json(path),
        "entries": Json(reference_files.get(path).unwrap_or(0)),
      }),
    ),
  }
}
