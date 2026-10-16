// Unicode 15.0.0 decimal digit starts, derived from CPython unicodedata.

///|
let format_decimal_starts : Array[Int32] = [
  48, 1632, 1776, 1984, 2406, 2534, 2662, 2790, 2918, 3046, 3174, 3302, 3430, 3558,
  3664, 3792, 3872, 4160, 4240, 6112, 6160, 6470, 6608, 6784, 6800, 6992, 7088, 7232,
  7248, 42528, 43216, 43264, 43472, 43504, 43600, 44016, 65296, 66720, 68912, 69734,
  69872, 69942, 70096, 70384, 70736, 70864, 71248, 71360, 71472, 71904, 72016, 72784,
  73040, 73120, 73552, 92768, 92864, 93008, 120782, 120792, 120802, 120812, 120822,
  123200, 123632, 124144, 125264, 130032,
]

///|
fn format_decimal_digit(char : Char) -> Int32? {
  let point = char.to_int()
  if point >= 48 && point <= 57 {
    return Some(point - 48)
  }
  if point < 1632 {
    return None
  }
  for start in format_decimal_starts {
    if point >= start && point < start + 10 {
      return Some(point - start)
    }
  }
  None
}

///|
fn format_decimal_text(raw : String, maximum : Int32) -> Int32? {
  let mut value = 0
  if raw == "" {
    return None
  }
  for char in raw.to_array() {
    let digit = match format_decimal_digit(char) {
      Some(digit) => digit
      None => return None
    }
    if value > (maximum - digit) / 10 {
      return None
    }
    value = value * 10 + digit
  }
  Some(value)
}
