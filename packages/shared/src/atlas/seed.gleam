import atlas.{
  type Atlas, type Edge, type Graph, type Motion, type Node, type NodeId,
  type Opportunity, type OpportunityVisit, type StageBand, type StageId,
  type ViewBox, Activities, Activity, Atlas, Awareness, Adoption, Breakdown,
  Commitment, Edge, Education, Expansion, Feedback, Flow, Graph, Handoff,
  HighTouch, Inbound, Knot, LowTouch, MediumTouch, Neighbor, NoTouch, Node,
  NodeId, Onboarding, Opportunity, OpportunityId, OpportunityVisit, Outbound,
  Overview, Point, Selection, Size, Stage, StageBand, Task, ViewBox,
}
import gleam/int
import gleam/list
import gleam/option.{None, Some}

pub fn atlas() -> Atlas {
  let custom = custom_breakdowns()
  let breakdowns =
    list.map(activity_nodes(), fn(n: Node) {
      let graph = case list.key_find(custom, n.id) {
        Ok(g) -> g
        Error(_) -> stub_breakdown(n.id, n.label)
      }
      #(n.id, graph)
    })
  Atlas(
    overview: overview_graph(),
    activity_map: activity_map(),
    breakdowns: breakdowns,
    opportunities: opportunities(),
  )
}

pub fn opportunities() -> List(Opportunity) {
  [
    Opportunity(
      id: OpportunityId("opp-umbrella"),
      name: "Umbrella Labs",
      current_stage: Awareness,
      visits: [visit("aw_events", "2026-04-02")],
    ),
    Opportunity(
      id: OpportunityId("opp-wayne"),
      name: "Wayne Enterprises",
      current_stage: Education,
      visits: [
        visit("aw_content", "2026-02-18"),
        visit("aw_outbound", "2026-03-02"),
        visit("ed_sdr_qual", "2026-03-20"),
        visit("ed_case_studies", "2026-04-05"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-acme"),
      name: "Acme Corp",
      current_stage: Selection,
      visits: [
        visit("aw_web_ads", "2026-01-08"),
        visit("awb_impression", "2026-01-08"),
        visit("awb_click", "2026-01-09"),
        visit("awb_form", "2026-01-10"),
        visit("awb_lead", "2026-01-10"),
        visit("ed_inbound", "2026-01-12"),
        visit("edi_search", "2026-01-12"),
        visit("edi_page", "2026-01-13"),
        visit("edi_download", "2026-01-15"),
        visit("edi_nurture", "2026-01-15"),
        visit("sel_demo", "2026-01-22"),
        visit("seld_book", "2026-01-22"),
        visit("seld_demo", "2026-01-28"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-globex"),
      name: "Globex Industries",
      current_stage: Commitment,
      visits: [
        visit("aw_partners", "2025-11-05"),
        visit("ed_sdr_qual", "2025-11-20"),
        visit("sel_poc", "2025-12-10"),
        visit("sel_demo", "2025-12-18"),
        visit("seld_book", "2025-12-18"),
        visit("seld_demo", "2025-12-22"),
        visit("seld_spiced", "2026-01-05"),
        visit("seld_proposal", "2026-01-12"),
        visit("com_contract", "2026-01-25"),
        visit("comc_msa", "2026-01-25"),
        visit("comc_redline", "2026-02-05"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-initech"),
      name: "Initech Solutions",
      current_stage: Onboarding,
      visits: [
        visit("aw_outbound", "2025-09-15"),
        visit("ed_sdr_qual", "2025-10-01"),
        visit("ed_case_studies", "2025-10-18"),
        visit("sel_demo", "2025-11-04"),
        visit("seld_book", "2025-11-04"),
        visit("seld_demo", "2025-11-10"),
        visit("seld_spiced", "2025-11-20"),
        visit("seld_proposal", "2025-12-02"),
        visit("com_contract", "2025-12-15"),
        visit("comc_msa", "2025-12-15"),
        visit("comc_redline", "2026-01-08"),
        visit("comc_agree", "2026-01-22"),
        visit("comc_sign", "2026-01-30"),
        visit("onb_guided", "2026-02-05"),
        visit("onbg_welcome", "2026-02-05"),
        visit("onbg_kickoff", "2026-02-12"),
        visit("onbg_setup", "2026-02-20"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-soylent"),
      name: "Soylent Dynamics",
      current_stage: Adoption,
      visits: [
        visit("aw_web_ads", "2025-06-10"),
        visit("awb_impression", "2025-06-10"),
        visit("awb_click", "2025-06-11"),
        visit("awb_form", "2025-06-12"),
        visit("awb_lead", "2025-06-12"),
        visit("ed_inbound", "2025-06-20"),
        visit("sel_self_trial", "2025-07-05"),
        visit("com_signature", "2025-07-25"),
        visit("onb_self", "2025-07-28"),
        visit("adp_nudges", "2025-08-15"),
        visit("adp_training", "2025-09-10"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-tyrell"),
      name: "Tyrell Systems",
      current_stage: Adoption,
      visits: [
        visit("aw_partners", "2025-08-04"),
        visit("ed_sdr_qual", "2025-08-20"),
        visit("sel_rfp", "2025-09-12"),
        visit("sel_security", "2025-10-01"),
        visit("com_procurement", "2025-10-25"),
        visit("onb_kickoff", "2025-11-10"),
        visit("adp_csm", "2025-12-05"),
        visit("adpc_review", "2025-12-05"),
        visit("adpc_call", "2026-01-10"),
        visit("adpc_action", "2026-02-05"),
        visit("adpc_followup", "2026-03-08"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-stark"),
      name: "Stark Industries",
      current_stage: Expansion,
      visits: [
        visit("aw_events", "2024-09-15"),
        visit("ed_whitepapers", "2024-10-08"),
        visit("sel_rfp", "2024-11-12"),
        visit("com_procurement", "2025-01-10"),
        visit("com_contract", "2025-02-08"),
        visit("comc_msa", "2025-02-08"),
        visit("comc_redline", "2025-02-22"),
        visit("comc_agree", "2025-03-05"),
        visit("comc_sign", "2025-03-18"),
        visit("onb_impl", "2025-03-25"),
        visit("onb_kickoff", "2025-04-02"),
        visit("adp_csm", "2025-05-15"),
        visit("adp_health", "2025-07-20"),
        visit("exp_renewal", "2026-01-10"),
        visit("expr_notice", "2026-01-10"),
        visit("expr_value", "2026-02-05"),
        visit("expr_terms", "2026-02-28"),
        visit("expr_sign", "2026-03-18"),
      ],
    ),
  ]
}

fn visit(id: String, date: String) -> OpportunityVisit {
  OpportunityVisit(node_id: NodeId(id), date: date)
}

fn custom_breakdowns() -> List(#(NodeId, Graph)) {
  [
    #(NodeId("aw_web_ads"), web_ads_breakdown()),
    #(NodeId("ed_inbound"), inbound_breakdown()),
    #(NodeId("sel_demo"), demo_breakdown()),
    #(NodeId("com_contract"), contract_breakdown()),
    #(NodeId("onb_guided"), guided_onboarding_breakdown()),
    #(NodeId("adp_csm"), csm_breakdown()),
    #(NodeId("exp_renewal"), renewal_breakdown()),
  ]
}

fn stub_breakdown(parent: NodeId, label: String) -> Graph {
  let NodeId(pid) = parent
  let task_id = pid <> "_stub"
  let nodes = [task(task_id, label, "—", parent, 660.0, 330.0, [])]
  breakdown_graph(parent, task_id, task_id, nodes, [])
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
    StageBand(stage: Awareness, x: 60.0, width: 620.0, label: "Awareness"),
    StageBand(stage: Education, x: 700.0, width: 620.0, label: "Education"),
    StageBand(stage: Selection, x: 1340.0, width: 620.0, label: "Selection"),
    StageBand(stage: Commitment, x: 1980.0, width: 360.0, label: "Commitment"),
    StageBand(stage: Onboarding, x: 2360.0, width: 620.0, label: "Onboarding"),
    StageBand(stage: Adoption, x: 3000.0, width: 620.0, label: "Adoption"),
    StageBand(stage: Expansion, x: 3640.0, width: 360.0, label: "Expansion"),
  ]
}

fn activity_map() -> Graph {
  Graph(
    level: Activities,
    parent: None,
    bands: stage_bands(),
    viewbox: ViewBox(0.0, 0.0, 4100.0, 1400.0),
    nodes: activity_nodes(),
    edges: activity_edges(),
  )
}

fn activity_nodes() -> List(Node) {
  [
    // Awareness: left col x=220, right col x=520
    activity("aw_web_ads", "Web advertising", Awareness, 220.0, 380.0,
      [HighTouch, MediumTouch, LowTouch], True),
    activity("aw_content", "Content marketing", Awareness, 220.0, 540.0,
      [NoTouch, LowTouch], False),
    activity("aw_partners", "Partner referrals", Awareness, 220.0, 700.0,
      [HighTouch], False),
    activity("aw_events", "Events & conferences", Awareness, 220.0, 860.0,
      [HighTouch], False),
    activity("aw_outbound", "Outbound SDR", Awareness, 520.0, 540.0,
      [MediumTouch, HighTouch], False),

    // Education: left col x=860, right col x=1160
    activity("ed_inbound", "Inbound web traffic", Education, 860.0, 380.0,
      [NoTouch, LowTouch], True),
    activity("ed_webinars", "Product webinars", Education, 860.0, 540.0,
      [LowTouch, MediumTouch], False),
    activity("ed_whitepapers", "Whitepaper downloads", Education, 860.0, 700.0,
      [NoTouch, LowTouch], False),
    activity("ed_sdr_qual", "SDR qualification", Education, 860.0, 860.0,
      [MediumTouch, HighTouch], False),
    activity("ed_case_studies", "Case study library", Education, 1160.0,
      860.0, [LowTouch], False),

    // Selection: left col x=1500, right col x=1800
    activity("sel_self_trial", "Self-serve trial", Selection, 1500.0, 380.0,
      [NoTouch, LowTouch], False),
    activity("sel_poc", "POC / pilot", Selection, 1500.0, 540.0, [HighTouch],
      False),
    activity("sel_rfp", "RFP response", Selection, 1500.0, 700.0, [HighTouch],
      False),
    activity("sel_security", "Security review", Selection, 1500.0, 860.0,
      [MediumTouch, HighTouch], False),
    activity("sel_demo", "Live demo", Selection, 1800.0, 380.0, [MediumTouch,
      HighTouch], True),

    // Commitment (knot, single column x=2160, narrower)
    activity_narrow("com_negotiate", "Price negotiation", Commitment, 2160.0,
      500.0, [MediumTouch, HighTouch], False),
    activity_narrow("com_contract", "Contract negotiation", Commitment, 2160.0,
      640.0, [MediumTouch, HighTouch], True),
    activity_narrow("com_procurement", "Procurement & legal", Commitment,
      2160.0, 780.0, [HighTouch], False),
    activity_narrow("com_signature", "Order form signature", Commitment,
      2160.0, 920.0, [NoTouch, LowTouch, MediumTouch, HighTouch], False),

    // Onboarding: left col x=2520, right col x=2820
    activity("onb_self", "Self-serve setup", Onboarding, 2520.0, 500.0,
      [NoTouch, LowTouch], False),
    activity("onb_impl", "Dedicated implementation", Onboarding, 2520.0, 660.0,
      [HighTouch], False),
    activity("onb_kickoff", "Kickoff meeting", Onboarding, 2520.0, 820.0,
      [MediumTouch, HighTouch], False),
    activity("onb_guided", "Guided onboarding", Onboarding, 2820.0, 820.0,
      [LowTouch, MediumTouch], True),

    // Adoption: left col x=3160, right col x=3460
    activity("adp_nudges", "In-app nudges", Adoption, 3160.0, 380.0, [NoTouch,
      LowTouch], False),
    activity("adp_training", "Product training", Adoption, 3160.0, 540.0,
      [LowTouch, MediumTouch], False),
    activity("adp_csm", "CSM check-ins", Adoption, 3160.0, 700.0, [MediumTouch,
      HighTouch], True),
    activity("adp_community", "Customer community", Adoption, 3160.0, 860.0,
      [NoTouch, LowTouch], False),
    activity("adp_health", "Health score monitoring", Adoption, 3460.0, 700.0,
      [NoTouch, LowTouch, MediumTouch, HighTouch], False),

    // Expansion (single column x=3820)
    activity("exp_usage", "Usage-based upsell", Expansion, 3820.0, 500.0,
      [NoTouch, LowTouch], False),
    activity("exp_crosssell", "Cross-sell new teams", Expansion, 3820.0, 660.0,
      [MediumTouch, HighTouch], False),
    activity("exp_renewal", "Renewal", Expansion, 3820.0, 820.0, [NoTouch,
      LowTouch, MediumTouch, HighTouch], True),
    activity("exp_qbr", "Strategic business review", Expansion, 3820.0, 980.0,
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
  _drillable: Bool,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Activity(stage),
    position: Point(x, y),
    size: Size(280.0, 82.0),
    motions: motions,
    parent: None,
    children_level: Some(Breakdown),
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
  _drillable: Bool,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Activity(stage),
    position: Point(x, y),
    size: Size(240.0, 76.0),
    motions: motions,
    parent: None,
    children_level: Some(Breakdown),
    notes: "",
  )
}

// -------- Level 3: Breakdown swimlanes ----------

fn breakdown_graph(
  parent: NodeId,
  entry: String,
  exit: String,
  nodes: List(Node),
  edges: List(Edge),
) -> Graph {
  let #(neighbors, bridges) = neighbor_nodes_and_edges(parent, entry, exit)
  Graph(
    level: Breakdown,
    parent: Some(parent),
    bands: [],
    viewbox: ViewBox(-420.0, -60.0, 2040.0, 900.0),
    nodes: list.append(nodes, neighbors),
    edges: list.append(edges, bridges),
  )
}

fn neighbor_nodes_and_edges(
  parent: NodeId,
  entry: String,
  exit: String,
) -> #(List(Node), List(Edge)) {
  let map_nodes = activity_nodes()
  let map_edges = activity_edges()
  let parent_label = case
    list.find(map_nodes, fn(n: Node) { n.id == parent })
  {
    Ok(n) -> n.label
    Error(_) -> ""
  }
  let inbound_ids =
    list.filter_map(map_edges, fn(e: Edge) {
      case e.to == parent {
        True -> Ok(e.from)
        False -> Error(Nil)
      }
    })
  let outbound_ids =
    list.filter_map(map_edges, fn(e: Edge) {
      case e.from == parent {
        True -> Ok(e.to)
        False -> Error(Nil)
      }
    })
  let in_nodes = neighbor_column(map_nodes, inbound_ids, Inbound, -240.0)
  let out_nodes = neighbor_column(map_nodes, outbound_ids, Outbound, 1420.0)
  let in_edges =
    list.map(in_nodes, fn(n: Node) {
      let NodeId(nid) = n.id
      edge(
        nid <> "_bridge_" <> entry,
        nid,
        entry,
        parent_label,
        Flow,
        [],
      )
    })
  let out_edges =
    list.map(out_nodes, fn(n: Node) {
      let NodeId(nid) = n.id
      edge(
        exit <> "_bridge_" <> nid,
        exit,
        nid,
        parent_label,
        Flow,
        [],
      )
    })
  #(list.append(in_nodes, out_nodes), list.append(in_edges, out_edges))
}

fn neighbor_column(
  map_nodes: List(Node),
  ids: List(NodeId),
  direction: atlas.Direction,
  cx: Float,
) -> List(Node) {
  let refs =
    list.filter_map(ids, fn(id: NodeId) {
      list.find(map_nodes, fn(n: Node) { n.id == id })
    })
  let count = list.length(refs)
  case count {
    0 -> []
    _ -> {
      let step = 780.0 /. int.to_float(count)
      list.index_map(refs, fn(src: Node, i: Int) {
        let y = 20.0 +. step *. { int.to_float(i) +. 0.5 }
        let stage = case src.kind {
          Activity(s) -> s
          _ -> Awareness
        }
        Node(
          id: src.id,
          label: src.label,
          kind: Neighbor(stage: stage, direction: direction),
          position: Point(cx, y),
          size: Size(200.0, 90.0),
          motions: src.motions,
          parent: None,
          children_level: Some(Breakdown),
          notes: "",
        )
      })
    }
  }
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
  breakdown_graph(parent, "awb_impression", "awb_lead", nodes, edges)
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
  breakdown_graph(parent, "edi_search", "edi_nurture", nodes, edges)
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
  breakdown_graph(parent, "seld_book", "seld_proposal", nodes, edges)
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
  breakdown_graph(parent, "comc_msa", "comc_sign", nodes, edges)
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
  breakdown_graph(parent, "onbg_welcome", "onbg_handoff", nodes, edges)
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
  breakdown_graph(parent, "adpc_review", "adpc_followup", nodes, edges)
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
  breakdown_graph(parent, "expr_notice", "expr_sign", nodes, edges)
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
    Awareness -> StageBand(stage: Awareness, x: 60.0, width: 620.0, label: "")
    Education -> StageBand(stage: Education, x: 700.0, width: 620.0, label: "")
    Selection -> StageBand(stage: Selection, x: 1340.0, width: 620.0, label: "")
    Commitment ->
      StageBand(stage: Commitment, x: 1980.0, width: 360.0, label: "")
    Onboarding ->
      StageBand(stage: Onboarding, x: 2360.0, width: 620.0, label: "")
    Adoption -> StageBand(stage: Adoption, x: 3000.0, width: 620.0, label: "")
    Expansion -> StageBand(stage: Expansion, x: 3640.0, width: 360.0, label: "")
  }
  let pad = 240.0
  ViewBox(
    x: band.x -. pad,
    y: 240.0,
    width: band.width +. { pad *. 2.0 },
    height: 1000.0,
  )
}
