# boba-raider-8 - Architecture Guide

## Overview

This is a full-stack Gleam monorepo web application with three independent packages that share types across compilation targets:

- **Lustre frontend** (JavaScript target) - Browser UI using the Model-View-Update pattern
- **OTP backend** (Erlang target) - HTTP server with actor-based concurrency and supervision
- **Shared types** (no target) - Domain types compiled to both JavaScript and Erlang

## Project Structure

```
boba-raider-8/
├── packages/
│   ├── shared/                       # Pure types (no platform target)
│   │   ├── gleam.toml
│   │   └── src/shared.gleam          # Domain error types (AppError)
│   │
│   ├── client/                       # Lustre frontend (JavaScript)
│   │   ├── gleam.toml
│   │   └── src/
│   │       ├── client.gleam          # Entry point
│   │       └── frontend/
│   │           ├── app.gleam         # Lustre app initialization
│   │           ├── model.gleam       # State type
│   │           ├── msg.gleam         # Message type
│   │           ├── update.gleam      # State transitions
│   │           ├── view.gleam        # HTML rendering
│   │           └── effects.gleam     # Side effects (API calls)
│   │
│   └── server/                       # OTP backend (Erlang)
│       ├── gleam.toml
│       ├── src/
│       │   ├── server.gleam          # Entry point
│       │   ├── app.gleam             # Main application module
│       │   ├── config.gleam          # Environment config loading
│       │   ├── app_supervisor.gleam  # OTP supervisor tree
│       │   ├── http_server.erl       # Low-level TCP server (Erlang)
│       │   ├── server_ffi.erl        # FFI bridge layer (Erlang)
│       │   └── web/
│       │       ├── http_server_actor.gleam  # Actor wrapper for HTTP server
│       │       ├── router.gleam      # HTTP routing
│       │       ├── server.gleam      # Request/Response types & builders
│       │       └── static.gleam      # Static file serving
│       └── priv/static/
│           ├── index.html            # Frontend HTML shell
│           ├── css/styles.css        # Styles
│           └── js/app.js             # Compiled Lustre app (generated)
│
├── Makefile                          # Build orchestration
└── AGENTS.md                         # This file
```

## Why a Monorepo with Separate Packages?

Gleam compiles ALL modules in a package's `src/` directory to a single target (JavaScript or Erlang). This application requires code running on two different runtimes:

- **Backend** needs Erlang OTP for actors, processes, TCP sockets, and supervision trees
- **Frontend** needs JavaScript for browser DOM manipulation via Lustre

A single package cannot target both. The solution: three independent packages with different `target` declarations in their `gleam.toml` files. The `shared` package declares no target, making it compilable to both. Each package declares dependencies on others via local path references, enabling type sharing while keeping platform-specific code isolated.

## Package Details

### packages/shared

- **Target:** None (compiles to all targets)
- **Purpose:** Domain types and pure functions shared between client and server
- **Dependencies:** `gleam_stdlib`, `gleam_json`
- **Key type:** `AppError` - domain-level error variants

This package stays minimal and pure. It contains only types and functions that work on any platform with no runtime-specific imports.

### packages/client

- **Target:** JavaScript
- **Purpose:** Lustre frontend application running in the browser
- **Entry:** `src/client.gleam` -> `frontend/app.gleam`
- **Pattern:** MVU (Model-View-Update)
- **Dependencies:** `gleam_stdlib`, `gleam_json`, `lustre`, `shared` (local)
- **Dev dependencies:** `lustre_dev_tools` (hot reload dev server)

The client compiles Gleam to ES modules. During build, `lustre/dev build` bundles the application into a single `app.js` file that gets output to `packages/server/priv/static/js/app.js` for the server to serve.

### packages/server

- **Target:** Erlang
- **Purpose:** HTTP server with OTP supervision, static file serving, and API endpoints
- **Entry:** `src/server.gleam` -> `app.gleam`
- **Dependencies:** `gleam_stdlib`, `gleam_erlang`, `gleam_json`, `gleam_otp`, `gleam_http`, `simplifile`, `envoy`, `shared` (local)

The server uses two Erlang FFI modules (`server_ffi.erl` and `http_server.erl`) to implement a raw TCP-based HTTP server, wrapped in Gleam's OTP actor system for lifecycle management.

## Server Startup & OTP Supervision

```
server.gleam (entry point)
  └── app.main()
      ├── config.load() - Reads PORT from environment (default 3000)
      └── app_supervisor.start(config)
          └── HttpServerActor (gleam_otp actor)
              └── server_ffi:start/2 (Erlang FFI)
                  └── http_server:start/2 (raw TCP)
                      ├── gen_tcp:listen(Port)
                      ├── accept_loop (spawned process)
                      │   ├── gen_tcp:accept(Socket)
                      │   ├── spawn(handle_client) per connection
                      │   └── loops back to accept
                      └── handle_client
                          ├── Parse HTTP request
                          ├── Call Gleam handler function
                          └── Send HTTP response
```

The `HttpServerActor` wraps the raw Erlang TCP server in an OTP actor that responds to `Shutdown` messages, enabling proper lifecycle management. The supervisor monitors this actor and can restart it on crashes.

After starting the supervision tree, `app.main()` calls `process.sleep_forever()` to keep the Erlang VM alive.

## HTTP Request/Response Flow

```
TCP Socket (gen_tcp)
  ↓
http_server.erl
  Parses raw HTTP: method, path, headers, body
  ↓
server_ffi.erl
  Converts Erlang maps → Gleam types (Request record)
  Converts Erlang header maps → Gleam Dict
  ↓
router.gleam
  Pattern matches on {method, path segments}:
    GET /           → static.serve_index()
    GET /health     → json health response
    GET /api/health → json health response
    GET /static/*   → static.serve(path)
    _               → 404 not found
  ↓
Response builders (web/server.gleam)
  json_response(status, json_string)
  html_response(status, html_string)
  text_response(status, text_string)
  ↓
server_ffi.erl
  Converts Gleam Response → Erlang map
  ↓
http_server.erl
  Formats HTTP/1.1 response with status line, headers, Content-Length, body
  ↓
TCP Socket → Client
```

## FFI Architecture (Two-Layer Bridge)

Gleam uses `@external` annotations to call into platform-native code. This project has two Erlang FFI modules:

### Layer 1: server_ffi.erl (Gleam-Erlang Bridge)

Translates between Gleam's type system and Erlang's runtime representations:
- Converts Gleam `Dict` to/from Erlang maps for HTTP headers
- Handles binary/string conversions (Gleam strings are Erlang binaries)
- Provides the `start/2` and `stop/1` functions called from `http_server_actor.gleam`

Gleam-side declaration:
```gleam
@external(erlang, "server_ffi", "start")
fn start_http_server(port: Int, handler: fn(Request) -> Response)
    -> Result(ServerHandle, String)
```

### Layer 2: http_server.erl (Low-Level TCP Server)

Raw `gen_tcp` socket handling:
- Creates TCP listener with `{packet, http_bin}` for Erlang's built-in HTTP parsing
- Spawns a process per connection for concurrent request handling
- Parses HTTP request lines, headers, and body
- Serializes HTTP responses back to wire format

## Lustre Frontend (MVU Pattern)

The frontend follows Lustre's Model-View-Update architecture, where the application is a loop of: render view -> user interaction -> message -> update state -> re-render.

### Initialization

```gleam
// frontend/app.gleam
lustre.application(init, update.update, view.view)
  |> lustre.start("#app", Nil)
```

Mounts to the `<div id="app">` element in `index.html`.

### Data Flow

```
Model (frontend/model.gleam)
  type Model { count: Int, error: String }
  default() → Model(count: 0, error: "")
       │
       ▼
View (frontend/view.gleam)
  Renders Model → Element(Msg)
  Attaches event handlers: on_click(Increment), on_click(Decrement), on_click(Reset)
       │
       ▼ (user clicks button)
Msg (frontend/msg.gleam)
  Increment | Decrement | Reset
       │
       ▼
Update (frontend/update.gleam)
  (Model, Msg) → #(Model, Effect(Msg))
  Increment → count + 1, effect.none()
  Decrement → count - 1, effect.none()
  Reset     → count = 0, effect.none()
       │
       ▼ (Lustre re-renders automatically)
View (re-invoked with new Model)
```

### Effects

`effects.gleam` contains a placeholder `fetch_data()` function for future HTTP API calls. Lustre effects are first-class: update functions return `#(Model, Effect(Msg))` tuples, where effects describe async operations (HTTP requests, timers, etc.) that eventually produce new messages.

## Static File Serving

`static.gleam` serves files from the `priv/` directory using `simplifile` for file I/O. Content-Type detection is based on file extension:

| Extension | Content-Type |
|-----------|-------------|
| `.html` | `text/html; charset=utf-8` |
| `.css` | `text/css` |
| `.js`, `.mjs` | `application/javascript` |
| `.json` | `application/json` |
| `.png` | `image/png` |
| `.svg` | `image/svg+xml` |
| Default | `application/octet-stream` |

## Configuration

Environment variables loaded via the `envoy` package, following 12-factor app principles:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3000 | HTTP server port |

```gleam
envoy.get("PORT")
  |> result.try(int.parse)
  |> result.unwrap(3000)
```

## Dependency Graph

### Server (Production)

```
gleam_stdlib 0.69.0
gleam_erlang 1.3.0     → gleam_stdlib
gleam_json 3.1.0       → gleam_stdlib
gleam_otp 1.2.0        → gleam_erlang, gleam_stdlib
gleam_http 4.3.0       → gleam_stdlib
simplifile 2.3.2       → filepath 1.1.2, gleam_stdlib
envoy 1.1.0            → gleam_stdlib
shared (local)         → gleam_stdlib, gleam_json
```

### Client (Production)

```
gleam_stdlib 0.69.0
gleam_json 3.1.0       → gleam_stdlib
lustre 5.5.2           → gleam_stdlib, gleam_json, houdini 1.2.0
shared (local)         → gleam_stdlib, gleam_json
```

### Client (Dev Only)

```
lustre_dev_tools 2.3.4 → mist, glisten, gramps, glint, simplifile, wisp, tom, + others
gleeunit 1.9.0         (testing framework, used by all packages)
```

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Build all packages (shared -> client -> server) |
| `make test` | Run tests for all packages |
| `make run` | Full build + start server |
| `make run-quick` | Skip frontend rebuild, start server only |
| `make dev` | Start Lustre dev server (hot reload) |
| `make release` | Production build (clean + frontend + server) |
| `make clean` | Remove build artifacts |
| `make format` | Format all Gleam code |

### Build Pipeline

1. **Build shared** - `cd packages/shared && gleam build`
2. **Build client** - `cd packages/client && gleam build`
3. **Bundle frontend** - `cd packages/client && gleam run -m lustre/dev build frontend/app --outdir=../server/priv/static/js` (outputs `app.js`)
4. **Build server** - `cd packages/server && gleam build`
5. **Run** - `cd packages/server && gleam run` (starts Erlang VM)

## Common Issues

1. **Import errors**: Check package dependencies in `gleam.toml` - each package must explicitly declare its deps
2. **Target mismatch**: Erlang-only modules (e.g., `gleam/otp/actor`) cannot be imported in the client package. JavaScript-only modules (e.g., Lustre DOM) cannot be imported in the server package
3. **String types**: Gleam strings are Erlang binaries at runtime - FFI code must handle `<<>>` binary syntax, not Erlang strings (charlists)
4. **Frontend not updating**: Run `make build` or `make release` to rebundle the Lustre app into `priv/static/js/app.js`
5. **Port already in use**: The HTTP server will crash if the port is occupied - check with `lsof -i :3000`
