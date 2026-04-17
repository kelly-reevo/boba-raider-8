# GTM Atlas Frontend

Interactive SVG visualization of a bowtie GTM model with three zoomable levels. Built in Gleam targeting JavaScript via Lustre's MVU runtime. Mounted to `#app` in `packages/server/priv/static/index.html`; bundled by `gleam run -m lustre/dev build frontend/app` into `../server/priv/static/js/app.js`.

## File Map

```
src/
├── client.gleam                 Entry point; delegates to frontend/app.main
└── frontend/
    ├── app.gleam                lustre.simple wiring (init/update/view) → #app
    ├── model.gleam              Model type, init, motion helpers
    ├── msg.gleam                Msg variants (single, flat sum type)
    ├── update.gleam             Pure (Model, Msg) -> Model reducer
    ├── view.gleam               Model -> Element(Msg); sidebar + SVG canvas
    ├── svg_helpers.gleam        canvas_width/height consts, viewbox_transform, arrow markers
    └── wheel_ffi.mjs            JS FFI: map wheel event to 1600×900 canvas coords
```

Domain types live in the `shared` package under `atlas.gleam`, `atlas/seed.gleam` (hardcoded sample data), and `atlas/lookup.gleam` (pure finders). See `packages/shared/CLAUDE.md`.

## Runtime Shape: lustre.simple (no effects)

```gleam
lustre.simple(init, update.update, view.view)
|> lustre.start("#app", Nil)
```

The app uses **`lustre.simple`** — `update` has signature `(Model, Msg) -> Model`, NOT `-> #(Model, Effect(Msg))`. There are no HTTP calls, no subscriptions, no effects. All atlas data is seeded client-side via `atlas/seed.gleam`. Do not add `gleam_fetch`-style calls without first converting to `lustre.application` (would require rewriting every `Msg` handler).

## Canvas Coordinate System

- SVG element has `viewBox="0 0 1600 900"` and `preserveAspectRatio="xMidYMid meet"`. `canvas_width = 1600.0`, `canvas_height = 900.0` live in `svg_helpers.gleam` and are duplicated as `canvas_w`/`canvas_h` constants in `update.gleam` — keep these in sync.
- Each level's `<g>` layer is transformed by `svg_helpers.viewbox_transform(vb)` into `translate(tx ty) scale(s)`, where `s = min(1600/vb.width, 900/vb.height)` and `tx`/`ty` center the content ("meet" semantics). Zoom/pan mutate the **layer's viewbox**, not the SVG viewBox.
- `update.canvas_to_inner(cx, cy, vb)` is the inverse of `viewbox_transform` — converts canvas-space pointer coords to the layer's inner coordinate space. Used by pan and wheel zoom.
- `wheel_ffi.mjs:pointer_canvas_pos` does the same inversion in JS for wheel events (converts `clientX/clientY` relative to `currentTarget`'s bounding rect back to the 1600×900 space).

## Three-Layer Rendering (Overview / Activities / Breakdown)

**All three layers are always rendered in the DOM.** `render_overview_layer`, `render_activities_layer`, `render_breakdown_layer` each produce a `<g class="layer ...">` unconditionally (breakdown renders nothing only when `active_breakdown` is `None`). Switching levels changes which layer has the `active` class.

CSS (`packages/server/priv/static/css/styles.css`) drives the crossfade:
- `.layer { opacity: 0; pointer-events: none; transition: transform 420ms, opacity 220ms; }`
- `.layer.active { opacity: 1; pointer-events: auto; }`
- `.layer.no-transition { transition: none; }` — applied to the active layer while `model.dragging` is true so pan feels instant.

Do not try to conditionally mount layers: the persistent DOM is what lets CSS crossfade work, and keeping each layer's viewbox in state is what lets "back" navigation restore the previous zoom/pan.

## Model (frontend/model.gleam)

```gleam
Model(
  atlas: Atlas,                             // seeded once in init; never mutated
  level: atlas.Level,                       // which layer is .active
  overview_viewbox: ViewBox,                // persisted per-level so back nav restores
  activities_viewbox: ViewBox,              //   previous zoom/pan
  breakdown_viewbox: ViewBox,
  active_breakdown: Option(NodeId),         // parent activity id when in Breakdown
  stack: List(Crumb),                       // breadcrumb history (head = most recent)
  hovered: Option(NodeId),
  motions: Set(Motion),                     // empty = show all; otherwise dim non-matching
  focused_stage: Option(StageId),           // at Activities, which stage band is focused
  dragging: Bool,                           // mouse is held down
  drag_moved: Bool,                         // pan distance > 3px this gesture — suppresses click
)
```

`Crumb` snapshots `level`, `active_breakdown`, `focused_stage`, and a human label. Pushed on drill, popped by `BackClicked`/`BreadcrumbClicked`/wheel-out-past-min-zoom.

`model.init()` hardcodes the **breakdown** starting viewbox to `ViewBox(-300, 0, 1800, 720)`, but drilling into a breakdown overwrites it with `graph.viewbox` from the seed (`ViewBox(-420, -60, 2040, 900)`). The initial value is only visible if you switch to Breakdown without drilling — practically, only the drill-overwritten value is seen.

### Motion filter semantics

`motion_match(model, motions)` returns true if the filter set is empty OR any of the node/edge's motions is active. Empty filter = pass-through. Non-matching nodes render at `opacity=0.18`; non-matching edges at `opacity=0.12`.

## Messages & Update (frontend/msg.gleam, frontend/update.gleam)

```
NodeHovered(id) / NodeUnhovered / NodeClicked(id)
BackClicked / BreadcrumbClicked(idx)
MotionToggled(m) / ClearMotions
ResetView
PanStart / PanMove(dx, dy, svg_w, svg_h) / PanEnd
WheelScroll(delta_y, canvas_x, canvas_y)
```

### Click-vs-drag disambiguation

`NodeClicked` does nothing if `drag_moved` was set during the current gesture — it only resets `drag_moved` to `False`. `drag_moved` is set in `apply_pan` when `|dx| + |dy| > 3`. Without this, a pan-then-release over a node would drill unintentionally.

### Drill logic (`handle_click` / `drill_into`)

- `Stage(_)` or `Knot(_)` node with `children_level = Some(Activities)` → `drill_to_stage`: push a crumb, switch to Activities, set `activities_viewbox = seed.focus_viewbox(stage)`, set `focused_stage = Some(stage)`.
- `Activity(_)` node with `children_level = Some(Breakdown)` → `drill_to_breakdown`.
- **Sideways navigation from Breakdown**: If the user is *already* in Breakdown and clicks a drillable node (a neighbor activity), the top of the stack is **replaced** with an "activities" crumb for the neighbor's stage — `list.drop(model.stack, 1)` then prepend a fresh activities crumb. This lets the user ping-pong between breakdowns without stacking N crumbs. Regular drill (from Activities) pushes instead.

### Wheel zoom (`handle_wheel`)

- Delta `< 0` → zoom in; `> 0` → zoom out. Other values are ignored.
- `current_zoom_ratio(model) = base_viewbox.width / active_viewbox.width`, where `base_viewbox` is `focus_viewbox(stage)` when `level == Activities && focused_stage == Some(stage)`, else `active_graph.viewbox`.
- **Zoom-in past max** (`zoom + epsilon >= level_max_zoom(level)`) → drill. Priority: hovered node (if drillable) > first drillable node at the pointer (point-in-node test on each node's rect). No drill → no-op.
- **Zoom-out past min** (`zoom - epsilon <= level_min_zoom(level)`) → pop the stack (back nav). Empty stack → no-op.
- Otherwise: `apply_zoom` adjusts the active viewbox width/height to `base.width / target_zoom` and anchors the pointer position in inner coords (so the point under the cursor stays under the cursor after zoom).
- Per-level bounds: Activities uses `0.45..1.7`; Overview/Breakdown use `0.6..2.5`. `zoom_step = 1.15`.

### Pan (`apply_pan`)

Mouse-down on `.canvas-wrap` fires `PanStart` (sets `dragging=True, drag_moved=False`). Mousemove decodes `buttons`, `movementX/Y`, and `currentTarget.clientWidth/Height`; ignores when `buttons == 0`. Pixel deltas convert to inner viewbox deltas via `canvas_to_px * zoom_scale` (px per inner unit); then the active viewbox is translated by `-dx_inner, -dy_inner`. `drag_moved` latches once movement exceeds 3px.

### ResetView

Rebuilds via `model.init()` but **preserves `atlas` and `motions`** (keeps the filter chip selection). Stack, focused stage, active breakdown, and all three viewboxes reset.

## Wheel FFI (frontend/wheel_ffi.mjs)

A 21-line JS module, imported as `@external(javascript, "./wheel_ffi.mjs", "pointer_canvas_pos")`. Returns the pointer position in the 1600×900 canvas space as a `#(Float, Float)` Gleam tuple (a JS array on the JS target). Used inside `view.wheel_decoder` because `decode` can't easily read `getBoundingClientRect` from dynamic event data.

If you add more FFI, keep it in a single `*_ffi.mjs` module and export explicit functions. Lustre bundles all JS imports transitively.

## View (frontend/view.gleam)

### Event decoders

- `pan_move_decoder`: reads `buttons`, `movementX`, `movementY`, `currentTarget.clientWidth`, `currentTarget.clientHeight`. Fails decode if `buttons == 0` (mouse up).
- `wheel_decoder`: reads `deltaY` (tolerates int or float), then reinvokes `pointer_canvas_pos(raw_event)` via FFI. Wrapped in `event.prevent_default` so the page doesn't scroll.

### Node rendering

Dispatched on `NodeKind`:
- `Stage` → `rect_shape` r=16
- `Activity` → `rect_shape` r=12
- `Task` → `rect_shape` r=10 + `owner_pill` (pill rendered above the rect showing the task's `owner` string)
- `Knot` → `knot_shape` (4-point diamond polygon)
- `Neighbor(stage, direction)` → `hex_shape` (hexagon polygon, inbound/outbound styled differently via `.neighbor-in`/`.neighbor-out` classes)

Node CSS class string is `"node " <> kind_class <> " hovered"? <> " drillable"?`. Fill color is driven entirely by CSS rules keyed on `.node.activity-<stage>` / `.node.stage-<stage>` (see styles.css). `drillable` is derived from `node.children_level`.

### Edge rendering

- Overview → straight `<line>` with `marker-end`.
- Activities/Breakdown → cubic bezier `<path>` with horizontal tangents (`bezier_path`).
- `Flow` → solid, grey, `url(#arrow)`.
- `Handoff` → dashed `8 6`, purple, `url(#arrow-dashed)`.
- `Feedback` → dashed `4 4`, orange, `url(#arrow)`.

Endpoint anchoring: `endpoint(a, b)` returns the point on `a`'s bounding box closest to `b` — right edge if `b.x > a.x`, left edge if `b.x < a.x`, bottom edge otherwise. This means vertically-stacked nodes draw from the bottom, which can look odd for back-edges; adjust if needed.

### Stage bands (Activities level only)

`stage_bands_layer` renders one `<rect>` per `StageBand` behind the activity nodes with a fill tinted by stage (Commitment = purple, post-sale stages = green-tinted, pre-sale = blue-tinted). Focused stage gets a brighter stroke. Band labels are uppercase text at y=210.

### Bowtie silhouette (Overview level only)

Two opaque triangles (left blue, right green) meeting at the Commitment knot — pure decoration, rendered as `svg.polygon` with `pointer-events: none`.

## Interaction Summary

| User action | Result |
|-------------|--------|
| Click a drillable node | Push crumb; switch level; load new viewbox |
| Click a Neighbor (in Breakdown) | Replace top crumb; go to that breakdown |
| Click "← Back" | Pop top crumb |
| Click a breadcrumb label | Jump to that crumb (drop all newer) |
| Click a motion chip | Toggle membership in `motions` set |
| Click "Show all" | Clear `motions` |
| Click "Reset view" | Reinit viewboxes + stack (keep atlas + motions) |
| Drag in canvas | Pan active viewbox |
| Wheel up (over canvas) | Zoom in; drill if at max zoom over drillable node |
| Wheel down (over canvas) | Zoom out; back-pop if at min zoom |
| Hover a node | Sets `hovered`; CSS highlights; biases wheel-zoom drill target |

## CSS Touchpoints

Styling lives in `packages/server/priv/static/css/styles.css` (served at `/static/css/styles.css`). Classes emitted by the view that the CSS keys on:

- Layout: `.app-shell`, `.sidebar`, `.canvas-wrap`, `.atlas-svg`
- Sidebar: `.sidebar-header`, `.subtitle`, `.level-indicator`, `.level-label`, `.level-value`, `.breadcrumb`, `.back-btn`, `.crumb-trail`, `.crumb-btn`, `.crumb-sep`, `.crumb-current`, `.motion-section`, `.section-title`, `.section-hint`, `.motion-grid`, `.chip`, `.chip.active`, `.motion-no`/`.motion-low`/`.motion-med`/`.motion-high`, `.ghost-btn`, `.ghost-btn.small`, `.sidebar-footer`
- Canvas: `.canvas-wrap.pannable`, `.canvas-wrap.pannable.dragging`
- Layers: `.layer`, `.layer.active`, `.layer.no-transition`, `.layer-overview`/`.layer-activities`/`.layer-breakdown`
- Nodes: `.node`, `.node.drillable`, `.node.hovered`, `.node.stage`, `.node.stage-<stage>`, `.node.activity`, `.node.activity-<stage>`, `.node.task`, `.node.knot`, `.node.neighbor`, `.node.neighbor-in`/`.neighbor-out`, `.node-label`, `.owner-pill`, `.owner-pill-label`
- Edges/bg: `.edges`, `.nodes`, `.edge-label`, `.bowtie-bg`, `.stage-bands`, `.band-label`

Stage-keyed class names come from `string.lowercase(atlas.stage_label(stage))` — "awareness", "education", "selection", "commitment", "onboarding", "adoption", "expansion".

## Build & Dev

From the repo root:

```
make build          # build all packages (shared → client → server)
make build-frontend # bundle Lustre app to packages/server/priv/static/js/app.js
make dev            # start Lustre dev server with hot reload (no backend)
make run            # build frontend + start backend server on port 3777
make run-quick      # start server without rebuilding frontend
```

Hot reload: `make dev` uses `lustre/dev start` which serves the frontend standalone. Server-mode dev requires `make build-frontend` after every frontend change (or `make run`).

Package-level: `cd packages/client && gleam format src` and `gleam test` work as usual. Client target is `javascript`; importing any Erlang-only module (e.g. `gleam/otp/actor`) will fail to compile.

## Gotchas

- **Two sources of truth for canvas size**: `svg_helpers.canvas_width/height` (Float consts) and `update.canvas_w/canvas_h` (Float consts). Do not diverge them.
- **Two sources of truth for `focus_viewbox`**: `update.base_viewbox` calls `seed.focus_viewbox` and the view's `render_activities_layer` uses `model.activities_viewbox` directly. Ensure drilling/reset keeps them consistent — `drill_to_stage` sets `activities_viewbox = seed.focus_viewbox(stage)`; `focused_stage` is what makes `base_viewbox` return the focus box so the zoom ratio is 1.0 at drill time.
- **Breakdown `active_breakdown` required**: If `level == Breakdown` but `active_breakdown == None`, `active_graph` returns the overview graph (fallback). `render_breakdown_layer` renders nothing. This state is technically reachable only via a bug — prefer fixing the state machine over adding fallbacks.
- **Neighbors and edges on drill**: Neighbor nodes/edges in a breakdown graph are **computed at seed time** (`neighbor_nodes_and_edges` in `seed.gleam`) by scanning the activity map's edges. They are NOT lazily generated. If `custom_breakdowns` changes entry/exit IDs, regenerate.
- **Click on knot**: `drill_into` handles both `Stage(s)` and `Knot(s)` by drilling to Activities for that stage. The Commitment knot thus behaves like a stage rect.
- **`lustre.simple` cannot dispatch from the outside**: no way to trigger a `Msg` from JS except through a DOM event. If you need async, migrate to `lustre.application` and thread `Effect(Msg)` through `update`.
