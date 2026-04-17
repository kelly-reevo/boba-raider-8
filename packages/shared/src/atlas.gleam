import gleam/option.{type Option}

pub type Motion {
  NoTouch
  LowTouch
  MediumTouch
  HighTouch
}

pub type Level {
  Overview
  Activities
  Breakdown
}

pub type StageId {
  Awareness
  Education
  Selection
  Commitment
  Onboarding
  Adoption
  Expansion
}

pub type NodeId {
  NodeId(String)
}

pub type Point {
  Point(x: Float, y: Float)
}

pub type Size {
  Size(width: Float, height: Float)
}

pub type ViewBox {
  ViewBox(x: Float, y: Float, width: Float, height: Float)
}

pub type StageBand {
  StageBand(stage: StageId, x: Float, width: Float, label: String)
}

pub type Direction {
  Inbound
  Outbound
}

pub type NodeKind {
  Stage(StageId)
  Knot(StageId)
  Activity(StageId)
  Task(owner: String)
  Neighbor(stage: StageId, direction: Direction)
}

pub type Node {
  Node(
    id: NodeId,
    label: String,
    kind: NodeKind,
    position: Point,
    size: Size,
    motions: List(Motion),
    parent: Option(NodeId),
    children_level: Option(Level),
    notes: String,
  )
}

pub type EdgeKind {
  Flow
  Feedback
  Handoff
}

pub type Edge {
  Edge(
    id: String,
    from: NodeId,
    to: NodeId,
    label: String,
    kind: EdgeKind,
    motions: List(Motion),
  )
}

pub type Graph {
  Graph(
    level: Level,
    parent: Option(NodeId),
    nodes: List(Node),
    edges: List(Edge),
    viewbox: ViewBox,
    bands: List(StageBand),
  )
}

pub type Atlas {
  Atlas(
    overview: Graph,
    activity_map: Graph,
    breakdowns: List(#(NodeId, Graph)),
    opportunities: List(Opportunity),
  )
}

pub type OpportunityId {
  OpportunityId(String)
}

pub type OpportunityVisit {
  OpportunityVisit(node_id: NodeId, date: String)
}

pub type Opportunity {
  Opportunity(
    id: OpportunityId,
    name: String,
    current_stage: StageId,
    visits: List(OpportunityVisit),
  )
}

pub fn motion_label(motion: Motion) -> String {
  case motion {
    NoTouch -> "No Touch"
    LowTouch -> "Low Touch"
    MediumTouch -> "Medium Touch"
    HighTouch -> "High Touch"
  }
}

pub fn stage_label(stage: StageId) -> String {
  case stage {
    Awareness -> "Awareness"
    Education -> "Education"
    Selection -> "Selection"
    Commitment -> "Commitment"
    Onboarding -> "Onboarding"
    Adoption -> "Adoption"
    Expansion -> "Expansion"
  }
}

pub fn level_label(level: Level) -> String {
  case level {
    Overview -> "Overview"
    Activities -> "Activities"
    Breakdown -> "Breakdown"
  }
}

pub fn stage_is_post_sale(stage: StageId) -> Bool {
  case stage {
    Onboarding -> True
    Adoption -> True
    Expansion -> True
    _ -> False
  }
}
