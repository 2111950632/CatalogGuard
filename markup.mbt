///|
pub(all) struct MarkupOptions {
  mode : String
  translatable_attributes : Array[String]
  max_chars : Int32
  max_nodes : Int32
  max_depth : Int32
} derive(Debug)

///|
pub fn default_markup_options() -> MarkupOptions {
  {
    mode: "off",
    translatable_attributes: [
      "alt", "title", "aria-label", "placeholder", "lang", "xml:lang",
    ],
    max_chars: 262144,
    max_nodes: 4096,
    max_depth: 64,
  }
}

///|
pub(all) struct MarkupError {
  offset : Int32
  message : String
} derive(Eq, Debug)

///|
pub(all) struct MarkupContract {
  mode : String
  nodes : Int32
  signature : String
} derive(Eq, Debug)

///|
priv struct MarkupState {
  chars : Array[Char]
  options : MarkupOptions
  mut cursor : Int32
  mut nodes : Int32
}

///|
fn markup_error(state : MarkupState, message : String) -> MarkupError {
  { offset: state.cursor, message, }
}

///|
fn markup_starts(state : MarkupState, token : String) -> Bool {
  let chars = token.to_array()
  if state.cursor + chars.length() > state.chars.length() {
    return false
  }
  for i, c in chars {
    if state.chars[state.cursor + i] != c {
      return false
    }
  }
  true
}

///|
fn markup_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\u000C'
}

///|
fn markup_skip_space(state : MarkupState) -> Unit {
  while state.cursor < state.chars.length() &&
        markup_space(state.chars[state.cursor]) {
    state.cursor += 1
  }
}

///|
fn markup_xml_char(n : Int32) -> Bool {
  n == 9 ||
  n == 10 ||
  n == 13 ||
  (n >= 0x20 && n <= 0xD7FF) ||
  (n >= 0xE000 && n <= 0xFFFD) ||
  (n >= 0x10000 && n <= 0x10FFFF)
}

///|
fn markup_name_start(c : Char) -> Bool {
  let n = c.to_int()
  c == ':' ||
  c == '_' ||
  (c >= 'A' && c <= 'Z') ||
  (c >= 'a' && c <= 'z') ||
  (n >= 0xC0 && n <= 0xD6) ||
  (n >= 0xD8 && n <= 0xF6) ||
  (n >= 0xF8 && n <= 0x2FF) ||
  (n >= 0x370 && n <= 0x37D) ||
  (n >= 0x37F && n <= 0x1FFF) ||
  (n >= 0x200C && n <= 0x200D) ||
  (n >= 0x2070 && n <= 0x218F) ||
  (n >= 0x2C00 && n <= 0x2FEF) ||
  (n >= 0x3001 && n <= 0xD7FF) ||
  (n >= 0xF900 && n <= 0xFDCF) ||
  (n >= 0xFDF0 && n <= 0xFFFD) ||
  (n >= 0x10000 && n <= 0xEFFFF)
}

///|
fn markup_name(state : MarkupState) -> Result[String, MarkupError] {
  let start = state.cursor
  if start >= state.chars.length() || !markup_name_start(state.chars[start]) {
    return Err(markup_error(state, "Expected a tag or attribute name"))
  }
  state.cursor += 1
  while state.cursor < state.chars.length() {
    let c = state.chars[state.cursor]
    let n = c.to_int()
    if !markup_name_start(c) &&
      c != '-' &&
      c != '.' &&
      !(c >= '0' && c <= '9') &&
      n != 0xB7 &&
      !(n >= 0x300 && n <= 0x36F) &&
      !(n >= 0x203F && n <= 0x2040) {
      break
    }
    state.cursor += 1
  }
  let name = char_slice(state.chars, start, state.cursor)
  Ok(
    if state.options.mode == "html" {
      String::from_array(
        name
        .to_array()
        .map(c => {
          if c >= 'A' && c <= 'Z' {
            (c.to_int() + 32).unsafe_to_char()
          } else {
            c
          }
        }),
      )
    } else {
      name
    },
  )
}

///|
fn markup_part(text : String) -> String {
  text.length().to_string() + ":" + text
}

///|
fn markup_parts(parts : Array[String]) -> String {
  parts.sort()
  parts.map(markup_part).join("")
}

///|
fn markup_html_numeric_reference(number : Int32) -> Int32 {
  // HTML numeric character reference end state; XML keeps the original value.
  match number {
    0x80 => 0x20AC
    0x82 => 0x201A
    0x83 => 0x0192
    0x84 => 0x201E
    0x85 => 0x2026
    0x86 => 0x2020
    0x87 => 0x2021
    0x88 => 0x02C6
    0x89 => 0x2030
    0x8A => 0x0160
    0x8B => 0x2039
    0x8C => 0x0152
    0x8E => 0x017D
    0x91 => 0x2018
    0x92 => 0x2019
    0x93 => 0x201C
    0x94 => 0x201D
    0x95 => 0x2022
    0x96 => 0x2013
    0x97 => 0x2014
    0x98 => 0x02DC
    0x99 => 0x2122
    0x9A => 0x0161
    0x9B => 0x203A
    0x9C => 0x0153
    0x9E => 0x017E
    0x9F => 0x0178
    _ => number
  }
}

///|
fn markup_entity(state : MarkupState) -> Result[String, MarkupError] {
  let start = state.cursor
  state.cursor += 1
  let begin = state.cursor
  while state.cursor < state.chars.length() && state.chars[state.cursor] != ';' {
    let c = state.chars[state.cursor]
    if !(c == '#' ||
      (c >= '0' && c <= '9') ||
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z')) {
      break
    }
    state.cursor += 1
  }
  if state.cursor == state.chars.length() || state.chars[state.cursor] != ';' {
    if state.options.mode == "html" {
      state.cursor = start + 1
      return Ok("&")
    }
    return Err(markup_error(state, "XML entity references require a semicolon"))
  }
  let body = char_slice(state.chars, begin, state.cursor)
  state.cursor += 1
  match body {
    "amp" => return Ok("&")
    "lt" => return Ok("<")
    "gt" => return Ok(">")
    "quot" => return Ok("\"")
    "apos" => return Ok("'")
    "nbsp" => if state.options.mode == "html" { return Ok("\u00A0") }
    _ => ()
  }
  if body.has_prefix("#") {
    let chars = body.to_array()
    let hex = chars.length() > 1 &&
      (chars[1] == 'x' || (state.options.mode == "html" && chars[1] == 'X'))
    let from = if hex { 2 } else { 1 }
    if chars.length() <= from {
      return Err(markup_error(state, "Empty numeric character reference"))
    }
    let mut number = 0
    let radix = if hex { 16 } else { 10 }
    for i = from; i < chars.length(); i = i + 1 {
      let c = chars[i]
      let digit = if c >= '0' && c <= '9' {
        c.to_int() - 48
      } else if hex && c >= 'a' && c <= 'f' {
        c.to_int() - 87
      } else if hex && c >= 'A' && c <= 'F' {
        c.to_int() - 55
      } else {
        -1
      }
      if digit < 0 || number > (0x10FFFF - digit) / radix {
        return Err(markup_error(state, "Invalid numeric character reference"))
      }
      number = number * radix + digit
    }
    if !markup_xml_char(number) {
      return Err(
        markup_error(
          state, "Character reference is outside the supported character range",
        ),
      )
    }
    let normalized = if state.options.mode == "html" {
      markup_html_numeric_reference(number)
    } else {
      number
    }
    return Ok(String::from_array([normalized.unsafe_to_char()]))
  }
  if state.options.mode == "html" {
    return Ok(char_slice(state.chars, start, state.cursor))
  }
  Err(
    markup_error(
      state, "Undeclared XML entity; DTD and external entity expansion are unsupported",
    ),
  )
}

///|
fn markup_attribute(state : MarkupState) -> Result[String, MarkupError] {
  let html = state.options.mode == "html"
  let quote = if state.cursor < state.chars.length() &&
    (state.chars[state.cursor] == '\'' || state.chars[state.cursor] == '"') {
    let c = state.chars[state.cursor]
    state.cursor += 1
    Some(c)
  } else {
    None
  }
  if quote is None && !html {
    return Err(markup_error(state, "XML attribute values must be quoted"))
  }
  let start = state.cursor
  let output = StringBuilder()
  while state.cursor < state.chars.length() {
    let c = state.chars[state.cursor]
    if quote == Some(c) {
      state.cursor += 1
      return Ok(output.to_string())
    }
    if quote is None && (markup_space(c) || c == '>') {
      break
    }
    if c == '<' ||
      (quote is None && (c == '\'' || c == '"' || c == '`' || c == '=')) {
      return Err(markup_error(state, "Invalid character in an attribute value"))
    }
    if c == '&' {
      match markup_entity(state) {
        Ok(value) => output.write_string(value)
        Err(error) => return Err(error)
      }
    } else {
      output.write_char(
        if c == '\r' {
          if html {
            '\n'
          } else {
            ' '
          }
        } else if !html && (c == '\t' || c == '\n') {
          ' '
        } else {
          c
        },
      )
      state.cursor += 1
      // A literal CRLF is one line break before attribute normalization.
      // Character references took the other branch and retain their value.
      if c == '\r' &&
        state.cursor < state.chars.length() &&
        state.chars[state.cursor] == '\n' {
        state.cursor += 1
      }
    }
  }
  if quote is Some(_) {
    return Err(markup_error(state, "Unterminated quoted attribute"))
  }
  if state.cursor == start {
    return Err(markup_error(state, "Empty unquoted attribute"))
  }
  Ok(output.to_string())
}

///|
fn markup_void(name : String) -> Bool {
  [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source",
    "track", "wbr",
  ].contains(name)
}

///|
fn markup_children(
  state : MarkupState,
  parent : String?,
  depth : Int32,
) -> Result[Array[String], MarkupError] {
  let children : Array[String] = []
  while state.cursor < state.chars.length() {
    if markup_starts(state, "</") {
      state.cursor += 2
      let name = match markup_name(state) {
        Ok(name) => name
        Err(error) => return Err(error)
      }
      markup_skip_space(state)
      if !markup_starts(state, ">") {
        return Err(markup_error(state, "Closing tags cannot have attributes"))
      }
      state.cursor += 1
      if parent != Some(name) {
        return Err(
          markup_error(state, "Mismatched or unexpected closing tag: " + name),
        )
      }
      return Ok(children)
    }
    if markup_starts(state, "<!--") {
      state.cursor += 4
      while state.cursor < state.chars.length() && !markup_starts(state, "-->") {
        if markup_starts(state, "--") {
          return Err(
            markup_error(state, "Double hyphen inside a comment is unsupported"),
          )
        }
        state.cursor += 1
      }
      if !markup_starts(state, "-->") {
        return Err(markup_error(state, "Unterminated comment"))
      }
      state.cursor += 3
      continue
    }
    if markup_starts(state, "<![CDATA[") && state.options.mode == "xml" {
      state.cursor += 9
      while state.cursor < state.chars.length() && !markup_starts(state, "]]>") {
        state.cursor += 1
      }
      if !markup_starts(state, "]]>") {
        return Err(markup_error(state, "Unterminated CDATA section"))
      }
      state.cursor += 3
      continue
    }
    if markup_starts(state, "<!") || markup_starts(state, "<?") {
      return Err(
        markup_error(
          state, "Declarations, DTD, processing instructions and HTML CDATA are outside this fragment profile",
        ),
      )
    }
    if markup_starts(state, "<") {
      match markup_element(state, depth + 1) {
        Ok(node) => children.push(node)
        Err(error) => return Err(error)
      }
      continue
    }
    if state.options.mode == "xml" && markup_starts(state, "]]>") {
      return Err(
        markup_error(state, "CDATA terminator in normal character data"),
      )
    }
    if state.chars[state.cursor] == '&' {
      match markup_entity(state) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    } else {
      state.cursor += 1
    }
  }
  if parent is Some(name) {
    return Err(markup_error(state, "Missing closing tag: " + name))
  }
  Ok(children)
}

///|
fn markup_element(
  state : MarkupState,
  depth : Int32,
) -> Result[String, MarkupError] {
  if depth > state.options.max_depth || state.nodes >= state.options.max_nodes {
    return Err(
      markup_error(state, "Markup depth or node resource limit exceeded"),
    )
  }
  state.nodes += 1
  state.cursor += 1
  if state.options.mode == "html" && state.cursor < state.chars.length() {
    let first = state.chars[state.cursor]
    if !((first >= 'a' && first <= 'z') || (first >= 'A' && first <= 'Z')) {
      return Err(
        markup_error(
          state, "HTML fragment element names must begin with an ASCII letter",
        ),
      )
    }
  }
  let name = match markup_name(state) {
    Ok(name) => name
    Err(error) => return Err(error)
  }
  let html = state.options.mode == "html"
  if html &&
    [
      "script", "style", "textarea", "title", "svg", "math", "template", "plaintext",
      "xmp", "iframe", "noembed", "noframes",
    ].contains(name) {
    return Err(
      markup_error(
        state,
        "Raw-text, template and foreign HTML elements are outside this fragment profile: " +
        name,
      ),
    )
  }
  let attributes : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut closed = false
  let mut ended = false
  while state.cursor < state.chars.length() {
    let before = state.cursor
    markup_skip_space(state)
    if markup_starts(state, "/>") {
      closed = true
      ended = true
      state.cursor += 2
      break
    }
    if markup_starts(state, ">") {
      ended = true
      state.cursor += 1
      break
    }
    if before == state.cursor {
      return Err(
        markup_error(state, "Attributes require separating whitespace"),
      )
    }
    let key = match markup_name(state) {
      Ok(name) => name
      Err(error) => return Err(error)
    }
    if seen.contains(key) {
      return Err(markup_error(state, "Duplicate attribute: " + key))
    }
    seen.set(key, true)
    // Whitespace after a boolean HTML attribute belongs to the next attribute.
    let after_key = state.cursor
    markup_skip_space(state)
    let value = if markup_starts(state, "=") {
      state.cursor += 1
      markup_skip_space(state)
      match markup_attribute(state) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
    } else if html {
      state.cursor = after_key
      ""
    } else {
      return Err(markup_error(state, "XML attributes require a value"))
    }
    attributes.push(
      markup_part(key) +
      (if state.options.translatable_attributes.contains(key) {
        "T"
      } else {
        "V" + markup_part(value)
      }),
    )
  }
  if !ended {
    return Err(markup_error(state, "Unterminated start tag"))
  }
  if html && closed && !markup_void(name) {
    return Err(
      markup_error(
        state, "Non-void HTML elements require an explicit closing tag",
      ),
    )
  }
  let children = if closed || (html && markup_void(name)) {
    []
  } else {
    match markup_children(state, Some(name), depth) {
      Ok(children) => children
      Err(error) => return Err(error)
    }
  }
  Ok(
    markup_part(name) +
    "A" +
    markup_part(markup_parts(attributes)) +
    "C" +
    markup_part(markup_parts(children)),
  )
}

///|
pub fn validate_markup_options(options : MarkupOptions) -> Array[String] {
  let errors : Array[String] = []
  if !["off", "html", "xml"].contains(options.mode) {
    errors.push("markup mode must be off, html, or xml")
  }
  if options.max_chars < 1 || options.max_chars > 1048576 {
    errors.push("markup max_chars must be in 1..1048576")
  }
  if options.max_nodes < 1 || options.max_nodes > 16384 {
    errors.push("markup max_nodes must be in 1..16384")
  }
  if options.max_depth < 1 || options.max_depth > 128 {
    errors.push("markup max_depth must be in 1..128")
  }
  if options.translatable_attributes.length() > 64 ||
    options.translatable_attributes.any(name => {
      name == "" || name.length() > 128
    }) {
    errors.push(
      "markup translatable_attributes requires at most 64 nonempty names of at most 128 units",
    )
  }
  errors
}

///|
/// CGM-1 balanced fragments, not an HTML browser tree builder or XML validator.
pub fn markup_contract(
  text : String,
  options~ : MarkupOptions = { ..default_markup_options(), mode: "html", },
) -> Result[MarkupContract, MarkupError] {
  let errors = validate_markup_options(options)
  if !errors.is_empty() || options.mode == "off" {
    return Err({
      offset: 0,
      message: if errors.is_empty() {
        "markup_contract requires html or xml mode"
      } else {
        join_strings(errors, "; ")
      },
    })
  }
  if text.length() > options.max_chars {
    return Err({
      offset: 0,
      message: "Markup character resource limit exceeded",
    })
  }
  let chars = text.to_array()
  for index, c in chars {
    if !markup_xml_char(c.to_int()) {
      return Err({
        offset: index,
        message: "Unsupported markup control character",
      })
    }
  }
  let state = { chars, options, cursor: 0, nodes: 0, }
  match markup_children(state, None, 0) {
    Err(error) => Err(error)
    Ok(children) =>
      Ok({
        mode: options.mode,
        nodes: state.nodes,
        signature: markup_parts(children),
      })
  }
}

///|
pub fn check_markup_catalog(
  catalog : Catalog,
  options~ : MarkupOptions = { ..default_markup_options(), mode: "html", },
) -> Array[Diagnostic] {
  let result : Array[Diagnostic] = []
  let errors = validate_markup_options(options)
  if !errors.is_empty() {
    return [
      issue(
        "O001",
        Error,
        join_strings(errors, "; "),
        catalog.file,
        line_span(1, 1, 0),
      ),
    ]
  }
  if options.mode == "off" {
    return result
  }
  for index, entry in catalog.entries {
    if entry.obsolete || entry.is_header() {
      continue
    }
    let source = match markup_contract(entry.id, options~) {
      Ok(contract) => contract
      Err(error) => {
        result.push(
          issue(
            "M001",
            Error,
            error.message,
            catalog.file,
            entry.id_span,
            entry=index,
            hint="Decoded source character offset " +
              error.offset.to_string() +
              "; PO span identifies the containing field.",
          ),
        )
        continue
      }
    }
    if entry.plural is Some(plural) {
      match markup_contract(plural, options~) {
        Err(error) => {
          result.push(
            issue(
              "M001",
              Error,
              error.message,
              catalog.file,
              entry.plural_span.unwrap_or(entry.span),
              entry=index,
            ),
          )
          continue
        }
        Ok(other) =>
          if source.signature != other.signature {
            result.push(
              issue(
                "M004",
                Error,
                "Singular and plural source markup contracts differ; a shared translation contract cannot be inferred",
                catalog.file,
                entry.plural_span.unwrap_or(entry.span),
                entry=index,
                related=entry.id_span,
              ),
            )
            continue
          }
      }
    }
    for translation in entry.translations {
      if translation.value == "" {
        continue
      }
      match markup_contract(translation.value, options~) {
        Err(error) =>
          result.push(
            issue(
              "M002",
              Error,
              error.message,
              catalog.file,
              translation.span,
              entry=index,
              related=entry.id_span,
              hint="Decoded translation character offset " +
                error.offset.to_string() +
                "; PO span identifies the containing field.",
            ),
          )
        Ok(target) =>
          if source.signature != target.signature {
            result.push(
              issue(
                "M003",
                Error,
                "Markup tree, attribute presence or protected attribute value differs from source",
                catalog.file,
                translation.span,
                entry=index,
                related=entry.id_span,
                hint="Sibling/attribute order and translated text may change; tag ancestry, multiplicity and protected values must remain.",
              ),
            )
          }
      }
    }
  }
  result
}
