///|
/// Check nesting before invoking the core parser.
fn bounded_json(text : String, maximum_depth : Int32) -> Result[Json, String] {
  let chars = text.to_array()
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  for i, c in chars {
    if quoted {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
      continue
    }
    if c == '"' {
      quoted = true
    } else if c == '{' || c == '[' {
      depth += 1
      if depth > maximum_depth {
        return Err(
          "JSON nesting exceeds " +
          maximum_depth.to_string() +
          " at character " +
          (i + 1).to_string(),
        )
      }
    } else if c == '}' || c == ']' {
      depth -= 1
      if depth < 0 {
        return Err(
          "Unexpected JSON closing delimiter at character " +
          (i + 1).to_string(),
        )
      }
    }
  }
  if quoted || depth != 0 {
    return Err("Unterminated JSON string or container")
  }
  let value = @json.parse(text[:]) catch {
    error => return Err(error.to_string())
  }
  Ok(value)
}
