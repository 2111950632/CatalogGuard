///|
test "multiline UTF8 catalog with context and ordered plurals" {
  let source = "#: src/main.mbt:12\n#, c-format\nmsgctxt \"button\"\nmsgid \"Open \"\n\"%d file\"\nmsgid_plural \"Open %d files\"\nmsgstr[0] \"打开 %d 个文件\"\nmsgstr[1] \"打开 %d 个文件\"\n"
  let catalog = parse_catalog(source, file="demo.po")
  assert_eq(catalog.diagnostics.length(), 0)
  assert_eq(catalog.entries.length(), 1)
  let entry = catalog.entries[0]
  assert_eq(entry.context, Some("button"))
  assert_eq(entry.id, "Open %d file")
  assert_eq(entry.plural, Some("Open %d files"))
  assert_eq(entry.translation(1), Some("打开 %d 个文件"))
  assert_true(entry.has_flag("c-format"))
  assert_eq(entry.id_span.start.line, 4)
}

///|
test "octal UTF8 bytes can cross continuation boundaries" {
  let c = parse_catalog("msgid \"x\"\nmsgstr \"\\303\"\n\"\\251\"\n")
  assert_eq(c.diagnostics.length(), 0)
  assert_eq(c.entries[0].translation(0), Some("é"))
}

///|
test "malformed escape and duplicate translation are diagnosed" {
  let c = parse_catalog(
    "msgid \"x\"\nmsgstr \"\\q\"\nmsgstr \"a\"\nmsgstr \"b\"\n",
  )
  assert_true(c.diagnostics.any(d => d.code == "P002"))
  assert_true(c.diagnostics.any(d => d.code == "P010"))
}

///|
test "obsolete entries and adjacent entries remain separated" {
  let c = parse_catalog(
    "#~ msgid \"old\"\n#~ msgstr \"ancien\"\n\nmsgid \"a\"\nmsgstr \"A\"\nmsgid \"b\"\nmsgstr \"B\"",
  )
  assert_eq(c.entries.length(), 3)
  assert_true(c.entries[0].obsolete)
  assert_eq(c.entries[2].id, "b")
}
