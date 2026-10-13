///|
/// Encode a string as a PO quoted literal, preserving Unicode code points.
pub fn quote_po(text : String) -> String {
  let parts : Array[String] = ["\""]
  for c in text.to_array() {
    let encoded = match c {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      '\u0008' => "\\b"
      '\u000C' => "\\f"
      _ => {
        let code = c.to_int()
        if code < 32 || code == 127 {
          "\\" +
          (code / 64).to_string() +
          (code / 8 % 8).to_string() +
          (code % 8).to_string()
        } else {
          c.to_string()
        }
      }
    }
    parts.push(encoded)
  }
  parts.push("\"")
  join_strings(parts, "")
}

///|
fn emit_po_field(
  lines : Array[String],
  prefix : String,
  name : String,
  value : String,
) -> Unit {
  if !value.contains("\n") {
    lines.push(prefix + name + " " + quote_po(value))
    return
  }
  lines.push(prefix + name + " \"\"")
  let chars = value.to_array()
  let mut start = 0
  for i, c in chars {
    if c == '\n' {
      lines.push(prefix + quote_po(char_slice(chars, start, i + 1)))
      start = i + 1
    }
  }
  if start < chars.length() {
    lines.push(prefix + quote_po(char_slice(chars, start, chars.length())))
  }
}

///|
fn serialized_entry(entry : Entry) -> Result[String, String] {
  if entry.context is Some(context) {
    if context.to_array().any(c => c == '\u0000') {
      return Err("Cannot normalize a context containing NUL")
    }
  }
  let seen : Map[Int32, Bool] = Map([])
  for translation in entry.translations {
    if translation.index < 0 || seen.get(translation.index) is Some(_) {
      return Err("Cannot normalize a duplicate or negative translation index")
    }
    seen.set(translation.index, true)
  }
  if entry.comments.any(c => c.text.contains("\n") || c.text.contains("\r")) {
    return Err("Comment data contains a raw newline")
  }
  if entry.translations.is_empty() {
    return Err("Cannot normalize an entry without a translation field")
  }
  if entry.plural is None &&
    (entry.translations.length() != 1 || entry.translations[0].index != 0) {
    return Err("Cannot normalize indexed translations on a singular entry")
  }
  let lines : Array[String] = []
  let prefix = if entry.obsolete { "#~ " } else { "" }
  for comment in entry.comments {
    if comment.kind == "flags" {
      continue
    }
    let marker = match comment.kind {
      "reference" => "#:"
      "extracted" => "#."
      "previous" => "#|"
      _ => "#"
    }
    lines.push(prefix + marker + " " + comment.text)
  }
  if !entry.flags.is_empty() {
    lines.push(prefix + "#, " + join_strings(entry.flags, ", "))
  }
  if entry.context is Some(context) {
    emit_po_field(lines, prefix, "msgctxt", context)
  }
  emit_po_field(lines, prefix, "msgid", entry.id)
  if entry.plural is Some(plural) {
    emit_po_field(lines, prefix, "msgid_plural", plural)
  }
  let order = entry.translations.map(t => t.index)
  order.sort()
  for index in order {
    let name = if entry.plural is Some(_) {
      "msgstr[" + index.to_string() + "]"
    } else {
      "msgstr"
    }
    emit_po_field(lines, prefix, name, entry.translation(index).unwrap_or(""))
  }
  Ok(join_strings(lines, "\n"))
}

///|
/// Canonical syntax only. Refuses parse errors; no automatic translation fixes.
pub fn serialize_catalog(catalog : Catalog) -> Result[String, String] {
  if !catalog.diagnostics.is_empty() {
    return Err("Cannot normalize a catalog with parse diagnostics")
  }
  let entries : Array[String] = []
  for entry in catalog.entries {
    match serialized_entry(entry) {
      Ok(value) => entries.push(value)
      Err(error) =>
        return Err(
          error + " at source line " + entry.id_span.start.line.to_string(),
        )
    }
  }
  if entries.is_empty() {
    Ok("")
  } else {
    Ok(join_strings(entries, "\n\n") + "\n")
  }
}
