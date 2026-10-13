///|
/// Public JSON uses null or a scalar, rather than MoonBit's Option encoding.
fn[T : ToJson] optional_json(value : T?) -> Json {
  match value {
    None => Json::null()
    Some(value) => Json(value)
  }
}
