///|
test "bounded integer and whitespace utilities" {
  assert_eq(decimal_text("2147483647", 2147483647), Some(2147483647))
  assert_eq(decimal_text("2147483648", 2147483647), None)
  assert_eq(decimal_text("12x", 100), None)
  assert_eq(trim_text(" \t中文 \r"), "中文")
  assert_eq(split_lines("a\r\nb\n"), ["a", "b", ""])
}
