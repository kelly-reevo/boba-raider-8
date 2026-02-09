# boba-raider-8 - Architecture Guide

## Overview

This is a Gleam monorepo web application with:
- **Lustre frontend** (JavaScript target) for the UI
- **OTP backend** (Erlang target) for the server
- **Shared types** compiled to both targets

## Project Structure

```
boba-raider-8/
├── packages/
│   ├── shared/     # Pure types (no platform target)
│   ├── client/     # Lustre frontend (JavaScript)
│   └── server/     # OTP backend (Erlang)
├── Makefile        # Build orchestration
└── AGENTS.md       # This file
```

## Why Monorepo?

Gleam compiles ALL modules in `src/` for the target platform. Since:
- Backend needs Erlang OTP (actors, processes)
- Frontend needs JavaScript (browser APIs)

We use separate packages with different targets to share types while targeting different platforms.

## Package Details

### packages/shared
- **Target:** None (compiles to all)
- **Purpose:** Domain types and pure functions

### packages/client
- **Target:** JavaScript
- **Purpose:** Lustre frontend application
- **Entry:** `src/client.gleam` -> `frontend/app.gleam`
- **Pattern:** MVU (Model-View-Update)

### packages/server
- **Target:** Erlang
- **Purpose:** HTTP server with OTP supervision
- **Entry:** `src/server.gleam` -> `app.gleam`

## OTP Supervision Tree

```
app.main()
└── app_supervisor.start(config)
    └── HttpServerActor
        └── HTTP server (server_ffi.erl)
```

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Build all packages |
| `make test` | Run all tests |
| `make run` | Build and start server |
| `make dev` | Start Lustre dev server |
| `make release` | Full production build |
| `make clean` | Remove build artifacts |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3000 | HTTP server port |

## Key Patterns

### Lustre MVU
- `model.gleam` - State type
- `msg.gleam` - Message type
- `update.gleam` - State updates
- `view.gleam` - HTML rendering
- `effects.gleam` - Side effects (API calls)

### FFI
- JavaScript: `@external(javascript, "path", "function")`
- Erlang: `@external(erlang, "module", "function")`

## Common Issues

1. **Import errors**: Check package dependencies in `gleam.toml`
2. **Target mismatch**: Ensure modules use correct target-specific code
3. **String types**: Gleam strings are binaries in Erlang
