///|
fn acceptance_entry(
  context : String,
  value : String,
  plural~ : String? = None,
  flag~ : String = "",
) -> String {
  let prefix = (if flag == "" { "" } else { "#, " + flag + "\n" }) +
    "msgctxt " +
    quote_po(context) +
    "\nmsgid \"Save\"\n"
  let fields = match plural {
    None => "msgstr " + quote_po(value) + "\n\n"
    Some(plural) =>
      "msgid_plural " +
      quote_po(plural) +
      "\nmsgstr[0] " +
      quote_po(value) +
      "\nmsgstr[1] \"Same plural\"\n\n"
  }
  prefix + fields
}

///|
fn acceptance_merged(files : Array[Catalog]) -> Array[ProjectFinding] {
  check_consistency(files, options={
    ..default_consistency_options(),
    enabled: true,
    ignore_context: true,
  })
}

///|
test "Merged contexts retain conflicting translation witnesses in either order" {
  let a = acceptance_entry("menu", "Same")
  let b = acceptance_entry("dialog", "Different")
  for body in [a + b, b + a] {
    let files = project_pair(body, a)
    assert_eq(check_consistency(files).length(), 0)
    for ordered in [files, [files[1], files[0]]] {
      let found = acceptance_merged(ordered)
      assert_true(found.any(f => f.diagnostic.code == "X002"))
      assert_true(found.all(f => f.related_file != Some(f.diagnostic.file)))
    }
  }
}

///|
test "Merged contexts retain plural source witnesses in either order" {
  let a = acceptance_entry("menu", "Same", plural=Some("Saves"))
  let b = acceptance_entry("dialog", "Same", plural=Some("Saved items"))
  for body in [a + b, b + a] {
    let files = project_pair(body, a)
    assert_eq(check_consistency(files).length(), 0)
    for ordered in [files, [files[1], files[0]]] {
      assert_true(
        acceptance_merged(ordered).any(f => f.diagnostic.code == "X003"),
      )
    }
  }
}

///|
test "Merged contexts retain format flag witnesses in either order" {
  let a = acceptance_entry("menu", "Same", flag="c-format")
  let b = acceptance_entry("dialog", "Same", flag="python-format")
  for body in [a + b, b + a] {
    let files = project_pair(body, a)
    assert_eq(check_consistency(files).length(), 0)
    for ordered in [files, [files[1], files[0]]] {
      assert_true(
        acceptance_merged(ordered).any(f => f.diagnostic.code == "X004"),
      )
    }
  }
}

///|
test "Plural and translation conflicts can have different valid witnesses" {
  let files = project_pair(
    acceptance_entry("menu", "A", plural=Some("Saves")) +
    acceptance_entry("dialog", "B", plural=Some("Saved items")),
    acceptance_entry("menu", "C", plural=Some("Saves")),
  )
  let found = acceptance_merged(files)
  assert_eq(found.length(), 2)
  assert_eq(found[0].diagnostic.code, "X003")
  assert_eq(found[0].related_entry, Some(2))
  assert_eq(found[1].diagnostic.code, "X002")
  assert_eq(found[1].related_entry, Some(1))
}

///|
test "Merged alternatives in one file do not invent a cross-file conflict" {
  let files = [
    project_catalog(
      "a.po",
      "en",
      acceptance_entry("menu", "A") + acceptance_entry("dialog", "B"),
    ),
    project_catalog("b.po", "fr", acceptance_entry("menu", "C")),
  ]
  assert_eq(acceptance_merged(files).length(), 0)
}

///|
test "Forward witness indexes agree with brute force on 768 small projects" {
  let divisors = [1, 2, 4, 8, 16, 32, 64, 128]
  for mode = 0; mode < 3; mode = mode + 1 {
    let code = ["X002", "X003", "X004"][mode]
    for pattern = 0; pattern < 256; pattern = pattern + 1 {
      let values = divisors.map(divisor => pattern / divisor % 2)
      let files = Array::makei(4, file => {
        let body = [0, 1]
          .map(entry => {
            let value = values[file * 2 + entry]
            acceptance_entry(
              "context " + entry.to_string(),
              if mode == 0 {
                value.to_string()
              } else {
                "Same"
              },
              plural=if mode == 1 {
                Some("plural " + value.to_string())
              } else {
                None
              },
              flag=if mode == 2 {
                ["c-format", "python-format"][value]
              } else {
                ""
              },
            )
          })
          .join("")
        project_catalog(file.to_string() + ".po", "en", body)
      })
      let expected : Array[String] = []
      for file = 0; file < 4; file = file + 1 {
        for entry = 0; entry < 2; entry = entry + 1 {
          let mut conflict = false
          for previous = 0; previous < file * 2; previous = previous + 1 {
            if values[previous] != values[file * 2 + entry] {
              conflict = true
            }
          }
          if conflict {
            expected.push(file.to_string() + ":" + (entry + 1).to_string())
          }
        }
      }
      let found = acceptance_merged(files)
      assert_eq(
        found.map(f => {
          f.file_index.to_string() +
          ":" +
          f.diagnostic.entry.unwrap().to_string()
        }),
        expected,
      )
      assert_true(
        found.all(f => {
          f.diagnostic.code == code && f.related_file != Some(f.diagnostic.file)
        }),
      )
    }
  }
}
