///|
pub(all) struct RuleDefinition {
  code : String
  category : String
  summary : String
  configurable : Bool
} derive(Eq, Debug)

///|
/// Discoverable rule inventory for editors, CI tools, and config validation.
pub fn rule_definitions() -> Array[RuleDefinition] {
  let definitions = [
    ("P001", "syntax", "Unknown directive or missing directive whitespace"),
    ("P002", "syntax", "Malformed quoted string or unsupported escape"),
    ("P003", "syntax", "Entry fields appear without msgid"),
    ("P004", "syntax", "Continuation has no preceding string field"),
    ("P005", "syntax", "Invalid or excessive translation index"),
    ("P006", "syntax", "Active and obsolete fields are mixed"),
    ("P007", "syntax", "Translation appears before its source"),
    ("P008", "encoding", "Escaped bytes do not form valid UTF-8"),
    ("P009", "resource", "Configured line or entry limit was exceeded"),
    ("P010", "syntax", "A field occurs more than once in an entry"),
    ("P011", "syntax", "Singular and indexed msgstr syntax disagree"),
    ("P012", "syntax", "Trailing comments have no associated catalog entry"),
    ("H001", "metadata", "Catalog has no metadata header"),
    ("H002", "metadata", "Malformed metadata line or field name"),
    ("H003", "metadata", "Duplicate metadata field"),
    ("H004", "encoding", "Unsupported Content-Type or charset"),
    ("H005", "metadata", "Unexpected MIME version or transfer encoding"),
    ("H006", "metadata", "Required metadata field is missing or empty"),
    ("H007", "metadata", "Language metadata is missing or malformed"),
    ("H008", "metadata", "Date is malformed or outside calendar bounds"),
    ("H009", "metadata", "Metadata contains an unfilled template placeholder"),
    ("C001", "catalog", "Duplicate active context and source key"),
    ("C002", "catalog", "Header has an invalid plural structure"),
    ("C003", "catalog", "Entry has no translation field"),
    ("C004", "catalog", "Singular entry has plural translation indexes"),
    ("C005", "catalog", "Plural source string is empty"),
    ("C006", "review", "Translation is marked fuzzy"),
    ("C007", "review", "Translation string is empty"),
    ("C008", "template", "POT template contains a translation"),
    ("C010", "content", "Final newline differs between source and translation"),
    (
      "C011", "content", "Initial newline differs between source and translation",
    ),
    ("C012", "content", "String contains a NUL character"),
    ("C013", "content", "String contains a carriage return"),
    ("F001", "format", "Invalid or unsupported source format syntax"),
    ("F002", "format", "Invalid or unsupported translation format syntax"),
    ("F003", "format", "Required argument is missing"),
    ("F004", "format", "Translation introduces an extra argument"),
    ("F005", "format", "Argument type or conversion contract changed"),
    ("F006", "format", "Format contract styles differ"),
    ("F007", "format", "An explicit format flag is unsupported"),
    ("F008", "format", "Format flags contradict an explicit no-format flag"),
    ("L001", "plural", "Plural entries have no Plural-Forms metadata"),
    ("L002", "plural", "Plural rule syntax or parameters are invalid"),
    ("L003", "plural", "Expected translation slot is missing"),
    ("L004", "plural", "Translation slot exceeds nplurals"),
    ("L005", "plural", "A plural slot was not reached in the finite interval"),
    ("L006", "plural", "Plural evaluation failed or returned an invalid index"),
    ("T001", "template", "An exact template entry is missing"),
    ("T002", "template", "Translation entry is absent from the template"),
    ("T003", "template", "Plural source differs from template"),
    ("T004", "template", "Format flags differ from template"),
    ("O001", "configuration", "An option is outside supported bounds"),
    (
      "M001", "markup", "Source markup is invalid or outside the fragment profile",
    ),
    (
      "M002", "markup", "Translation markup is invalid or outside the fragment profile",
    ),
    ("M003", "markup", "Markup tree or protected attribute contract changed"),
    ("M004", "markup", "Singular and plural source markup contracts differ"),
    (
      "X001", "consistency", "Language metadata cannot establish a comparison group",
    ),
    (
      "X002", "consistency", "Same source has conflicting translations across files",
    ),
    (
      "X003", "consistency", "Same source has different plural definitions across files",
    ),
    ("X004", "consistency", "Format flags differ across files"),
    (
      "X005", "consistency", "Different sources share a translation (inverse review)",
    ),
    ("X009", "resource", "Project consistency entry limit exceeded"),
  ]
  definitions.map(definition => {
    let (code, category, summary) = definition
    { code, category, summary, configurable: configurable_rule(code), }
  })
}

///|
fn rules_response() -> Json {
  let rules = rule_definitions()
  let text = rules.map(rule => {
    rule.code +
    " [" +
    rule.category +
    "] " +
    rule.summary +
    (if rule.configurable { " (configurable)" } else { "" })
  })
  {
    "exit_code": Json(0),
    "text": Json(join_strings(text, "\n") + "\n"),
    "data": {
      "schema_version": Json(1),
      "rules": Json(
        rules.map(rule => {
          "code": Json(rule.code),
          "category": Json(rule.category),
          "summary": Json(rule.summary),
          "configurable": Json(rule.configurable),
        }),
      ),
    },
  }
}
