///|
test "plural operator precedence and right associative conditionals" {
  let tree = parse_plural_expression("n==1 ? 0 : n==2 ? 1 : 2").unwrap()
  assert_eq(evaluate_plural(tree, 1), Ok(0))
  assert_eq(evaluate_plural(tree, 2), Ok(1))
  assert_eq(evaluate_plural(tree, 7), Ok(2))
  let arithmetic = parse_plural_expression("2+3*4==14 && 10%3==1").unwrap()
  assert_eq(evaluate_plural(arithmetic, 0), Ok(1))
}

///|
test "short circuit does not evaluate dead division" {
  for input in ["0 && 1/0", "1 || 1/0", "n==0 ? 0 : 1/n"] {
    let expression = parse_plural_expression(input).unwrap()
    assert_true(evaluate_plural(expression, 0) is Ok(_))
  }
  let divide = parse_plural_expression("1/(n-1)").unwrap()
  assert_true(evaluate_plural(divide, 1) is Err(_))
}

///|
test "Russian plural coverage has three forms" {
  let rule = parse_plural_rule(
    "nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;",
  ).unwrap()
  assert_eq(evaluate_plural(rule.tree, 21), Ok(0))
  assert_eq(evaluate_plural(rule.tree, 22), Ok(1))
  assert_eq(evaluate_plural(rule.tree, 11), Ok(2))
  assert_eq(plural_coverage(rule).unwrap().reached.length(), 3)
}

///|
test "bad grammar unsafe arithmetic and bounded resources fail explicitly" {
  for input in ["", "n ? 1", "n+", "n & 1", "2147483648", "n n", "(n"] {
    assert_true(parse_plural_expression(input) is Err(_))
  }
  assert_true(parse_plural_rule("nplurals=0; plural=0;") is Err(_))
  assert_true(parse_plural_rule("nplurals=2; nplurals=3; plural=0;") is Err(_))
  let overflow = parse_plural_expression("2147483647+1").unwrap()
  assert_true(evaluate_plural(overflow, 0) is Err(_))
  assert_true(evaluate_plural(Count, 1, budget=0) is Err(_))
  assert_true(parse_plural_expression("((((n))))", maximum_depth=2) is Err(_))
  let invalid = parse_plural_rule("nplurals=2; plural=n;").unwrap()
  assert_true(!plural_coverage(invalid, maximum=5).unwrap().failures.is_empty())
}
