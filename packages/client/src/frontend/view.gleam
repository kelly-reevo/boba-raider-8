import atlas.{
  type Edge, type Motion, type Node, type StageBand, Activities, Activity,
  Feedback, Flow, Handoff, HighTouch, Knot, LowTouch, MediumTouch, NoTouch,
  Overview, Stage, Task,
}
import atlas/lookup
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import frontend/svg_helpers.{fattr, viewbox_transform}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import lustre/attribute.{attribute, class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("app-shell")], [sidebar(model), main_canvas(model)])
}

// -------- sidebar ----------

fn sidebar(model: Model) -> Element(Msg) {
  html.aside([class("sidebar")], [
    html.header([class("sidebar-header")], [
      html.h1([], [element.text("GTM Atlas")]),
      html.p([class("subtitle")], [
        element.text("Bowtie model · zoom to drill down"),
      ]),
    ]),
    breadcrumb(model),
    level_legend(model),
    motion_filters(model),
    html.footer([class("sidebar-footer")], [
      html.button(
        [event.on_click(msg.ResetView), class("ghost-btn")],
        [element.text("Reset view")],
      ),
    ]),
  ])
}

fn breadcrumb(model: Model) -> Element(Msg) {
  let crumb_els =
    list.index_map(model.stack, fn(c, i) {
      html.button(
        [event.on_click(msg.BreadcrumbClicked(i)), class("crumb-btn")],
        [element.text(c.label)],
      )
    })
  let current = html.span([class("crumb-current")], [
    element.text(current_label(model)),
  ])
  let separator = html.span([class("crumb-sep")], [element.text("›")])
  let trail_children = case crumb_els {
    [] -> [current]
    _ ->
      list.fold(crumb_els, [current], fn(acc, el) { [el, separator, ..acc] })
  }
  let back_btn = case model.stack {
    [] -> element.none()
    _ ->
      html.button(
        [event.on_click(msg.BackClicked), class("back-btn")],
        [element.text("← Back")],
      )
  }
  html.nav([class("breadcrumb")], [
    back_btn,
    html.div([class("crumb-trail")], trail_children),
  ])
}

fn current_label(model: Model) -> String {
  case model.current.level, model.focused_stage {
    Overview, _ -> "Overview"
    atlas.Activities, Some(stage) ->
      atlas.stage_label(stage) <> " activities"
    atlas.Activities, None -> "Activities"
    atlas.Breakdown, _ -> breakdown_label(model)
  }
}

fn breakdown_label(model: Model) -> String {
  case model.current.parent {
    Some(id) ->
      case lookup.find_node(model.atlas.activity_map, id) {
        Some(n) -> n.label
        None -> "Breakdown"
      }
    None -> "Breakdown"
  }
}

fn level_legend(model: Model) -> Element(Msg) {
  html.div([class("level-indicator")], [
    html.span([class("level-label")], [element.text("Level")]),
    html.span([class("level-value")], [
      element.text(atlas.level_label(model.current.level)),
    ]),
  ])
}

fn motion_filters(model: Model) -> Element(Msg) {
  html.section([class("motion-section")], [
    html.h2([class("section-title")], [element.text("GTM motion filter")]),
    html.p([class("section-hint")], [
      element.text("Toggle to dim non-matching nodes."),
    ]),
    html.div([class("motion-grid")], [
      motion_chip(model, NoTouch),
      motion_chip(model, LowTouch),
      motion_chip(model, MediumTouch),
      motion_chip(model, HighTouch),
    ]),
    html.button(
      [event.on_click(msg.ClearMotions), class("ghost-btn small")],
      [element.text("Show all")],
    ),
  ])
}

fn motion_chip(model: Model, motion: Motion) -> Element(Msg) {
  let active = model.motion_active(model, motion)
  let cls = case active {
    True -> "chip active " <> motion_class(motion)
    False -> "chip " <> motion_class(motion)
  }
  html.button([event.on_click(msg.MotionToggled(motion)), class(cls)], [
    element.text(atlas.motion_label(motion)),
  ])
}

fn motion_class(motion: Motion) -> String {
  case motion {
    NoTouch -> "motion-no"
    LowTouch -> "motion-low"
    MediumTouch -> "motion-med"
    HighTouch -> "motion-high"
  }
}

// -------- main canvas ----------

fn main_canvas(model: Model) -> Element(Msg) {
  let pannable = model.current.level == Activities
  let wrap_classes =
    "canvas-wrap"
    <> case pannable {
      True -> " pannable"
      False -> ""
    }
    <> case model.dragging {
      True -> " dragging"
      False -> ""
    }
  let zoom_classes =
    "zoom-layer"
    <> case model.dragging {
      True -> " no-transition"
      False -> ""
    }
  html.main(
    [
      class(wrap_classes),
      event.on_mouse_down(msg.PanStart),
      event.on_mouse_up(msg.PanEnd),
      event.on_mouse_leave(msg.PanEnd),
      event.on("mousemove", pan_move_decoder()),
    ],
    [
      svg.svg(
        [
          attribute(
            "viewBox",
            "0 0 "
              <> float.to_string(svg_helpers.canvas_width)
              <> " "
              <> float.to_string(svg_helpers.canvas_height),
          ),
          attribute("preserveAspectRatio", "xMidYMid meet"),
          class("atlas-svg"),
        ],
        [
          svg_helpers.arrow_marker_defs(),
          svg.g(
            [
              class(zoom_classes),
              attribute("transform", viewbox_transform(model.viewbox)),
            ],
            [
              bowtie_silhouette(model),
              stage_bands_layer(model),
              render_graph(model),
            ],
          ),
        ],
      ),
    ],
  )
}

fn pan_move_decoder() -> decode.Decoder(Msg) {
  use buttons <- decode.field("buttons", decode.int)
  use dx <- decode.field("movementX", decode.int)
  use dy <- decode.field("movementY", decode.int)
  use width <- decode.subfield(["currentTarget", "clientWidth"], decode.int)
  use height <- decode.subfield(["currentTarget", "clientHeight"], decode.int)
  case buttons > 0 {
    True -> decode.success(msg.PanMove(dx, dy, width, height))
    False -> decode.failure(msg.PanMove(0, 0, 0, 0), "not dragging")
  }
}

fn bowtie_silhouette(model: Model) -> Element(Msg) {
  case model.current.level {
    Overview ->
      svg.g([class("bowtie-bg")], [
        svg.polygon([
          attribute("points", "80,200 800,450 80,700"),
          attribute("fill", "#eef3ff"),
          attribute("stroke", "#6b8ae0"),
          attribute("stroke-width", "2"),
          attribute("opacity", "0.55"),
        ]),
        svg.polygon([
          attribute("points", "1520,200 800,450 1520,700"),
          attribute("fill", "#eefaf3"),
          attribute("stroke", "#4ca082"),
          attribute("stroke-width", "2"),
          attribute("opacity", "0.55"),
        ]),
      ])
    _ -> element.none()
  }
}

fn stage_bands_layer(model: Model) -> Element(Msg) {
  case model.current.bands {
    [] -> element.none()
    bands ->
      svg.g(
        [class("stage-bands")],
        list.flatten([
          list.map(bands, fn(b) { band_rect(model, b) }),
          list.map(bands, band_label),
        ]),
      )
  }
}

fn band_rect(model: Model, band: StageBand) -> Element(Msg) {
  let focused = case model.focused_stage {
    Some(s) -> s == band.stage
    None -> False
  }
  let fill = case band.stage {
    atlas.Commitment -> "rgba(160, 107, 200, 0.18)"
    _ ->
      case atlas.stage_is_post_sale(band.stage) {
        True -> "rgba(76, 160, 130, 0.10)"
        False -> "rgba(107, 138, 224, 0.10)"
      }
  }
  let stroke = case focused {
    True -> "rgba(255,255,255,0.55)"
    False -> "rgba(255,255,255,0.12)"
  }
  svg.rect([
    fattr("x", band.x),
    fattr("y", 160.0),
    fattr("width", band.width),
    fattr("height", 1160.0),
    attribute("fill", fill),
    attribute("stroke", stroke),
    attribute("stroke-width", "2"),
    attribute("rx", "10"),
  ])
}

fn band_label(band: StageBand) -> Element(Msg) {
  svg.text(
    [
      fattr("x", band.x +. band.width /. 2.0),
      fattr("y", 210.0),
      attribute("text-anchor", "middle"),
      attribute("class", "band-label"),
    ],
    string.uppercase(band.label),
  )
}

fn render_graph(model: Model) -> Element(Msg) {
  let edges_layer =
    svg.g(
      [class("edges")],
      list.map(model.current.edges, fn(e) { render_edge(model, e) }),
    )
  let nodes_layer =
    svg.g(
      [class("nodes")],
      list.map(model.current.nodes, fn(n) { render_node(model, n) }),
    )
  svg.g([class("graph")], [edges_layer, nodes_layer])
}

// -------- edges ----------

fn render_edge(model: Model, edge: Edge) -> Element(Msg) {
  let from_node = lookup.find_node(model.current, edge.from)
  let to_node = lookup.find_node(model.current, edge.to)
  case from_node, to_node {
    Some(fnode), Some(tnode) -> draw_edge(model, edge, fnode, tnode)
    _, _ -> element.none()
  }
}

fn draw_edge(model: Model, edge: Edge, from: Node, to: Node) -> Element(Msg) {
  let #(x1, y1) = endpoint(from, to)
  let #(x2, y2) = endpoint(to, from)
  let opacity = case model.motion_match(model, edge.motions) {
    True -> "1"
    False -> "0.12"
  }
  let #(stroke, dash, marker) = case edge.kind {
    Flow -> #("#7e8da3", "", "url(#arrow)")
    Handoff -> #("#a06bc8", "8 6", "url(#arrow-dashed)")
    Feedback -> #("#c78f4a", "4 4", "url(#arrow)")
  }
  let label_el = case edge.label {
    "" -> element.none()
    lbl ->
      svg.text(
        [
          fattr("x", { x1 +. x2 } /. 2.0),
          fattr("y", { y1 +. y2 } /. 2.0 -. 8.0),
          attribute("text-anchor", "middle"),
          attribute("class", "edge-label"),
          attribute("opacity", opacity),
        ],
        lbl,
      )
  }
  case model.current.level {
    Overview ->
      svg.g([], [
        svg.line([
          fattr("x1", x1),
          fattr("y1", y1),
          fattr("x2", x2),
          fattr("y2", y2),
          attribute("stroke", stroke),
          attribute("stroke-width", "3"),
          attribute("stroke-dasharray", dash),
          attribute("marker-end", marker),
          attribute("opacity", opacity),
        ]),
        label_el,
      ])
    _ ->
      svg.g([], [
        svg.path([
          attribute("d", bezier_path(x1, y1, x2, y2)),
          attribute("fill", "none"),
          attribute("stroke", stroke),
          attribute("stroke-width", "2"),
          attribute("stroke-dasharray", dash),
          attribute("marker-end", marker),
          attribute("opacity", opacity),
        ]),
        label_el,
      ])
  }
}

fn bezier_path(x1: Float, y1: Float, x2: Float, y2: Float) -> String {
  let dx = x2 -. x1
  let abs_dx = case dx <. 0.0 {
    True -> 0.0 -. dx
    False -> dx
  }
  let offset = case abs_dx <. 120.0 {
    True -> 80.0
    False -> abs_dx /. 2.0
  }
  "M "
  <> float.to_string(x1)
  <> " "
  <> float.to_string(y1)
  <> " C "
  <> float.to_string(x1 +. offset)
  <> " "
  <> float.to_string(y1)
  <> ", "
  <> float.to_string(x2 -. offset)
  <> " "
  <> float.to_string(y2)
  <> ", "
  <> float.to_string(x2)
  <> " "
  <> float.to_string(y2)
}

fn endpoint(a: Node, b: Node) -> #(Float, Float) {
  let ax = a.position.x
  let ay = a.position.y
  let bx = b.position.x
  let _by = b.position.y
  let half_w = a.size.width /. 2.0
  let half_h = a.size.height /. 2.0
  case bx >. ax, bx <. ax {
    True, _ -> #(ax +. half_w, ay)
    _, True -> #(ax -. half_w, ay)
    _, _ -> #(ax, ay +. half_h)
  }
}

// -------- nodes ----------

fn render_node(model: Model, node: Node) -> Element(Msg) {
  let opacity = case model.motion_match(model, node.motions) {
    True -> "1"
    False -> "0.18"
  }
  let drillable = case node.children_level {
    Some(_) -> True
    None -> False
  }
  let cursor = case drillable {
    True -> "pointer"
    False -> "default"
  }
  let hovered = model.hovered == Some(node.id)
  let class_name =
    "node "
    <> node_kind_class(node.kind)
    <> case hovered {
      True -> " hovered"
      False -> ""
    }
    <> case drillable {
      True -> " drillable"
      False -> ""
    }
  let shape = case node.kind {
    Knot(_) -> knot_shape(node, opacity)
    Stage(_) -> rect_shape(node, opacity, 16.0)
    Activity(_) -> rect_shape(node, opacity, 12.0)
    Task(_) -> rect_shape(node, opacity, 10.0)
  }
  let extras = case node.kind {
    Task(owner) -> [owner_pill(node, owner, opacity)]
    _ -> []
  }
  let label = label_element(node, opacity)
  svg.g(
    [
      class(class_name),
      attribute("cursor", cursor),
      event.on_click(msg.NodeClicked(node.id)),
      event.on_mouse_enter(msg.NodeHovered(node.id)),
      event.on_mouse_leave(msg.NodeUnhovered),
    ],
    list.flatten([[shape, label], extras]),
  )
}

fn node_kind_class(kind: atlas.NodeKind) -> String {
  case kind {
    Stage(s) -> "stage stage-" <> string.lowercase(atlas.stage_label(s))
    Knot(_) -> "knot"
    Activity(s) -> "activity activity-" <> string.lowercase(atlas.stage_label(s))
    Task(_) -> "task"
  }
}

fn rect_shape(node: Node, opacity: String, radius: Float) -> Element(msg) {
  let x = node.position.x -. node.size.width /. 2.0
  let y = node.position.y -. node.size.height /. 2.0
  svg.rect([
    fattr("x", x),
    fattr("y", y),
    fattr("width", node.size.width),
    fattr("height", node.size.height),
    fattr("rx", radius),
    fattr("ry", radius),
    attribute("opacity", opacity),
  ])
}

fn knot_shape(node: Node, opacity: String) -> Element(msg) {
  let cx = node.position.x
  let cy = node.position.y
  let half = node.size.width /. 2.0
  let points =
    float.to_string(cx)
    <> ","
    <> float.to_string(cy -. half)
    <> " "
    <> float.to_string(cx +. half)
    <> ","
    <> float.to_string(cy)
    <> " "
    <> float.to_string(cx)
    <> ","
    <> float.to_string(cy +. half)
    <> " "
    <> float.to_string(cx -. half)
    <> ","
    <> float.to_string(cy)
  svg.polygon([attribute("points", points), attribute("opacity", opacity)])
}

fn owner_pill(node: Node, owner: String, opacity: String) -> Element(msg) {
  let pill_height = 28.0
  let pad = 18.0
  let char_w = 8.0
  let pill_width =
    char_w *. int.to_float(string.length(owner)) +. pad *. 2.0
  let cx = node.position.x
  let pill_x = cx -. pill_width /. 2.0
  let pill_y = node.position.y -. node.size.height /. 2.0 -. pill_height /. 2.0
  svg.g([attribute("class", "owner-pill"), attribute("opacity", opacity)], [
    svg.rect([
      fattr("x", pill_x),
      fattr("y", pill_y),
      fattr("width", pill_width),
      fattr("height", pill_height),
      fattr("rx", pill_height /. 2.0),
      fattr("ry", pill_height /. 2.0),
    ]),
    svg.text(
      [
        fattr("x", cx),
        fattr("y", pill_y +. pill_height /. 2.0 +. 4.0),
        attribute("text-anchor", "middle"),
        attribute("class", "owner-pill-label"),
      ],
      owner,
    ),
  ])
}

fn label_element(node: Node, opacity: String) -> Element(msg) {
  svg.text(
    [
      fattr("x", node.position.x),
      fattr("y", node.position.y +. 5.0),
      attribute("text-anchor", "middle"),
      attribute("dominant-baseline", "middle"),
      attribute("class", "node-label"),
      attribute("opacity", opacity),
    ],
    node.label,
  )
}
