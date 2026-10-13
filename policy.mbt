///|
pub(all) struct Policy {
  options : Options
  overrides : Map[String, Severity]
  disabled : Array[String]
} derive(Debug)

///|
pub fn default_policy() -> Policy {
  { options: default_options(), overrides: Map([]), disabled: [], }
}

///|
fn json_field(value : Json, name : String) -> Json? {
  match value {
    Object(fields) => fields.get(name)
    _ => None
  }
}

///|
fn json_string(value : Json) -> String? {
  match value {
    String(text) => Some(text)
    _ => None
  }
}

///|
fn json_integer(value : Json) -> Int32? {
  match value {
    Number(number, ..) => {
      if number < -2147483648.0 || number > 2147483647.0 {
        return None
      }
      let integer = number.to_int()
      if integer.to_double() == number {
        Some(integer)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn json_bool(value : Json) -> Bool? {
  match value {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
pub fn parse_severity(value : String) -> Severity? {
  match value {
    "error" => Some(Error)
    "warning" => Some(Warning)
    "info" => Some(Info)
    _ => None
  }
}

///|
pub fn options_from_json(
  base : Options,
  value : Json,
) -> Result[Options, String] {
  let fields = match value {
    Object(fields) => fields
    _ => return Err("options must be a JSON object")
  }
  let mut options = base
  for name, value in fields {
    match name {
      "strict" =>
        match json_bool(value) {
          Some(strict) => options = { ..options, strict, }
          None => return Err("strict must be a boolean")
        }
      "empty_severity" | "fuzzy_severity" => {
        let severity = match json_string(value).bind(parse_severity) {
          Some(severity) => severity
          None => return Err(name + " must be error, warning, or info")
        }
        options = if name == "empty_severity" {
          { ..options, empty_severity: severity, }
        } else {
          { ..options, fuzzy_severity: severity, }
        }
      }
      "plural_max"
      | "expression_depth"
      | "expression_budget"
      | "max_entries"
      | "max_line_chars" => {
        let integer = match json_integer(value) {
          Some(integer) => integer
          None => return Err(name + " must be a signed 32-bit integer")
        }
        options = match name {
          "plural_max" => { ..options, plural_max: integer, }
          "expression_depth" => { ..options, expression_depth: integer, }
          "expression_budget" => { ..options, expression_budget: integer, }
          "max_entries" => { ..options, max_entries: integer, }
          _ => { ..options, max_line_chars: integer, }
        }
      }
      _ => return Err("Unknown option: " + name)
    }
  }
  let errors = validate_options(options)
  if errors.is_empty() {
    Ok(options)
  } else {
    Err(join_strings(errors, "; "))
  }
}

///|
fn configurable_rule(code : String) -> Bool {
  [
    "H001", "H006", "H007", "H008", "H009", "C006", "C007", "C011", "C013", "L005",
    "T002", "F007",
  ].contains(code)
}

///|
/// Only review-policy findings can be disabled or reclassified.
pub fn parse_policy(text : String) -> Result[Policy, String] {
  let json = match bounded_json(text, 16) {
    Ok(value) => value
    Err(error) => return Err("Invalid configuration JSON: " + error)
  }
  let fields = match json {
    Object(fields) => fields
    _ => return Err("Configuration must be an object")
  }
  let mut policy = default_policy()
  for name, value in fields {
    match name {
      "schema_version" =>
        if json_integer(value) != Some(1) {
          return Err("Configuration schema_version must be 1")
        }
      "options" =>
        match options_from_json(policy.options, value) {
          Ok(options) => policy = { ..policy, options, }
          Err(error) => return Err(error)
        }
      "rules" => {
        let rules = match value {
          Object(rules) => rules
          _ =>
            return Err("rules must be an object of diagnostic code to severity")
        }
        for code, setting in rules {
          if !configurable_rule(code) {
            return Err("Rule is unknown or cannot be reclassified: " + code)
          }
          let setting = match json_string(setting) {
            Some(setting) => setting
            None => return Err("Rule setting must be a string: " + code)
          }
          if setting == "off" {
            policy.disabled.push(code)
          } else {
            match parse_severity(setting) {
              Some(severity) => policy.overrides.set(code, severity)
              None =>
                return Err(
                  "Rule setting must be error, warning, info, or off: " + code,
                )
            }
          }
        }
      }
      _ => return Err("Unknown configuration field: " + name)
    }
  }
  Ok(policy)
}

///|
pub fn apply_policy(report : Report, policy : Policy) -> Report {
  let diagnostics : Array[Diagnostic] = []
  for diagnostic in report.diagnostics {
    if policy.disabled.contains(diagnostic.code) &&
      configurable_rule(diagnostic.code) {
      continue
    }
    if configurable_rule(diagnostic.code) &&
      policy.overrides.get(diagnostic.code) is Some(severity) {
      diagnostics.push({ ..diagnostic, severity, })
    } else {
      diagnostics.push(diagnostic)
    }
  }
  report_with(
    report.catalog,
    diagnostics,
    policy.options,
    report.plural_checked_through,
  )
}
