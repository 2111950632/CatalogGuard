///|
/// Python percent formatting uses mapping names or sequential arguments.
pub fn python_percent_contract(text : String) -> Result[FormatContract, String] {
  let chars = text.to_array()
  let arguments : Array[FormatArgument] = []
  let kinds : Map[String, String] = Map([])
  let mut i = 0
  let mut next = 1
  let mut mapping = false
  let mut sequential = false
  while i < chars.length() {
    if chars[i] != '%' {
      i += 1
      continue
    }
    let offset = i
    i += 1
    if i == chars.length() {
      return Err("Incomplete Python percent format")
    }
    if chars[i] == '%' {
      i += 1
      continue
    }
    let mut name : String? = None
    if chars[i] == '(' {
      mapping = true
      i += 1
      let start = i
      let mut depth = 1
      while i < chars.length() && depth > 0 {
        if chars[i] == '(' {
          depth += 1
        } else if chars[i] == ')' {
          depth -= 1
        }
        if depth > 0 {
          i += 1
        }
      }
      if i == chars.length() {
        return Err("Python mapping key has no closing parenthesis")
      }
      name = Some(char_slice(chars, start, i))
      i += 1
    } else {
      sequential = true
    }
    if mapping && sequential {
      return Err("Cannot mix mapping and sequential Python percent fields")
    }
    while i < chars.length() && ['#', '0', '-', ' ', '+'].contains(chars[i]) {
      i += 1
    }
    if i < chars.length() && chars[i] == '*' {
      if mapping {
        return Err("Mapping percent fields cannot use dynamic width")
      }
      match
        add_format_argument(
          arguments,
          kinds,
          next.to_string(),
          "integer",
          offset,
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      next += 1
      i += 1
    } else {
      while i < chars.length() && chars[i].is_ascii_digit() {
        i += 1
      }
    }
    if i < chars.length() && chars[i] == '.' {
      i += 1
      if i < chars.length() && chars[i] == '*' {
        if mapping {
          return Err("Mapping percent fields cannot use dynamic precision")
        }
        match
          add_format_argument(
            arguments,
            kinds,
            next.to_string(),
            "integer",
            offset,
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        next += 1
        i += 1
      } else {
        while i < chars.length() && chars[i].is_ascii_digit() {
          i += 1
        }
      }
    }
    // Python accepts but ignores a single C length modifier.
    if i < chars.length() && ['h', 'l', 'L'].contains(chars[i]) {
      i += 1
    }
    if i >= chars.length() {
      return Err("Python percent conversion is incomplete")
    }
    let kind = match chars[i] {
      'd' | 'i' | 'u' | 'o' | 'x' | 'X' => "integer"
      'e' | 'E' | 'f' | 'F' | 'g' | 'G' => "numeric"
      'c' => "character"
      's' => "string-conversion"
      'r' => "repr-conversion"
      'a' => "ascii-conversion"
      _ =>
        return Err(
          "Unsupported Python percent conversion: " + chars[i].to_string(),
        )
    }
    i += 1
    let argument = match name {
      Some(name) => "mapping:" + name
      None => {
        let name = next.to_string()
        next += 1
        name
      }
    }
    match add_python_argument(arguments, kinds, argument, kind, offset) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if arguments.length() > 4096 {
      return Err("Format contract exceeds 4096 distinct arguments")
    }
  }
  Ok({ arguments, style: "python-format", })
}

///|
pub fn format_contract(
  style : String,
  text : String,
) -> Result[FormatContract, String] {
  match style {
    "c-format" => printf_contract(text)
    "python-brace-format" => brace_contract(text)
    "python-format" => python_percent_contract(text)
    _ => Err("Unsupported format style: " + style)
  }
}
