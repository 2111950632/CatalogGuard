///|
test "protocol malformed JSON and unknown options are invocation failures" {
  for
    input in [
      "{", "[]", "{\"command\":\"unknown\"}", "{\"options\":{\"strict\":\"yes\"}}",
      "{\"options\":{\"plural_max\":1.5}}",
    ] {
    let response = @json.parse(dispatch(input)[:])
    assert_eq(json_field(response, "exit_code").bind(json_integer), Some(2))
  }
}

///|
test "config applies review policy and protects structural errors" {
  let policy = parse_policy(
    "{\"schema_version\":1,\"rules\":{\"H001\":\"off\",\"C007\":\"error\"}}",
  ).unwrap()
  let report = apply_policy(check_text("msgid \"x\"\nmsgstr \"\"\n"), policy)
  assert_eq(report.exit_code, 1)
  assert_true(!report.diagnostics.any(d => d.code == "H001"))
  assert_true(parse_policy("{\"rules\":{\"P002\":\"off\"}}") is Err(_))
  assert_true(parse_policy("{\"options\":{\"plural_max\":-1}}") is Err(_))
  assert_true(parse_policy("{\"typo\":1}") is Err(_))
}

///|
test "dispatch checks multiple files and returns versioned reports" {
  let request : Json = {
    "command": Json("check"),
    "files": Json([
      {
        "path": Json("good.po"),
        "text": Json(test_header() + "msgid \"x\"\nmsgstr \"X\"\n"),
      },
      { "path": Json("bad.po"), "text": Json("msgid x\n") },
    ]),
  }
  let response = @json.parse(dispatch(request.stringify())[:])
  assert_eq(json_field(response, "exit_code").bind(json_integer), Some(1))
  let data = json_field(response, "data").unwrap()
  assert_eq(json_field(data, "schema_version").bind(json_integer), Some(1))
}

///|
test "rule codes are unique and every configurable rule is discoverable" {
  let seen : Map[String, Bool] = Map([])
  for rule in rule_definitions() {
    assert_true(seen.get(rule.code) is None)
    seen.set(rule.code, true)
  }
  assert_true(rule_definitions().any(rule => rule.code == "F005"))
  assert_true(
    rule_definitions().any(rule => rule.code == "C007" && rule.configurable),
  )
}
