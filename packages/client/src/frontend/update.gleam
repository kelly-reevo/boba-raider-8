import atlas.{Activities, Breakdown, Knot, Overview, Stage, ViewBox}
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
    msg.ResetView ->
      Model(
        ..model,
        current: model.atlas.overview,
        viewbox: model.atlas.overview.viewbox,
        stack: [],
        hovered: None,
        focused_stage: None,
        dragging: False,
        drag_moved: False,
      )
    msg.PanStart ->
      case model.current.level {
        Activities -> Model(..model, dragging: True, drag_moved: False)
        _ -> model
      }
    msg.PanMove(dx, dy, svg_w, svg_h) ->
      case model.dragging, model.current.level {
        True, Activities -> apply_pan(model, dx, dy, svg_w, svg_h)
        _, _ -> model
      }
    msg.PanEnd -> Model(..model, dragging: False)
  }
}

fn apply_pan(model: Model, dx: Int, dy: Int, svg_w: Int, svg_h: Int) -> Model {
  case svg_w <= 0 || svg_h <= 0 {
    True -> model
    False -> {
      let canvas_w = 1600.0
      let canvas_h = 900.0
      let canvas_to_px =
        float.min(
          int.to_float(svg_w) /. canvas_w,
          int.to_float(svg_h) /. canvas_h,
        )
      let zoom_scale =
        float.min(
          canvas_w /. model.viewbox.width,
          canvas_h /. model.viewbox.height,
        )
      let px_per_inner = canvas_to_px *. zoom_scale
      let inner_per_px = 1.0 /. px_per_inner
      let new_x = model.viewbox.x -. int.to_float(dx) *. inner_per_px
      let new_y = model.viewbox.y -. int.to_float(dy) *. inner_per_px
      let moved = int.absolute_value(dx) + int.absolute_value(dy) > 3
      Model(
        ..model,
        viewbox: ViewBox(
          x: new_x,
          y: new_y,
          width: model.viewbox.width,
          height: model.viewbox.height,
        ),
        drag_moved: model.drag_moved || moved,
      )
    }
  }
}

fn handle_click(model: Model, id: atlas.NodeId) -> Model {
  case lookup.find_node(model.current, id) {
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
  let focus = seed.focus_viewbox(stage_id)
  let crumb = make_crumb(model)
  Model(
    ..model,
    current: model.atlas.activity_map,
    viewbox: focus,
    stack: [crumb, ..model.stack],
    hovered: None,
    focused_stage: Some(stage_id),
  )
}

fn drill_to_breakdown(model: Model, node: atlas.Node) -> Model {
  case lookup.find_graph(model.atlas, Breakdown, Some(node.id)) {
    Some(graph) -> {
      let crumb = make_crumb(model)
      Model(
        ..model,
        current: graph,
        viewbox: graph.viewbox,
        stack: [crumb, ..model.stack],
        hovered: None,
        focused_stage: None,
      )
    }
    None -> model
  }
}

fn make_crumb(model: Model) -> Crumb {
  Crumb(
    level: model.current.level,
    parent: model.current.parent,
    viewbox: model.viewbox,
    focused_stage: model.focused_stage,
    label: crumb_label(model),
  )
}

fn crumb_label(model: Model) -> String {
  case model.current.level, model.focused_stage {
    Overview, _ -> "Overview"
    Activities, Some(stage) -> atlas.stage_label(stage) <> " activities"
    Activities, None -> "Activities"
    Breakdown, _ -> breakdown_label(model)
  }
}

fn breakdown_label(model: Model) -> String {
  case model.current.parent {
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
  case lookup.find_graph(model.atlas, crumb.level, crumb.parent) {
    Some(graph) ->
      Model(
        ..model,
        current: graph,
        viewbox: crumb.viewbox,
        stack: rest,
        hovered: None,
        focused_stage: crumb.focused_stage,
      )
    None -> model
  }
}
