///|
fn project_catalog(file : String, language : String, body : String) -> Catalog {
  let header = "msgid \"\"\nmsgstr \"Language: " +
    language +
    "\\nContent-Type: text/plain; charset=UTF-8\\nPlural-Forms: nplurals=2; plural=(n!=1);\\n\"\n\n"
  parse_catalog(header + body, file~)
}

///|
fn project_pair(first : String, second : String) -> Array[Catalog] {
  [
    project_catalog("first.po", "zh_CN", first),
    project_catalog("second.po", "zh_CN", second),
  ]
}

///|
test "CGP-1 identical targets are consistent" {
  assert_eq(
    check_consistency(
      project_pair(
        "msgid \"Save\"\nmsgstr \"保存\"\n", "msgid \"Save\"\nmsgstr \"保存\"\n",
      ),
    ).length(),
    0,
  )
}

///|
test "CGP-1 conflicts retain both file locations" {
  let findings = check_consistency(
    project_pair(
      "msgid \"Save\"\nmsgstr \"保存\"\n", "msgid \"Save\"\nmsgstr \"存储\"\n",
    ),
  )
  assert_eq(findings.length(), 1)
  let found = findings[0]
  assert_eq(found.diagnostic.code, "X002")
  assert_eq(found.diagnostic.file, "second.po")
  assert_eq(found.related_file, Some("first.po"))
  assert_true(found.related_span.unwrap().start.line > 0)
  assert_eq(found.related_entry, Some(1))
}

///|
test "CGP-1 contexts distinguish meanings" {
  let files = project_pair(
    "msgctxt \"verb\"\nmsgid \"Open\"\nmsgstr \"打开\"\n", "msgctxt \"adjective\"\nmsgid \"Open\"\nmsgstr \"开放\"\n",
  )
  assert_eq(check_consistency(files).length(), 0)
}

///|
test "CGP-1 context folding is explicit" {
  let files = project_pair(
    "msgctxt \"verb\"\nmsgid \"Open\"\nmsgstr \"打开\"\n", "msgctxt \"adjective\"\nmsgid \"Open\"\nmsgstr \"开放\"\n",
  )
  assert_eq(
    check_consistency(files, options={
      ..default_consistency_options(),
      enabled: true,
      ignore_context: true,
    })[0].diagnostic.code,
    "X002",
  )
}

///|
test "CGP-1 different languages are separate" {
  let files = [
    project_catalog("a.po", "fr", "msgid \"Save\"\nmsgstr \"Enregistrer\"\n"),
    project_catalog("b.po", "de", "msgid \"Save\"\nmsgstr \"Speichern\"\n"),
  ]
  assert_eq(check_consistency(files).length(), 0)
}

///|
test "CGP-1 case and underscore locale aliases group together" {
  let files = [
    project_catalog("a.po", "ZH_cn", "msgid \"Save\"\nmsgstr \"保存\"\n"),
    project_catalog("b.po", "zh-CN", "msgid \"Save\"\nmsgstr \"存储\"\n"),
  ]
  assert_eq(check_consistency(files)[0].diagnostic.code, "X002")
}

///|
test "CGP-1 territory variants are separate" {
  let files = [
    project_catalog("a.po", "zh_CN", "msgid \"Save\"\nmsgstr \"保存\"\n"),
    project_catalog("b.po", "zh_TW", "msgid \"Save\"\nmsgstr \"儲存\"\n"),
  ]
  assert_eq(check_consistency(files).length(), 0)
}

///|
test "CGP-1 missing language is reported without guessed groups" {
  let findings = check_consistency([
    parse_catalog("msgid \"Save\"\nmsgstr \"保存\"\n", file="unknown.po"),
  ])
  assert_eq(findings[0].diagnostic.code, "X001")
  assert_eq(findings[0].diagnostic.entry, None)
}

///|
test "CGP-1 fuzzy translations are excluded" {
  assert_eq(
    check_consistency(
      project_pair(
        "#, fuzzy\nmsgid \"Save\"\nmsgstr \"保存\"\n", "msgid \"Save\"\nmsgstr \"存储\"\n",
      ),
    ).length(),
    0,
  )
}

///|
test "CGP-1 obsolete translations are excluded" {
  assert_eq(
    check_consistency(
      project_pair(
        "#~ msgid \"Save\"\n#~ msgstr \"保存\"\n", "msgid \"Save\"\nmsgstr \"存储\"\n",
      ),
    ).length(),
    0,
  )
}

///|
test "CGP-1 empty translations are excluded" {
  assert_eq(
    check_consistency(
      project_pair(
        "msgid \"Save\"\nmsgstr \"\"\n", "msgid \"Save\"\nmsgstr \"存储\"\n",
      ),
    ).length(),
    0,
  )
}

///|
test "CGP-1 plural source drift is a structural error" {
  let files = project_pair(
    "msgid \"file\"\nmsgid_plural \"files\"\nmsgstr[0] \"文件\"\nmsgstr[1] \"文件\"\n",
    "msgid \"file\"\nmsgid_plural \"documents\"\nmsgstr[0] \"文件\"\nmsgstr[1] \"文件\"\n",
  )
  assert_eq(check_consistency(files)[0].diagnostic.code, "X003")
}

///|
test "CGP-1 all plural slots participate" {
  let files = project_pair(
    "msgid \"file\"\nmsgid_plural \"files\"\nmsgstr[0] \"文件\"\nmsgstr[1] \"文件\"\n",
    "msgid \"file\"\nmsgid_plural \"files\"\nmsgstr[0] \"文件\"\nmsgstr[1] \"档案\"\n",
  )
  assert_eq(check_consistency(files)[0].diagnostic.code, "X002")
}

///|
test "CGP-1 flags drift is independently reported" {
  let files = project_pair(
    "#, c-format\nmsgid \"%s\"\nmsgstr \"%s\"\n", "#, python-format\nmsgid \"%s\"\nmsgstr \"%s\"\n",
  )
  assert_eq(check_consistency(files)[0].diagnostic.code, "X004")
}

///|
test "CGP-1 within-file duplicates belong to catalog checking" {
  let files = [
    project_catalog(
      "a.po", "en", "msgid \"Save\"\nmsgstr \"A\"\n\nmsgid \"Save\"\nmsgstr \"B\"\n",
    ),
  ]
  assert_eq(check_consistency(files).length(), 0)
  assert_true(check_catalog(files[0]).diagnostics.any(d => d.code == "C001"))
}

///|
test "CGP-1 inverse collision review is opt-in" {
  let files = project_pair(
    "msgid \"Delete\"\nmsgstr \"取消\"\n", "msgid \"Cancel\"\nmsgstr \"取消\"\n",
  )
  assert_eq(check_consistency(files).length(), 0)
  assert_eq(
    check_consistency(files, options={
      ..default_consistency_options(),
      enabled: true,
      inverse: true,
    })[0].diagnostic.code,
    "X005",
  )
}

///|
test "CGP-1 project-wide limits fail explicitly" {
  let files = project_pair(
    "msgid \"Save\"\nmsgstr \"A\"\n", "msgid \"Save\"\nmsgstr \"B\"\n",
  )
  assert_eq(
    check_consistency(files, options={
      ..default_consistency_options(),
      enabled: true,
      max_entries: 1,
    })[0].diagnostic.code,
    "X009",
  )
  assert_eq(
    check_consistency(files, options={
      ..default_consistency_options(),
      enabled: true,
      max_entries: 0,
    })[0].diagnostic.code,
    "O001",
  )
}

///|
test "CGP-1 malformed catalogs are not used as conflict evidence" {
  let files = [
    parse_catalog("msgid bad\nmsgstr \"A\"\n", file="bad.po"),
    project_catalog("ok.po", "en", "msgid \"Save\"\nmsgstr \"B\"\n"),
  ]
  assert_eq(check_consistency(files).length(), 0)
}

///|
test "CGP-1 severity overrides match project findings and file reports" {
  let config = parse_project_policy(
    "{\"quality\":{\"consistency\":{\"enabled\":true}},\"rules\":{\"X002\":\"error\"}}",
  ).unwrap()
  let checked = check_project(
    project_pair(
      "msgid \"Save\"\nmsgstr \"A\"\n", "msgid \"Save\"\nmsgstr \"B\"\n",
    ),
    configuration=config,
  )
  assert_eq(checked.exit_code, 1)
  assert_eq(checked.findings[0].diagnostic.severity, Error)
  assert_true(
    checked.reports[1].diagnostics.any(d => {
      d.code == "X002" && d.severity == Error
    }),
  )
}

///|
test "CGP-1 review findings can be disabled but structural failures cannot" {
  let config = parse_project_policy(
    "{\"quality\":{\"consistency\":{\"enabled\":true}},\"rules\":{\"X002\":\"off\"}}",
  ).unwrap()
  let checked = check_project(
    project_pair(
      "msgid \"Save\"\nmsgstr \"A\"\n", "msgid \"Save\"\nmsgstr \"B\"\n",
    ),
    configuration=config,
  )
  assert_eq(checked.findings.length(), 0)
  assert_true(!checked.reports[1].diagnostics.any(d => d.code == "X002"))
  assert_true(parse_project_policy("{\"rules\":{\"M003\":\"off\"}}") is Err(_))
}

///|
test "CGM-1 resource limits reject rather than truncate" {
  let long_value = String::from_array(Array::make(65536, 'a'))
  assert_eq(
    markup_contract("<a href='" + long_value + "'>x</a>").unwrap().nodes,
    1,
  )
  assert_true(
    markup_contract("<b>x</b>", options={
      ..default_markup_options(),
      mode: "html",
      max_chars: 4,
    })
    is Err(_),
  )
  assert_true(
    markup_contract("<b><i>x</i></b>", options={
      ..default_markup_options(),
      mode: "html",
      max_depth: 1,
    })
    is Err(_),
  )
  assert_true(
    markup_contract("<b>x</b><i>y</i>", options={
      ..default_markup_options(),
      mode: "html",
      max_nodes: 1,
    })
    is Err(_),
  )
}

///|
test "CGM-1 protected attributes remain attached to their subtrees" {
  let source = markup_contract(
    "<a href='one'><b>x</b></a><a href='two'><i>y</i></a>",
  ).unwrap()
  let target = markup_contract(
    "<a href='one'><i>x</i></a><a href='two'><b>y</b></a>",
  ).unwrap()
  assert_true(source.signature != target.signature)
}

///|
test "CGM-1 plural source contract drift cannot be guessed from slot zero" {
  let catalog = project_catalog(
    "plural.po", "en", "msgid \"<b>file</b>\"\nmsgid_plural \"<i>files</i>\"\nmsgstr[0] \"<b>文件</b>\"\nmsgstr[1] \"<i>文件</i>\"\n",
  )
  assert_eq(check_markup_catalog(catalog)[0].code, "M004")
}

///|
test "CGM-1 translatable attribute set is configurable" {
  let a = markup_contract("<a href='one'>x</a>", options={
    ..default_markup_options(),
    mode: "html",
    translatable_attributes: ["href"],
  }).unwrap()
  let b = markup_contract("<a href='two'>y</a>", options={
    ..default_markup_options(),
    mode: "html",
    translatable_attributes: ["href"],
  }).unwrap()
  assert_eq(a.signature, b.signature)
}

///|
test "CGP-1 invalid new configuration is rejected" {
  for
    config in [
      "{\"quality\":{\"markup\":{\"mode\":\"auto\"}}}", "{\"quality\":{\"consistency\":{\"enabled\":1}}}",
      "{\"quality\":{\"markup\":{\"max_depth\":129}}}", "{\"quality\":{\"markup\":{\"translatable_attributes\":[1]}}}",
      "{\"quality\":{\"other\":{}}}",
    ] {
    assert_true(parse_project_policy(config) is Err(_))
  }
  let duplicate = @json.parse(
    dispatch(
      "{\"files\":[{\"path\":\"same.po\",\"text\":\"\"},{\"path\":\"same.po\",\"text\":\"\"}]}",
    ),
  ) catch {
    _ => abort("Expected JSON response")
  }
  assert_eq(json_field(duplicate, "exit_code").bind(json_integer), Some(2))
}

///|
test "CGP-1 defaults preserve existing single-catalog semantics" {
  let checked = check_project(
    project_pair(
      "msgid \"<b>x</b>\"\nmsgstr \"broken\"\n", "msgid \"<b>x</b>\"\nmsgstr \"different\"\n",
    ),
  )
  assert_eq(checked.findings.length(), 0)
  assert_true(
    checked.reports.all(r => {
      !r.diagnostics.any(d => d.code.has_prefix("M") || d.code.has_prefix("X"))
    }),
  )
}
