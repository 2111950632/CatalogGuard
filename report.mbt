///|
fn position_json(position : Position) -> Json {
  { "line": Json(position.line), "column": Json(position.column) }
}

///|
fn span_json(span : Span) -> Json {
  { "start": position_json(span.start), "end": position_json(span.end) }
}

///|
pub fn diagnostic_json(diagnostic : Diagnostic) -> Json {
  {
    "code": Json(diagnostic.code),
    "severity": Json(severity_name(diagnostic.severity)),
    "message": Json(diagnostic.message),
    "file": Json(diagnostic.file),
    "span": span_json(diagnostic.span),
    "entry": optional_json(diagnostic.entry),
    "related": match diagnostic.related {
      None => Json::null()
      Some(span) => span_json(span)
    },
    "hint": Json(diagnostic.hint),
  }
}

///|
pub fn statistics_json(stats : Statistics) -> Json {
  {
    "total": Json(stats.total),
    "active": Json(stats.active),
    "obsolete": Json(stats.obsolete),
    "translated": Json(stats.translated),
    "untranslated": Json(stats.untranslated),
    "fuzzy": Json(stats.fuzzy),
    "plural": Json(stats.plural),
    "errors": Json(stats.errors),
    "warnings": Json(stats.warnings),
    "infos": Json(stats.infos),
  }
}

///|
pub fn entry_json(entry : Entry) -> Json {
  {
    "context": optional_json(entry.context),
    "id": Json(entry.id),
    "plural": optional_json(entry.plural),
    "translations": Json(
      entry.translations.map(t => {
        "index": Json(t.index),
        "value": Json(t.value),
        "span": span_json(t.span),
      }),
    ),
    "flags": Json(entry.flags),
    "references": Json(entry.references),
    "comments": Json(
      entry.comments.map(c => {
        "kind": Json(c.kind),
        "text": Json(c.text),
        "span": span_json(c.span),
      }),
    ),
    "obsolete": Json(entry.obsolete),
    "span": span_json(entry.span),
    "id_span": span_json(entry.id_span),
    "plural_span": match entry.plural_span {
      None => Json::null()
      Some(span) => span_json(span)
    },
  }
}

///|
pub fn catalog_json(catalog : Catalog) -> Json {
  {
    "schema_version": Json(1),
    "file": Json(catalog.file),
    "entries": Json(catalog.entries.map(entry_json)),
    "diagnostics": Json(catalog.diagnostics.map(diagnostic_json)),
  }
}

///|
pub fn report_json(report : Report) -> Json {
  {
    "schema_version": Json(1),
    "tool": Json("szs"),
    "version": Json("0.1.0"),
    "file": Json(report.catalog.file),
    "exit_code": Json(report.exit_code),
    "statistics": statistics_json(report.stats),
    "plural_checked_through": optional_json(report.plural_checked_through),
    "diagnostics": Json(report.diagnostics.map(diagnostic_json)),
  }
}

///|
pub fn report_text(report : Report) -> String {
  let lines : Array[String] = []
  for diagnostic in report.diagnostics {
    let start = diagnostic.span.start
    lines.push(
      diagnostic.file +
      ":" +
      start.line.to_string() +
      ":" +
      start.column.to_string() +
      ": " +
      severity_name(diagnostic.severity) +
      " " +
      diagnostic.code +
      " " +
      diagnostic.message,
    )
    if diagnostic.hint != "" {
      lines.push("  hint: " + diagnostic.hint)
    }
    if diagnostic.related is Some(span) {
      lines.push(
        "  related source: " +
        span.start.line.to_string() +
        ":" +
        span.start.column.to_string(),
      )
    }
  }
  let stats = report.stats
  lines.push(
    report.catalog.file +
    ": " +
    stats.active.to_string() +
    " active, " +
    stats.translated.to_string() +
    " translated, " +
    stats.errors.to_string() +
    " errors, " +
    stats.warnings.to_string() +
    " warnings",
  )
  if report.plural_checked_through is Some(maximum) {
    lines.push(
      "Plural expression checked for n=0.." +
      maximum.to_string() +
      " (finite interval only).",
    )
  }
  join_strings(lines, "\n") + "\n"
}
