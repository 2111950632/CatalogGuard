// Generated from tests/markup-cases.json. Edit the fixture, then regenerate.

///|
test "CGM-1 H01 plain text" {
  let catalog = parse_catalog(
    test_header() + "msgid \"Save & close\"\nmsgstr \"保存并关闭\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H02 balanced nested tags" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b><i>Save</i></b>\"\nmsgstr \"<b><i>保存</i></b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H03 legal sibling reorder" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b>one</b><i>two</i>\"\nmsgstr \"<i>二</i><b>一</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H04 legal attribute reorder" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"/help\\\" class=\\\"x\\\">Help</a>\"\nmsgstr \"<a class=\\\"x\\\" href=\\\"/help\\\">帮助</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H05 translatable attributes" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<img src=\\\"a.png\\\" alt=\\\"Image\\\" title=\\\"Hint\\\">\"\nmsgstr \"<img title=\\\"提示\\\" alt=\\\"图片\\\" src=\\\"a.png\\\">\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H06 protected href" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"/help\\\">Help</a>\"\nmsgstr \"<a href=\\\"/pay\\\">帮助</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 H07 missing tag" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>Save</b>\"\nmsgstr \"保存\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 H08 translated tag name" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b>Save</b>\"\nmsgstr \"<strong>保存</strong>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 H09 same counts changed ancestry" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b><i>one</i></b><u>two</u>\"\nmsgstr \"<b>一</b><u><i>二</i></u>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 H10 crossed closing tags" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b><i>Save</i></b>\"\nmsgstr \"<b><i>保存</b></i>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H11 unclosed tag" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>Save</b>\"\nmsgstr \"<b>保存\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H12 unexpected closing tag" {
  let catalog = parse_catalog(
    test_header() + "msgid \"Save\"\nmsgstr \"保存</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H13 quoted greater-than" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a data-x=\\\"a>b\\\">x</a>\"\nmsgstr \"<a data-x=\\\"a>b\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H14 HTML unquoted attributes" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=/help>Help</a>\"\nmsgstr \"<a href=\\\"/help\\\">帮助</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H15 HTML boolean attribute" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<input disabled>\"\nmsgstr \"<input disabled=\\\"\\\">\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H16 HTML void self closing" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<br>\"\nmsgstr \"<br/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H17 HTML void closing prohibited" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<br>\"\nmsgstr \"<br></br>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H18 nonvoid HTML slash is not a close" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>Save</b>\"\nmsgstr \"<b/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H19 HTML ASCII case folding" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<B TITLE=\\\"Help\\\">Help</B>\"\nmsgstr \"<b title=\\\"帮助\\\">帮助</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H20 duplicate attributes" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"x\\\">x</a>\"\nmsgstr \"<a href=\\\"x\\\" HREF=\\\"x\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H21 attribute whitespace" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"x\\\">x</a>\"\nmsgstr \"<a href=\\\"x\\\"title=\\\"中\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H22 unterminated attribute" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"x\\\">x</a>\"\nmsgstr \"<a href=\\\"x>中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H23 source raw text unsupported" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<script>x</script>\"\nmsgstr \"<script>y</script>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M001"])
}

///|
test "CGM-1 H24 target raw text unsupported" {
  let catalog = parse_catalog(
    test_header() + "msgid \"Save\"\nmsgstr \"<script>保存</script>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H25 HTML declaration unsupported" {
  let catalog = parse_catalog(
    test_header() + "msgid \"Save\"\nmsgstr \"<!DOCTYPE html>保存\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H26 comments do not freeze translations" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b>Save</b><!-- source -->\"\nmsgstr \"<!-- target --><b>保存</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H27 malformed comment" {
  let catalog = parse_catalog(
    test_header() + "msgid \"Save\"\nmsgstr \"<!-- a--b -->保存\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H28 unterminated start tag" {
  let catalog = parse_catalog(test_header() + "msgid \"Save\"\nmsgstr \"<b\"\n")
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 H29 multiple root fragments" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"A<b>B</b><i>C</i>\"\nmsgstr \"<i>丙</i>甲<b>乙</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H30 literal ampersand in HTML" {
  let catalog = parse_catalog(
    test_header() + "msgid \"A & B\"\nmsgstr \"甲 & 乙\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H31 protected entity equivalence" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"?x=1&amp;y=2\\\">x</a>\"\nmsgstr \"<a href=\\\"?x=1&#38;y=2\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H32 numeric reference identity" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"a\\\">x</a>\"\nmsgstr \"<a href=\\\"&#x61;\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H33 protected class changes" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b class=\\\"warning\\\">x</b>\"\nmsgstr \"<b class=\\\"ok\\\">中</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 H34 escaped angle brackets are text" {
  let catalog = parse_catalog(
    test_header() + "msgid \"&lt;Error&gt;\"\nmsgstr \"错误\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H35 opt-in plain less-than boundary" {
  let catalog = parse_catalog(
    test_header() + "msgid \"1 < 2\"\nmsgstr \"一小于二\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M001"])
}

///|
test "CGM-1 H36 HTML named entities in text" {
  let catalog = parse_catalog(
    test_header() + "msgid \"&copy; A\"\nmsgstr \"&reg; 乙\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H37 HTML uppercase hexadecimal reference" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a href=\\\"a\\\">x</a>\"\nmsgstr \"<a href=\\\"&#X61;\\\">中</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 H38 HTML element names start with ASCII letters" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<标签>x</标签>\"\nmsgstr \"<标签>中</标签>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "html",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M001"])
}

///|
test "CGM-1 X01 XML empty and paired elements" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<br/>\"\nmsgstr \"<br></br>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X02 XML case-sensitive names" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<B>x</B>\"\nmsgstr \"<b>中</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 X03 XML case-sensitive closing" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<B>x</B>\"\nmsgstr \"<B>中</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X04 XML quoted attributes required" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<a x=\\\"1\\\"/>\"\nmsgstr \"<a x=1/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X05 XML boolean attributes invalid" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<a x=\\\"\\\"/>\"\nmsgstr \"<a x/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X06 XML CDATA and comments" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b><![CDATA[<name>]]></b>\"\nmsgstr \"<!--中--><b><![CDATA[<名字>]]></b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X07 qualified names retained" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<x:a xmlns:x=\\\"urn:x\\\">one</x:a>\"\nmsgstr \"<x:a xmlns:x=\\\"urn:x\\\">一</x:a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X08 prefix changes are lexical contract changes" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<x:a xmlns:x=\\\"urn:x\\\"/>\"\nmsgstr \"<y:a xmlns:y=\\\"urn:x\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M003"])
}

///|
test "CGM-1 X09 undefined XML entity" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>&unknown;</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X10 bare XML ampersand" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>A & B</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X11 NUL reference" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>&#0;</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X12 surrogate reference" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>&#xD800;</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X13 out of range reference" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>&#99999999;</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X14 hex decimal attribute identity" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<b x=\\\"&#65;\\\"/>\"\nmsgstr \"<b x=\\\"&#x41;\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X15 Unicode XML names" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<标签 属性=\\\"值\\\">one</标签>\"\nmsgstr \"<标签 属性=\\\"值\\\">一</标签>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X16 CDATA terminator outside CDATA" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>x</b>\"\nmsgstr \"<b>]]></b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X17 DTD source unsupported" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<!DOCTYPE a><a/>\"\nmsgstr \"<a/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M001"])
}

///|
test "CGM-1 X18 processing instruction unsupported" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<a/>\"\nmsgstr \"<?target value?><a/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X19 unterminated CDATA" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<a/>\"\nmsgstr \"<a><![CDATA[x</a>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X20 less-than in quoted attribute" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<a x=\\\"1\\\"/>\"\nmsgstr \"<a x=\\\"<\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X21 XML attribute whitespace normalization" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a x=\\\"a b\\\"/>\"\nmsgstr \"<a x=\\\"a\\tb\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X22 XML duplicate attribute" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a x=\\\"1\\\"/>\"\nmsgstr \"<a x=\\\"1\\\" x=\\\"1\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}

///|
test "CGM-1 X23 XML has no void tags" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<br>\"\nmsgstr \"<br/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M001"])
}

///|
test "CGM-1 X24 XML escaped text may translate" {
  let catalog = parse_catalog(
    test_header() + "msgid \"<b>A&amp;B</b>\"\nmsgstr \"<b>甲&#38;乙</b>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, [])
}

///|
test "CGM-1 X25 XML uppercase hexadecimal prefix is invalid" {
  let catalog = parse_catalog(
    test_header() +
    "msgid \"<a x=\\\"a\\\"/>\"\nmsgstr \"<a x=\\\"&#X61;\\\"/>\"\n",
  )
  let result = check_markup_catalog(catalog, options={
    ..default_markup_options(),
    mode: "xml",
  })
  let codes = result.map(d => d.code)
  codes.sort()
  assert_eq(codes, ["M002"])
}
