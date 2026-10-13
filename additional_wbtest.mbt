///|
test "percent mapping reorder and dynamic width are checked" {
  let source = python_percent_contract("%(name)s %(count)d %%").unwrap()
  let translated = python_percent_contract("%(count)d 个，%(name)s").unwrap()
  assert_eq(compare_contracts(source, translated).length(), 0)
  assert_eq(python_percent_contract("%*.*f").unwrap().arguments.length(), 3)
  assert_true(python_percent_contract("%(name)*s") is Err(_))
  assert_true(python_percent_contract("%(name)s %d") is Err(_))
  assert_true(python_percent_contract("%(name") is Err(_))
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(count)d\"\nmsgstr \"%(count)s\"\n",
  )
  assert_true(report.diagnostics.any(d => d.code == "F005"))
  assert_true(!report.diagnostics.any(d => d.code == "F007"))
}

///|
test "continuation spans include their last source line" {
  let catalog = parse_catalog(
    "msgid \"\"\n\"a\"\n\"b\"\nmsgstr \"\"\n\"A\"\n\"B\"\n",
  )
  assert_eq(catalog.entries[0].id_span.end.line, 3)
  assert_eq(catalog.entries[0].translations[0].span.end.line, 6)
  assert_true(
    parse_catalog("msgid \"x\"\nmsgstr[0] \"X\"\n").diagnostics.any(d => {
      d.code == "P011"
    }),
  )
  assert_true(
    parse_catalog("msgid \"x\"\nmsgid_plural \"xs\"\nmsgstr \"X\"\n").diagnostics.any(d => {
        d.code == "P011"
      },
    ),
  )
}

///|
test "reference and context summaries preserve distinct sources" {
  assert_eq(parse_reference("C:\\src\\main.mbt:42"), {
    path: "C:\\src\\main.mbt",
    line: Some(42),
  })
  assert_eq(parse_reference("source.mbt"), { path: "source.mbt", line: None, })
  let source = "#: src/a.mbt:1 src/a.mbt:2\nmsgid \"a\"\nmsgstr \"A\"\n\nmsgctxt \"\"\nmsgid \"b\"\nmsgstr \"\"\n"
  let groups = context_summaries(parse_catalog(source))
  assert_eq(groups.length(), 2)
  assert_eq(groups[0].translated, 1)
  assert_eq(groups[1].translated, 0)
  assert_true(
    @json.valid(catalog_summary_json(parse_catalog(source)).stringify()[:]),
  )
}

///|
test "JSON preflight counts only delimiters outside strings" {
  assert_true(bounded_json("{\"x\":\"[[{\\\"\"}", 1) is Ok(_))
  assert_true(bounded_json("[[[]]]", 2) is Err(_))
  assert_true(bounded_json("{", 32) is Err(_))
  assert_true(bounded_json("[}", 32) is Err(_))
}

///|
test "bytes BOM UTF16 malformed data and dangling comments are explicit" {
  let bytes = @utf8.encode("msgid \"x\"\nmsgstr \"X\"\n"[:], bom=true)
  assert_eq(parse_catalog_bytes(bytes).entries[0].id, "x")
  assert_true(check_bytes(b"\xFF\xFE").diagnostics.any(d => d.code == "P008"))
  assert_true(check_bytes(b"\xC0\xAF").diagnostics.any(d => d.code == "P008"))
  let comments = parse_catalog(
    "# copyright\n\nmsgid \"x\"\nmsgstr \"X\"\n\n# dangling\n",
  )
  assert_eq(comments.entries[0].comments[0].text, "copyright")
  assert_true(comments.diagnostics.any(d => d.code == "P012"))
  assert_true(serialize_catalog(comments) is Err(_))
}

///|
test "contradictory format flags context controls and empty header fail" {
  assert_true(check_text("msgid \"\"\n").diagnostics.any(d => d.code == "C003"))
  let text = "#, c-format, no-c-format\nmsgctxt \"x\\000\"\nmsgid \"%d\"\nmsgstr \"%d\"\n"
  let report = check_text(text)
  assert_true(report.diagnostics.any(d => d.code == "F008"))
  assert_true(report.diagnostics.any(d => d.code == "C012"))
}
