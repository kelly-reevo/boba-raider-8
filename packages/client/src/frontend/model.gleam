import atlas.{
  type Atlas, type Motion, type NodeId, type OpportunityId, type StageId,
  type ViewBox, ViewBox,
}
import atlas/seed
import gleam/option.{type Option, None}
import gleam/set.{type Set}

pub type Crumb {
  Crumb(
    level: atlas.Level,
    active_breakdown: Option(NodeId),
    focused_stage: Option(StageId),
    label: String,
  )
}

pub type Model {
  Model(
    atlas: Atlas,
    level: atlas.Level,
    overview_viewbox: ViewBox,
    activities_viewbox: ViewBox,
    active_breakdown: Option(NodeId),
    breakdown_viewbox: ViewBox,
    stack: List(Crumb),
    hovered: Option(NodeId),
    motions: Set(Motion),
    focused_stage: Option(StageId),
    selected_opportunity: Option(OpportunityId),
    dragging: Bool,
    drag_moved: Bool,
  )
}

pub fn init() -> Model {
  let a = seed.atlas()
  Model(
    atlas: a,
    level: atlas.Overview,
    overview_viewbox: a.overview.viewbox,
    activities_viewbox: a.activity_map.viewbox,
    active_breakdown: None,
    breakdown_viewbox: ViewBox(-300.0, 0.0, 1800.0, 720.0),
    stack: [],
    hovered: None,
    motions: set.new(),
    focused_stage: None,
    selected_opportunity: None,
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
