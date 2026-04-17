import atlas.{
  type Atlas, type Edge, type Graph, type Motion, type Node, type NodeId,
  type StageBand, type StageId, type ViewBox, Activities, Activity, Atlas,
  Awareness, Adoption, Breakdown, Commitment, Edge, Education, Expansion,
  Feedback, Flow, Graph, Handoff, HighTouch, Knot, LowTouch, MediumTouch,
  NoTouch, Node, NodeId, Onboarding, Overview, Point, Selection, Size, Stage,
  StageBand, Task, ViewBox,
}
import gleam/option.{None, Some}

pub fn atlas() -> Atlas {
  Atlas(
    overview: overview_graph(),
    activity_map: activity_map(),
    breakdowns: [
      #(NodeId("aw_web_ads"), web_ads_breakdown()),
      #(NodeId("ed_inbound"), inbound_breakdown()),
      #(NodeId("sel_demo"), demo_breakdown()),
      #(NodeId("com_contract"), contract_breakdown()),
      #(NodeId("onb_guided"), guided_onboarding_breakdown()),
      #(NodeId("adp_csm"), csm_breakdown()),
      #(NodeId("exp_renewal"), renewal_breakdown()),
    ],
  )
}

// -------- Level 1: Overview (bowtie) ----------

fn overview_graph() -> Graph {
  Graph(
    level: Overview,
    parent: None,
    bands: [],
    viewbox: ViewBox(0.0, 0.0, 1600.0, 900.0),
    nodes: [
      stage_rect("awareness", "Awareness", Awareness, 160.0),
      stage_rect("education", "Education", Education, 380.0),
      stage_rect("selection", "Selection", Selection, 600.0),
      knot_diamond("commitment", "Commitment", Commitment, 800.0),
      stage_rect("onboarding", "Onboarding", Onboarding, 1000.0),
      stage_rect("adoption", "Adoption", Adoption, 1220.0),
      stage_rect("expansion", "Expansion", Expansion, 1440.0),
    ],
    edges: [
      flow("awareness", "education", ""),
      flow("education", "selection", ""),
      flow("selection", "commitment", ""),
      flow("commitment", "onboarding", ""),
      flow("onboarding", "adoption", ""),
      flow("adoption", "expansion", ""),
    ],
  )
}

fn stage_rect(id: String, label: String, stage: StageId, x: Float) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Stage(stage),
    position: Point(x, 450.0),
    size: Size(200.0, 80.0),
    motions: [],
    parent: None,
    children_level: Some(Activities),
    notes: "",
  )
}

fn knot_diamond(id: String, label: String, stage: StageId, x: Float) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Knot(stage),
    position: Point(x, 450.0),
    size: Size(140.0, 140.0),
    motions: [],
    parent: None,
    children_level: Some(Activities),
    notes: "",
  )
}

// -------- Level 2: Unified activity map ----------

pub fn stage_bands() -> List(StageBand) {
  [
    StageBand(stage: Awareness, x: 60.0, width: 420.0, label: "Awareness"),
    StageBand(stage: Education, x: 480.0, width: 420.0, label: "Education"),
    StageBand(stage: Selection, x: 900.0, width: 420.0, label: "Selection"),
    StageBand(stage: Commitment, x: 1320.0, width: 280.0, label: "Commitment"),
    StageBand(stage: Onboarding, x: 1600.0, width: 420.0, label: "Onboarding"),
    StageBand(stage: Adoption, x: 2020.0, width: 420.0, label: "Adoption"),
    StageBand(stage: Expansion, x: 2440.0, width: 420.0, label: "Expansion"),
  ]
}

fn activity_map() -> Graph {
  Graph(
    level: Activities,
    parent: None,
    bands: stage_bands(),
    viewbox: ViewBox(0.0, 0.0, 2920.0, 1400.0),
    nodes: activity_nodes(),
    edges: activity_edges(),
  )
}

fn activity_nodes() -> List(Node) {
  [
    // Awareness (center x 270)
    activity("aw_web_ads", "Web advertising", Awareness, 270.0, 380.0,
      [HighTouch, MediumTouch, LowTouch], True),
    activity("aw_content", "Content marketing", Awareness, 270.0, 540.0,
      [NoTouch, LowTouch], False),
    activity("aw_outbound", "Outbound SDR", Awareness, 270.0, 700.0,
      [MediumTouch, HighTouch], False),
    activity("aw_partners", "Partner referrals", Awareness, 270.0, 860.0,
      [HighTouch], False),
    activity("aw_events", "Events & conferences", Awareness, 270.0, 1020.0,
      [HighTouch], False),

    // Education (center x 690)
    activity("ed_inbound", "Inbound web traffic", Education, 690.0, 380.0,
      [NoTouch, LowTouch], True),
    activity("ed_webinars", "Product webinars", Education, 690.0, 540.0,
      [LowTouch, MediumTouch], False),
    activity("ed_whitepapers", "Whitepaper downloads", Education, 690.0, 700.0,
      [NoTouch, LowTouch], False),
    activity("ed_sdr_qual", "SDR qualification", Education, 690.0, 860.0,
      [MediumTouch, HighTouch], False),
    activity("ed_case_studies", "Case study library", Education, 690.0, 1020.0,
      [LowTouch], False),

    // Selection (center x 1110)
    activity("sel_self_trial", "Self-serve trial", Selection, 1110.0, 380.0,
      [NoTouch, LowTouch], False),
    activity("sel_demo", "Live demo", Selection, 1110.0, 540.0, [MediumTouch,
      HighTouch], True),
    activity("sel_poc", "POC / pilot", Selection, 1110.0, 700.0, [HighTouch],
      False),
    activity("sel_rfp", "RFP response", Selection, 1110.0, 860.0, [HighTouch],
      False),
    activity("sel_security", "Security review", Selection, 1110.0, 1020.0,
      [MediumTouch, HighTouch], False),

    // Commitment (knot, center x 1460, narrower)
    activity_narrow("com_negotiate", "Price negotiation", Commitment, 1460.0,
      500.0, [MediumTouch, HighTouch], False),
    activity_narrow("com_contract", "Contract negotiation", Commitment, 1460.0,
      640.0, [MediumTouch, HighTouch], True),
    activity_narrow("com_procurement", "Procurement & legal", Commitment,
      1460.0, 780.0, [HighTouch], False),
    activity_narrow("com_signature", "Order form signature", Commitment,
      1460.0, 920.0, [NoTouch, LowTouch, MediumTouch, HighTouch], False),

    // Onboarding (center x 1810)
    activity("onb_self", "Self-serve setup", Onboarding, 1810.0, 500.0,
      [NoTouch, LowTouch], False),
    activity("onb_guided", "Guided onboarding", Onboarding, 1810.0, 660.0,
      [LowTouch, MediumTouch], True),
    activity("onb_impl", "Dedicated implementation", Onboarding, 1810.0, 820.0,
      [HighTouch], False),
    activity("onb_kickoff", "Kickoff meeting", Onboarding, 1810.0, 980.0,
      [MediumTouch, HighTouch], False),

    // Adoption (center x 2230)
    activity("adp_nudges", "In-app nudges", Adoption, 2230.0, 380.0, [NoTouch,
      LowTouch], False),
    activity("adp_training", "Product training", Adoption, 2230.0, 540.0,
      [LowTouch, MediumTouch], False),
    activity("adp_csm", "CSM check-ins", Adoption, 2230.0, 700.0, [MediumTouch,
      HighTouch], True),
    activity("adp_health", "Health score monitoring", Adoption, 2230.0, 860.0,
      [NoTouch, LowTouch, MediumTouch, HighTouch], False),
    activity("adp_community", "Customer community", Adoption, 2230.0, 1020.0,
      [NoTouch, LowTouch], False),

    // Expansion (center x 2650)
    activity("exp_usage", "Usage-based upsell", Expansion, 2650.0, 500.0,
      [NoTouch, LowTouch], False),
    activity("exp_crosssell", "Cross-sell new teams", Expansion, 2650.0, 660.0,
      [MediumTouch, HighTouch], False),
    activity("exp_renewal", "Renewal", Expansion, 2650.0, 820.0, [NoTouch,
      LowTouch, MediumTouch, HighTouch], True),
    activity("exp_qbr", "Strategic business review", Expansion, 2650.0, 980.0,
      [HighTouch], False),
  ]
}

fn activity_edges() -> List(Edge) {
  [
    // Awareness → Education
    flow("aw_web_ads", "ed_inbound", ""),
    flow("aw_content", "ed_inbound", ""),
    flow("aw_outbound", "ed_sdr_qual", ""),
    flow("aw_partners", "ed_sdr_qual", ""),
    flow("aw_events", "ed_whitepapers", ""),
    // intra-Awareness
    flow("aw_content", "aw_outbound", ""),

    // Education → Selection
    flow("ed_inbound", "sel_self_trial", ""),
    flow("ed_inbound", "sel_demo", ""),
    flow("ed_webinars", "sel_demo", ""),
    flow("ed_sdr_qual", "sel_demo", ""),
    flow("ed_sdr_qual", "sel_poc", ""),
    flow("ed_whitepapers", "sel_rfp", ""),
    flow("ed_case_studies", "sel_demo", ""),
    // intra-Education
    flow("ed_sdr_qual", "ed_case_studies", ""),

    // Selection → Commitment
    flow("sel_self_trial", "com_signature", ""),
    flow("sel_demo", "com_negotiate", ""),
    flow("sel_demo", "com_contract", ""),
    flow("sel_poc", "com_contract", ""),
    flow("sel_rfp", "com_contract", ""),
    flow("sel_security", "com_procurement", ""),
    // intra-Selection
    flow("sel_self_trial", "sel_demo", ""),

    // Commitment → Onboarding (the knot handoff)
    handoff("com_signature", "onb_self", ""),
    handoff("com_contract", "onb_guided", ""),
    handoff("com_contract", "onb_impl", ""),
    handoff("com_procurement", "onb_kickoff", ""),

    // Onboarding → Adoption
    flow("onb_self", "adp_nudges", ""),
    flow("onb_guided", "adp_training", ""),
    flow("onb_guided", "adp_csm", ""),
    flow("onb_impl", "adp_csm", ""),
    flow("onb_kickoff", "adp_csm", ""),
    // intra-Onboarding
    flow("onb_kickoff", "onb_guided", ""),

    // Adoption → Expansion
    flow("adp_nudges", "exp_usage", ""),
    flow("adp_training", "exp_crosssell", ""),
    flow("adp_csm", "exp_qbr", ""),
    flow("adp_csm", "exp_renewal", ""),
    flow("adp_health", "exp_renewal", ""),
    flow("adp_community", "exp_renewal", ""),
    // intra-Adoption
    flow("adp_csm", "adp_health", ""),
  ]
}

fn activity(
  id: String,
  label: String,
  stage: StageId,
  x: Float,
  y: Float,
  motions: List(Motion),
  drillable: Bool,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Activity(stage),
    position: Point(x, y),
    size: Size(340.0, 82.0),
    motions: motions,
    parent: None,
    children_level: case drillable {
      True -> Some(Breakdown)
      False -> None
    },
    notes: "",
  )
}

fn activity_narrow(
  id: String,
  label: String,
  stage: StageId,
  x: Float,
  y: Float,
  motions: List(Motion),
  drillable: Bool,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Activity(stage),
    position: Point(x, y),
    size: Size(240.0, 76.0),
    motions: motions,
    parent: None,
    children_level: case drillable {
      True -> Some(Breakdown)
      False -> None
    },
    notes: "",
  )
}

// -------- Level 3: Breakdown swimlanes ----------

fn breakdown_graph(parent: NodeId, nodes: List(Node), edges: List(Edge)) -> Graph {
  Graph(
    level: Breakdown,
    parent: Some(parent),
    bands: [],
    viewbox: ViewBox(0.0, 0.0, 1200.0, 720.0),
    nodes: nodes,
    edges: edges,
  )
}

fn web_ads_breakdown() -> Graph {
  let parent = NodeId("aw_web_ads")
  let nodes = [
    task("awb_impression", "Ad impression served", "Ad platform", parent,
      260.0, 220.0, [HighTouch, MediumTouch, LowTouch]),
    task("awb_click", "Click landing page", "Prospect", parent, 660.0, 220.0,
      [HighTouch, MediumTouch, LowTouch]),
    task("awb_form", "Fills demo form", "Prospect", parent, 660.0, 440.0,
      [HighTouch, MediumTouch]),
    task("awb_lead", "Lead created in CRM", "CRM", parent, 1060.0, 440.0,
      [HighTouch, MediumTouch]),
  ]
  let edges = [
    edge("awb_e1", "awb_impression", "awb_click", "", Flow, []),
    edge("awb_e2", "awb_click", "awb_form", "", Flow, []),
    edge("awb_e3", "awb_form", "awb_lead", "submit", Flow, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn inbound_breakdown() -> Graph {
  let parent = NodeId("ed_inbound")
  let nodes = [
    task("edi_search", "Google search", "Prospect", parent, 260.0, 220.0,
      [NoTouch, LowTouch]),
    task("edi_page", "Reads product page", "Marketing site", parent, 660.0,
      220.0, [NoTouch, LowTouch]),
    task("edi_download", "Downloads whitepaper", "Prospect", parent, 660.0,
      440.0, [LowTouch]),
    task("edi_nurture", "Enrolled in nurture", "Email sequence", parent,
      1060.0, 440.0, [LowTouch]),
  ]
  let edges = [
    edge("edi_e1", "edi_search", "edi_page", "", Flow, []),
    edge("edi_e2", "edi_page", "edi_download", "", Flow, []),
    edge("edi_e3", "edi_download", "edi_nurture", "", Flow, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn demo_breakdown() -> Graph {
  let parent = NodeId("sel_demo")
  let nodes = [
    task("seld_book", "Books demo slot", "Prospect", parent, 260.0, 220.0,
      [MediumTouch, HighTouch]),
    task("seld_demo", "Holds live demo", "Account Executive", parent, 660.0,
      220.0, [MediumTouch, HighTouch]),
    task("seld_spiced", "Qualify w/ SPICED", "Account Executive", parent,
      1060.0, 220.0, [MediumTouch, HighTouch]),
    task("seld_proposal", "Send proposal", "Account Executive", parent, 1060.0,
      440.0, [MediumTouch, HighTouch]),
  ]
  let edges = [
    edge("seld_e1", "seld_book", "seld_demo", "", Flow, []),
    edge("seld_e2", "seld_demo", "seld_spiced", "", Flow, []),
    edge("seld_e3", "seld_spiced", "seld_proposal", "", Flow, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn contract_breakdown() -> Graph {
  let parent = NodeId("com_contract")
  let nodes = [
    task("comc_msa", "Send MSA draft", "Account Executive", parent, 260.0,
      220.0, [MediumTouch, HighTouch]),
    task("comc_redline", "Redline review", "Legal", parent, 660.0, 220.0,
      [HighTouch]),
    task("comc_agree", "Terms agreed", "Account Executive", parent, 1060.0,
      220.0, [MediumTouch, HighTouch]),
    task("comc_sign", "e-signature collected", "Contract system", parent,
      1060.0, 440.0, [NoTouch, LowTouch, MediumTouch, HighTouch]),
  ]
  let edges = [
    edge("comc_e1", "comc_msa", "comc_redline", "", Flow, []),
    edge("comc_e2", "comc_redline", "comc_agree", "", Flow, []),
    edge("comc_e3", "comc_agree", "comc_sign", "", Flow, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn guided_onboarding_breakdown() -> Graph {
  let parent = NodeId("onb_guided")
  let nodes = [
    task("onbg_welcome", "Welcome email", "CSM", parent, 260.0, 220.0,
      [LowTouch, MediumTouch]),
    task("onbg_kickoff", "Kickoff call", "CSM", parent, 660.0, 220.0,
      [MediumTouch]),
    task("onbg_setup", "Workspace setup", "Customer champion", parent, 660.0,
      440.0, [LowTouch, MediumTouch]),
    task("onbg_firstvalue", "First value moment", "Product app", parent,
      1060.0, 220.0, [LowTouch, MediumTouch]),
    task("onbg_handoff", "Handoff to success", "CSM", parent, 1060.0, 440.0,
      [MediumTouch]),
  ]
  let edges = [
    edge("onbg_e1", "onbg_welcome", "onbg_kickoff", "", Flow, []),
    edge("onbg_e2", "onbg_kickoff", "onbg_setup", "", Flow, []),
    edge("onbg_e3", "onbg_setup", "onbg_firstvalue", "", Flow, []),
    edge("onbg_e4", "onbg_firstvalue", "onbg_handoff", "", Handoff, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn csm_breakdown() -> Graph {
  let parent = NodeId("adp_csm")
  let nodes = [
    task("adpc_review", "Review health score", "CSM", parent, 260.0, 220.0,
      [MediumTouch, HighTouch]),
    task("adpc_call", "Monthly check-in call", "CSM", parent, 660.0, 220.0,
      [MediumTouch, HighTouch]),
    task("adpc_action", "Log action items", "Customer champion", parent,
      1060.0, 220.0, [MediumTouch, HighTouch]),
    task("adpc_followup", "Follow-up tickets", "CSM", parent, 1060.0, 440.0,
      [MediumTouch, HighTouch]),
  ]
  let edges = [
    edge("adpc_e1", "adpc_review", "adpc_call", "", Flow, []),
    edge("adpc_e2", "adpc_call", "adpc_action", "", Flow, []),
    edge("adpc_e3", "adpc_action", "adpc_followup", "", Flow, []),
    edge("adpc_e4", "adpc_followup", "adpc_review", "loop", Feedback, []),
  ]
  breakdown_graph(parent, nodes, edges)
}

fn renewal_breakdown() -> Graph {
  let parent = NodeId("exp_renewal")
  let nodes = [
    task("expr_notice", "Renewal 90d notice", "CRM", parent, 260.0, 220.0,
      [NoTouch, LowTouch, MediumTouch, HighTouch]),
    task("expr_value", "Value recap", "CSM / AM", parent, 660.0, 220.0,
      [MediumTouch, HighTouch]),
    task("expr_terms", "Confirm terms", "CSM / AM", parent, 660.0, 440.0,
      [MediumTouch, HighTouch]),
    task("expr_auto", "Auto-renew fire", "Billing system", parent, 1060.0,
      220.0, [NoTouch, LowTouch]),
    task("expr_sign", "Renewal signed", "Customer champion", parent, 1060.0,
      440.0, [NoTouch, LowTouch, MediumTouch, HighTouch]),
  ]
  let edges = [
    edge("expr_e1", "expr_notice", "expr_value", "", Flow, [MediumTouch,
      HighTouch]),
    edge("expr_e2", "expr_value", "expr_terms", "", Flow, [MediumTouch,
      HighTouch]),
    edge("expr_e3", "expr_terms", "expr_sign", "", Flow, [MediumTouch,
      HighTouch]),
    edge("expr_e4", "expr_notice", "expr_auto", "", Flow, [NoTouch, LowTouch]),
    edge("expr_e5", "expr_auto", "expr_sign", "", Flow, [NoTouch, LowTouch]),
  ]
  breakdown_graph(parent, nodes, edges)
}

// -------- node / edge helpers ----------

fn task(
  id: String,
  label: String,
  owner: String,
  parent: NodeId,
  x: Float,
  y: Float,
  motions: List(Motion),
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Task(owner: owner),
    position: Point(x, y),
    size: Size(300.0, 110.0),
    motions: motions,
    parent: Some(parent),
    children_level: None,
    notes: "",
  )
}

fn flow(from: String, to: String, label: String) -> Edge {
  edge(from <> "_to_" <> to, from, to, label, Flow, [])
}

fn handoff(from: String, to: String, label: String) -> Edge {
  edge(from <> "_to_" <> to, from, to, label, Handoff, [])
}

fn edge(
  id: String,
  from: String,
  to: String,
  label: String,
  kind: atlas.EdgeKind,
  motions: List(Motion),
) -> Edge {
  Edge(
    id: id,
    from: NodeId(from),
    to: NodeId(to),
    label: label,
    kind: kind,
    motions: motions,
  )
}

pub fn focus_viewbox(stage: StageId) -> ViewBox {
  let band = case stage {
    Awareness -> StageBand(stage: Awareness, x: 60.0, width: 420.0, label: "")
    Education -> StageBand(stage: Education, x: 480.0, width: 420.0, label: "")
    Selection -> StageBand(stage: Selection, x: 900.0, width: 420.0, label: "")
    Commitment ->
      StageBand(stage: Commitment, x: 1320.0, width: 280.0, label: "")
    Onboarding ->
      StageBand(stage: Onboarding, x: 1600.0, width: 420.0, label: "")
    Adoption -> StageBand(stage: Adoption, x: 2020.0, width: 420.0, label: "")
    Expansion -> StageBand(stage: Expansion, x: 2440.0, width: 420.0, label: "")
  }
  let pad = 260.0
  ViewBox(
    x: band.x -. pad,
    y: 200.0,
    width: band.width +. { pad *. 2.0 },
    height: 1000.0,
  )
}
