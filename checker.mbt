///|
pub fn validate_options(options : Options) -> Array[String] {
  let errors : Array[String] = []
  if options.plural_max < 0 || options.plural_max > 100000 {
    errors.push("plural_max must be in 0..100000")
  }
  if options.expression_depth < 1 || options.expression_depth > 128 {
    errors.push("expression_depth must be in 1..128")
  }
  if options.expression_budget < 1 || options.expression_budget > 1000000 {
    errors.push("expression_budget must be in 1..1000000")
  }
  if options.max_entries < 1 || options.max_entries > 1000000 {
    errors.push("max_entries must be in 1..1000000")
  }
  if options.max_line_chars < 1 || options.max_line_chars > 4194304 {
    errors.push("max_line_chars must be in 1..4194304")
  }
  errors
}

///|
fn check_format_entry(entry : Entry, index : Int, catalog : Catalog, result : Array[Diagnostic]) -> Unit {
  for flag in entry.flags {
    if flag.has_suffix("-format") && flag != "c-format" && flag != "python-brace-format" && !flag.has_prefix("no-") && !flag.has_prefix("possible-") {
      result.push(issue("F007", Warning, "Format style is not checked in this release: " + flag, catalog.file, entry.id_span, entry=index))
    }
  }
  for style in ["c-format", "python-brace-format"] {
    if !entry.has_flag(style) {
      continue
    }
    let source = if style == "c-format" { printf_contract(entry.id) } else { brace_contract(entry.id) }
    let contract = match source {
      Ok(contract) => contract
      Err(error) => {
        result.push(issue("F001", Error, "Invalid or unsupported source format: " + error, catalog.file, entry.id_span, entry=index))
        continue
      }
    }
    if entry.plural is Some(plural) {
      let plural_contract = if style == "c-format" { printf_contract(plural) } else { brace_contract(plural) }
      match plural_contract {
        Err(error) => result.push(issue("F001", Error, "Invalid or unsupported plural source format: " + error, catalog.file, entry.plural_span.unwrap_or(entry.span), entry=index))
        Ok(actual) => {
          for difference in compare_contracts(contract, actual) {
            result.push(issue(difference.code, Error, "Singular/plural source mismatch: " + difference.message, catalog.file, entry.plural_span.unwrap_or(entry.span), entry=index, related=entry.id_span))
          }
        }
      }
    }
    for translation in entry.translations {
      if translation.value == "" {
        continue
      }
      let target = if style == "c-format" { printf_contract(translation.value) } else { brace_contract(translation.value) }
      match target {
        Err(error) => result.push(issue("F002", Error, "Invalid or unsupported translation format: " + error, catalog.file, translation.span, entry=index, related=entry.id_span))
        Ok(target) => {
          for difference in compare_contracts(contract, target) {
            result.push(issue(difference.code, Error, difference.message, catalog.file, translation.span, entry=index, related=entry.id_span))
          }
        }
      }
    }
  }
}

///|
fn check_entry_shape(entry : Entry, index : Int, catalog : Catalog, nplurals : Int?, template : Bool, options : Options, result : Array[Diagnostic]) -> Unit {
  if entry.translations.is_empty() {
    result.push(issue("C003", Error, "Entry has no msgstr field", catalog.file, entry.id_span, entry=index))
  }
  if entry.plural is None {
    for translation in entry.translations {
      if translation.index != 0 {
        result.push(issue("C004", Error, "Singular entry has a plural translation index", catalog.file, translation.span, entry=index))
      }
    }
  } else {
    if entry.plural == Some("") {
      result.push(issue("C005", Error, "msgid_plural is empty", catalog.file, entry.plural_span.unwrap_or(entry.span), entry=index))
    }
    if !template && nplurals is Some(count) {
      for expected = 0; expected < count; expected = expected + 1 {
        if entry.translation(expected) is None {
          result.push(issue("L003", Error, "Missing msgstr[" + expected.to_string() + "]", catalog.file, entry.span, entry=index))
        }
      }
      for translation in entry.translations {
        if translation.index >= count {
          result.push(issue("L004", Error, "Translation index exceeds nplurals", catalog.file, translation.span, entry=index))
        }
      }
    }
  }
  if entry.has_flag("fuzzy") && !template {
    result.push(issue("C006", options.fuzzy_severity, "Translation is marked fuzzy and needs review", catalog.file, entry.span, entry=index))
  }
  for translation in entry.translations {
    if translation.value == "" && !template {
      result.push(issue("C007", options.empty_severity, "Translation is empty at index " + translation.index.to_string(), catalog.file, translation.span, entry=index))
      continue
    }
    if template && translation.value != "" {
      result.push(issue("C008", Warning, "Template contains a translated msgstr", catalog.file, translation.span, entry=index))
    }
    if translation.value != "" {
      if entry.id.has_suffix("\n") != translation.value.has_suffix("\n") {
        result.push(issue("C010", Error, "Source and translation disagree on a final newline", catalog.file, translation.span, entry=index, related=entry.id_span))
      }
      if entry.id.has_prefix("\n") != translation.value.has_prefix("\n") {
        result.push(issue("C011", Warning, "Source and translation disagree on an initial newline", catalog.file, translation.span, entry=index, related=entry.id_span))
      }
    }
    check_control_characters(translation.value, catalog.file, translation.span, index, result)
  }
  check_control_characters(entry.id, catalog.file, entry.id_span, index, result)
  if entry.plural is Some(plural) {
    check_control_characters(plural, catalog.file, entry.plural_span.unwrap_or(entry.span), index, result)
    if entry.id.has_suffix("\n") != plural.has_suffix("\n") {
      result.push(issue("C010", Error, "Singular and plural sources disagree on a final newline", catalog.file, entry.plural_span.unwrap_or(entry.span), entry=index, related=entry.id_span))
    }
  }
}

///|
fn check_control_characters(text : String, file : String, span : Span, index : Int, result : Array[Diagnostic]) -> Unit {
  if text.to_array().any(c => c == '\u0000') {
    result.push(issue("C012", Error, "Catalog strings must not contain NUL", file, span, entry=index))
  }
  if text.to_array().any(c => c == '\r') {
    result.push(issue("C013", Warning, "String contains a carriage return", file, span, entry=index, hint="Use newline escapes unless a carriage return is intentional."))
  }
}

///|
fn report_with(catalog : Catalog, diagnostics : Array[Diagnostic], options : Options, checked : Int?) -> Report {
  let stats = statistics(catalog, diagnostics)
  let exit_code = if diagnostics.any(d => d.code == "O001") { 2 } else if stats.errors > 0 || (options.strict && stats.warnings > 0) { 1 } else { 0 }
  { catalog, diagnostics, stats, exit_code, plural_checked_through: checked }
}

///|
/// Validate a parsed catalog. Obsolete entries are retained but not checked.
pub fn check_catalog(catalog : Catalog, options? : Options = default_options(), template? : Bool = false) -> Report {
  let result = catalog.diagnostics.copy()
  let option_errors = validate_options(options)
  if !option_errors.is_empty() {
    for error in option_errors {
      result.push(issue("O001", Error, error, catalog.file, line_span(1, 1, 0)))
    }
    return report_with(catalog, result, options, None)
  }
  let header = read_header(catalog)
  for diagnostic in validate_header(catalog, header, template~) {
    result.push(diagnostic)
  }
  let mut count : Int? = None
  let mut checked : Int? = None
  let has_plural = catalog.entries.any(e => !e.obsolete && e.plural is Some(_))
  if !template {
    match header.get("Plural-Forms") {
      None => {
        if has_plural {
          result.push(issue("L001", Error, "Plural entries require Plural-Forms metadata", catalog.file, header_span(catalog)))
        }
      }
      Some(value) => {
        match parse_plural_rule(value, maximum_depth=options.expression_depth) {
          Err(error) => result.push(issue("L002", Error, error, catalog.file, header_span(catalog)))
          Ok(rule) => {
            count = Some(rule.nplurals)
            match plural_coverage(rule, maximum=options.plural_max, budget=options.expression_budget, maximum_depth=options.expression_depth) {
              Err(error) => result.push(issue("L002", Error, error, catalog.file, header_span(catalog)))
              Ok(coverage) => {
                if coverage.failures.is_empty() {
                  checked = Some(coverage.maximum)
                }
                for failure in coverage.failures {
                  result.push(issue("L006", Error, failure, catalog.file, header_span(catalog)))
                }
                for form = 0; form < rule.nplurals; form = form + 1 {
                  if !coverage.reached.contains(form) {
                    result.push(issue("L005", Warning, "Plural form " + form.to_string() + " was not reached in the tested interval", catalog.file, header_span(catalog), hint="Finite sampling is not a proof of unreachability for every n."))
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  let keys : Map[String, Int] = Map([])
  for index, entry in catalog.entries {
    if entry.obsolete {
      continue
    }
    let key = entry_key(entry)
    if keys.get(key) is Some(previous) {
      result.push(issue("C001", Error, "Duplicate msgctxt/msgid pair", catalog.file, entry.id_span, entry=index, related=catalog.entries[previous].id_span))
    } else {
      keys.set(key, index)
    }
    if entry.is_header() {
      if entry.plural is Some(_) || entry.translations.any(t => t.index != 0) {
        result.push(issue("C002", Error, "Header must be a singular untranslated-id entry", catalog.file, entry.span, entry=index))
      }
      continue
    }
    check_entry_shape(entry, index, catalog, count, template, options, result)
    check_format_entry(entry, index, catalog, result)
  }
  report_with(catalog, result, options, checked)
}

///|
pub fn check_text(text : String, file? : String = "<memory>", options? : Options = default_options(), template? : Bool = false) -> Report {
  check_catalog(parse_catalog(text, file~, options~), options~, template~)
}
