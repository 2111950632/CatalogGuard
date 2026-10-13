///|
test "public consumer API checks a contextual catalog" {
  let text = "msgctxt \"menu\"\nmsgid \"Open\"\nmsgstr \"打开\"\n"
  let catalog = @szs.parse_catalog(text, file="consumer.po")
  assert_eq(catalog.entries[0].context, Some("menu"))
  assert_eq(catalog.entries[0].translation(0), Some("打开"))
  assert_eq(@szs.check_catalog(catalog).stats.translated, 1)
  assert_true(@szs.serialize_catalog(catalog) is Ok(_))
}
