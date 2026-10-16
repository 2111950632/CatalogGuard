// Cases generated from tests/format-cases.json; edit the fixture and regenerate.

///|
test "CGFC-1 C-01 legal-reorder" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%s has %d files\"\nmsgstr \"%2$d files for %1$s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-02 legal-reorder" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%*.*f %s\"\nmsgstr \"%4$s %3$*1$.*2$f\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-03 legal-repeat" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s %d\"\nmsgstr \"%2$d %1$s %1$s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-04 literal" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"100%% %d\"\nmsgstr \"%1$d 100%%\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-05 conversion-family" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%d %x %f\"\nmsgstr \"%1$i %2$o %3$e\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-06 width-precision" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%08.2f\"\nmsgstr \"%+12.4f\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-07 length" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%f\"\nmsgstr \"%lf\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-08 length" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%hhd %hd %ld %lld %jd %zd %td\"\nmsgstr \"%7$td %6$zd %5$jd %4$lld %3$ld %2$hd %1$hhd\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-09 length" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%hhu %hu %lu %llu %ju %zu %tu\"\nmsgstr \"%7$tu %6$zu %5$ju %4$llu %3$lu %2$hu %1$hhu\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-10 wide-and-pointer" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%lc %ls %p %Ln\"\nmsgstr \"%1$lc %2$ls %3$p %4$Ln\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F001"])
}

///|
test "CGFC-1 C-11 wide-and-pointer" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%lc %ls %p %n %hn %hhn %ln %lln %jn %zn %tn\"\nmsgstr \"%11$tn %10$zn %9$jn %8$lln %7$ln %6$hhn %5$hn %4$n %3$p %2$ls %1$lc\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-12 float" {
  let report = check_text(
    test_header() +
    "#, c-format\nmsgid \"%a %A %F %E %G %Lf\"\nmsgstr \"%6$Le %5$g %4$f %3$e %2$a %1$f\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-13 gnu-extension" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%m %%\"\nmsgstr \"%% %#m\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 C-14 missing" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s %d\"\nmsgstr \"%s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F003"])
}

///|
test "CGFC-1 C-15 extra" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%d\"\nmsgstr \"%d %s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F004"])
}

///|
test "CGFC-1 C-16 type-change" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%d\"\nmsgstr \"%s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F005"])
}

///|
test "CGFC-1 C-17 type-change" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%ld\"\nmsgstr \"%d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F005"])
}

///|
test "CGFC-1 C-18 type-change" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%n\"\nmsgstr \"%ln\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F005"])
}

///|
test "CGFC-1 C-19 syntax" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-20 syntax" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s %d\"\nmsgstr \"%1$s %d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-21 syntax" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%0$s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-22 syntax" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%2$s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-23 syntax" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%Ls\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-24 conflicting-reuse" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%d\"\nmsgstr \"%1$d %1$s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-25 outside-profile" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%d\"\nmsgstr \"%b\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-26 escaped-percent" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"100%% %d\"\nmsgstr \"100%5% %d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-27 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%#s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-28 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%s\"\nmsgstr \"%0s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-29 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%c\"\nmsgstr \"%.2c\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-30 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%n\"\nmsgstr \"%+n\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-31 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%n\"\nmsgstr \"%10n\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-32 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%n\"\nmsgstr \"%.*n\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-33 undefined-C-combination" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%p\"\nmsgstr \"%.*p\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 C-34 positional-gap" {
  let report = check_text(
    test_header() + "#, c-format\nmsgid \"%*d\"\nmsgstr \"%2$*3$d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-01 legal-reorder" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(name)s %(count)d\"\nmsgstr \"%(count)d %(name)s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-02 legal-repeat" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(name)s\"\nmsgstr \"%(name)s %(name)s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-03 dynamic-width" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%*.*f\"\nmsgstr \"%+*.*e\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-04 length" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%ld %hd %Ld\"\nmsgstr \"%d %d %d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-05 literal" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%% %(x)d\"\nmsgstr \"%(x)d %%\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-06 conversion-family" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%d %u %i %o %x %X\"\nmsgstr \"%i %d %u %x %o %X\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-07 float" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%e %E %f %F %g %G\"\nmsgstr \"%f %g %G %e %E %F\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-08 character" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%c\"\nmsgstr \"%3c\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-09 object-conversion" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%s %r %a\"\nmsgstr \"%10s %.5r %-10a\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-10 mapping-key" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(名字)s\"\nmsgstr \"%(名字)10s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-11 mapping-key" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%()s\"\nmsgstr \"%()10s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-12 mapping-key" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%((x))s\"\nmsgstr \"%((x))10s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-13 legal-repeated-uses" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(x)s %(x)r\"\nmsgstr \"%(x)r %(x)s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-14 legal-repeated-uses" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(x)d %(x)f\"\nmsgstr \"%(x)f %(x)d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 P-15 type-change" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%(x)d\"\nmsgstr \"%(x)s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F005"])
}

///|
test "CGFC-1 P-16 missing" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(x)d %(y)s\"\nmsgstr \"%(x)d\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F003"])
}

///|
test "CGFC-1 P-17 extra" {
  let report = check_text(
    test_header() +
    "#, python-format\nmsgid \"%(x)d\"\nmsgstr \"%(x)d %(y)s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F004"])
}

///|
test "CGFC-1 P-18 missing-star-operand" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%*.*f\"\nmsgstr \"%.*f\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F003", "F005"])
}

///|
test "CGFC-1 P-19 syntax" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%s\"\nmsgstr \"%\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-20 syntax" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%s\"\nmsgstr \"%q\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-21 outside-profile" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%(x)s\"\nmsgstr \"%(x)s %s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-22 syntax" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%(x)s\"\nmsgstr \"%(x)*s\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-23 syntax" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%s\"\nmsgstr \"%lls\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 P-24 syntax" {
  let report = check_text(
    test_header() + "#, python-format\nmsgid \"%(x)s\"\nmsgstr \"%(x\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-01 legal-reorder" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{name} {count:d}\"\nmsgstr \"{count:d} {name}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-02 legal-reorder" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{} {:d}\"\nmsgstr \"{1:d} {0}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-03 legal-repeat" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:d}\"\nmsgstr \"{x:d} {x:x}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-04 escape" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{{name}} {x}\"\nmsgstr \"{x} {{name}}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-05 dynamic-width-precision" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{v:{w}.{p}f} {name!s}\"\nmsgstr \"{name!s} {v:{w}.{p}f}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-06 path" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{user[name]} {items[0]}\"\nmsgstr \"{items[0]} {user[name]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-07 canonical-index" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{00} {items[01]}\"\nmsgstr \"{0} {items[1]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-08 automatic-path" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{[name]}\"\nmsgstr \"{0[name]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-09 automatic-path" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{.real}\"\nmsgstr \"{0.real}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-10 legal-repeated-uses" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x} {x:d}\"\nmsgstr \"{x:d} {x}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-11 legal-repeated-uses" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x!s} {x!r}\"\nmsgstr \"{x!r} {x!s}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-12 mini-language" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:*>+12,.2f}\"\nmsgstr \"{x:0=+15,.3e}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-13 mini-language" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:#08x}\"\nmsgstr \"{x:_b}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-14 mini-language" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:z.2f}\"\nmsgstr \"{x:z.3e}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-15 conversion" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x!s:>10s} {y!r} {z!a}\"\nmsgstr \"{z!a} {y!r} {x!s:^12s}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-16 type-change" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:d}\"\nmsgstr \"{x:s}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F005"])
}

///|
test "CGFC-1 B-17 missing-dynamic-operand" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{v:{w}.{p}f}\"\nmsgstr \"{v:.{p}f}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F003"])
}

///|
test "CGFC-1 B-18 missing" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x} {y}\"\nmsgstr \"{x}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F003"])
}

///|
test "CGFC-1 B-19 extra" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x}\"\nmsgstr \"{x} {y}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F004"])
}

///|
test "CGFC-1 B-20 syntax" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{} {}\"\nmsgstr \"{} {1}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-21 syntax" {
  let report = check_text(
    test_header() + "#, python-brace-format\nmsgid \"{x}\"\nmsgstr \"{x\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-22 syntax" {
  let report = check_text(
    test_header() + "#, python-brace-format\nmsgid \"{x}\"\nmsgstr \"x}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-23 syntax" {
  let report = check_text(
    test_header() + "#, python-brace-format\nmsgid \"{x}\"\nmsgstr \"{x!q}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-24 syntax" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:f}\"\nmsgstr \"{x:.f}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-25 nesting-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{0:{1}}\"\nmsgstr \"{0:{1:{2}}}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-26 mini-language-type-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:s}\"\nmsgstr \"{x:+s}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-27 mini-language-type-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:d}\"\nmsgstr \"{x:.2d}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-28 mini-language-type-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:d}\"\nmsgstr \"{x:zd}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-29 mini-language-type-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x:n}\"\nmsgstr \"{x:,n}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-30 conversion-type-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{x!s}\"\nmsgstr \"{x!s:d}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}

///|
test "CGFC-1 B-31 unicode-name" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{名字}\"\nmsgstr \"{名字:>8}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-32 literal-index" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{data[a:b]}\"\nmsgstr \"{data[a:b]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-33 unicode-decimal-index" {
  let report = check_text(
    test_header() + "#, python-brace-format\nmsgid \"{٠}\"\nmsgstr \"{0}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-34 unicode-decimal-index" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{０} {１２}\"\nmsgstr \"{0} {12}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-35 unicode-path" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{data[键]}\"\nmsgstr \"{data[键]:>8}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-36 literal-index" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{data[a[b]}\"\nmsgstr \"{data[a[b]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-37 literal-index" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{data[{}]}\"\nmsgstr \"{data[{}]}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, [])
}

///|
test "CGFC-1 B-38 resource-boundary" {
  let report = check_text(
    test_header() +
    "#, python-brace-format\nmsgid \"{0}\"\nmsgstr \"{10001}\"\n",
  )
  let codes = report.diagnostics
    .filter(d => d.code.has_prefix("F"))
    .map(d => d.code)
  let unique : Array[String] = []
  for code in codes {
    if !unique.contains(code) {
      unique.push(code)
    }
  }
  unique.sort()
  assert_eq(unique, ["F002"])
}
