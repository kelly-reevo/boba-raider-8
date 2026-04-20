import gleam/option.{type Option}

pub type Motion {
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
  Edge(id: String, from: NodeId, to: NodeId, label: String, kind: EdgeKind)
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
    motion: Motion,
    current_stage: StageId,
    visits: List(OpportunityVisit),
  )
}

pub type MotionAtlas {
  MotionAtlas(
    activity_map: Graph,
    breakdowns: List(#(NodeId, Graph)),
    opportunities: List(Opportunity),
  )
}

pub type Atlas {
  Atlas(overview: Graph, motion_atlases: List(#(Motion, MotionAtlas)))
}

pub fn motion_label(motion: Motion) -> String {
  case motion {
    LowTouch -> "Low Touch"
    MediumTouch -> "Medium Touch"
    HighTouch -> "High Touch"
  }
}

pub fn motion_subtitle(motion: Motion) -> String {
  case motion {
    HighTouch -> "Human-led growth · enterprise"
    MediumTouch -> "AI-led growth · mid-market"
    LowTouch -> "Product-led growth · self-serve"
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
