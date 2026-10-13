///|
/// Diagnostic severity. Warning policy can be promoted by the caller.
pub(all) enum Severity {
  Error
  Warning
  Info
} derive(Eq, Debug)

///|
pub(all) struct Position {
  line : Int32
  column : Int32
} derive(Eq, Debug)

///|
pub(all) struct Span {
  start : Position
  end : Position
} derive(Eq, Debug)

///|
pub(all) struct Diagnostic {
  code : String
  severity : Severity
  message : String
  file : String
  span : Span
  entry : Int32?
  related : Span?
  hint : String
} derive(Eq, Debug)

///|
pub(all) struct Comment {
  kind : String
  text : String
  span : Span
} derive(Eq, Debug)

///|
pub(all) struct Translation {
  index : Int32
  value : String
  span : Span
} derive(Eq, Debug)

///|
pub(all) struct Entry {
  context : String?
  id : String
  plural : String?
  translations : Array[Translation]
  flags : Array[String]
  comments : Array[Comment]
  references : Array[String]
  obsolete : Bool
  span : Span
  id_span : Span
  plural_span : Span?
} derive(Eq, Debug)

///|
pub(all) struct Catalog {
  file : String
  entries : Array[Entry]
  diagnostics : Array[Diagnostic]
} derive(Debug)

///|
pub(all) struct Options {
  empty_severity : Severity
  fuzzy_severity : Severity
  strict : Bool
  plural_max : Int32
  expression_depth : Int32
  expression_budget : Int32
  max_entries : Int32
  max_line_chars : Int32
} derive(Eq, Debug)

///|
pub fn default_options() -> Options {
  {
    empty_severity: Warning,
    fuzzy_severity: Warning,
    strict: false,
    plural_max: 1000,
    expression_depth: 64,
    expression_budget: 10000,
    max_entries: 100000,
    max_line_chars: 1048576,
  }
}

///|
pub(all) struct Statistics {
  total : Int32
  active : Int32
  obsolete : Int32
  translated : Int32
  untranslated : Int32
  fuzzy : Int32
  plural : Int32
  errors : Int32
  warnings : Int32
  infos : Int32
} derive(Eq, Debug)

///|
pub(all) struct Report {
  catalog : Catalog
  diagnostics : Array[Diagnostic]
  stats : Statistics
  exit_code : Int32
  plural_checked_through : Int32?
} derive(Debug)

///|
fn point(line : Int32, column : Int32) -> Position {
  { line, column, }
}

///|
fn line_span(line : Int32, column : Int32, length : Int32) -> Span {
  { start: point(line, column), end: point(line, column + length), }
}

///|
fn issue(
  code : String,
  severity : Severity,
  message : String,
  file : String,
  span : Span,
  entry? : Int32,
  related? : Span,
  hint~ : String = "",
) -> Diagnostic {
  { code, severity, message, file, span, entry, related, hint, }
}

///|
pub fn Entry::translation(self : Entry, index : Int32) -> String? {
  for value in self.translations {
    if value.index == index {
      return Some(value.value)
    }
  }
  None
}

///|
pub fn Entry::has_flag(self : Entry, flag : String) -> Bool {
  self.flags.contains(flag)
}

///|
pub fn Entry::is_header(self : Entry) -> Bool {
  self.id == "" && self.context is None && !self.obsolete
}

///|
pub fn Entry::is_translated(self : Entry) -> Bool {
  !self.translations.is_empty() && self.translations.all(t => t.value != "")
}

///|
pub fn Catalog::header(self : Catalog) -> Entry? {
  for entry in self.entries {
    if entry.is_header() {
      return Some(entry)
    }
  }
  None
}

///|
pub fn severity_name(severity : Severity) -> String {
  match severity {
    Error => "error"
    Warning => "warning"
    Info => "info"
  }
}

///|
pub fn statistics(
  catalog : Catalog,
  diagnostics : Array[Diagnostic],
) -> Statistics {
  let mut active = 0
  let mut obsolete = 0
  let mut translated = 0
  let mut untranslated = 0
  let mut fuzzy = 0
  let mut plural = 0
  for entry in catalog.entries {
    if entry.obsolete {
      obsolete += 1
      continue
    }
    if entry.is_header() {
      continue
    }
    active += 1
    if entry.is_translated() {
      translated += 1
    } else {
      untranslated += 1
    }
    if entry.has_flag("fuzzy") {
      fuzzy += 1
    }
    if entry.plural is Some(_) {
      plural += 1
    }
  }
  let mut errors = 0
  let mut warnings = 0
  let mut infos = 0
  for diagnostic in diagnostics {
    match diagnostic.severity {
      Error => errors += 1
      Warning => warnings += 1
      Info => infos += 1
    }
  }
  {
    total: active + obsolete,
    active,
    obsolete,
    translated,
    untranslated,
    fuzzy,
    plural,
    errors,
    warnings,
    infos,
  }
}
