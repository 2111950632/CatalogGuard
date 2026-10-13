///|
priv struct RequestFile {
  path : String
  text : String
  template : Bool
}

///|
fn protocol_error(message : String) -> Json {
  {
    "exit_code": Json(2),
    "text": Json("szs: " + message + "\n"),
    "data": {
      "schema_version": Json(1),
      "error": Json(message),
      "exit_code": Json(2),
    },
  }
}

///|
fn request_files(request : Json) -> Result[Array[RequestFile], String] {
  let raw = json_field(request, "files").unwrap_or(Json::array([]))
  let files = match raw {
    Array(files) => files
    _ => return Err("files must be an array")
  }
  if files.length() > 1000 {
    return Err("A request supports at most 1000 files")
  }
  let result : Array[RequestFile] = []
  for file in files {
    let path = match json_field(file, "path").bind(json_string) {
      Some(path) => path
      None => return Err("Every input requires a string path")
    }
    let text = match json_field(file, "text").bind(json_string) {
      Some(text) => text
      None => return Err("Every input requires UTF-8 decoded text")
    }
    let template = match json_field(file, "template") {
      None => false
      Some(value) =>
        match json_bool(value) {
          Some(value) => value
          None => return Err("template must be a boolean")
        }
    }
    result.push({ path, text, template, })
  }
  Ok(result)
}

///|
fn protocol_plural(request : Json, policy : Policy) -> Json {
  let rule_text = match json_field(request, "rule").bind(json_string) {
    Some(text) => text
    None => return protocol_error("plural command requires a rule string")
  }
  let rule = match
    parse_plural_rule(rule_text, maximum_depth=policy.options.expression_depth) {
    Ok(rule) => rule
    Err(error) => return protocol_error(error)
  }
  let coverage = match
    plural_coverage(
      rule,
      maximum=policy.options.plural_max,
      budget=policy.options.expression_budget,
      maximum_depth=policy.options.expression_depth,
    ) {
    Ok(value) => value
    Err(error) => return protocol_error(error)
  }
  let exit_code = if coverage.failures.is_empty() { 0 } else { 1 }
  let lines : Array[String] = ["nplurals=" + rule.nplurals.to_string()]
  for i, form in coverage.reached {
    lines.push(
      "form " +
      form.to_string() +
      " reached at n=" +
      coverage.examples[i].to_string(),
    )
  }
  for failure in coverage.failures {
    lines.push(failure)
  }
  lines.push(
    "Test interval: n=0.." +
    coverage.maximum.to_string() +
    "; finite sampling only.",
  )
  {
    "exit_code": Json(exit_code),
    "text": Json(join_strings(lines, "\n") + "\n"),
    "data": {
      "schema_version": Json(1),
      "nplurals": Json(rule.nplurals),
      "expression": Json(rule.expression),
      "maximum": Json(coverage.maximum),
      "reached": Json(coverage.reached),
      "examples": Json(coverage.examples),
      "failures": Json(coverage.failures),
      "exit_code": Json(exit_code),
    },
  }
}

///|
fn run_request(request : Json) -> Json {
  if !(request is Object(_)) {
    return protocol_error("Request must be a JSON object")
  }
  let command = json_field(request, "command")
    .bind(json_string)
    .unwrap_or("check")
  let mut policy = default_policy()
  if json_field(request, "config").bind(json_string) is Some(text) {
    policy = match parse_policy(text) {
      Ok(policy) => policy
      Err(error) => return protocol_error(error)
    }
  }
  if json_field(request, "options") is Some(value) {
    match options_from_json(policy.options, value) {
      Ok(options) => policy = { ..policy, options, }
      Err(error) => return protocol_error(error)
    }
  }
  if command == "plural" {
    return protocol_plural(request, policy)
  }
  if command == "rules" {
    return rules_response()
  }
  if !["check", "inspect", "normalize", "stats"].contains(command) {
    return protocol_error("Unknown command: " + command)
  }
  let files = match request_files(request) {
    Ok(files) => files
    Err(error) => return protocol_error(error)
  }
  if files.is_empty() {
    return protocol_error("At least one PO/POT file is required")
  }
  if command == "normalize" && files.length() != 1 {
    return protocol_error("normalize accepts exactly one input")
  }
  let template = match json_field(request, "reference") {
    None => None
    Some(value) => {
      let path = json_field(value, "path")
        .bind(json_string)
        .unwrap_or("<template>")
      let text = match json_field(value, "text").bind(json_string) {
        Some(text) => text
        None => return protocol_error("reference requires text")
      }
      Some(parse_catalog(text, file=path, options=policy.options))
    }
  }
  let reports : Array[Json] = []
  let texts : Array[String] = []
  let mut exit_code = 0
  for file in files {
    let catalog = parse_catalog(
      file.text,
      file=file.path,
      options=policy.options,
    )
    if command == "normalize" {
      match serialize_catalog(catalog) {
        Ok(text) =>
          return {
            "exit_code": Json(0),
            "text": Json(text),
            "data": {
              "schema_version": Json(1),
              "file": Json(file.path),
              "normalized": Json(text),
            },
          }
        Err(error) => return protocol_error(error)
      }
    }
    if command == "inspect" {
      reports.push(catalog_json(catalog))
      if catalog.diagnostics.any(d => d.severity == Error) {
        exit_code = 1
      }
      texts.push(catalog_json(catalog).stringify(indent=2))
      continue
    }
    let raw_report = match template {
      None =>
        check_catalog(catalog, options=policy.options, template=file.template)
      Some(reference) =>
        check_against_template(reference, catalog, options=policy.options)
    }
    let report = apply_policy(raw_report, policy)
    if report.exit_code > exit_code {
      exit_code = report.exit_code
    }
    reports.push(
      if command == "stats" {
        {
          "file": Json(file.path),
          "statistics": statistics_json(report.stats),
          "summary": catalog_summary_json(report.catalog),
          "exit_code": Json(report.exit_code),
        }
      } else {
        report_json(report)
      },
    )
    texts.push(report_text(report))
  }
  {
    "exit_code": Json(exit_code),
    "text": Json(join_strings(texts, "\n")),
    "data": {
      "schema_version": Json(1),
      "command": Json(command),
      "exit_code": Json(exit_code),
      "files": Json(reports),
    },
  }
}

///|
/// Host bridge: JSON in, JSON out. All checking stays inside MoonBit.
pub fn dispatch(request : String) -> String {
  if request.length() > 67108864 {
    return protocol_error("Request exceeds 64 MiB").stringify()
  }
  let value = match bounded_json(request, 32) {
    Ok(value) => value
    Err(error) =>
      return protocol_error("Invalid request JSON: " + error).stringify()
  }
  run_request(value).stringify()
}
