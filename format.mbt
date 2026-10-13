///|
pub(all) struct FormatArgument {
  name : String
  kind : String
  offset : Int32
} derive(Eq, Debug)

///|
pub(all) struct FormatContract {
  arguments : Array[FormatArgument]
  style : String
} derive(Eq, Debug)

///|
pub(all) struct FormatDifference {
  code : String
  message : String
  argument : String
} derive(Eq, Debug)

///|
priv struct PrintfState {
  arguments : Array[FormatArgument]
  mut next : Int32
  mut positional : Bool
  mut sequential : Bool
}

///|
fn add_format_argument(
  arguments : Array[FormatArgument],
  name : String,
  kind : String,
  offset : Int32,
) -> Result[Unit, String] {
  for previous in arguments {
    if previous.name == name {
      if previous.kind != kind {
        return Err(
          "Argument " +
          name +
          " is used with incompatible types " +
          previous.kind +
          " and " +
          kind,
        )
      }
      return Ok(())
    }
  }
  if arguments.length() >= 4096 {
    return Err("Format contract exceeds 4096 distinct arguments")
  }
  arguments.push({ name, kind, offset, })
  Ok(())
}

///|
fn PrintfState::add(
  self : PrintfState,
  index : Int32?,
  kind : String,
  offset : Int32,
) -> Result[Unit, String] {
  let number = match index {
    Some(number) => {
      self.positional = true
      number
    }
    None => {
      self.sequential = true
      let number = self.next
      self.next += 1
      number
    }
  }
  if self.positional && self.sequential {
    return Err("Cannot mix numbered and sequential printf arguments")
  }
  add_format_argument(self.arguments, number.to_string(), kind, offset)
}

///|
fn printf_number(chars : Array[Char], start : Int32) -> (Int32?, Int32, Bool) {
  let mut end = start
  while end < chars.length() && chars[end].is_ascii_digit() {
    end += 1
  }
  if end == start || end >= chars.length() || chars[end] != '$' {
    return (None, start, false)
  }
  let number = decimal_text(char_slice(chars, start, end), 10000)
  (number, end + 1, true)
}

///|
fn printf_kind(conversion : Char, length : String) -> Result[String?, String] {
  match conversion {
    'd' | 'i' => {
      if !["", "hh", "h", "l", "ll", "j", "z", "t"].contains(length) {
        return Err("Invalid length modifier for signed integer")
      }
      // hh and h use a promoted int in printf's variadic calling convention.
      let width = if length == "hh" || length == "h" { "" } else { length }
      Ok(Some("signed:" + width))
    }
    'u' | 'o' | 'x' | 'X' => {
      if !["", "hh", "h", "l", "ll", "j", "z", "t"].contains(length) {
        return Err("Invalid length modifier for unsigned integer")
      }
      let width = if length == "hh" || length == "h" { "" } else { length }
      Ok(Some("unsigned:" + width))
    }
    'f' | 'F' | 'e' | 'E' | 'g' | 'G' | 'a' | 'A' => {
      if !["", "l", "L"].contains(length) {
        return Err("Invalid length modifier for floating point")
      }
      Ok(Some(if length == "L" { "long-double" } else { "double" }))
    }
    'c' =>
      match length {
        "" => Ok(Some("signed:"))
        "l" => Ok(Some("wide-char"))
        _ => Err("Invalid length modifier for character")
      }
    's' =>
      match length {
        "" => Ok(Some("string"))
        "l" => Ok(Some("wide-string"))
        _ => Err("Invalid length modifier for string")
      }
    'p' =>
      if length != "" {
        Err("Pointer conversion does not accept a length modifier")
      } else {
        Ok(Some("pointer"))
      }
    'n' => {
      if !["", "hh", "h", "l", "ll", "j", "z", "t"].contains(length) {
        return Err("Invalid length modifier for count pointer")
      }
      Ok(Some("count-pointer:" + length))
    }
    'm' =>
      if length != "" {
        Err("GNU %m does not accept a length modifier")
      } else {
        Ok(None)
      }
    _ => Err("Unsupported printf conversion: " + conversion.to_string())
  }
}

///|
/// Extract typed printf arguments, including positional width and precision.
pub fn printf_contract(text : String) -> Result[FormatContract, String] {
  let chars = text.to_array()
  let state : PrintfState = {
    arguments: [],
    next: 1,
    positional: false,
    sequential: false,
  }
  let mut i = 0
  while i < chars.length() {
    if chars[i] != '%' {
      i += 1
      continue
    }
    let offset = i
    i += 1
    if i == chars.length() {
      return Err("Trailing percent at character " + (offset + 1).to_string())
    }
    if chars[i] == '%' {
      i += 1
      continue
    }
    let (position, after_position, explicit) = printf_number(chars, i)
    if explicit && (position is None || position == Some(0)) {
      return Err("Printf argument position must be in 1..10000")
    }
    i = after_position
    while i < chars.length() &&
          ['-', '+', ' ', '#', '0', '\'', 'I'].contains(chars[i]) {
      i += 1
    }
    if i < chars.length() && chars[i] == '*' {
      i += 1
      let (width, after, numbered) = printf_number(chars, i)
      if numbered && (width is None || width == Some(0)) {
        return Err("Printf width argument position must be in 1..10000")
      }
      i = after
      match state.add(width, "signed:", offset) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    } else {
      while i < chars.length() && chars[i].is_ascii_digit() {
        i += 1
      }
    }
    if i < chars.length() && chars[i] == '.' {
      i += 1
      if i < chars.length() && chars[i] == '*' {
        i += 1
        let (precision, after, numbered) = printf_number(chars, i)
        if numbered && (precision is None || precision == Some(0)) {
          return Err("Printf precision argument position must be in 1..10000")
        }
        i = after
        match state.add(precision, "signed:", offset) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      } else {
        while i < chars.length() && chars[i].is_ascii_digit() {
          i += 1
        }
      }
    }
    let mut length = ""
    if i + 1 < chars.length() {
      let pair = char_slice(chars, i, i + 2)
      if pair == "hh" || pair == "ll" {
        length = pair
        i += 2
      }
    }
    if length == "" &&
      i < chars.length() &&
      ['h', 'l', 'L', 'j', 'z', 't'].contains(chars[i]) {
      length = chars[i].to_string()
      i += 1
    }
    if i >= chars.length() {
      return Err(
        "Incomplete printf conversion at character " + (offset + 1).to_string(),
      )
    }
    let conversion = chars[i]
    i += 1
    match printf_kind(conversion, length) {
      Err(error) =>
        return Err(error + " at character " + (offset + 1).to_string())
      Ok(None) =>
        if explicit {
          return Err("A conversion without an argument cannot have a position")
        }
      Ok(Some(kind)) =>
        match state.add(position, kind, offset) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
    }
  }
  if state.positional {
    for position = 1
        position <= state.arguments.length()
        position = position + 1 {
      if !state.arguments.any(a => a.name == position.to_string()) {
        return Err("Numbered printf arguments must not leave a gap")
      }
    }
  }
  Ok({ arguments: state.arguments, style: "c-format", })
}

///|
/// Compare argument identities and types, allowing reordered numbered arguments.
pub fn compare_contracts(
  source : FormatContract,
  target : FormatContract,
) -> Array[FormatDifference] {
  let differences : Array[FormatDifference] = []
  if source.style != target.style {
    differences.push({
      code: "F006",
      message: "Format styles differ",
      argument: "",
    })
    return differences
  }
  for argument in source.arguments {
    let mut found : FormatArgument? = None
    for candidate in target.arguments {
      if candidate.name == argument.name {
        found = Some(candidate)
        break
      }
    }
    match found {
      None =>
        differences.push({
          code: "F003",
          message: "Missing format argument " + argument.name,
          argument: argument.name,
        })
      Some(actual) =>
        if actual.kind != argument.kind {
          differences.push({
            code: "F005",
            message: "Argument " +
            argument.name +
            " changes type from " +
            argument.kind +
            " to " +
            actual.kind,
            argument: argument.name,
          })
        }
    }
  }
  for argument in target.arguments {
    if !source.arguments.any(a => a.name == argument.name) {
      differences.push({
        code: "F004",
        message: "Unexpected format argument " + argument.name,
        argument: argument.name,
      })
    }
  }
  differences
}
