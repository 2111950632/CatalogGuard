///|
test "printf positional reorder and repeated arguments are compatible" {
  let a = printf_contract("%s has %d files").unwrap()
  let b = printf_contract("%2$d fichiers pour %1$s (%1$s)").unwrap()
  assert_eq(compare_contracts(a, b).length(), 0)
  assert_eq(printf_contract("%% %m").unwrap().arguments.length(), 0)
}

///|
test "printf consumes star width and precision before value" {
  let a = printf_contract("%*.*f").unwrap()
  let b = printf_contract("%3$*1$.*2$f").unwrap()
  assert_eq(compare_contracts(a, b).length(), 0)
  assert_eq(a.arguments.length(), 3)
  assert_true(printf_contract("%1$s %d") is Err(_))
  assert_true(printf_contract("%0$s") is Err(_))
  assert_true(printf_contract("%2$s") is Err(_))
  assert_true(printf_contract("%") is Err(_))
  assert_true(printf_contract("%Ls") is Err(_))
}

///|
test "printf dropped extra and changed type arguments have distinct findings" {
  let a = printf_contract("%s %d").unwrap()
  let b = printf_contract("%d %d %f").unwrap()
  let findings = compare_contracts(a, b)
  assert_true(findings.any(d => d.code == "F005"))
  assert_true(findings.any(d => d.code == "F004"))
  let c = printf_contract("%s").unwrap()
  assert_true(compare_contracts(a, c).any(d => d.code == "F003"))
  assert_true(!compare_contracts(printf_contract("%ld").unwrap(), printf_contract("%d").unwrap()).is_empty())
}

///|
test "brace named reorder escaped literals and nested precision" {
  let a = brace_contract("{{hello}} {user.name!s} {value:{width}.{precision}f}").unwrap()
  let b = brace_contract("{value:{width}.{precision}f} 用户 {user.name!s}").unwrap()
  assert_eq(compare_contracts(a, b).length(), 0)
  assert_eq(a.arguments.length(), 4)
  assert_eq(brace_contract("{} {}").unwrap().arguments[0].name, "0")
}

///|
test "brace rejects mixed numbering syntax mistakes and changed presentation" {
  for input in ["{} {1}", "{x", "x}", "{x!q}", "{x:.f}", "{x[}"] {
    assert_true(brace_contract(input) is Err(_))
  }
  let a = brace_contract("{count:d}").unwrap()
  let b = brace_contract("{count:s}").unwrap()
  assert_true(compare_contracts(a, b).any(d => d.code == "F005"))
}
