///|
pub(all) struct HeaderField {
  name : String
  value : String
  span : Span
} derive(Eq, Debug)

///|
pub(all) struct CatalogHeader {
  fields : Array[HeaderField]
  diagnostics : Array[Diagnostic]
} derive(Debug)

///|
pub fn CatalogHeader::get(self : CatalogHeader, name : String) -> String? {
  let key = name.to_lower()
  for field in self.fields {
    if field.name.to_lower() == key {
      return Some(field.value)
    }
  }
  None
}

///|
/// Header spans point to the containing msgstr, not guessed decoded line positions.
pub fn read_header(catalog : Catalog) -> CatalogHeader {
  let fields : Array[HeaderField] = []
  let diagnostics : Array[Diagnostic] = []
  let entry = match catalog.header() {
    None => {
      diagnostics.push(
        issue(
          "H001",
          Warning,
          "Catalog has no metadata header",
          catalog.file,
          line_span(1, 1, 0),
        ),
      )
      return { fields, diagnostics, }
    }
    Some(entry) => entry
  }
  let value = entry.translation(0).unwrap_or("")
  let span = translated_span(entry, 0)
  let seen : Map[String, Bool] = Map([])
  for line in split_lines(value) {
    if trim_text(line) == "" {
      continue
    }
    let chars = line.to_array()
    let mut colon = -1
    for i, c in chars {
      if c == ':' {
        colon = i
        break
      }
    }
    if colon <= 0 {
      diagnostics.push(
        issue(
          "H002",
          Error,
          "Header line requires a field name and colon: " + line,
          catalog.file,
          span,
        ),
      )
      continue
    }
    let name = trim_text(char_slice(chars, 0, colon))
    let value = trim_text(char_slice(chars, colon + 1, chars.length()))
    if !name
      .to_array()
      .all(c => (c.is_ascii_alphabetic() || c.is_ascii_digit()) || c == '-') {
      diagnostics.push(
        issue(
          "H002",
          Error,
          "Invalid metadata field name: " + name,
          catalog.file,
          span,
        ),
      )
      continue
    }
    let key = name.to_lower()
    if seen.get(key) is Some(_) {
      diagnostics.push(
        issue(
          "H003",
          Error,
          "Duplicate metadata field: " + name,
          catalog.file,
          span,
        ),
      )
    }
    seen.set(key, true)
    fields.push({ name, value, span, })
  }
  { fields, diagnostics, }
}

///|
fn header_span(catalog : Catalog) -> Span {
  match catalog.header() {
    None => line_span(1, 1, 0)
    Some(entry) => translated_span(entry, 0)
  }
}

///|
fn charset_of(content_type : String) -> String? {
  for fragment in content_type.split(";") {
    let value = trim_text(fragment.to_owned())
    let parts = value.split("=").map(p => trim_text(p.to_owned())).to_array()
    if parts.length() == 2 && parts[0].to_lower() == "charset" {
      let raw = parts[1].to_array()
      if raw.length() >= 2 && raw[0] == '"' && raw[raw.length() - 1] == '"' {
        return Some(char_slice(raw, 1, raw.length() - 1))
      }
      return Some(parts[1])
    }
  }
  None
}

///|
fn plausible_language(value : String) -> Bool {
  let chars = value.to_array()
  if chars.is_empty() || !chars[0].is_ascii_alphabetic() {
    return false
  }
  chars.all(c => {
    (c.is_ascii_alphabetic() || c.is_ascii_digit()) ||
    ['_', '-', '@', '.'].contains(c)
  })
}

///|
fn date_number(chars : Array[Char], start : Int32, end : Int32) -> Int32? {
  if end > chars.length() {
    return None
  }
  decimal_text(char_slice(chars, start, end), 9999)
}

///|
fn valid_po_date(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() != 21 ||
    chars[4] != '-' ||
    chars[7] != '-' ||
    chars[10] != ' ' ||
    chars[13] != ':' ||
    (chars[16] != '+' && chars[16] != '-') {
    return false
  }
  let year = date_number(chars, 0, 4).unwrap_or(-1)
  let month = date_number(chars, 5, 7).unwrap_or(-1)
  let day = date_number(chars, 8, 10).unwrap_or(-1)
  let hour = date_number(chars, 11, 13).unwrap_or(-1)
  let minute = date_number(chars, 14, 16).unwrap_or(-1)
  let zone_hour = date_number(chars, 17, 19).unwrap_or(-1)
  let zone_minute = date_number(chars, 19, 21).unwrap_or(-1)
  if year < 1 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59 ||
    zone_hour < 0 ||
    zone_hour > 23 ||
    zone_minute < 0 ||
    zone_minute > 59 {
    return false
  }
  let days = match month {
    4 | 6 | 9 | 11 => 30
    2 =>
      if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) {
        29
      } else {
        28
      }
    _ => 31
  }
  day <= days
}

///|
pub fn validate_header(
  catalog : Catalog,
  header : CatalogHeader,
  template~ : Bool = false,
) -> Array[Diagnostic] {
  let result = header.diagnostics.copy()
  if catalog.header() is None {
    return result
  }
  let span = header_span(catalog)
  for
    name in [
      "Project-Id-Version", "MIME-Version", "Content-Type", "Content-Transfer-Encoding",
    ] {
    match header.get(name) {
      None =>
        result.push(
          issue(
            "H006",
            Warning,
            "Missing metadata field " + name,
            catalog.file,
            span,
          ),
        )
      Some(value) =>
        if value == "" {
          result.push(
            issue(
              "H006",
              Warning,
              "Metadata field is empty: " + name,
              catalog.file,
              span,
            ),
          )
        }
    }
  }
  match header.get("Content-Type") {
    None => ()
    Some(value) => {
      if !value.to_lower().has_prefix("text/plain") {
        result.push(
          issue(
            "H004",
            Error,
            "Content-Type must describe a text/plain catalog",
            catalog.file,
            span,
          ),
        )
      }
      match charset_of(value) {
        None =>
          result.push(
            issue(
              "H004",
              Error,
              "Content-Type has no charset",
              catalog.file,
              span,
            ),
          )
        Some(charset) =>
          if charset.to_lower() != "utf-8" && charset.to_lower() != "utf8" {
            result.push(
              issue(
                "H004",
                Error,
                "Unsupported catalog encoding: " + charset,
                catalog.file,
                span,
                hint="Convert the original file to UTF-8 before checking it.",
              ),
            )
          }
      }
    }
  }
  if header.get("MIME-Version") is Some(value) {
    if value != "1.0" {
      result.push(
        issue("H005", Warning, "Expected MIME-Version 1.0", catalog.file, span),
      )
    }
  }
  if header.get("Content-Transfer-Encoding") is Some(value) {
    if value.to_lower() != "8bit" {
      result.push(
        issue(
          "H005",
          Error,
          "Only Content-Transfer-Encoding: 8bit is supported",
          catalog.file,
          span,
        ),
      )
    }
  }
  if !template {
    match header.get("Language") {
      None =>
        result.push(
          issue(
            "H007",
            Warning,
            "Missing Language metadata",
            catalog.file,
            span,
          ),
        )
      Some(value) =>
        if !plausible_language(value) {
          result.push(
            issue(
              "H007",
              Warning,
              "Language metadata is empty or malformed",
              catalog.file,
              span,
            ),
          )
        }
    }
  }
  for name in ["PO-Revision-Date", "POT-Creation-Date"] {
    if header.get(name) is Some(value) {
      if value != "" && !valid_po_date(value) {
        result.push(
          issue(
            "H008",
            Warning,
            "Invalid " + name + ": expected YYYY-MM-DD HH:MM+ZZZZ",
            catalog.file,
            span,
          ),
        )
      }
    }
  }
  for name in ["Project-Id-Version", "Last-Translator", "Language-Team"] {
    if header.get(name) is Some(value) {
      if value.contains("PACKAGE VERSION") ||
        value.contains("FULL NAME") ||
        value.contains("LANGUAGE <") {
        result.push(
          issue(
            "H009",
            Warning,
            "Unfilled metadata placeholder in " + name,
            catalog.file,
            span,
          ),
        )
      }
    }
  }
  result
}
