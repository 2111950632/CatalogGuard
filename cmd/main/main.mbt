///|
extern "js" fn host_request() -> String =
  #| () => globalThis.__szsRequest

///|
extern "js" fn host_response(value : String) -> Unit =
  #| (value) => { globalThis.__szsResponse = value; }

///|
fn main {
  host_response(@szs.dispatch(host_request()))
}
