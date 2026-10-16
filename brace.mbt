///|
priv struct BraceState {
  arguments : Array[FormatArgument]
  kinds : Map[String, String]
  mut automatic : Bool
  mut numbered : Bool
  mut next : Int32
}

///|
fn brace_name(state : BraceState, raw : String) -> Result[String, String] {
  if raw == "" {
    state.automatic = true
    if state.numbered {
      return Err("Cannot mix automatic and numbered brace fields")
    }
    let index = state.next
    state.next += 1
    return Ok(index.to_string())
  }
  let chars = raw.to_array()
  let mut i = 0
  while i < chars.length() && chars[i] != '.' && chars[i] != '[' {
    i += 1
  }
  let root = char_slice(chars, 0, i)
  let mut canonical = if root == "" {
    match brace_name(state, "") {
      Ok(name) => name
      Err(error) => return Err(error)
    }
  } else {
    root
  }
  if root != "" && root.to_array().all(c => format_decimal_digit(c) is Some(_)) {
    canonical = match format_decimal_text(root, 10000) {
      None => return Err("Brace argument index exceeds 10000")
      Some(index) => index.to_string()
    }
    state.numbered = true
    if state.automatic {
      return Err("Cannot mix automatic and numbered brace fields")
    }
  }
  while i < chars.length() {
    if chars[i] == '.' {
      i += 1
      let start = i
      while i < chars.length() && chars[i] != '.' && chars[i] != '[' {
        i += 1
      }
      if i == start {
        return Err("Invalid attribute in brace field")
      }
      canonical += "." + char_slice(chars, start, i)
    } else if chars[i] == '[' {
      i += 1
      let start = i
      while i < chars.length() && chars[i] != ']' {
        i += 1
      }
      if i == start || i == chars.length() {
        return Err("Brace index requires content and a closing bracket")
      }
      let index_text = char_slice(chars, start, i)
      let index = if index_text
        .to_array()
        .all(c => format_decimal_digit(c) is Some(_)) {
        match format_decimal_text(index_text, 2147483647) {
          Some(index) => index.to_string()
          None =>
            return Err("Brace element index exceeds the signed 32-bit range")
        }
      } else {
        index_text
      }
      canonical += "[" + index + "]"
      i += 1
    } else {
      return Err("Unexpected character in brace field")
    }
  }
  Ok(canonical)
}

///|
fn brace_presentation(spec : String) -> Result[String, String] {
  let chars = spec.to_array()
  if chars.is_empty() {
    return Ok("default")
  }
  let mut i = 0
  let mut numeric_align = false
  if chars.length() >= 2 && ['<', '>', '=', '^'].contains(chars[1]) {
    numeric_align = chars[1] == '='
    i = 2
  } else if ['<', '>', '=', '^'].contains(chars[0]) {
    numeric_align = chars[0] == '='
    i = 1
  }
  let mut sign = false
  if i < chars.length() && ['+', '-', ' '].contains(chars[i]) {
    sign = true
    i += 1
  }
  let mut negative_zero = false
  if i < chars.length() && chars[i] == 'z' {
    negative_zero = true
    i += 1
  }
  let mut alternate = false
  if i < chars.length() && chars[i] == '#' {
    alternate = true
    i += 1
  }
  if i < chars.length() && chars[i] == '0' {
    i += 1
  }
  while i < chars.length() && chars[i].is_ascii_digit() {
    i += 1
  }
  let mut grouping = false
  let mut comma = false
  if i < chars.length() && [',', '_'].contains(chars[i]) {
    grouping = true
    comma = chars[i] == ','
    i += 1
  }
  let mut precision = false
  if i < chars.length() && chars[i] == '.' {
    precision = true
    i += 1
    let start = i
    while i < chars.length() && chars[i].is_ascii_digit() {
      i += 1
    }
    if i == start {
      return Err("Brace precision requires a number or a nested field")
    }
  }
  if i == chars.length() {
    return Ok(
      if numeric_align || sign || negative_zero || alternate || grouping {
        "numeric"
      } else {
        "default"
      },
    )
  }
  if i + 1 != chars.length() {
    return Err("Unsupported brace format specification: " + spec)
  }
  let kind = match chars[i] {
    'b' | 'd' | 'o' | 'x' | 'X' => "integer"
    'e' | 'E' | 'f' | 'F' | 'g' | 'G' | '%' => "numeric"
    'n' => "locale-numeric"
    'c' => "character"
    's' => "string"
    _ =>
      return Err("Unsupported brace presentation type: " + chars[i].to_string())
  }
  if kind == "string" &&
    (numeric_align || sign || negative_zero || alternate || grouping) {
    return Err("String presentation does not accept numeric format options")
  }
  if (kind == "integer" || kind == "character") && precision {
    return Err("Integer and character presentation do not accept precision")
  }
  if negative_zero && kind != "numeric" {
    return Err("Negative zero coercion requires floating-point presentation")
  }
  if kind == "locale-numeric" && grouping {
    return Err("Locale n presentation does not accept a grouping option")
  }
  if kind == "character" && (sign || alternate || grouping) {
    return Err(
      "Character presentation does not accept sign, alternate form, or grouping",
    )
  }
  if comma && ['b', 'o', 'x', 'X'].contains(chars[i]) {
    return Err("Non-decimal integer presentation requires underscore grouping")
  }
  Ok(kind)
}

///|
fn brace_field(
  chars : Array[Char],
  start : Int32,
  state : BraceState,
  depth : Int32,
) -> Result[Int32, String] {
  if depth > 1 {
    return Err(
      "Python str.format permits only one nested replacement-field level",
    )
  }
  let mut i = start + 1
  let name_start = i
  let mut bracket = false
  while i < chars.length() {
    let c = chars[i]
    if c == '[' {
      bracket = true
    } else if c == ']' {
      bracket = false
    }
    if !bracket && (c == '!' || c == ':' || c == '}') {
      break
    }
    if c == '{' && !bracket {
      return Err("Unexpected opening brace inside a field name")
    }
    i += 1
  }
  if i == chars.length() {
    return Err("Brace field has no closing brace")
  }
  let name = match brace_name(state, char_slice(chars, name_start, i)) {
    Ok(name) => name
    Err(error) => return Err(error)
  }
  let mut conversion = ""
  if chars[i] == '!' {
    i += 1
    if i >= chars.length() || !['s', 'r', 'a'].contains(chars[i]) {
      return Err("Brace conversion must be !s, !r, or !a")
    }
    conversion = chars[i].to_string()
    i += 1
    if i >= chars.length() || (chars[i] != ':' && chars[i] != '}') {
      return Err("Unexpected content after brace conversion")
    }
  }
  let mut presentation = "default"
  if chars[i] == ':' {
    i += 1
    let spec : Array[String] = []
    while i < chars.length() && chars[i] != '}' {
      if chars[i] == '{' {
        match brace_field(chars, i, state, depth + 1) {
          Ok(end) => {
            // A dynamic width/precision is represented by a numeric sentinel.
            spec.push("1")
            i = end
          }
          Err(error) => return Err(error)
        }
      } else {
        spec.push(chars[i].to_string())
        i += 1
      }
    }
    match brace_presentation(join_strings(spec, "")) {
      Ok(kind) => presentation = kind
      Err(error) => return Err(error)
    }
  }
  if i >= chars.length() || chars[i] != '}' {
    return Err("Brace field has no closing brace")
  }
  if conversion != "" && presentation != "default" && presentation != "string" {
    return Err(
      "!s, !r, and !a produce a string and cannot use numeric presentation",
    )
  }
  match
    add_python_argument(
      state.arguments,
      state.kinds,
      name,
      conversion + ":" + presentation,
      start,
    ) {
    Err(error) => Err(error)
    Ok(_) => Ok(i + 1)
  }
}

///|
/// Check Python str.format brace syntax; escaped {{ and }} do not consume args.
pub fn brace_contract(text : String) -> Result[FormatContract, String] {
  let chars = text.to_array()
  let state : BraceState = {
    arguments: [],
    kinds: Map([]),
    automatic: false,
    numbered: false,
    next: 0,
  }
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '{' || chars[i] == '}' {
      if i + 1 < chars.length() && chars[i] == chars[i + 1] {
        i += 2
        continue
      }
      if chars[i] == '}' {
        return Err(
          "Unmatched closing brace at character " + (i + 1).to_string(),
        )
      }
      match brace_field(chars, i, state, 0) {
        Ok(end) => i = end
        Err(error) => return Err(error + " at character " + (i + 1).to_string())
      }
    } else {
      i += 1
    }
  }
  Ok({ arguments: state.arguments, style: "python-brace-format", })
}
