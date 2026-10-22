///|
test "XML CRLF in protected attributes is one normalized space" {
  let options = { ..default_markup_options(), mode: "xml", }
  let source = markup_contract("<a href='one two'/>", options~).unwrap()
  let target = markup_contract("<a href='one\r\ntwo'/>", options~).unwrap()
  assert_eq(source.signature, target.signature)
}

///|
test "XML character references preserve explicit carriage return" {
  let options = { ..default_markup_options(), mode: "xml", }
  let source = markup_contract("<a href='one two'/>", options~).unwrap()
  let literal = markup_contract("<a href='one\rtwo'/>", options~).unwrap()
  let reference = markup_contract("<a href='one&#13;two'/>", options~).unwrap()
  assert_eq(source.signature, literal.signature)
  assert_true(source.signature != reference.signature)
}

///|
test "Malformed language identifiers do not create consistency groups" {
  for language in ["123", "-", "zh_", "_CN", "zh--CN", "zh__CN", "zh-_-CN"] {
    let first = project_catalog(
      "first.po", language, "msgid \"Save\"\nmsgstr \"保存\"\n",
    )
    let second = project_catalog(
      "second.po", language, "msgid \"Save\"\nmsgstr \"存储\"\n",
    )
    let findings = check_consistency([first, second])
    assert_eq(findings.length(), 2)
    assert_true(findings.all(f => f.diagnostic.code == "X001"))
  }
}

///|
test "Regional script and numeric subtags retain explicit language groups" {
  for
    pair in [
      ("zh_Hans_CN", "zh-hans-cn"),
      ("es_419", "es-419"),
      ("x_demo", "x-demo"),
    ] {
    let (language, normalized) = pair
    let first = project_catalog(
      "first.po", language, "msgid \"Save\"\nmsgstr \"保存\"\n",
    )
    let second = project_catalog(
      "second.po", normalized, "msgid \"Save\"\nmsgstr \"存储\"\n",
    )
    let findings = check_consistency([first, second])
    assert_eq(findings.length(), 1)
    assert_eq(findings[0].diagnostic.code, "X002")
  }
}

///|
test "Inverse review sees a later source in the first file" {
  let files = project_pair(
    "msgid \"Cancel\"\nmsgstr \"取消\"\n\nmsgid \"Delete\"\nmsgstr \"取消\"\n",
    "msgid \"Cancel\"\nmsgstr \"取消\"\n",
  )
  let found = check_consistency(files, options={
    ..default_consistency_options(),
    enabled: true,
    inverse: true,
  })
  assert_eq(found.length(), 1)
  assert_eq(found[0].diagnostic.code, "X005")
  assert_eq(found[0].related_file, Some("first.po"))
  assert_eq(found[0].related_entry, Some(2))
}

///|
test "Inverse witnesses must differ in both file and source" {
  let files = [
    project_catalog("a.po", "zh_CN", "msgid \"Cancel\"\nmsgstr \"取消\"\n"),
    project_catalog("b.po", "zh_CN", "msgid \"Delete\"\nmsgstr \"取消\"\n"),
    project_catalog("c.po", "zh_CN", "msgid \"Delete\"\nmsgstr \"取消\"\n"),
    project_catalog("d.po", "zh_CN", "msgid \"Cancel\"\nmsgstr \"取消\"\n"),
  ]
  let found = check_consistency(files, options={
    ..default_consistency_options(),
    enabled: true,
    inverse: true,
  })
  assert_eq(found.filter(f => f.diagnostic.code == "X005").length(), 3)
  assert_eq(found[2].diagnostic.file, "d.po")
}

///|
test "Inverse grouping agrees with a brute-force reference on 729 small projects" {
  let choices = [[0], [1], [2], [0, 1], [1, 0], [0, 2], [2, 0], [1, 2], [2, 1]]
  for first in choices {
    for second in choices {
      for third in choices {
        let rows = [first, second, third]
        let files = rows.mapi((index, sources) => {
          let body = sources
            .map(source => {
              "msgid \"source " +
              source.to_string() +
              "\"\nmsgstr \"shared\"\n\n"
            })
            .join("")
          project_catalog(index.to_string() + ".po", "en", body)
        })
        let expected : Array[String] = []
        for file_index, sources in rows {
          for entry_index, source in sources {
            let mut conflict = false
            for previous_file = 0
                previous_file < file_index
                previous_file = previous_file + 1 {
              if rows[previous_file].any(previous => previous != source) {
                conflict = true
              }
            }
            if conflict {
              expected.push(
                file_index.to_string() + ":" + (entry_index + 1).to_string(),
              )
            }
          }
        }
        let findings = check_consistency(files, options={
          ..default_consistency_options(),
          enabled: true,
          inverse: true,
        })
        assert_eq(
          findings.map(f => {
            f.file_index.to_string() +
            ":" +
            f.diagnostic.entry.unwrap().to_string()
          }),
          expected,
        )
        assert_true(
          findings.all(f => {
            f.diagnostic.code == "X005" &&
            f.related_file != Some(f.diagnostic.file)
          }),
        )
      }
    }
  }
}

///|
test "Same-file alternatives alone do not establish an inverse conflict" {
  let files = project_pair(
    "msgid \"Cancel\"\nmsgstr \"取消\"\n", "msgid \"Delete\"\nmsgstr \"取消\"\n\nmsgid \"Cancel\"\nmsgstr \"取消\"\n",
  )
  let found = check_consistency(files, options={
    ..default_consistency_options(),
    enabled: true,
    inverse: true,
  })
  assert_eq(found.length(), 1)
  assert_eq(found[0].diagnostic.entry, Some(1))
}

///|
test "Project diagnostics remain attached to the right files in bulk review" {
  let files = Array::makei(24, index => {
    project_catalog(
      index.to_string() + ".po",
      "en",
      "msgid \"Save\"\nmsgstr \"value " + index.to_string() + "\"\n",
    )
  })
  let report = check_project(files, configuration={
    ..default_project_policy(),
    consistency: { ..default_consistency_options(), enabled: true, },
  })
  assert_eq(report.findings.length(), 23)
  for index, file in report.reports {
    let conflicts = file.diagnostics.filter(d => d.code == "X002")
    assert_eq(conflicts.length(), if index == 0 { 0 } else { 1 })
    assert_true(conflicts.all(d => d.file == index.to_string() + ".po"))
  }
}

///|
test "HTML literal line endings normalize to LF without collapsing spaces" {
  let source = markup_contract("<a href='one\ntwo'>x</a>").unwrap()
  for target in ["<a href='one\r\ntwo'>y</a>", "<a href='one\rtwo'>y</a>"] {
    assert_eq(source.signature, markup_contract(target).unwrap().signature)
  }
  assert_true(
    source.signature !=
    markup_contract("<a href='one two'>y</a>").unwrap().signature,
  )
}

///|
test "HTML numeric carriage-return references are not literal line breaks" {
  let literal = markup_contract("<a href='one\ntwo'>x</a>").unwrap()
  let reference = markup_contract("<a href='one&#13;two'>x</a>").unwrap()
  assert_true(literal.signature != reference.signature)
}
