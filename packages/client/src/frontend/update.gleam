import atlas.{
  type ViewBox, Activities, Activity, Awareness, Breakdown, Knot, Neighbor,
  Overview, Stage, ViewBox,
}
import atlas/lookup
import atlas/seed
import frontend/model.{type Crumb, type Model, Crumb, Model}
import frontend/msg.{type Msg}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/set

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    msg.NodeHovered(id) -> Model(..model, hovered: Some(id))
    msg.NodeUnhovered -> Model(..model, hovered: None)
    msg.NodeClicked(id) ->
      case model.drag_moved {
        True -> Model(..model, drag_moved: False)
        False -> handle_click(model, id)
      }
    msg.BackClicked -> pop_stack(model)
    msg.BreadcrumbClicked(idx) -> jump_to_crumb(model, idx)
    msg.MotionToggled(m) -> {
      let motions = case set.contains(model.motions, m) {
        True -> set.delete(model.motions, m)
        False -> set.insert(model.motions, m)
      }
      Model(..model, motions: motions)
    }
    msg.ClearMotions -> Model(..model, motions: set.new())
    msg.ResetView -> {
      let fresh = model.init()
      Model(
        ..fresh,
        atlas: model.atlas,
        motions: model.motions,
      )
    }
    msg.PanStart -> Model(..model, dragging: True, drag_moved: False)
    msg.PanMove(dx, dy, svg_w, svg_h) ->
      case model.dragging {
        True -> apply_pan(model, dx, dy, svg_w, svg_h)
        False -> model
      }
    msg.PanEnd -> Model(..model, dragging: False)
    msg.WheelScroll(delta, cx, cy) -> handle_wheel(model, delta, cx, cy)
  }
}

// -------- active-layer accessors ----------

pub fn active_viewbox(model: Model) -> ViewBox {
  case model.level {
    Overview -> model.overview_viewbox
    Activities -> model.activities_viewbox
    Breakdown -> model.breakdown_viewbox
  }
}

fn set_active_viewbox(model: Model, vb: ViewBox) -> Model {
  case model.level {
    Overview -> Model(..model, overview_viewbox: vb)
    Activities -> Model(..model, activities_viewbox: vb)
    Breakdown -> Model(..model, breakdown_viewbox: vb)
  }
}

pub fn active_graph(model: Model) -> atlas.Graph {
  case model.level {
    Overview -> model.atlas.overview
    Activities -> model.atlas.activity_map
    Breakdown ->
      case model.active_breakdown {
        Some(id) ->
          case lookup.find_breakdown_graph(model.atlas, id) {
            Some(g) -> g
            None -> model.atlas.overview
          }
        None -> model.atlas.overview
      }
  }
}

// -------- zoom ----------

const min_zoom: Float = 0.6

const max_zoom: Float = 2.5

const max_zoom_activities: Float = 1.7

const zoom_step: Float = 1.15

const zoom_epsilon: Float = 0.01

const canvas_w: Float = 1600.0

const canvas_h: Float = 900.0

fn level_max_zoom(level: atlas.Level) -> Float {
  case level {
    Activities -> max_zoom_activities
    _ -> max_zoom
  }
}

fn base_viewbox(model: Model) -> atlas.ViewBox {
  case model.level, model.focused_stage {
    Activities, Some(stage) -> seed.focus_viewbox(stage)
    _, _ -> active_graph(model).viewbox
  }
}

fn current_zoom_ratio(model: Model) -> Float {
  let base = base_viewbox(model)
  base.width /. active_viewbox(model).width
}

fn handle_wheel(model: Model, delta: Float, cx: Float, cy: Float) -> Model {
  case delta <. 0.0, delta >. 0.0 {
    True, _ -> wheel_zoom_in(model, cx, cy)
    _, True -> wheel_zoom_out(model, cx, cy)
    _, _ -> model
  }
}

fn wheel_zoom_in(model: Model, cx: Float, cy: Float) -> Model {
  let zoom = current_zoom_ratio(model)
  case zoom +. zoom_epsilon >=. level_max_zoom(model.level) {
    True -> try_drill_at(model, cx, cy)
    False -> apply_zoom(model, zoom *. zoom_step, cx, cy)
  }
}

fn wheel_zoom_out(model: Model, cx: Float, cy: Float) -> Model {
  let zoom = current_zoom_ratio(model)
  case zoom -. zoom_epsilon <=. min_zoom {
    True ->
      case model.stack {
        [] -> model
        _ -> pop_stack(model)
      }
    False -> apply_zoom(model, zoom /. zoom_step, cx, cy)
  }
}

fn try_drill_at(model: Model, cx: Float, cy: Float) -> Model {
  case drillable_at_pointer(model, cx, cy) {
    Some(node) -> drill_into(model, node)
    None -> model
  }
}

fn drillable_at_pointer(
  model: Model,
  cx: Float,
  cy: Float,
) -> option.Option(atlas.Node) {
  let graph = active_graph(model)
  let #(ix, iy) = canvas_to_inner(cx, cy, active_viewbox(model))
  let candidates = case model.hovered {
    Some(id) ->
      case lookup.find_node(graph, id) {
        Some(n) ->
          case n.children_level {
            Some(_) -> [n]
            None -> []
          }
        None -> []
      }
    None -> []
  }
  case candidates {
    [n, ..] -> Some(n)
    [] -> first_drillable_at(graph.nodes, ix, iy)
  }
}

fn first_drillable_at(
  nodes: List(atlas.Node),
  ix: Float,
  iy: Float,
) -> option.Option(atlas.Node) {
  case nodes {
    [] -> None
    [n, ..rest] ->
      case n.children_level, point_in_node(n, ix, iy) {
        Some(_), True -> Some(n)
        _, _ -> first_drillable_at(rest, ix, iy)
      }
  }
}

fn point_in_node(node: atlas.Node, ix: Float, iy: Float) -> Bool {
  let half_w = node.size.width /. 2.0
  let half_h = node.size.height /. 2.0
  let dx = ix -. node.position.x
  let dy = iy -. node.position.y
  dx >=. 0.0 -. half_w
  && dx <=. half_w
  && dy >=. 0.0 -. half_h
  && dy <=. half_h
}

fn apply_zoom(
  model: Model,
  target_zoom: Float,
  cx: Float,
  cy: Float,
) -> Model {
  let clamped =
    float.max(
      min_zoom,
      float.min(level_max_zoom(model.level), target_zoom),
    )
  let base = base_viewbox(model)
  let new_w = base.width /. clamped
  let new_h = base.height /. clamped
  let #(ix, iy) = canvas_to_inner(cx, cy, active_viewbox(model))
  let new_s = float.min(canvas_w /. new_w, canvas_h /. new_h)
  let new_x =
    canvas_w /. { 2.0 *. new_s } -. new_w /. 2.0 -. cx /. new_s +. ix
  let new_y =
    canvas_h /. { 2.0 *. new_s } -. new_h /. 2.0 -. cy /. new_s +. iy
  set_active_viewbox(
    model,
    ViewBox(x: new_x, y: new_y, width: new_w, height: new_h),
  )
}

fn canvas_to_inner(
  cx: Float,
  cy: Float,
  vb: atlas.ViewBox,
) -> #(Float, Float) {
  let s = float.min(canvas_w /. vb.width, canvas_h /. vb.height)
  let tx = { canvas_w -. s *. vb.width } /. 2.0 -. vb.x *. s
  let ty = { canvas_h -. s *. vb.height } /. 2.0 -. vb.y *. s
  #({ cx -. tx } /. s, { cy -. ty } /. s)
}

// -------- pan ----------

fn apply_pan(model: Model, dx: Int, dy: Int, svg_w: Int, svg_h: Int) -> Model {
  case svg_w <= 0 || svg_h <= 0 {
    True -> model
    False -> {
      let vb = active_viewbox(model)
      let canvas_to_px =
        float.min(
          int.to_float(svg_w) /. canvas_w,
          int.to_float(svg_h) /. canvas_h,
        )
      let zoom_scale =
        float.min(canvas_w /. vb.width, canvas_h /. vb.height)
      let px_per_inner = canvas_to_px *. zoom_scale
      let inner_per_px = 1.0 /. px_per_inner
      let new_x = vb.x -. int.to_float(dx) *. inner_per_px
      let new_y = vb.y -. int.to_float(dy) *. inner_per_px
      let moved = int.absolute_value(dx) + int.absolute_value(dy) > 3
      Model(
        ..set_active_viewbox(
          model,
          ViewBox(x: new_x, y: new_y, width: vb.width, height: vb.height),
        ),
        drag_moved: model.drag_moved || moved,
      )
    }
  }
}

// -------- navigation ----------

fn handle_click(model: Model, id: atlas.NodeId) -> Model {
  case lookup.find_node(active_graph(model), id) {
    Some(node) -> drill_into(model, node)
    None -> model
  }
}

fn drill_into(model: Model, node: atlas.Node) -> Model {
  case node.children_level, node.kind {
    Some(Activities), Stage(stage_id) -> drill_to_stage(model, node, stage_id)
    Some(Activities), Knot(stage_id) -> drill_to_stage(model, node, stage_id)
    Some(Breakdown), _ -> drill_to_breakdown(model, node)
    _, _ -> model
  }
}

fn drill_to_stage(
  model: Model,
  _node: atlas.Node,
  stage_id: atlas.StageId,
) -> Model {
  let crumb = make_crumb(model)
  Model(
    ..model,
    level: Activities,
    activities_viewbox: seed.focus_viewbox(stage_id),
    focused_stage: Some(stage_id),
    stack: [crumb, ..model.stack],
    hovered: None,
  )
}

fn drill_to_breakdown(model: Model, node: atlas.Node) -> Model {
  case lookup.find_breakdown_graph(model.atlas, node.id) {
    Some(graph) -> {
      let stage = stage_for_node(model, node)
      let #(stack, activities_vb, focused) = case model.level {
        Breakdown -> #(
          [
            activities_crumb_for(stage),
            ..list.drop(model.stack, 1)
          ],
          seed.focus_viewbox(stage),
          Some(stage),
        )
        _ -> #([make_crumb(model), ..model.stack], model.activities_viewbox, model.focused_stage)
      }
      Model(
        ..model,
        level: Breakdown,
        active_breakdown: Some(node.id),
        breakdown_viewbox: graph.viewbox,
        activities_viewbox: activities_vb,
        focused_stage: focused,
        stack: stack,
        hovered: None,
      )
    }
    None -> model
  }
}

fn activities_crumb_for(stage: atlas.StageId) -> Crumb {
  Crumb(
    level: Activities,
    active_breakdown: None,
    focused_stage: Some(stage),
    label: atlas.stage_label(stage) <> " activities",
  )
}

fn stage_for_node(model: Model, node: atlas.Node) -> atlas.StageId {
  case lookup.find_node(model.atlas.activity_map, node.id) {
    Some(act) ->
      case act.kind {
        Activity(s) -> s
        _ -> stage_from_kind(node.kind)
      }
    None -> stage_from_kind(node.kind)
  }
}

fn stage_from_kind(kind: atlas.NodeKind) -> atlas.StageId {
  case kind {
    Neighbor(stage: s, ..) -> s
    Activity(s) -> s
    Stage(s) -> s
    Knot(s) -> s
    _ -> Awareness
  }
}

fn make_crumb(model: Model) -> Crumb {
  Crumb(
    level: model.level,
    active_breakdown: model.active_breakdown,
    focused_stage: model.focused_stage,
    label: crumb_label(model),
  )
}

fn crumb_label(model: Model) -> String {
  case model.level, model.focused_stage {
    Overview, _ -> "Overview"
    Activities, Some(stage) -> atlas.stage_label(stage) <> " activities"
    Activities, None -> "Activities"
    Breakdown, _ -> breakdown_label(model)
  }
}

fn breakdown_label(model: Model) -> String {
  case model.active_breakdown {
    Some(parent_id) ->
      case lookup.find_node(model.atlas.activity_map, parent_id) {
        Some(n) -> n.label
        None -> "Breakdown"
      }
    None -> "Breakdown"
  }
}

fn pop_stack(model: Model) -> Model {
  case model.stack {
    [] -> model
    [head, ..rest] -> restore_from_crumb(model, head, rest)
  }
}

fn jump_to_crumb(model: Model, idx: Int) -> Model {
  let dropped = list.drop(model.stack, idx)
  case dropped {
    [] -> model
    [head, ..rest] -> restore_from_crumb(model, head, rest)
  }
}

fn restore_from_crumb(
  model: Model,
  crumb: Crumb,
  rest: List(Crumb),
) -> Model {
  Model(
    ..model,
    level: crumb.level,
    active_breakdown: crumb.active_breakdown,
    focused_stage: crumb.focused_stage,
    stack: rest,
    hovered: None,
  )
}
