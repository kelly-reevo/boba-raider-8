import atlas.{
  type Atlas, type Graph, type Motion, type NodeId, type StageId, type ViewBox,
}
import atlas/seed
import gleam/option.{type Option, None}
import gleam/set.{type Set}

pub type Crumb {
  Crumb(
    level: atlas.Level,
    parent: Option(NodeId),
    viewbox: ViewBox,
    focused_stage: Option(StageId),
    label: String,
  )
}

pub type Model {
  Model(
    atlas: Atlas,
    stack: List(Crumb),
    current: Graph,
    hovered: Option(NodeId),
    motions: Set(Motion),
    viewbox: ViewBox,
    focused_stage: Option(StageId),
    dragging: Bool,
    drag_moved: Bool,
  )
}

pub fn init() -> Model {
  let a = seed.atlas()
  Model(
    atlas: a,
    stack: [],
    current: a.overview,
    hovered: None,
    motions: set.new(),
    viewbox: a.overview.viewbox,
    focused_stage: None,
    dragging: False,
    drag_moved: False,
  )
}

pub fn motion_active(model: Model, motion: Motion) -> Bool {
  set.contains(model.motions, motion)
}

pub fn motion_match(model: Model, motions: List(Motion)) -> Bool {
  case set.is_empty(model.motions) {
    True -> True
    False ->
      case motions {
        [] -> True
        _ -> list_any_active(motions, model.motions)
      }
  }
}

fn list_any_active(motions: List(Motion), active: Set(Motion)) -> Bool {
  case motions {
    [] -> False
    [m, ..rest] ->
      case set.contains(active, m) {
        True -> True
        False -> list_any_active(rest, active)
      }
  }
}
