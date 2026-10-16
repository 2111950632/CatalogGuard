///|
fn trim_text(text : String) -> String {
  text.trim().to_owned()
}

///|
fn char_slice(chars : Array[Char], start : Int32, end : Int32) -> String {
  String::from_array(chars[start:end])
}

///|
fn split_lines(text : String) -> Array[String] {
  text
  .split("\n")
  .map(line => {
    let value = line.to_owned()
    if value.has_suffix("\r") {
      value[:value.length() - 1].to_owned()
    } else {
      value
    }
  })
  .to_array()
}

///|
fn ascii_digit(c : Char) -> Int32? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else {
    None
  }
}

///|
fn decimal_text(text : String, limit : Int32) -> Int32? {
  let chars = text.to_array()
  if chars.is_empty() {
    return None
  }
  let mut value = 0
  for c in chars {
    match ascii_digit(c) {
      None => return None
      Some(digit) => {
        if digit > limit || value > (limit - digit) / 10 {
          return None
        }
        value = value * 10 + digit
      }
    }
  }
  Some(value)
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let output : Array[String] = []
  for value in values {
    if !output.contains(value) {
      output.push(value)
    }
  }
  output
}

///|
fn join_strings(values : Array[String], separator : String) -> String {
  let mut result = ""
  for index, value in values {
    if index != 0 {
      result += separator
    }
    result += value
  }
  result
}

///|
fn skip_spaces(chars : Array[Char], from : Int32) -> Int32 {
  let mut index = from
  while index < chars.length() && (chars[index] == ' ' || chars[index] == '\t') {
    index += 1
  }
  index
}

///|
fn entry_key(entry : Entry) -> String {
  // Prefix each component with its length to avoid separator collisions.
  let context = entry.context.unwrap_or("")
  let present = if entry.context is Some(_) { "1" } else { "0" }
  "\{present}:\{context.length()}:\{context}\{entry.id.length()}:\{entry.id}"
}

///|
fn translated_span(entry : Entry, index : Int32) -> Span {
  for translation in entry.translations {
    if translation.index == index {
      return translation.span
    }
  }
  entry.span
}
