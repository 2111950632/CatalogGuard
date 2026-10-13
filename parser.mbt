///|
priv enum Field {
  NoField
  ContextField
  IdField
  PluralField
  TranslationField(Int)
} derive(Eq, Debug)

///|
priv struct TranslationBuilder {
  index : Int
  bytes : Array[Byte]
  span : Span
}

///|
priv struct EntryBuilder {
  mut context : Array[Byte]?
  mut id : Array[Byte]?
  mut plural : Array[Byte]?
  translations : Array[TranslationBuilder]
  comments : Array[Comment]
  flags : Array[String]
  references : Array[String]
  mut obsolete : Bool
  mut start : Position?
  mut end : Position
  mut id_span : Span?
  mut plural_span : Span?
  mut field : Field
}

///|
fn new_builder() -> EntryBuilder {
  {
    context: None,
    id: None,
    plural: None,
    translations: [],
    comments: [],
    flags: [],
    references: [],
    obsolete: false,
    start: None,
    end: point(1, 1),
    id_span: None,
    plural_span: None,
    field: NoField,
  }
}

///|
fn hex_digit(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
fn quoted_bytes(chars : Array[Char], from : Int) -> Result[Array[Byte], String] {
  let mut index = skip_spaces(chars, from)
  if index >= chars.length() || chars[index] != '"' {
    return Err("Expected a quoted string")
  }
  index += 1
  let bytes : Array[Byte] = []
  let mut closed = false
  while index < chars.length() {
    let c = chars[index]
    index += 1
    if c == '"' {
      closed = true
      break
    }
    if c != '\\' {
      if c == '\u0000' || c == '\r' || c == '\n' {
        return Err("Unescaped control character inside a PO string")
      }
      for byte in @utf8.encode(c.to_string()[:]) {
        bytes.push(byte)
      }
      continue
    }
    if index >= chars.length() {
      return Err("A backslash at the end of a quoted string is incomplete")
    }
    let escaped = chars[index]
    index += 1
    let value = match escaped {
      'n' => 10
      'r' => 13
      't' => 9
      'b' => 8
      'f' => 12
      'v' => 11
      'a' => 7
      '"' => 34
      '\\' => 92
      '0'..='7' => {
        let mut number = escaped.to_int() - '0'.to_int()
        let mut count = 1
        while count < 3 && index < chars.length() &&
          chars[index] >= '0' && chars[index] <= '7' {
          number = number * 8 + chars[index].to_int() - '0'.to_int()
          index += 1
          count += 1
        }
        if number > 255 {
          return Err("Octal escape is outside the byte range")
        }
        number
      }
      'x' => {
        let mut number = 0
        let mut count = 0
        while index < chars.length() {
          match hex_digit(chars[index]) {
            None => break
            Some(digit) => {
              if number > (255 - digit) / 16 {
                return Err("Hex escape is outside the byte range")
              }
              number = number * 16 + digit
              index += 1
              count += 1
            }
          }
        }
        if count == 0 {
          return Err("Hex escape requires at least one digit")
        }
        number
      }
      _ => return Err("Unsupported PO escape: \\" + escaped.to_string())
    }
    bytes.push(value.to_byte())
  }
  if !closed {
    return Err("Quoted string has no closing quote")
  }
  if skip_spaces(chars, index) != chars.length() {
    return Err("Unexpected content after the closing quote")
  }
  Ok(bytes)
}

///|
fn decode_field(
  bytes : Array[Byte],
  file : String,
  span : Span,
  diagnostics : Array[Diagnostic],
) -> String {
  try @utf8.decode(Bytes::from_array(bytes)[:]) catch {
    _ => {
      diagnostics.push(issue(
        "P008",
        Error,
        "Quoted byte escapes do not form valid UTF-8",
        file,
        span,
        hint="This release accepts UTF-8 catalogs only.",
      ))
      ""
    }
  }
}

///|
fn finish_builder(
  builder : EntryBuilder,
  file : String,
  diagnostics : Array[Diagnostic],
) -> Entry? {
  let start = builder.start.unwrap_or(point(1, 1))
  let span = { start, end: builder.end }
  let id_span = builder.id_span.unwrap_or(span)
  let id = match builder.id {
    None => {
      if builder.context is Some(_) || !builder.translations.is_empty() {
        diagnostics.push(issue(
          "P003", Error, "Entry has fields but no msgid", file, span,
        ))
      }
      return None
    }
    Some(bytes) => decode_field(bytes, file, id_span, diagnostics)
  }
  let context = builder.context.map(bytes =>
    decode_field(bytes, file, span, diagnostics))
  let plural = builder.plural.map(bytes =>
    decode_field(bytes, file, builder.plural_span.unwrap_or(span), diagnostics))
  let translations = builder.translations.map(t => {
    {
      index: t.index,
      value: decode_field(t.bytes, file, t.span, diagnostics),
      span: t.span,
    }
  })
  Some({
    context,
    id,
    plural,
    translations,
    flags: unique_strings(builder.flags),
    comments: builder.comments.copy(),
    references: unique_strings(builder.references),
    obsolete: builder.obsolete,
    span,
    id_span,
    plural_span: builder.plural_span,
  })
}

///|
fn add_comment(builder : EntryBuilder, text : String, span : Span) -> Unit {
  let chars = text.to_array()
  let marker = if chars.length() > 1 { chars[1] } else { ' ' }
  let (kind, content) = match marker {
    ',' => ("flags", trim_text(char_slice(chars, 2, chars.length())))
    ':' => ("reference", trim_text(char_slice(chars, 2, chars.length())))
    '.' => ("extracted", trim_text(char_slice(chars, 2, chars.length())))
    '|' => ("previous", trim_text(char_slice(chars, 2, chars.length())))
    _ => ("translator", trim_text(char_slice(chars, 1, chars.length())))
  }
  builder.comments.push({ kind, text: content, span })
  if kind == "flags" {
    for flag in content.split(",") {
      let value = flag.trim().to_owned()
      if value != "" {
        builder.flags.push(value)
      }
    }
  }
  if kind == "reference" {
    let tokens = content.to_array()
    let mut start = 0
    for index, c in tokens {
      if c.is_whitespace() {
        if index > start {
          builder.references.push(char_slice(tokens, start, index))
        }
        start = index + 1
      }
    }
    if start < tokens.length() {
      builder.references.push(char_slice(tokens, start, tokens.length()))
    }
  }
}

///|
fn append_field(builder : EntryBuilder, bytes : Array[Byte]) -> Bool {
  match builder.field {
    NoField => return false
    ContextField => builder.context.iter().each(target =>
      bytes.each(byte => target.push(byte)))
    IdField => builder.id.iter().each(target =>
      bytes.each(byte => target.push(byte)))
    PluralField => builder.plural.iter().each(target =>
      bytes.each(byte => target.push(byte)))
    TranslationField(index) =>
      for t in builder.translations {
        if t.index == index {
          bytes.each(byte => t.bytes.push(byte))
        }
      }
  }
  true
}

///|
/// Parse a catalog without throwing. Malformed entries produce diagnostics.
pub fn parse_catalog(
  text : String,
  file? : String = "<memory>",
  options? : Options = default_options(),
) -> Catalog {
  let lines = split_lines(text)
  let entries : Array[Entry] = []
  let diagnostics : Array[Diagnostic] = []
  let mut builder = new_builder()
  for line_index, source in lines {
    let line_number = line_index + 1
    let mut chars = source.to_array()
    if line_index == 0 && !chars.is_empty() && chars[0] == '\uFEFF' {
      chars = chars[1:].to_owned()
    }
    if chars.length() > options.max_line_chars {
      diagnostics.push(issue(
        "P009", Error, "Line exceeds the configured character limit",
        file, line_span(line_number, 1, 1),
      ))
      break
    }
    let mut offset = skip_spaces(chars, 0)
    if offset == chars.length() {
      if finish_builder(builder, file, diagnostics) is Some(entry) {
        entries.push(entry)
      }
      builder = new_builder()
      continue
    }
    let mut obsolete = false
    if chars.length() >= offset + 2 &&
      chars[offset] == '#' && chars[offset + 1] == '~' {
      obsolete = true
      offset = skip_spaces(chars, offset + 2)
    }
    let content = char_slice(chars, offset, chars.length())
    let span = line_span(line_number, offset + 1, chars.length() - offset)
    if content.has_prefix("#") {
      if !builder.translations.is_empty() {
        if finish_builder(builder, file, diagnostics) is Some(entry) {
          entries.push(entry)
        }
        builder = new_builder()
      }
      add_comment(builder, content, span)
      if builder.start is None {
        builder.start = Some(span.start)
      }
      builder.obsolete = obsolete
      continue
    }
    if content == "" {
      continue
    }
    let data = content.to_array()
    if data[0] == '"' {
      if builder.obsolete != obsolete {
        diagnostics.push(issue(
          "P006", Error, "Continuation changes active/obsolete status",
          file, span,
        ))
        continue
      }
      match quoted_bytes(data, 0) {
        Err(message) =>
          diagnostics.push(issue("P002", Error, message, file, span))
        Ok(bytes) =>
          if !append_field(builder, bytes) {
            diagnostics.push(issue(
              "P004", Error, "String continuation has no preceding field",
              file, span,
            ))
          }
      }
      builder.end = span.end
      continue
    }
    let mut word_end = 0
    while word_end < data.length() &&
      (data[word_end].is_ascii_alphabetic() || data[word_end] == '_') {
      word_end += 1
    }
    let word = char_slice(data, 0, word_end)
    let starts_entry = (word == "msgid" && builder.id is Some(_)) ||
      (word == "msgctxt" && builder.id is Some(_))
    if starts_entry {
      if finish_builder(builder, file, diagnostics) is Some(entry) {
        entries.push(entry)
      }
      builder = new_builder()
    }
    if entries.length() >= options.max_entries {
      diagnostics.push(issue(
        "P009", Error, "Catalog exceeds the configured entry limit",
        file, span,
      ))
      break
    }
    if builder.start is None {
      builder.start = Some(span.start)
    }
    if builder.id is Some(_) && builder.obsolete != obsolete {
      diagnostics.push(issue(
        "P006", Error, "Entry mixes active and obsolete fields", file, span,
      ))
    }
    builder.obsolete = obsolete
    builder.end = span.end
    let mut value_start = word_end
    let field = match word {
      "msgctxt" => ContextField
      "msgid" => IdField
      "msgid_plural" => PluralField
      "msgstr" => {
        if value_start < data.length() && data[value_start] == '[' {
          value_start += 1
          let index_start = value_start
          while value_start < data.length() && data[value_start].is_ascii_digit() {
            value_start += 1
          }
          if value_start >= data.length() || data[value_start] != ']' {
            diagnostics.push(issue(
              "P005", Error, "msgstr index requires digits and a closing bracket",
              file, span,
            ))
            builder.field = NoField
            continue
          }
          let parsed = decimal_text(
            char_slice(data, index_start, value_start), 10000,
          )
          value_start += 1
          match parsed {
            Some(index) => TranslationField(index)
            None => {
              diagnostics.push(issue(
                "P005", Error, "msgstr index is invalid or exceeds 10000",
                file, span,
              ))
              continue
            }
          }
        } else {
          TranslationField(0)
        }
      }
      _ => {
        diagnostics.push(issue(
          "P001", Error, "Unknown PO directive: " + word, file, span,
        ))
        builder.field = NoField
        continue
      }
    }
    if value_start < data.length() &&
      data[value_start] != ' ' && data[value_start] != '\t' {
      diagnostics.push(issue(
        "P001", Error, "A directive must be followed by whitespace",
        file, span,
      ))
      continue
    }
    let bytes = match quoted_bytes(data, value_start) {
      Ok(bytes) => bytes
      Err(message) => {
        diagnostics.push(issue("P002", Error, message, file, span))
        builder.field = NoField
        continue
      }
    }
    let mut duplicate = false
    match field {
      ContextField => {
        duplicate = builder.context is Some(_)
        builder.context = Some(bytes)
      }
      IdField => {
        builder.id = Some(bytes)
        builder.id_span = Some(span)
      }
      PluralField => {
        duplicate = builder.plural is Some(_)
        builder.plural = Some(bytes)
        builder.plural_span = Some(span)
      }
      TranslationField(index) => {
        duplicate = builder.translations.any(t => t.index == index)
        if !duplicate {
          builder.translations.push({ index, bytes, span })
        }
        if builder.id is None {
          diagnostics.push(issue(
            "P007", Error, "msgstr must follow msgid", file, span,
          ))
        }
      }
      NoField => ()
    }
    if duplicate {
      diagnostics.push(issue(
        "P010", Error, "Duplicate field inside an entry", file, span,
      ))
      builder.field = NoField
    } else {
      builder.field = field
    }
  }
  if finish_builder(builder, file, diagnostics) is Some(entry) {
    if entries.length() < options.max_entries {
      entries.push(entry)
    }
  }
  { file, entries, diagnostics }
}
