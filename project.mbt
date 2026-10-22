///|
pub(all) struct ProjectPolicy {
  policy : Policy
  markup : MarkupOptions
  consistency : ConsistencyOptions
} derive(Debug)

///|
pub(all) struct ProjectReport {
  reports : Array[Report]
  findings : Array[ProjectFinding]
  exit_code : Int32
} derive(Debug)

///|
pub fn default_project_policy() -> ProjectPolicy {
  {
    policy: default_policy(),
    markup: default_markup_options(),
    consistency: default_consistency_options(),
  }
}

///|
fn quality_from_json(
  base : ProjectPolicy,
  value : Json,
) -> Result[ProjectPolicy, String] {
  let fields = match value {
    Object(fields) => fields
    _ => return Err("quality must be an object")
  }
  let mut result = base
  for section, value in fields {
    let fields = match value {
      Object(fields) => fields
      _ => return Err(section + " must be an object")
    }
    if section == "markup" {
      let mut options = result.markup
      for key, value in fields {
        match key {
          "mode" =>
            match json_string(value) {
              Some(mode) => options = { ..options, mode, }
              None => return Err("markup mode must be a string")
            }
          "max_chars" | "max_nodes" | "max_depth" => {
            let number = match json_integer(value) {
              Some(number) => number
              None => return Err("markup " + key + " must be an integer")
            }
            options = match key {
              "max_chars" => { ..options, max_chars: number, }
              "max_nodes" => { ..options, max_nodes: number, }
              _ => { ..options, max_depth: number, }
            }
          }
          "translatable_attributes" => {
            let items = match value {
              Array(items) => items
              _ => return Err("translatable_attributes must be a string array")
            }
            let names : Array[String] = []
            for item in items {
              match json_string(item) {
                Some(name) => names.push(name)
                None =>
                  return Err("translatable_attributes must contain strings")
              }
            }
            options = { ..options, translatable_attributes: names, }
          }
          _ => return Err("Unknown markup option: " + key)
        }
      }
      let errors = validate_markup_options(options)
      if !errors.is_empty() {
        return Err(join_strings(errors, "; "))
      }
      result = { ..result, markup: options, }
    } else if section == "consistency" {
      let mut options = result.consistency
      for key, value in fields {
        match key {
          "enabled" | "ignore_context" | "inverse" => {
            let flag = match json_bool(value) {
              Some(flag) => flag
              None => return Err("consistency " + key + " must be a boolean")
            }
            options = match key {
              "enabled" => { ..options, enabled: flag, }
              "ignore_context" => { ..options, ignore_context: flag, }
              _ => { ..options, inverse: flag, }
            }
          }
          "max_entries" =>
            match json_integer(value) {
              Some(number) => options = { ..options, max_entries: number, }
              None => return Err("consistency max_entries must be an integer")
            }
          _ => return Err("Unknown consistency option: " + key)
        }
      }
      if options.max_entries < 1 || options.max_entries > 1000000 {
        return Err("consistency max_entries must be in 1..1000000")
      }
      result = { ..result, consistency: options, }
    } else {
      return Err("Unknown quality section: " + section)
    }
  }
  Ok(result)
}

///|
/// Extends the version-1 policy without changing parse_policy or Options.
pub fn parse_project_policy(text : String) -> Result[ProjectPolicy, String] {
  let value = match bounded_json(text, 16) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let fields = match value {
    Object(fields) => fields
    _ => return Err("Configuration must be an object")
  }
  let base : Map[String, Json] = Map([])
  let mut result = default_project_policy()
  for key, value in fields {
    if key == "quality" {
      match quality_from_json(result, value) {
        Ok(next) => result = next
        Err(error) => return Err(error)
      }
    } else {
      base.set(key, value)
    }
  }
  match parse_policy(Json::object(base).stringify()) {
    Ok(policy) => Ok({ ..result, policy, })
    Err(error) => Err(error)
  }
}

///|
fn project_reports(
  raw : Array[Report],
  project : ProjectPolicy,
  templates : Array[Int32],
) -> ProjectReport {
  let catalogs = raw.mapi((i, report) => {
    if templates.contains(i) {
      { file: report.catalog.file, entries: [], diagnostics: [], }
    } else {
      report.catalog
    }
  })
  let found = check_consistency(catalogs, options=project.consistency)
  let by_file : Array[Array[Diagnostic]] = Array::makei(raw.length(), _ => [])
  for finding in found {
    by_file[finding.file_index].push(finding.diagnostic)
  }
  let reports : Array[Report] = []
  let mut exit_code = 0
  for index, report in raw {
    let diagnostics = report.diagnostics.copy()
    for
      diagnostic in check_markup_catalog(report.catalog, options=project.markup) {
      diagnostics.push(diagnostic)
    }
    for diagnostic in by_file[index] {
      diagnostics.push(diagnostic)
    }
    let checked = apply_policy(
      report_with(
        report.catalog,
        diagnostics,
        project.policy.options,
        report.plural_checked_through,
      ),
      project.policy,
    )
    reports.push(checked)
    if checked.exit_code > exit_code {
      exit_code = checked.exit_code
    }
  }
  let findings : Array[ProjectFinding] = []
  for finding in found {
    let code = finding.diagnostic.code
    if configurable_rule(code) && project.policy.disabled.contains(code) {
      continue
    }
    let diagnostic = if configurable_rule(code) &&
      project.policy.overrides.get(code) is Some(severity) {
      { ..finding.diagnostic, severity, }
    } else {
      finding.diagnostic
    }
    findings.push({ ..finding, diagnostic, })
  }
  { reports, findings, exit_code, }
}

///|
/// Validate target catalogs and apply opt-in markup/project checks and policy.
pub fn check_project(
  catalogs : Array[Catalog],
  configuration~ : ProjectPolicy = default_project_policy(),
) -> ProjectReport {
  project_reports(
    catalogs.map(catalog => {
      check_catalog(catalog, options=configuration.policy.options)
    }),
    configuration,
    [],
  )
}
