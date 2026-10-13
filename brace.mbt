///|
priv struct BraceState {
  arguments : Array[FormatArgument]
  mut automatic : Bool
  mut numbered : Bool
  mut next : Int
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
  if root == "" {
    return Err("Brace field requires a root argument")
  }
  if root.to_array().all(c => c.is_ascii_digit()) {
    if decimal_text(root, 10000) is None {
      return Err("Brace argument index exceeds 10000")
    }
    state.numbered = true
    if state.automatic {
      return Err("Cannot mix automatic and numbered brace fields")
    }
  } else {
    let root_chars = root.to_array()
    if !is_identifier_start(root_chars[0]) || !root_chars.all(is_identifier_part) {
      return Err("Unsupported brace argument identifier: " + root)
    }
  }
  while i < chars.length() {
    if chars[i] == '.' {
      i += 1
      let start = i
      while i < chars.length() && is_identifier_part(chars[i]) {
        i += 1
      }
      if i == start || !is_identifier_start(chars[start]) {
        return Err("Invalid attribute in brace field")
      }
    } else if chars[i] == '[' {
      i += 1
      let start = i
      while i < chars.length() && chars[i] != ']' {
        if chars[i] == '[' || chars[i] == '{' || chars[i] == '}' {
          return Err("Unsupported nested index in brace field")
        }
        i += 1
      }
      if i == start || i == chars.length() {
        return Err("Brace index requires content and a closing bracket")
      }
      i += 1
    } else {
      return Err("Unexpected character in brace field")
    }
  }
  Ok(raw)
}

///|
fn brace_presentation(spec : String) -> Result[String, String] {
  let chars = spec.to_array()
  if chars.is_empty() {
    return Ok("default")
  }
  let mut i = 0
  if chars.length() >= 2 && ['<', '>', '=', '^'].contains(chars[1]) {
    i = 2
  } else if ['<', '>', '=', '^'].contains(chars[0]) {
    i = 1
  }
  if i < chars.length() && ['+', '-', ' '].contains(chars[i]) {
    i += 1
  }
  if i < chars.length() && chars[i] == 'z' {
    i += 1
  }
  if i < chars.length() && chars[i] == '#' {
    i += 1
  }
  if i < chars.length() && chars[i] == '0' {
    i += 1
  }
  while i < chars.length() && chars[i].is_ascii_digit() {
    i += 1
  }
  if i < chars.length() && [',', '_'].contains(chars[i]) {
    i += 1
  }
  if i < chars.length() && chars[i] == '.' {
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
    return Ok("default")
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
    _ => return Err("Unsupported brace presentation type: " + chars[i].to_string())
  }
  Ok(kind)
}

///|
fn brace_field(chars : Array[Char], start : Int, state : BraceState, depth : Int) -> Result[Int, String] {
  if depth > 8 {
    return Err("Brace fields exceed the nesting limit of 8")
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
    if c == '{' {
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
  match add_format_argument(state.arguments, name, conversion + ":" + presentation, start) {
    Err(error) => Err(error)
    Ok(_) => Ok(i + 1)
  }
}

///|
/// Check Python str.format brace syntax; escaped {{ and }} do not consume args.
pub fn brace_contract(text : String) -> Result[FormatContract, String] {
  let chars = text.to_array()
  let state : BraceState = {
    arguments: [], automatic: false, numbered: false, next: 0,
  }
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '{' || chars[i] == '}' {
      if i + 1 < chars.length() && chars[i] == chars[i + 1] {
        i += 2
        continue
      }
      if chars[i] == '}' {
        return Err("Unmatched closing brace at character " + (i + 1).to_string())
      }
      match brace_field(chars, i, state, 0) {
        Ok(end) => i = end
        Err(error) => return Err(error + " at character " + (i + 1).to_string())
      }
    } else {
      i += 1
    }
  }
  Ok({ arguments: state.arguments, style: "python-brace-format" })
}
