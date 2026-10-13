///|
/// Parsed gettext plural expression. Arithmetic is checked signed 32-bit.
pub(all) enum PluralExpr {
  Constant(Int)
  Count
  Unary(String, PluralExpr)
  Binary(String, PluralExpr, PluralExpr)
  Conditional(PluralExpr, PluralExpr, PluralExpr)
} derive(Eq, Debug)

///|
pub(all) struct PluralRule {
  nplurals : Int
  expression : String
  tree : PluralExpr
} derive(Eq, Debug)

///|
pub(all) struct PluralCoverage {
  maximum : Int
  reached : Array[Int]
  examples : Array[Int]
  failures : Array[String]
} derive(Eq, Debug)

///|
priv struct PluralToken {
  kind : String
  value : Int
  offset : Int
}

///|
priv struct PluralParser {
  tokens : Array[PluralToken]
  mut index : Int
  mut fault : String?
  maximum_depth : Int
}

///|
priv struct EvalState {
  mut remaining : Int
  maximum_depth : Int
}

///|
fn plural_tokens(text : String) -> Result[Array[PluralToken], String] {
  let chars = text.to_array()
  if chars.length() > 4096 {
    return Err("Plural expression exceeds 4096 characters")
  }
  let tokens : Array[PluralToken] = []
  let mut i = 0
  while i < chars.length() {
    if chars[i].is_whitespace() {
      i += 1
      continue
    }
    if tokens.length() >= 2048 {
      return Err("Plural expression exceeds 2048 tokens")
    }
    let start = i
    if chars[i].is_ascii_digit() {
      while i < chars.length() && chars[i].is_ascii_digit() {
        i += 1
      }
      let literal = char_slice(chars, start, i)
      match decimal_text(literal, 2147483647) {
        Some(value) => tokens.push({ kind: "number", value, offset: start })
        None => return Err("Plural integer is outside the signed 32-bit range")
      }
      continue
    }
    if chars[i] == 'n' {
      tokens.push({ kind: "n", value: 0, offset: i })
      i += 1
      continue
    }
    if i + 1 < chars.length() {
      let pair = char_slice(chars, i, i + 2)
      if ["||", "&&", "==", "!=", "<=", ">="].contains(pair) {
        tokens.push({ kind: pair, value: 0, offset: i })
        i += 2
        continue
      }
    }
    let op = chars[i].to_string()
    if !["+", "-", "*", "/", "%", "!", "<", ">", "(", ")", "?", ":"].contains(op) {
      return Err("Unsupported plural token at character " + (i + 1).to_string() + ": " + op)
    }
    tokens.push({ kind: op, value: 0, offset: i })
    i += 1
  }
  tokens.push({ kind: "end", value: 0, offset: chars.length() })
  Ok(tokens)
}

///|
fn PluralParser::current(self : PluralParser) -> PluralToken {
  self.tokens[self.index]
}

///|
fn PluralParser::fail(self : PluralParser, message : String) -> Unit {
  if self.fault is None {
    self.fault = Some(message + " at character " + (self.current().offset + 1).to_string())
  }
}

///|
fn plural_precedence(op : String) -> Int {
  match op {
    "||" => 1
    "&&" => 2
    "==" | "!=" => 3
    "<" | "<=" | ">" | ">=" => 4
    "+" | "-" => 5
    "*" | "/" | "%" => 6
    _ => 0
  }
}

///|
fn plural_primary(parser : PluralParser, depth : Int) -> PluralExpr {
  if depth > parser.maximum_depth {
    parser.fail("Plural expression exceeds the configured nesting limit")
    return Constant(0)
  }
  let token = parser.current()
  match token.kind {
    "number" => {
      parser.index += 1
      Constant(token.value)
    }
    "n" => {
      parser.index += 1
      Count
    }
    "!" | "-" | "+" => {
      parser.index += 1
      Unary(token.kind, plural_primary(parser, depth + 1))
    }
    "(" => {
      parser.index += 1
      let expression = plural_conditional(parser, depth + 1)
      if parser.current().kind == ")" {
        parser.index += 1
      } else {
        parser.fail("Expected a closing parenthesis")
      }
      expression
    }
    _ => {
      parser.fail("Expected n, an integer, or a parenthesized expression")
      Constant(0)
    }
  }
}

///|
fn plural_binary(parser : PluralParser, minimum : Int, depth : Int) -> PluralExpr {
  let mut left = plural_primary(parser, depth)
  while parser.fault is None {
    let op = parser.current().kind
    let precedence = plural_precedence(op)
    if precedence < minimum || precedence == 0 {
      break
    }
    parser.index += 1
    let right = plural_binary(parser, precedence + 1, depth + 1)
    left = Binary(op, left, right)
  }
  left
}

///|
fn plural_conditional(parser : PluralParser, depth : Int) -> PluralExpr {
  let condition = plural_binary(parser, 1, depth)
  if parser.fault is Some(_) || parser.current().kind != "?" {
    return condition
  }
  if depth >= parser.maximum_depth {
    parser.fail("Plural conditional exceeds the configured nesting limit")
    return condition
  }
  parser.index += 1
  let yes = plural_conditional(parser, depth + 1)
  if parser.current().kind != ":" {
    parser.fail("Expected a colon in a conditional expression")
    return condition
  }
  parser.index += 1
  let no = plural_conditional(parser, depth + 1)
  Conditional(condition, yes, no)
}

///|
/// Parse only the expression, without running it.
pub fn parse_plural_expression(
  text : String,
  maximum_depth? : Int = 64,
) -> Result[PluralExpr, String] {
  if maximum_depth < 1 || maximum_depth > 128 {
    return Err("Nesting limit must be in 1..128")
  }
  let tokens = match plural_tokens(text) {
    Ok(tokens) => tokens
    Err(error) => return Err(error)
  }
  let parser : PluralParser = { tokens, index: 0, fault: None, maximum_depth }
  let tree = plural_conditional(parser, 0)
  match parser.fault {
    Some(error) => Err(error)
    None => {
      if parser.current().kind != "end" {
        Err("Unexpected plural token at character " + (parser.current().offset + 1).to_string())
      } else {
        Ok(tree)
      }
    }
  }
}

///|
/// Parse `nplurals=...; plural=...;`. Unknown or duplicate assignments fail.
pub fn parse_plural_rule(
  text : String,
  maximum_depth? : Int = 64,
) -> Result[PluralRule, String] {
  let mut count : Int? = None
  let mut expression : String? = None
  for fragment in text.split(";") {
    let assignment = trim_text(fragment.to_owned())
    if assignment == "" {
      continue
    }
    let chars = assignment.to_array()
    let mut equals = -1
    for i, c in chars {
      if c == '=' {
        equals = i
        break
      }
    }
    if equals < 0 {
      return Err("Plural-Forms requires name=value assignments")
    }
    let name = trim_text(char_slice(chars, 0, equals))
    let value = trim_text(char_slice(chars, equals + 1, chars.length()))
    match name {
      "nplurals" => {
        if count is Some(_) {
          return Err("Duplicate nplurals assignment")
        }
        count = decimal_text(value, 64)
        if count is None || count == Some(0) {
          return Err("nplurals must be in 1..64")
        }
      }
      "plural" => {
        if expression is Some(_) {
          return Err("Duplicate plural assignment")
        }
        expression = Some(value)
      }
      _ => return Err("Unsupported Plural-Forms assignment: " + name)
    }
  }
  let nplurals = match count {
    Some(value) => value
    None => return Err("Missing nplurals assignment")
  }
  let expression = match expression {
    Some(value) => value
    None => return Err("Missing plural assignment")
  }
  match parse_plural_expression(expression, maximum_depth~) {
    Ok(tree) => Ok({ nplurals, expression, tree })
    Err(error) => Err(error)
  }
}

///|
fn checked_plural_integer(value : Int64) -> Result[Int, String] {
  if value < -2147483648L || value > 2147483647L {
    Err("Signed 32-bit overflow in plural arithmetic")
  } else {
    Ok(value.to_int())
  }
}

///|
fn plural_truth(value : Bool) -> Int {
  if value { 1 } else { 0 }
}

///|
fn eval_plural_node(
  tree : PluralExpr,
  n : Int,
  state : EvalState,
  depth : Int,
) -> Result[Int, String] {
  if state.remaining <= 0 {
    return Err("Plural evaluation exhausted the operation budget")
  }
  if depth > state.maximum_depth {
    return Err("Plural evaluation exceeded the nesting limit")
  }
  state.remaining -= 1
  match tree {
    Constant(value) => Ok(value)
    Count => Ok(n)
    Unary(op, child) => {
      let value = match eval_plural_node(child, n, state, depth + 1) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match op {
        "!" => Ok(plural_truth(value == 0))
        "+" => Ok(value)
        "-" => checked_plural_integer(-value.to_int64())
        _ => Err("Unsupported unary operator")
      }
    }
    Binary(op, left, right) => {
      let a = match eval_plural_node(left, n, state, depth + 1) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if op == "&&" && a == 0 {
        return Ok(0)
      }
      if op == "||" && a != 0 {
        return Ok(1)
      }
      let b = match eval_plural_node(right, n, state, depth + 1) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match op {
        "&&" => Ok(plural_truth(b != 0))
        "||" => Ok(plural_truth(b != 0))
        "==" => Ok(plural_truth(a == b))
        "!=" => Ok(plural_truth(a != b))
        "<" => Ok(plural_truth(a < b))
        "<=" => Ok(plural_truth(a <= b))
        ">" => Ok(plural_truth(a > b))
        ">=" => Ok(plural_truth(a >= b))
        "+" => checked_plural_integer(a.to_int64() + b.to_int64())
        "-" => checked_plural_integer(a.to_int64() - b.to_int64())
        "*" => checked_plural_integer(a.to_int64() * b.to_int64())
        "/" => {
          if b == 0 {
            Err("Division by zero in plural expression")
          } else {
            checked_plural_integer(a.to_int64() / b.to_int64())
          }
        }
        "%" => {
          if b == 0 {
            Err("Remainder by zero in plural expression")
          } else {
            checked_plural_integer(a.to_int64() % b.to_int64())
          }
        }
        _ => Err("Unsupported binary operator")
      }
    }
    Conditional(condition, yes, no) => {
      let value = match eval_plural_node(condition, n, state, depth + 1) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      eval_plural_node(if value != 0 { yes } else { no }, n, state, depth + 1)
    }
  }
}

///|
/// Evaluate without using a host language's eval or executing arbitrary code.
pub fn evaluate_plural(
  expression : PluralExpr,
  n : Int,
  budget? : Int = 10000,
  maximum_depth? : Int = 64,
) -> Result[Int, String] {
  if n < 0 {
    return Err("Plural count n must be nonnegative")
  }
  if budget < 1 || budget > 1000000 {
    return Err("Operation budget must be in 1..1000000")
  }
  if maximum_depth < 1 || maximum_depth > 128 {
    return Err("Nesting limit must be in 1..128")
  }
  eval_plural_node(expression, n, { remaining: budget, maximum_depth }, 0)
}

///|
/// Exhaustive only over the stated finite interval; this is not a proof for all n.
pub fn plural_coverage(
  rule : PluralRule,
  maximum? : Int = 1000,
  budget? : Int = 10000,
  maximum_depth? : Int = 64,
) -> Result[PluralCoverage, String] {
  if maximum < 0 || maximum > 100000 {
    return Err("Plural sampling maximum must be in 0..100000")
  }
  if rule.nplurals < 1 || rule.nplurals > 64 {
    return Err("Plural count must be in 1..64")
  }
  let reached : Array[Int] = []
  let examples : Array[Int] = []
  let failures : Array[String] = []
  for n = 0; n <= maximum; n = n + 1 {
    match evaluate_plural(rule.tree, n, budget~, maximum_depth~) {
      Err(error) => {
        failures.push("n=" + n.to_string() + ": " + error)
        break
      }
      Ok(index) => {
        if index < 0 || index >= rule.nplurals {
          failures.push("n=" + n.to_string() + " produced index " + index.to_string() + " outside 0.." + (rule.nplurals - 1).to_string())
          break
        }
        if !reached.contains(index) {
          reached.push(index)
          examples.push(n)
        }
      }
    }
  }
  Ok({ maximum, reached, examples, failures })
}
