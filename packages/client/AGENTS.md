# Client Package - Architecture Guide

## Overview

Lustre frontend application targeting JavaScript. Uses the Model-View-Update (MVU) pattern with server-side state — all mutations go through HTTP effects to the backend API.

## Module Structure

```
src/
├── client.gleam              # Entry point (delegates to app.main())
└── frontend/
    ├── app.gleam             # Lustre app init, wires update + view
    ├── model.gleam           # Model type definition
    ├── msg.gleam             # Msg variants + HttpError type
    ├── update.gleam          # State transitions + effect dispatch
    ├── view.gleam            # HTML rendering
    ├── effects.gleam         # HTTP effect functions
    └── origin_ffi.mjs        # JS FFI for window.location.origin
```

## MVU Data Flow

```
init (app.gleam)
  → Model(count: 0, error: ""), effects.fetch_counter()

User clicks button
  → Msg (Increment | Decrement | Reset)
  → update dispatches HTTP POST effect (no local state change)
  → Server responds with {"count": N}
  → GotCounter(Ok(N)) → Model(count: N, error: "")

Network failure
  → GotCounter(Error(NetworkError)) → Model(..model, error: "Failed to reach server")
```

User actions never update the model directly. They fire HTTP effects, and the model only updates when the server responds via `GotCounter`. This guarantees client-server consistency.

## Making HTTP Requests

### Pattern

All HTTP communication lives in `effects.gleam`. Two internal helpers handle the mechanics:

- `api_get(path, to_msg)` — GET request, decode response, dispatch message
- `api_post(path, to_msg)` — POST request with empty JSON body

Public functions expose specific endpoints:

```gleam
pub fn fetch_counter() -> Effect(Msg)      // GET  /api/counter
pub fn post_increment() -> Effect(Msg)     // POST /api/counter/increment
pub fn post_decrement() -> Effect(Msg)     // POST /api/counter/decrement
pub fn post_reset() -> Effect(Msg)         // POST /api/counter/reset
```

### How It Works

1. **Build URL**: `get_origin() <> path` produces a full URL (e.g. `http://localhost:3000/api/counter`). The origin comes from a JS FFI call to `window.location.origin`.

2. **Create request**: `request.to(url)` from `gleam/http/request`. For POST, set method and content-type header.

3. **Send**: `fetch.send(req)` returns a `Promise(Result(Response(FetchBody), FetchError))`.

4. **Read body**: `promise.try_await(fetch.read_text_body)` extracts the response as `Response(String)`.

5. **Decode**: `json.parse(body, count_decoder())` using `gleam/dynamic/decode` to extract the `count` field.

6. **Dispatch**: `promise.tap(dispatch)` sends the resulting `Msg` back into the Lustre runtime.

### URL Construction

`gleam/http/request.to()` requires a full URL — relative paths like `/api/counter` return `Error(Nil)`. The `origin_ffi.mjs` FFI module provides `get_origin()` which returns `globalThis.location.origin` (e.g. `http://localhost:3000`), and effects prepend this to every path.

### Adding a New API Call

1. Add a route on the server (`packages/server/src/web/router.gleam`)
2. Add a `Msg` variant for the response in `msg.gleam`
3. Add a decoder if the response shape differs from `{"count": N}`
4. Add a public function in `effects.gleam` using `api_get` or `api_post`
5. Handle the new `Msg` in `update.gleam`

### Error Handling

```gleam
pub type HttpError {
  NetworkError           // fetch failed (offline, CORS, timeout)
  DecodeError            // JSON parse or decoder failure
  ServerError(Int)       // non-2xx HTTP status code
}
```

All API responses flow through `decode_counter_response` which checks the status code range (200-299) before attempting JSON decode. Errors surface as `GotCounter(Error(..))` in the update function, which sets `model.error` for display.

## Dependencies

| Package | Purpose |
|---------|---------|
| `lustre` | MVU framework, DOM rendering, effect system |
| `gleam_fetch` | Browser Fetch API bindings (sends HTTP requests) |
| `gleam_http` | HTTP types (`Request`, `Response`, `Method`) |
| `gleam_javascript` | Promise type and combinators |
| `gleam_json` | JSON encoding/decoding |
| `gleam_stdlib` | Core types, `Result`, `dynamic/decode` |
| `shared` | Shared domain types (local package) |

## FFI

The only FFI in the client is `origin_ffi.mjs`:

```javascript
export function get_origin() {
  return globalThis.location.origin;
}
```

Declared in Gleam as:

```gleam
@external(javascript, "./origin_ffi.mjs", "get_origin")
fn get_origin() -> String
```

When adding new FFI, place `.mjs` files next to the Gleam module that imports them. The path in `@external` is relative to the importing module's compiled output location.

## Build

The client compiles to JavaScript ES modules. During `make release`, `lustre/dev build` bundles everything into a single `app.js` output at `packages/server/priv/static/js/app.js`. The server then serves this as a static file.
