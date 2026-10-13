///|
/// Decode a complete UTF-8 catalog for library clients that receive raw bytes.
pub fn parse_catalog_bytes(
  bytes : Bytes,
  file~ : String = "<memory>",
  options~ : Options = default_options(),
) -> Catalog {
  if bytes.length() >= 2 &&
    (
      (bytes[0] == 0xFF && bytes[1] == 0xFE) ||
      (bytes[0] == 0xFE && bytes[1] == 0xFF)
    ) {
    return {
      file,
      entries: [],
      diagnostics: [
        issue(
          "P008",
          Error,
          "UTF-16 catalog input is unsupported",
          file,
          line_span(1, 1, 0),
          hint="Convert the original file to UTF-8.",
        ),
      ],
    }
  }
  let text = @utf8.decode(bytes[:]) catch {
    _ =>
      return {
        file,
        entries: [],
        diagnostics: [
          issue(
            "P008",
            Error,
            "Catalog bytes are not valid UTF-8",
            file,
            line_span(1, 1, 0),
            hint="The invalid byte position is unavailable from the decoder; line 1 identifies the file.",
          ),
        ],
      }
  }
  parse_catalog(text, file~, options~)
}

///|
pub fn check_bytes(
  bytes : Bytes,
  file~ : String = "<memory>",
  options~ : Options = default_options(),
  template~ : Bool = false,
) -> Report {
  check_catalog(
    parse_catalog_bytes(bytes, file~, options~),
    options~,
    template~,
  )
}
