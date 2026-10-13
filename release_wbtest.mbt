///|
test "content type rejects suffixes ambiguous charsets and malformed quotes" {
  for
    value in [
      "text/plainjunk; charset=UTF-8", "text/plain; charset=UTF-8; charset=ISO-8859-1",
      "text/plain; charset=\"UTF-8", "text/plain; charset", "text/plain",
    ] {
    assert_true(content_type_charset(value) is Err(_))
    let report = check_text(
      "msgid \"\"\nmsgstr " + quote_po("Content-Type: " + value + "\n") + "\n",
    )
    assert_true(report.diagnostics.any(d => d.code == "H004"))
    assert_eq(report.exit_code, 1)
  }
  assert_eq(content_type_charset("Text/Plain ; CHARSET=\"UTF-8\""), Ok("UTF-8"))
}

///|
test "numeric brace identities ignore leading zeros" {
  let source = brace_contract("{00} {values[01]}").unwrap()
  let target = brace_contract("{0} {values[1]}").unwrap()
  assert_eq(compare_contracts(source, target).length(), 0)
  assert_true(
    !compare_contracts(source, brace_contract("{0} {values[2]}").unwrap()).is_empty(),
  )
}

///|
test "host protocol rejects mistyped commands and config" {
  for text in ["{\"command\":0}", "{\"config\":{}}", "{\"config\":null}"] {
    let value = @json.parse(dispatch(text)[:])
    assert_eq(json_field(value, "exit_code").bind(json_integer), Some(2))
  }
}

///|
test "large repeated positional contracts remain deduplicated and compatible" {
  let pieces : Array[String] = []
  for position = 1; position <= 256; position = position + 1 {
    pieces.push("%" + position.to_string() + "$d")
  }
  let source = printf_contract(join_strings(pieces, " ")).unwrap()
  let repeated = pieces.copy()
  for i = 0; i < 2048; i = i + 1 {
    repeated.push("%256$d")
  }
  let target = printf_contract(join_strings(repeated, " ")).unwrap()
  assert_eq(target.arguments.length(), 256)
  assert_eq(compare_contracts(source, target).length(), 0)
  assert_true(printf_contract("%1$d %1$s") is Err(_))
}
