# Shared Package — GTM Atlas Domain Model

Pure Gleam types and seed data for the GTM Atlas visualization. No target declared in `gleam.toml`, so modules compile to both JavaScript (used by `client`) and Erlang (available to `server`). Must stay platform-independent: no DOM, no OTP, no `@external` FFIs.

Deps: `gleam_stdlib`, `gleam_json`. Nothing else — anything heavier breaks compilation on one target.

## File Map

```
src/
├── shared.gleam            Top-level domain errors (AppError variants; minimal)
├── atlas.gleam             Core atlas types + label/classifier helpers
└── atlas/
    ├── lookup.gleam        Pure finders over Graph / Atlas
    └── seed.gleam          Hardcoded GTM atlas data (THE sole data source)
```

## The Atlas Data Model (atlas.gleam)

An `Atlas` is a three-tier graph structure plus a flat opportunity roster:

```gleam
Atlas(
  overview: Graph,                       // Level 1: 7 stages + 1 knot in a row
  activity_map: Graph,                   // Level 2: ~30 activities grouped into stage bands
  breakdowns: List(#(NodeId, Graph)),    // Level 3: one graph per drillable activity
  opportunities: List(Opportunity),      // stand-in deal paths through the atlas
)
```

Each `Opportunity` has `id`, `name`, `current_stage`, and an ordered `visits: List(OpportunityVisit)` where each visit is `#(NodeId, date: String)`. Visits may reference activity node IDs (from the activity map) or task node IDs (from a breakdown); stage-level traversal at the Overview is derived — `lookup.stage_date` scans visits and maps them through the activity map.

All three `Graph`s share the same shape:

```gleam
Graph(
  level: Level,                // Overview | Activities | Breakdown
  parent: Option(NodeId),      // for breakdowns, the activity node they expand
  nodes: List(Node),
  edges: List(Edge),
  viewbox: ViewBox,            // default SVG viewbox for this graph
  bands: List(StageBand),      // only populated for activity_map
)
```

### Levels

```gleam
type Level { Overview | Activities | Breakdown }
```

- **Overview**: the seven-stage bowtie at x=160..1440, y=450. Viewbox `0 0 1600 900`.
- **Activities**: unified map of all activities across stages. Viewbox `0 0 4100 1400` — wider than canvas; the frontend zooms/pans this and uses `focus_viewbox(stage)` for drill targets.
- **Breakdown**: per-activity swimlane with task nodes + "neighbor" activities on either side. Viewbox `-420 -60 2040 900` (seed default; `frontend/model.init` uses `-300 0 1800 720` as the breakdown-layer starting viewbox, overwritten on drill).

### Stages

```gleam
type StageId {
  Awareness Education Selection Commitment Onboarding Adoption Expansion
}
```

- `stage_label(s) -> String` returns the title-cased name.
- `stage_is_post_sale(s) -> Bool` returns `True` for Onboarding, Adoption, Expansion.
- Pre-sale stages render in blue tints; post-sale in green; Commitment (the knot) in purple.

### Node shape

```gleam
Node(
  id: NodeId,
  label: String,
  kind: NodeKind,                    // drives rendering shape + CSS class
  position: Point,                   // center point in the graph's coordinate space
  size: Size,                        // bounding box (width × height)
  motions: List(Motion),             // which GTM motions this node applies to; [] = always show
  parent: Option(NodeId),            // set for Task nodes (points at owning activity)
  children_level: Option(Level),     // if Some(_), node is drillable to that level
  notes: String,                     // currently unused in rendering
)
```

`NodeKind` discriminates which SVG shape and style class the view produces:

- `Stage(StageId)` — rectangle, Overview level (drills to Activities).
- `Knot(StageId)` — diamond, Overview level, used for Commitment. Also drills to Activities.
- `Activity(StageId)` — rectangle, Activities level (drills to Breakdown).
- `Task(owner: String)` — rectangle with a pill showing `owner`. Breakdown level. Not drillable.
- `Neighbor(stage: StageId, direction: Direction)` — hexagon at the edges of a breakdown graph. `Direction` is `Inbound` or `Outbound`. Clicking a Neighbor does sideways navigation in the frontend (see `client/CLAUDE.md`).

### Edges

```gleam
Edge(id, from, to, label, kind: EdgeKind, motions)
type EdgeKind { Flow | Feedback | Handoff }
```

Edge CSS: Flow = solid grey arrow; Handoff = dashed purple (cross-stage transitions); Feedback = dashed orange (loop-backs like `adpc_followup → adpc_review`).

### Motions

```gleam
type Motion { NoTouch | LowTouch | MediumTouch | HighTouch }
```

The motion filter in the UI dims non-matching nodes/edges. A node/edge matches if its `motions` list intersects the active filter set, or the filter set is empty.

### ViewBox

`ViewBox(x, y, width, height)` — the logical coordinate region the graph occupies. The frontend scales this to the fixed 1600×900 canvas via `preserveAspectRatio="xMidYMid meet"`-style math (see `frontend/svg_helpers.viewbox_transform`).

### StageBand

```gleam
StageBand(stage: StageId, x: Float, width: Float, label: String)
```

Stripes behind the activity map indicating which stage each column belongs to. Only the activity-map graph carries bands. `seed.stage_bands()` is the sole source; `seed.focus_viewbox(stage)` returns a viewbox centered on that band with 240px padding.

## Seed Data (atlas/seed.gleam)

`seed.atlas()` is the **only** source of atlas data in the codebase. Called from `frontend/model.init` at app startup. No server API, no JSON decode — everything is hardcoded Gleam values. If you need to change the atlas, edit this file.

Structure:

1. `overview_graph()` — 7 stage rects + flow edges between them.
2. `activity_map()` — `activity_nodes()` (30 activities) + `activity_edges()` (~35 inter-activity flows/handoffs), with `stage_bands()` attached.
3. `breakdowns` — for each activity, either a custom breakdown (`custom_breakdowns()` — 7 hand-drawn: `aw_web_ads`, `ed_inbound`, `sel_demo`, `com_contract`, `onb_guided`, `adp_csm`, `exp_renewal`) or a `stub_breakdown` with a single placeholder task.

### Breakdown graph construction

`breakdown_graph(parent, entry, exit, nodes, edges)` wraps a caller's nodes/edges and **auto-generates neighbor columns**:

- `neighbor_nodes_and_edges(parent, entry, exit)` scans the full activity-map edges: every edge whose `to == parent` yields an Inbound neighbor (left column, x=-240); every edge whose `from == parent` yields an Outbound neighbor (right column, x=1420). Neighbors inherit `label`, `motions`, and `stage` from their source activity but get `kind: Neighbor(stage, direction)` and `children_level: Some(Breakdown)` (so clicking drills to their own breakdown).
- `breakdown` then auto-inserts bridge edges: each inbound neighbor → `entry` task, and `exit` task → each outbound neighbor.

This means the set of neighbors shown in a breakdown is **derived from the activity map's edges, not authored per-breakdown**. Adding an `activity_edges` entry changes what neighbors appear in the target's breakdown.

### Node ID convention

String-prefixed by stage and purpose:
- Overview: stage name (`awareness`, `commitment`, ...)
- Activities: `<stage prefix>_<slug>` — e.g. `aw_web_ads`, `ed_sdr_qual`, `sel_demo`, `com_contract`, `onb_guided`, `adp_csm`, `exp_renewal`.
- Tasks: `<activity prefix>_<slug>` — e.g. `awb_impression`, `seld_proposal`, `expr_sign`.

Edge IDs: generated `<from>_to_<to>` for `flow`/`handoff` helpers; explicit for `edge(...)` calls.

### Coordinate spaces

- Overview: nodes at y=450, x ∈ [160, 1440]. Knot at x=800 (Commitment).
- Activity map: bands tile horizontally from x=60 to x=4000; node y ∈ [380, 980]. Two-column layout within each stage band.
- Breakdown: task nodes roughly at x ∈ [260, 1060], y ∈ [220, 440]. Neighbors at x=-240 (in) and x=1420 (out). Graph viewbox `-420 -60 2040 900` exposes all of this.

## Lookup helpers (atlas/lookup.gleam)

Pure, list-based finders:

```gleam
find_node(graph, id) -> Option(Node)                     // linear scan of graph.nodes
find_breakdown_graph(atlas, activity_id) -> Option(Graph) // linear scan of atlas.breakdowns
find_graph(atlas, level, parent) -> Option(Graph)        // dispatches on level
find_stage_band(bands, stage) -> Option(StageBand)
```

All O(n). The atlas is small enough (~30 activities, ~50-100 nodes per level) that this is fine. Don't introduce a Dict-backed index unless profiling says otherwise.

## Conventions

- **Type changes propagate to both runtimes.** Editing `atlas.gleam` forces a rebuild of both `client` (JS) and `server` (Erlang) because both compile this package. Exhaustive pattern matches in the frontend (`view.gleam`, `update.gleam`) will error on missing variants — a feature, not a bug.
- **No `@external` FFIs in this package.** Any FFI ties the module to a specific target and breaks the dual-compilation guarantee. Put FFIs in the package that needs them (e.g. `client/src/frontend/wheel_ffi.mjs`).
- **Seed data is code, not config.** There is no JSON file, no server endpoint, no dynamic loading. All 30+ activities, their coordinates, their motions, and every breakdown are Gleam expressions in `seed.gleam`. Treat changes like any other source change.
- **`shared.gleam` currently only holds an `AppError` sum type** and is essentially unused by the atlas subsystem. Do not conflate it with `atlas.gleam`.
