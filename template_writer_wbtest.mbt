///|
test "template comparison finds context plural and format drift" {
  let template = parse_catalog(
    "#, c-format\nmsgctxt \"a\"\nmsgid \"%d\"\nmsgid_plural \"%d items\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n\nmsgid \"missing\"\nmsgstr \"\"\n",
  )
  let translation = parse_catalog(
    "msgctxt \"a\"\nmsgid \"%d\"\nmsgstr \"%d\"\n\nmsgid \"extra\"\nmsgstr \"X\"\n",
  )
  let delta = compare_template(template, translation)
  assert_eq(delta.missing, ["missing"])
  assert_eq(delta.extra, ["extra"])
  assert_eq(delta.changed_plural.length(), 1)
  assert_eq(delta.changed_flags.length(), 1)
}

///|
test "canonical writer preserves decoded values metadata and obsolete entries" {
  let source = test_header() +
    "# translator\n#: test.mbt:3\n#, python-brace-format\nmsgctxt \"menu\"\nmsgid \"Hello {name}\\n\"\nmsgstr \"你好 {name}\\n\"\n\n#~ msgid \"old\"\n#~ msgstr \"ancien\"\n"
  let original = parse_catalog(source)
  let encoded = serialize_catalog(original).unwrap()
  let decoded = parse_catalog(encoded)
  assert_eq(decoded.diagnostics.length(), 0)
  assert_eq(decoded.entries.length(), original.entries.length())
  for i, entry in original.entries {
    assert_eq(decoded.entries[i].id, entry.id)
    assert_eq(decoded.entries[i].context, entry.context)
    assert_eq(decoded.entries[i].translation(0), entry.translation(0))
    assert_eq(decoded.entries[i].obsolete, entry.obsolete)
  }
  assert_eq(serialize_catalog(decoded), Ok(encoded))
}

///|
test "writer refuses malformed catalogs and JSON schema is valid" {
  assert_true(serialize_catalog(parse_catalog("msgid x")) is Err(_))
  assert_true(serialize_catalog(parse_catalog("msgid \"x\"")) is Err(_))
  let report = check_text(test_header() + "msgid \"x\"\nmsgstr \"X\"\n")
  let encoded = report_json(report).stringify()
  assert_true(@json.valid(encoded[:]))
  assert_true(report_text(report).contains("0 errors"))
  assert_eq(decimal_text("1", 0), None)
}
