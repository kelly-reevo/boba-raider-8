# boba-raider-8 - Architecture Guide

## Overview

This is a full-stack Gleam monorepo web application with three independent packages that share types across compilation targets:

- **Lustre frontend** (JavaScript target) - Browser UI using the Model-View-Update pattern
- **OTP backend** (Erlang target) - HTTP server using mist + wisp with actor-based concurrency
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
│       │   ├── app.gleam             # Application startup (mist + wisp)
│       │   ├── config.gleam          # Environment config loading
│       │   ├── counter.gleam         # OTP actor for counter state
│       │   └── web/
│       │       ├── context.gleam     # Request context (counter, static dir)
│       │       └── router.gleam      # HTTP routing with wisp
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
- **Purpose:** HTTP server with static file serving and API endpoints
- **Entry:** `src/server.gleam` -> `app.gleam`
- **HTTP Stack:** mist (HTTP server) + wisp (web framework)
- **Dependencies:** `gleam_stdlib`, `gleam_erlang`, `gleam_json`, `gleam_otp`, `gleam_http`, `mist`, `wisp`, `envoy`, `shared` (local)

The server uses **mist** as the HTTP server and **wisp** as the web framework. Wisp provides routing, static file serving, and request/response helpers. Mist handles the low-level HTTP protocol under its own OTP supervision tree.

## Server Startup

```
server.gleam (entry point)
  └── app.main()
      ├── wisp.configure_logger()
      ├── config.load() - Reads PORT from environment (default 3777)
      ├── counter.start() - Starts counter OTP actor
      ├── wisp.priv_directory("server") - Resolves priv/static path
      ├── Context { counter, static_directory }
      ├── wisp_mist.handler(handler, secret_key_base)
      │   └── Adapts wisp handler to mist's expected shape
      ├── mist.new → mist.port → mist.start
      │   └── Starts HTTP server under mist's OTP supervisor
      └── process.sleep_forever()
```

Mist manages its own OTP supervision tree internally. The counter actor runs independently as a standard `gleam_otp` actor.

## HTTP Request/Response Flow

```
Client HTTP Request
  ↓
mist (HTTP server)
  Handles TCP, HTTP/1.1 protocol, keep-alive, connection management
  ↓
wisp_mist.handler
  Converts mist Connection → wisp Request
  ↓
router.handle_request(req, ctx)
  ├── wisp.serve_static (middleware)
  │   Checks /static/* prefix, serves files from priv/static/
  │   Content-type detection is automatic
  ├── cors_middleware
  │   OPTIONS → 204 with CORS headers
  │   Other methods → adds CORS headers to response
  └── Route matching on wisp.path_segments(req):
        GET  /                    → redirect to /static/index.html
        GET  /health              → {"status": "ok"}
        GET  /api/health          → {"status": "ok"}
        GET  /api/counter         → {"count": N}
        POST /api/counter/increment → {"count": N+1}
        POST /api/counter/decrement → {"count": N-1}
        POST /api/counter/reset   → {"count": 0}
        _                         → 404
  ↓
wisp Response
  ↓
wisp_mist (converts back to mist ResponseData)
  ↓
mist (sends HTTP response)
  ↓
Client
```

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
  Increment → POST /api/counter/increment
  Decrement → POST /api/counter/decrement
  Reset     → POST /api/counter/reset
  GotCounter(Ok(count)) → Model(count: count, error: "")
  GotCounter(Error(_))  → Model(..model, error: "...")
       │
       ▼ (Lustre re-renders automatically)
View (re-invoked with new Model)
```

### Effects

`effects.gleam` handles all HTTP communication with the server. User actions dispatch HTTP POST effects (no local state mutation). The model only updates when the server responds via `GotCounter`.

## Static File Serving

Static files are served by wisp's `serve_static` middleware from the `priv/static/` directory. The middleware is configured with:
- **Prefix:** `/static` — requests to `/static/*` are checked against the filesystem
- **Directory:** `priv/static/` — resolved at startup via `wisp.priv_directory("server")`

Content-type detection is automatic based on file extension. The `GET /` route redirects to `/static/index.html`.

## Configuration

Environment variables loaded via the `envoy` package, following 12-factor app principles:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3777 | HTTP server port |

```gleam
envoy.get("PORT")
  |> result.try(int.parse)
  |> result.unwrap(3777)
```

## Dependency Graph

### Server (Production)

```
gleam_stdlib 0.69.0
gleam_erlang 1.3.0     → gleam_stdlib
gleam_json 3.1.0       → gleam_stdlib
gleam_otp 1.2.0        → gleam_erlang, gleam_stdlib
gleam_http 4.3.0       → gleam_stdlib
mist 5.0.4             → gleam_erlang, gleam_http, gleam_otp, gleam_stdlib, glisten, gramps, logging
wisp 2.2.1             → gleam_http, gleam_json, gleam_stdlib, mist, simplifile, logging, marceau
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
3. **Frontend not updating**: Run `make build` or `make release` to rebundle the Lustre app into `priv/static/js/app.js`
4. **Port already in use**: The HTTP server will crash if the port is occupied - check with `lsof -i :3777`
