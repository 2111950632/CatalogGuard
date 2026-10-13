///|
fn test_header() -> String {
  "msgid \"\"\nmsgstr \"\"\n\"Project-Id-Version: test 1.0\\n\"\n\"MIME-Version: 1.0\\n\"\n\"Content-Type: text/plain; charset=UTF-8\\n\"\n\"Content-Transfer-Encoding: 8bit\\n\"\n\"Language: fr\\n\"\n\"Plural-Forms: nplurals=2; plural=(n!=1);\\n\"\n\n"
}

///|
test "complete catalog passes and format error changes exit status" {
  let good = test_header() + "#, c-format\nmsgid \"%d file\"\nmsgid_plural \"%d files\"\nmsgstr[0] \"%d fichier\"\nmsgstr[1] \"%d fichiers\"\n"
  let report = check_text(good)
  assert_eq(report.exit_code, 0)
  assert_eq(report.stats.translated, 1)
  assert_eq(report.plural_checked_through, Some(1000))
  let bad = test_header() + "#, c-format\nmsgid \"%d\"\nmsgstr \"%s\"\n"
  assert_true(check_text(bad).diagnostics.any(d => d.code == "F005"))
  assert_eq(check_text(bad).exit_code, 1)
}

///|
test "fuzzy empty policies promote warnings without changing parsing" {
  let input = test_header() + "#, fuzzy\nmsgid \"x\"\nmsgstr \"\"\n"
  assert_eq(check_text(input).exit_code, 0)
  assert_eq(check_text(input, options={ ..default_options(), strict: true }).exit_code, 1)
  assert_eq(check_text(input, options={ ..default_options(), empty_severity: Error }).exit_code, 1)
  assert_eq(check_text(input, template=true).stats.warnings, 0)
}

///|
test "duplicate context keys differ from distinct contexts" {
  let input = test_header() + "msgctxt \"a\"\nmsgid \"x\"\nmsgstr \"X\"\n\nmsgctxt \"b\"\nmsgid \"x\"\nmsgstr \"Y\"\n"
  assert_true(!check_text(input).diagnostics.any(d => d.code == "C001"))
  let duplicate = input + "\nmsgctxt \"a\"\nmsgid \"x\"\nmsgstr \"Z\"\n"
  assert_true(check_text(duplicate).diagnostics.any(d => d.code == "C001"))
}

///|
test "missing plural slot newline NUL metadata and options are diagnosed" {
  let input = test_header() + "msgid \"file\\n\"\nmsgid_plural \"files\\n\"\nmsgstr[0] \"fichier\\000\"\n"
  let diagnostics = check_text(input).diagnostics
  for code in ["L003", "C010", "C012"] {
    assert_true(diagnostics.any(d => d.code == code))
  }
  let header = parse_catalog("msgid \"\"\nmsgstr \"Language: fr\\nLanguage: de\\nContent-Type: text/plain; charset=ISO-8859-1\\n\"\n")
  let findings = validate_header(header, read_header(header))
  assert_true(findings.any(d => d.code == "H003"))
  assert_true(findings.any(d => d.code == "H004"))
  assert_eq(check_text(input, options={ ..default_options(), plural_max: -1 }).exit_code, 2)
}

///|
test "PO dates handle leap days and time zones" {
  assert_true(valid_po_date("2024-02-29 12:15+0800"))
  assert_true(!valid_po_date("2025-02-29 12:15+0800"))
  assert_true(!valid_po_date("2026-13-01 12:15+0800"))
  assert_true(!valid_po_date("2026-10-01 25:15+0800"))
}
