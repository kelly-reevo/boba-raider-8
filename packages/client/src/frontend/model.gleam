import atlas.{
  type Atlas, type Motion, type MotionAtlas, type NodeId, type OpportunityId,
  type StageId, type ViewBox, HighTouch, ViewBox,
}
import atlas/lookup
import atlas/seed
import gleam/option.{type Option, None}

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
    motion: Motion,
    level: atlas.Level,
    overview_viewbox: ViewBox,
    activities_viewbox: ViewBox,
    active_breakdown: Option(NodeId),
    breakdown_viewbox: ViewBox,
    stack: List(Crumb),
    hovered: Option(NodeId),
    focused_stage: Option(StageId),
    selected_opportunity: Option(OpportunityId),
    dragging: Bool,
    drag_moved: Bool,
  )
}

pub fn init() -> Model {
  let a = seed.atlas()
  let motion = HighTouch
  let ma = lookup.motion_atlas(a, motion)
  Model(
    atlas: a,
    motion: motion,
    level: atlas.Overview,
    overview_viewbox: a.overview.viewbox,
    activities_viewbox: ma.activity_map.viewbox,
    active_breakdown: None,
    breakdown_viewbox: ViewBox(-300.0, 0.0, 1800.0, 720.0),
    stack: [],
    hovered: None,
    focused_stage: None,
    selected_opportunity: None,
    dragging: False,
    drag_moved: False,
  )
}

pub fn active_motion_atlas(model: Model) -> MotionAtlas {
  lookup.motion_atlas(model.atlas, model.motion)
}
