import atlas.{
  type Atlas, type Edge, type Graph, type MotionAtlas, type Node, type NodeId,
  type Opportunity, type OpportunityVisit, type StageBand, type StageId,
  Activities, Activity, Atlas, Awareness, Adoption, Breakdown, Commitment,
  Edge, Education, Expansion, Feedback, Flow, Graph, Handoff, HighTouch,
  Inbound, Knot, LowTouch, MediumTouch, MotionAtlas, Neighbor, Node, NodeId,
  Onboarding, Opportunity, OpportunityId, OpportunityVisit, Outbound, Overview,
  Point, Selection, Size, Stage, StageBand, Task, ViewBox,
}
import gleam/int
import gleam/list
import gleam/option.{None, Some}

pub fn atlas() -> Atlas {
  Atlas(
    overview: overview_graph(),
    motion_atlases: [
      #(HighTouch, high_touch_atlas()),
      #(MediumTouch, medium_touch_atlas()),
      #(LowTouch, low_touch_atlas()),
    ],
  )
}

// ==========================================================================
// Level 1: Shared overview (the 7-stage bowtie)
// ==========================================================================

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
    parent: None,
    children_level: Some(Activities),
    notes: "",
  )
}

// ==========================================================================
// High Touch (HLG) — enterprise, human-led
// ==========================================================================

fn high_touch_atlas() -> MotionAtlas {
  let nodes = high_touch_nodes()
  let edges = high_touch_edges()
  let activity_map =
    Graph(
      level: Activities,
      parent: None,
      bands: high_touch_bands(),
      viewbox: ViewBox(0.0, 0.0, 3740.0, 1400.0),
      nodes: nodes,
      edges: edges,
    )
  let breakdowns = high_touch_breakdowns(nodes, edges)
  MotionAtlas(
    activity_map: activity_map,
    breakdowns: breakdowns,
    opportunities: high_touch_opportunities(),
  )
}

fn high_touch_bands() -> List(StageBand) {
  [
    StageBand(stage: Awareness, x: 60.0, width: 680.0, label: "Target & MQA"),
    StageBand(stage: Education, x: 760.0, width: 680.0, label: "Discovery"),
    StageBand(stage: Selection, x: 1460.0, width: 620.0, label: "Qualified Opp"),
    StageBand(stage: Commitment, x: 2100.0, width: 380.0, label: "Win"),
    StageBand(stage: Onboarding, x: 2500.0, width: 380.0, label: "Kickoff"),
    StageBand(stage: Adoption, x: 2900.0, width: 380.0, label: "MRR"),
    StageBand(stage: Expansion, x: 3300.0, width: 400.0, label: "LTV"),
  ]
}

fn high_touch_nodes() -> List(Node) {
  [
    // Awareness — 2 cols × 2 rows (warm lane right, outbound lane left)
    activity("h_aw_field_events", "Field events & CAB", Awareness, 240.0, 440.0),
    activity("h_aw_exec_refs", "Executive referrals", Awareness, 560.0, 440.0),
    activity("h_aw_abm", "ABM target list", Awareness, 240.0, 720.0),
    activity("h_aw_outbound", "SDR outbound", Awareness, 560.0, 720.0),
    // Education — 2 cols (split at disc deck)
    activity("h_ed_exec_brief", "Executive briefing", Education, 920.0, 440.0),
    activity("h_ed_sdr_disc", "SDR discovery call", Education, 920.0, 720.0),
    activity("h_ed_disc_deck", "Discovery deck", Education, 1260.0, 720.0),
    // Selection — 2 cols, roi at col-R bottom
    activity("h_sel_solution_demo", "Solution demo", Selection, 1620.0, 440.0),
    activity("h_sel_rfp", "RFP response", Selection, 1920.0, 440.0),
    activity("h_sel_poc", "POC / pilot", Selection, 1620.0, 720.0),
    activity("h_sel_security", "Security review", Selection, 1920.0, 720.0),
    activity("h_sel_roi", "ROI business case", Selection, 1920.0, 1000.0),
    // Commitment — single column
    activity("h_com_negotiate", "Price negotiation", Commitment, 2280.0, 440.0),
    activity("h_com_redline", "Contract redline", Commitment, 2280.0, 720.0),
    activity("h_com_procurement", "Procurement & legal", Commitment, 2280.0, 1000.0),
    // Onboarding — single column
    activity("h_onb_kickoff", "Kickoff & success plan", Onboarding, 2680.0, 440.0),
    activity("h_onb_impl", "Dedicated implementation", Onboarding, 2680.0, 720.0),
    activity("h_onb_integration", "Integrations build", Onboarding, 2680.0, 1000.0),
    // Adoption — single column
    activity("h_adp_csm", "CSM check-ins", Adoption, 3080.0, 440.0),
    activity("h_adp_qbr", "Quarterly business review", Adoption, 3080.0, 720.0),
    activity("h_adp_health", "Health-score monitoring", Adoption, 3080.0, 1000.0),
    // Expansion — single column
    activity("h_exp_am", "AM-led expansion", Expansion, 3500.0, 440.0),
    activity("h_exp_crosssell", "Cross-sell new BU", Expansion, 3500.0, 720.0),
    activity("h_exp_resell", "Champion reselling", Expansion, 3500.0, 1000.0),
  ]
}

fn high_touch_edges() -> List(Edge) {
  [
    // intra-Awareness
    flow("h_aw_field_events", "h_aw_exec_refs", ""),
    flow("h_aw_field_events", "h_aw_abm", ""),
    flow("h_aw_abm", "h_aw_outbound", ""),
    flow("h_aw_exec_refs", "h_aw_outbound", ""),
    // Awareness → Education
    flow("h_aw_exec_refs", "h_ed_exec_brief", ""),
    flow("h_aw_outbound", "h_ed_sdr_disc", ""),
    // intra-Education
    flow("h_ed_sdr_disc", "h_ed_disc_deck", ""),
    flow("h_ed_exec_brief", "h_ed_disc_deck", ""),
    // Education → Selection
    flow("h_ed_disc_deck", "h_sel_solution_demo", ""),
    flow("h_ed_disc_deck", "h_sel_poc", ""),
    // intra-Selection
    flow("h_sel_solution_demo", "h_sel_rfp", ""),
    flow("h_sel_solution_demo", "h_sel_poc", ""),
    flow("h_sel_rfp", "h_sel_security", ""),
    flow("h_sel_poc", "h_sel_security", ""),
    flow("h_sel_poc", "h_sel_roi", ""),
    flow("h_sel_security", "h_sel_roi", ""),
    // Selection → Commitment
    flow("h_sel_roi", "h_com_negotiate", ""),
    flow("h_com_negotiate", "h_com_redline", ""),
    flow("h_com_redline", "h_com_procurement", ""),
    // Commitment → Onboarding
    handoff("h_com_procurement", "h_onb_kickoff", ""),
    flow("h_onb_kickoff", "h_onb_impl", ""),
    flow("h_onb_impl", "h_onb_integration", ""),
    // Onboarding → Adoption
    flow("h_onb_kickoff", "h_adp_csm", ""),
    flow("h_adp_csm", "h_adp_qbr", ""),
    flow("h_adp_qbr", "h_adp_health", ""),
    // Adoption → Expansion
    flow("h_adp_csm", "h_exp_am", ""),
    flow("h_adp_qbr", "h_exp_crosssell", ""),
    flow("h_adp_health", "h_exp_resell", ""),
    flow("h_exp_am", "h_exp_crosssell", ""),
    flow("h_exp_crosssell", "h_exp_resell", ""),
    // Feedback loops (closed-loop growth)
    Edge(
      id: "h_feedback_resell",
      from: NodeId("h_exp_resell"),
      to: NodeId("h_aw_exec_refs"),
      label: "champion moves",
      kind: Feedback,
    ),
  ]
}

fn high_touch_breakdowns(
  nodes: List(Node),
  edges: List(Edge),
) -> List(#(NodeId, Graph)) {
  list.map(nodes, fn(n: Node) {
    let graph = case n.children_level {
      Some(_) ->
        case n.id {
          NodeId("h_aw_exec_refs") ->
            build_breakdown(n, edges, nodes, h_aw_exec_refs_tasks(), h_aw_exec_refs_task_edges())
          NodeId("h_ed_sdr_disc") ->
            build_breakdown(n, edges, nodes, h_ed_sdr_disc_tasks(), h_ed_sdr_disc_task_edges())
          NodeId("h_sel_poc") ->
            build_breakdown(n, edges, nodes, h_sel_poc_tasks(), h_sel_poc_task_edges())
          NodeId("h_com_redline") ->
            build_breakdown(n, edges, nodes, h_com_redline_tasks(), h_com_redline_task_edges())
          NodeId("h_onb_kickoff") ->
            build_breakdown(n, edges, nodes, h_onb_kickoff_tasks(), h_onb_kickoff_task_edges())
          NodeId("h_adp_csm") ->
            build_breakdown(n, edges, nodes, h_adp_csm_tasks(), h_adp_csm_task_edges())
          NodeId("h_exp_am") ->
            build_breakdown(n, edges, nodes, h_exp_am_tasks(), h_exp_am_task_edges())
          _ -> stub_breakdown(n, edges, nodes)
        }
      None -> stub_breakdown(n, edges, nodes)
    }
    #(n.id, graph)
  })
}

fn h_aw_exec_refs_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_exec_cab", "CAB lunch", "CAB host", 260.0, 220.0),
    #("h_exec_intro", "Warm intro email", "Customer champion", 660.0, 220.0),
    #("h_exec_meeting", "1:1 exec meeting", "Enterprise AE", 1060.0, 220.0),
    #("h_exec_logged", "Target added to ABM", "SDR", 1060.0, 440.0),
  ]
}

fn h_aw_exec_refs_task_edges() -> List(#(String, String, String)) {
  [
    #("h_exec_cab", "h_exec_intro", ""),
    #("h_exec_intro", "h_exec_meeting", ""),
    #("h_exec_meeting", "h_exec_logged", ""),
  ]
}

fn h_ed_sdr_disc_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_sdr_research", "Account research", "SDR", 260.0, 220.0),
    #("h_sdr_multithread", "Multi-thread outreach", "SDR", 660.0, 220.0),
    #("h_sdr_call", "Discovery call", "SDR + AE", 1060.0, 220.0),
    #("h_sdr_handoff", "Hand-off to AE", "SDR", 1060.0, 440.0),
  ]
}

fn h_ed_sdr_disc_task_edges() -> List(#(String, String, String)) {
  [
    #("h_sdr_research", "h_sdr_multithread", ""),
    #("h_sdr_multithread", "h_sdr_call", ""),
    #("h_sdr_call", "h_sdr_handoff", ""),
  ]
}

fn h_sel_poc_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_poc_scope", "Scope success criteria", "Enterprise AE", 260.0, 220.0),
    #("h_poc_stand", "Stand up sandbox", "Sales engineer", 660.0, 220.0),
    #("h_poc_run", "Run pilot", "Sales engineer", 1060.0, 220.0),
    #("h_poc_review", "Results review", "Enterprise AE", 1060.0, 440.0),
  ]
}

fn h_sel_poc_task_edges() -> List(#(String, String, String)) {
  [
    #("h_poc_scope", "h_poc_stand", ""),
    #("h_poc_stand", "h_poc_run", ""),
    #("h_poc_run", "h_poc_review", ""),
  ]
}

fn h_com_redline_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_red_msa", "Send MSA draft", "Enterprise AE", 260.0, 220.0),
    #("h_red_legal", "Legal redline", "Legal", 660.0, 220.0),
    #("h_red_terms", "Terms agreed", "Enterprise AE", 1060.0, 220.0),
    #("h_red_sign", "E-signature collected", "Contract system", 1060.0, 440.0),
  ]
}

fn h_com_redline_task_edges() -> List(#(String, String, String)) {
  [
    #("h_red_msa", "h_red_legal", ""),
    #("h_red_legal", "h_red_terms", ""),
    #("h_red_terms", "h_red_sign", ""),
  ]
}

fn h_onb_kickoff_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_ko_plan", "Success plan drafted", "CSM", 260.0, 220.0),
    #("h_ko_call", "Kickoff call", "CSM + Champion", 660.0, 220.0),
    #("h_ko_setup", "Workspace provisioning", "Implementation", 660.0, 440.0),
    #("h_ko_firstval", "First-impact moment", "Champion", 1060.0, 220.0),
    #("h_ko_handoff", "Hand-off to CSM", "Implementation", 1060.0, 440.0),
  ]
}

fn h_onb_kickoff_task_edges() -> List(#(String, String, String)) {
  [
    #("h_ko_plan", "h_ko_call", ""),
    #("h_ko_call", "h_ko_setup", ""),
    #("h_ko_setup", "h_ko_firstval", ""),
    #("h_ko_firstval", "h_ko_handoff", ""),
  ]
}

fn h_adp_csm_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_csm_health", "Review health score", "CSM", 260.0, 220.0),
    #("h_csm_monthly", "Monthly check-in", "CSM", 660.0, 220.0),
    #("h_csm_actions", "Log action items", "Customer champion", 1060.0, 220.0),
    #("h_csm_followup", "Follow-up tickets", "CSM", 1060.0, 440.0),
  ]
}

fn h_adp_csm_task_edges() -> List(#(String, String, String)) {
  [
    #("h_csm_health", "h_csm_monthly", ""),
    #("h_csm_monthly", "h_csm_actions", ""),
    #("h_csm_actions", "h_csm_followup", ""),
  ]
}

fn h_exp_am_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("h_am_plan", "Expansion plan", "Account Manager", 260.0, 220.0),
    #("h_am_discovery", "New BU discovery", "Account Manager", 660.0, 220.0),
    #("h_am_proposal", "Expansion proposal", "Account Manager", 1060.0, 220.0),
    #("h_am_sign", "Expansion signed", "Champion", 1060.0, 440.0),
  ]
}

fn h_exp_am_task_edges() -> List(#(String, String, String)) {
  [
    #("h_am_plan", "h_am_discovery", ""),
    #("h_am_discovery", "h_am_proposal", ""),
    #("h_am_proposal", "h_am_sign", ""),
  ]
}

fn high_touch_opportunities() -> List(Opportunity) {
  [
    Opportunity(
      id: OpportunityId("opp-umbrella"),
      name: "Umbrella Labs",
      motion: HighTouch,
      current_stage: Awareness,
      visits: [
        visit("h_aw_field_events", "2026-03-12"),
        visit("h_aw_abm", "2026-03-28"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-wayne"),
      name: "Wayne Enterprises",
      motion: HighTouch,
      current_stage: Selection,
      visits: [
        visit("h_aw_abm", "2025-12-02"),
        visit("h_aw_exec_refs", "2025-12-18"),
        visit("h_exec_cab", "2025-12-18"),
        visit("h_exec_intro", "2025-12-21"),
        visit("h_exec_meeting", "2026-01-08"),
        visit("h_ed_sdr_disc", "2026-01-22"),
        visit("h_sdr_research", "2026-01-22"),
        visit("h_sdr_multithread", "2026-01-28"),
        visit("h_sdr_call", "2026-02-05"),
        visit("h_ed_disc_deck", "2026-02-12"),
        visit("h_sel_solution_demo", "2026-02-26"),
        visit("h_sel_poc", "2026-03-20"),
        visit("h_poc_scope", "2026-03-20"),
        visit("h_poc_stand", "2026-03-28"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-stark"),
      name: "Stark Industries",
      motion: HighTouch,
      current_stage: Expansion,
      visits: [
        visit("h_aw_exec_refs", "2024-10-04"),
        visit("h_ed_exec_brief", "2024-10-28"),
        visit("h_sel_poc", "2024-12-02"),
        visit("h_sel_security", "2025-01-10"),
        visit("h_sel_roi", "2025-01-28"),
        visit("h_com_negotiate", "2025-02-15"),
        visit("h_com_redline", "2025-03-02"),
        visit("h_red_msa", "2025-03-02"),
        visit("h_red_legal", "2025-03-15"),
        visit("h_red_terms", "2025-03-22"),
        visit("h_red_sign", "2025-03-30"),
        visit("h_onb_impl", "2025-04-05"),
        visit("h_onb_kickoff", "2025-04-12"),
        visit("h_ko_plan", "2025-04-12"),
        visit("h_ko_call", "2025-04-18"),
        visit("h_adp_csm", "2025-06-20"),
        visit("h_adp_qbr", "2025-09-15"),
        visit("h_exp_am", "2026-02-14"),
        visit("h_am_plan", "2026-02-14"),
        visit("h_am_discovery", "2026-03-20"),
      ],
    ),
  ]
}

// ==========================================================================
// Medium Touch (AiLG) — mid-market, AI-led
// ==========================================================================

fn medium_touch_atlas() -> MotionAtlas {
  let nodes = medium_touch_nodes()
  let edges = medium_touch_edges()
  let activity_map =
    Graph(
      level: Activities,
      parent: None,
      bands: medium_touch_bands(),
      viewbox: ViewBox(0.0, 0.0, 3500.0, 1400.0),
      nodes: nodes,
      edges: edges,
    )
  let breakdowns = medium_touch_breakdowns(nodes, edges)
  MotionAtlas(
    activity_map: activity_map,
    breakdowns: breakdowns,
    opportunities: medium_touch_opportunities(),
  )
}

fn medium_touch_bands() -> List(StageBand) {
  [
    StageBand(stage: Awareness, x: 60.0, width: 420.0, label: "Prospect"),
    StageBand(stage: Education, x: 500.0, width: 420.0, label: "MQL → SQL"),
    StageBand(stage: Selection, x: 940.0, width: 420.0, label: "SAL"),
    StageBand(stage: Commitment, x: 1380.0, width: 420.0, label: "Win"),
    StageBand(stage: Onboarding, x: 1820.0, width: 420.0, label: "Activation"),
    StageBand(stage: Adoption, x: 2260.0, width: 420.0, label: "MRR"),
    StageBand(stage: Expansion, x: 2700.0, width: 420.0, label: "Renewal"),
  ]
}

fn medium_touch_nodes() -> List(Node) {
  [
    // Awareness — single column, three rows
    activity("m_aw_thought_lead", "Thought leadership", Awareness, 270.0, 440.0),
    activity("m_aw_paid_ads", "Paid ads & SEO", Awareness, 270.0, 720.0),
    activity("m_aw_ai_outbound", "AI-assisted outbound", Awareness, 270.0, 1000.0),
    // Education — single column, three rows
    activity("m_ed_webinars", "Webinars", Education, 710.0, 440.0),
    activity("m_ed_ai_chat", "AI chat qualification", Education, 710.0, 720.0),
    activity("m_ed_nurture", "Email nurture", Education, 710.0, 1000.0),
    // Selection — single column, two rows
    activity("m_sel_online_demo", "Online demo", Selection, 1150.0, 440.0),
    activity("m_sel_spiced", "SPICED qualification", Selection, 1150.0, 720.0),
    // Commitment — single column, two rows
    activity("m_com_proposal", "Automated proposal", Commitment, 1590.0, 440.0),
    activity("m_com_esign", "E-signature", Commitment, 1590.0, 720.0),
    // Onboarding — single column, two rows
    activity("m_onb_guided", "Guided onboarding", Onboarding, 2030.0, 440.0),
    activity("m_onb_training", "Role-based training", Onboarding, 2030.0, 720.0),
    // Adoption — single column, two rows
    activity("m_adp_health", "Health-score monitoring", Adoption, 2470.0, 440.0),
    activity("m_adp_playbooks", "Adoption playbooks", Adoption, 2470.0, 720.0),
    // Expansion — single column, two rows
    activity("m_exp_renewal", "Renewal", Expansion, 2910.0, 440.0),
    activity("m_exp_upsell", "Tier upsell", Expansion, 2910.0, 720.0),
  ]
}

fn medium_touch_edges() -> List(Edge) {
  [
    // intra-Awareness
    flow("m_aw_thought_lead", "m_aw_paid_ads", ""),
    flow("m_aw_paid_ads", "m_aw_ai_outbound", ""),
    // Awareness → Education
    flow("m_aw_thought_lead", "m_ed_webinars", ""),
    flow("m_aw_paid_ads", "m_ed_ai_chat", ""),
    flow("m_aw_ai_outbound", "m_ed_nurture", ""),
    // intra-Education
    flow("m_ed_webinars", "m_ed_ai_chat", ""),
    flow("m_ed_nurture", "m_ed_ai_chat", ""),
    // Education → Selection
    flow("m_ed_ai_chat", "m_sel_online_demo", ""),
    flow("m_ed_ai_chat", "m_sel_spiced", ""),
    flow("m_sel_spiced", "m_sel_online_demo", ""),
    // Selection → Commitment
    flow("m_sel_online_demo", "m_com_proposal", ""),
    flow("m_com_proposal", "m_com_esign", ""),
    // Commitment → Onboarding
    handoff("m_com_esign", "m_onb_guided", ""),
    flow("m_onb_guided", "m_onb_training", ""),
    // Onboarding → Adoption
    flow("m_onb_training", "m_adp_playbooks", ""),
    flow("m_onb_guided", "m_adp_health", ""),
    flow("m_adp_health", "m_adp_playbooks", ""),
    // Adoption → Expansion
    flow("m_adp_health", "m_exp_renewal", ""),
    flow("m_adp_playbooks", "m_exp_upsell", ""),
    flow("m_exp_upsell", "m_exp_renewal", ""),
    // Feedback loops
    Edge(
      id: "m_feedback_playbooks",
      from: NodeId("m_adp_playbooks"),
      to: NodeId("m_ed_webinars"),
      label: "ICP refinement",
      kind: Feedback,
    ),
  ]
}

fn medium_touch_breakdowns(
  nodes: List(Node),
  edges: List(Edge),
) -> List(#(NodeId, Graph)) {
  list.map(nodes, fn(n: Node) {
    let graph = case n.children_level {
      Some(_) ->
        case n.id {
          NodeId("m_aw_thought_lead") ->
            build_breakdown(n, edges, nodes, m_aw_thought_lead_tasks(), m_aw_thought_lead_task_edges())
          NodeId("m_ed_ai_chat") ->
            build_breakdown(n, edges, nodes, m_ed_ai_chat_tasks(), m_ed_ai_chat_task_edges())
          NodeId("m_sel_online_demo") ->
            build_breakdown(n, edges, nodes, m_sel_online_demo_tasks(), m_sel_online_demo_task_edges())
          NodeId("m_com_esign") ->
            build_breakdown(n, edges, nodes, m_com_esign_tasks(), m_com_esign_task_edges())
          NodeId("m_onb_guided") ->
            build_breakdown(n, edges, nodes, m_onb_guided_tasks(), m_onb_guided_task_edges())
          NodeId("m_exp_renewal") ->
            build_breakdown(n, edges, nodes, m_exp_renewal_tasks(), m_exp_renewal_task_edges())
          _ -> stub_breakdown(n, edges, nodes)
        }
      None -> stub_breakdown(n, edges, nodes)
    }
    #(n.id, graph)
  })
}

fn m_aw_thought_lead_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_tl_post", "Publish long-form post", "Marketing", 260.0, 220.0),
    #("m_tl_distribute", "Syndicate to channels", "Marketing", 660.0, 220.0),
    #("m_tl_capture", "Capture handraise", "Marketing site", 1060.0, 220.0),
    #("m_tl_score", "Lead scoring", "Marketing ops", 1060.0, 440.0),
  ]
}

fn m_aw_thought_lead_task_edges() -> List(#(String, String, String)) {
  [
    #("m_tl_post", "m_tl_distribute", ""),
    #("m_tl_distribute", "m_tl_capture", ""),
    #("m_tl_capture", "m_tl_score", ""),
  ]
}

fn m_ed_ai_chat_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_chat_trigger", "AI chat intro", "AI agent", 260.0, 220.0),
    #("m_chat_qualify", "Qualify intent", "AI agent", 660.0, 220.0),
    #("m_chat_book", "Book demo slot", "AI agent", 1060.0, 220.0),
    #("m_chat_handoff", "Route to sales", "AI agent", 1060.0, 440.0),
  ]
}

fn m_ed_ai_chat_task_edges() -> List(#(String, String, String)) {
  [
    #("m_chat_trigger", "m_chat_qualify", ""),
    #("m_chat_qualify", "m_chat_book", ""),
    #("m_chat_book", "m_chat_handoff", ""),
  ]
}

fn m_sel_online_demo_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_dem_prep", "Demo prep", "Account Executive", 260.0, 220.0),
    #("m_dem_run", "Run online demo", "Account Executive", 660.0, 220.0),
    #("m_dem_spiced", "SPICED questions", "Account Executive", 1060.0, 220.0),
    #("m_dem_recap", "Send recap & proposal", "Account Executive", 1060.0, 440.0),
  ]
}

fn m_sel_online_demo_task_edges() -> List(#(String, String, String)) {
  [
    #("m_dem_prep", "m_dem_run", ""),
    #("m_dem_run", "m_dem_spiced", ""),
    #("m_dem_spiced", "m_dem_recap", ""),
  ]
}

fn m_com_esign_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_esign_send", "Send order form", "Account Executive", 260.0, 220.0),
    #("m_esign_sign", "Customer signs", "Customer champion", 660.0, 220.0),
    #("m_esign_book", "Book revenue", "Billing system", 1060.0, 220.0),
  ]
}

fn m_com_esign_task_edges() -> List(#(String, String, String)) {
  [
    #("m_esign_send", "m_esign_sign", ""),
    #("m_esign_sign", "m_esign_book", ""),
  ]
}

fn m_onb_guided_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_og_welcome", "Welcome sequence", "Lifecycle marketing", 260.0, 220.0),
    #("m_og_kickoff", "Kickoff call", "CSM", 660.0, 220.0),
    #("m_og_setup", "Workspace setup", "Customer", 660.0, 440.0),
    #("m_og_firstvalue", "First-value checkpoint", "Product", 1060.0, 220.0),
    #("m_og_handoff", "Handoff to success", "CSM", 1060.0, 440.0),
  ]
}

fn m_onb_guided_task_edges() -> List(#(String, String, String)) {
  [
    #("m_og_welcome", "m_og_kickoff", ""),
    #("m_og_kickoff", "m_og_setup", ""),
    #("m_og_setup", "m_og_firstvalue", ""),
    #("m_og_firstvalue", "m_og_handoff", ""),
  ]
}

fn m_exp_renewal_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("m_ren_notice", "90-day renewal notice", "CRM", 260.0, 220.0),
    #("m_ren_value", "Value recap", "CSM", 660.0, 220.0),
    #("m_ren_terms", "Confirm terms", "Account Manager", 660.0, 440.0),
    #("m_ren_sign", "Renewal signed", "Customer champion", 1060.0, 220.0),
  ]
}

fn m_exp_renewal_task_edges() -> List(#(String, String, String)) {
  [
    #("m_ren_notice", "m_ren_value", ""),
    #("m_ren_value", "m_ren_terms", ""),
    #("m_ren_terms", "m_ren_sign", ""),
  ]
}

fn medium_touch_opportunities() -> List(Opportunity) {
  [
    Opportunity(
      id: OpportunityId("opp-globex"),
      name: "Globex Industries",
      motion: MediumTouch,
      current_stage: Commitment,
      visits: [
        visit("m_aw_thought_lead", "2025-11-14"),
        visit("m_tl_post", "2025-11-14"),
        visit("m_tl_capture", "2025-11-16"),
        visit("m_ed_nurture", "2025-11-25"),
        visit("m_ed_ai_chat", "2025-12-08"),
        visit("m_chat_trigger", "2025-12-08"),
        visit("m_chat_qualify", "2025-12-08"),
        visit("m_chat_book", "2025-12-10"),
        visit("m_sel_online_demo", "2025-12-18"),
        visit("m_dem_run", "2025-12-18"),
        visit("m_dem_spiced", "2026-01-05"),
        visit("m_com_proposal", "2026-02-02"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-initech"),
      name: "Initech Solutions",
      motion: MediumTouch,
      current_stage: Onboarding,
      visits: [
        visit("m_aw_paid_ads", "2025-09-08"),
        visit("m_ed_ai_chat", "2025-09-22"),
        visit("m_chat_book", "2025-09-28"),
        visit("m_sel_online_demo", "2025-10-14"),
        visit("m_com_proposal", "2025-11-06"),
        visit("m_com_esign", "2025-11-22"),
        visit("m_esign_send", "2025-11-22"),
        visit("m_esign_sign", "2025-12-01"),
        visit("m_esign_book", "2025-12-02"),
        visit("m_onb_guided", "2025-12-08"),
        visit("m_og_welcome", "2025-12-08"),
        visit("m_og_kickoff", "2025-12-15"),
        visit("m_og_setup", "2025-12-22"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-soylent"),
      name: "Soylent Dynamics",
      motion: MediumTouch,
      current_stage: Adoption,
      visits: [
        visit("m_aw_thought_lead", "2025-04-10"),
        visit("m_ed_webinars", "2025-05-06"),
        visit("m_ed_ai_chat", "2025-05-15"),
        visit("m_sel_online_demo", "2025-06-02"),
        visit("m_com_esign", "2025-07-04"),
        visit("m_onb_guided", "2025-07-10"),
        visit("m_onb_training", "2025-07-28"),
        visit("m_adp_health", "2025-09-05"),
        visit("m_adp_playbooks", "2025-11-20"),
      ],
    ),
  ]
}

// ==========================================================================
// Low Touch (PLG) — product-led, self-serve
// ==========================================================================

fn low_touch_atlas() -> MotionAtlas {
  let nodes = low_touch_nodes()
  let edges = low_touch_edges()
  let activity_map =
    Graph(
      level: Activities,
      parent: None,
      bands: low_touch_bands(),
      viewbox: ViewBox(0.0, 0.0, 3500.0, 1400.0),
      nodes: nodes,
      edges: edges,
    )
  let breakdowns = low_touch_breakdowns(nodes, edges)
  MotionAtlas(
    activity_map: activity_map,
    breakdowns: breakdowns,
    opportunities: low_touch_opportunities(),
  )
}

fn low_touch_bands() -> List(StageBand) {
  [
    StageBand(stage: Awareness, x: 60.0, width: 420.0, label: "Prospect"),
    StageBand(stage: Education, x: 500.0, width: 420.0, label: "Handraise"),
    StageBand(stage: Selection, x: 940.0, width: 420.0, label: "PQL → PQA"),
    StageBand(stage: Commitment, x: 1380.0, width: 420.0, label: "SignUp"),
    StageBand(stage: Onboarding, x: 1820.0, width: 420.0, label: "Activation"),
    StageBand(stage: Adoption, x: 2260.0, width: 420.0, label: "MAU"),
    StageBand(stage: Expansion, x: 2700.0, width: 420.0, label: "Invite"),
  ]
}

fn low_touch_nodes() -> List(Node) {
  [
    // Awareness — single column, three rows
    activity("l_aw_community", "Community buzz", Awareness, 270.0, 440.0),
    activity("l_aw_docs", "Docs & SEO", Awareness, 270.0, 720.0),
    activity("l_aw_viral", "Viral invites", Awareness, 270.0, 1000.0),
    // Education — single column, two rows
    activity("l_ed_signup", "Free sign-up", Education, 710.0, 440.0),
    activity("l_ed_interactive", "Interactive product tour", Education, 710.0, 720.0),
    // Selection — single column, three rows
    activity("l_sel_self_trial", "Self-serve trial", Selection, 1150.0, 440.0),
    activity("l_sel_pql", "PQL → PQA", Selection, 1150.0, 720.0),
    activity("l_sel_team_spread", "Team spread", Selection, 1150.0, 1000.0),
    // Commitment — single node centered
    activity("l_com_upgrade", "In-product upgrade", Commitment, 1590.0, 720.0),
    // Onboarding — single column, two rows
    activity("l_onb_activation", "First-value activation", Onboarding, 2030.0, 440.0),
    activity("l_onb_self", "Self-serve setup", Onboarding, 2030.0, 720.0),
    // Adoption — single column, two rows
    activity("l_adp_inapp", "In-app nudges", Adoption, 2470.0, 440.0),
    activity("l_adp_community", "Community & advocacy", Adoption, 2470.0, 720.0),
    // Expansion — single column, two rows
    activity("l_exp_usage", "Usage-based upsell", Expansion, 2910.0, 440.0),
    activity("l_exp_invite", "Invite peers", Expansion, 2910.0, 720.0),
  ]
}

fn low_touch_edges() -> List(Edge) {
  [
    // intra-Awareness
    flow("l_aw_community", "l_aw_docs", ""),
    flow("l_aw_docs", "l_aw_viral", ""),
    // Awareness → Education
    flow("l_aw_community", "l_ed_signup", ""),
    flow("l_aw_docs", "l_ed_signup", ""),
    flow("l_aw_viral", "l_ed_signup", ""),
    flow("l_aw_viral", "l_ed_interactive", ""),
    // intra-Education
    flow("l_ed_signup", "l_ed_interactive", ""),
    // Education → Selection
    flow("l_ed_signup", "l_sel_self_trial", ""),
    flow("l_ed_interactive", "l_sel_self_trial", ""),
    flow("l_sel_self_trial", "l_sel_pql", ""),
    flow("l_sel_pql", "l_sel_team_spread", ""),
    // Selection → Commitment
    flow("l_sel_pql", "l_com_upgrade", ""),
    flow("l_sel_team_spread", "l_com_upgrade", ""),
    // Commitment → Onboarding
    handoff("l_com_upgrade", "l_onb_activation", ""),
    flow("l_onb_activation", "l_onb_self", ""),
    // Onboarding → Adoption
    flow("l_onb_activation", "l_adp_inapp", ""),
    flow("l_onb_self", "l_adp_inapp", ""),
    flow("l_adp_inapp", "l_adp_community", ""),
    // Adoption → Expansion
    flow("l_adp_inapp", "l_exp_usage", ""),
    flow("l_adp_community", "l_exp_invite", ""),
    flow("l_exp_usage", "l_exp_invite", ""),
    // Feedback loop (PLG closed loop — advocacy drives awareness)
    Edge(
      id: "l_feedback_community",
      from: NodeId("l_adp_community"),
      to: NodeId("l_aw_community"),
      label: "advocacy",
      kind: Feedback,
    ),
  ]
}

fn low_touch_breakdowns(
  nodes: List(Node),
  edges: List(Edge),
) -> List(#(NodeId, Graph)) {
  list.map(nodes, fn(n: Node) {
    let graph = case n.children_level {
      Some(_) ->
        case n.id {
          NodeId("l_aw_viral") ->
            build_breakdown(n, edges, nodes, l_aw_viral_tasks(), l_aw_viral_task_edges())
          NodeId("l_ed_signup") ->
            build_breakdown(n, edges, nodes, l_ed_signup_tasks(), l_ed_signup_task_edges())
          NodeId("l_sel_pql") ->
            build_breakdown(n, edges, nodes, l_sel_pql_tasks(), l_sel_pql_task_edges())
          NodeId("l_onb_activation") ->
            build_breakdown(n, edges, nodes, l_onb_activation_tasks(), l_onb_activation_task_edges())
          NodeId("l_adp_community") ->
            build_breakdown(n, edges, nodes, l_adp_community_tasks(), l_adp_community_task_edges())
          _ -> stub_breakdown(n, edges, nodes)
        }
      None -> stub_breakdown(n, edges, nodes)
    }
    #(n.id, graph)
  })
}

fn l_aw_viral_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("l_vir_share", "User shares link", "Existing user", 260.0, 220.0),
    #("l_vir_visit", "Peer visits site", "Prospect", 660.0, 220.0),
    #("l_vir_signup", "Peer signs up", "Prospect", 1060.0, 220.0),
  ]
}

fn l_aw_viral_task_edges() -> List(#(String, String, String)) {
  [
    #("l_vir_share", "l_vir_visit", ""),
    #("l_vir_visit", "l_vir_signup", ""),
  ]
}

fn l_ed_signup_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("l_su_land", "Landing page", "Prospect", 260.0, 220.0),
    #("l_su_form", "Sign-up form", "Prospect", 660.0, 220.0),
    #("l_su_verify", "Email verification", "Auth system", 1060.0, 220.0),
    #("l_su_workspace", "Workspace created", "Product", 1060.0, 440.0),
  ]
}

fn l_ed_signup_task_edges() -> List(#(String, String, String)) {
  [
    #("l_su_land", "l_su_form", ""),
    #("l_su_form", "l_su_verify", ""),
    #("l_su_verify", "l_su_workspace", ""),
  ]
}

fn l_sel_pql_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("l_pql_track", "Track key events", "Analytics", 260.0, 220.0),
    #("l_pql_score", "Score PQL threshold", "Growth ops", 660.0, 220.0),
    #("l_pql_pqa", "Detect team spread", "Growth ops", 1060.0, 220.0),
    #("l_pql_prompt", "Upgrade prompt", "Product", 1060.0, 440.0),
  ]
}

fn l_sel_pql_task_edges() -> List(#(String, String, String)) {
  [
    #("l_pql_track", "l_pql_score", ""),
    #("l_pql_score", "l_pql_pqa", ""),
    #("l_pql_pqa", "l_pql_prompt", ""),
  ]
}

fn l_onb_activation_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("l_act_tour", "Guided tour", "Product", 260.0, 220.0),
    #("l_act_first", "First key action", "User", 660.0, 220.0),
    #("l_act_aha", "Aha moment", "User", 1060.0, 220.0),
    #("l_act_habit", "Return next day", "User", 1060.0, 440.0),
  ]
}

fn l_onb_activation_task_edges() -> List(#(String, String, String)) {
  [
    #("l_act_tour", "l_act_first", ""),
    #("l_act_first", "l_act_aha", ""),
    #("l_act_aha", "l_act_habit", ""),
  ]
}

fn l_adp_community_tasks() -> List(#(String, String, String, Float, Float)) {
  [
    #("l_comm_post", "User posts tip", "Power user", 260.0, 220.0),
    #("l_comm_reply", "Community replies", "Community", 660.0, 220.0),
    #("l_comm_featured", "Featured in digest", "Community team", 1060.0, 220.0),
  ]
}

fn l_adp_community_task_edges() -> List(#(String, String, String)) {
  [
    #("l_comm_post", "l_comm_reply", ""),
    #("l_comm_reply", "l_comm_featured", ""),
  ]
}

fn low_touch_opportunities() -> List(Opportunity) {
  [
    Opportunity(
      id: OpportunityId("opp-acme"),
      name: "Acme Corp",
      motion: LowTouch,
      current_stage: Selection,
      visits: [
        visit("l_aw_community", "2026-02-18"),
        visit("l_ed_signup", "2026-02-20"),
        visit("l_su_land", "2026-02-20"),
        visit("l_su_form", "2026-02-20"),
        visit("l_su_verify", "2026-02-20"),
        visit("l_su_workspace", "2026-02-20"),
        visit("l_ed_interactive", "2026-02-22"),
        visit("l_sel_self_trial", "2026-03-01"),
        visit("l_sel_pql", "2026-03-18"),
        visit("l_pql_track", "2026-03-18"),
        visit("l_pql_score", "2026-03-25"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-tyrell"),
      name: "Tyrell Systems",
      motion: LowTouch,
      current_stage: Adoption,
      visits: [
        visit("l_aw_viral", "2025-08-14"),
        visit("l_vir_share", "2025-08-14"),
        visit("l_vir_visit", "2025-08-15"),
        visit("l_vir_signup", "2025-08-15"),
        visit("l_ed_signup", "2025-08-15"),
        visit("l_sel_self_trial", "2025-08-22"),
        visit("l_sel_pql", "2025-09-04"),
        visit("l_com_upgrade", "2025-09-18"),
        visit("l_onb_activation", "2025-09-18"),
        visit("l_act_tour", "2025-09-18"),
        visit("l_act_first", "2025-09-19"),
        visit("l_act_aha", "2025-09-22"),
        visit("l_adp_inapp", "2025-10-04"),
        visit("l_adp_community", "2025-12-12"),
      ],
    ),
    Opportunity(
      id: OpportunityId("opp-hooli"),
      name: "Hooli",
      motion: LowTouch,
      current_stage: Expansion,
      visits: [
        visit("l_aw_viral", "2024-11-02"),
        visit("l_ed_signup", "2024-11-02"),
        visit("l_ed_interactive", "2024-11-04"),
        visit("l_sel_self_trial", "2024-11-18"),
        visit("l_sel_pql", "2024-12-05"),
        visit("l_sel_team_spread", "2025-01-10"),
        visit("l_com_upgrade", "2025-02-01"),
        visit("l_onb_activation", "2025-02-02"),
        visit("l_onb_self", "2025-02-08"),
        visit("l_adp_inapp", "2025-03-20"),
        visit("l_adp_community", "2025-08-12"),
        visit("l_exp_usage", "2025-11-04"),
        visit("l_exp_invite", "2026-02-18"),
      ],
    ),
  ]
}

// ==========================================================================
// Breakdown construction helpers (shared)
// ==========================================================================

fn build_breakdown(
  parent: Node,
  map_edges: List(Edge),
  map_nodes: List(Node),
  task_specs: List(#(String, String, String, Float, Float)),
  task_edge_specs: List(#(String, String, String)),
) -> Graph {
  let task_nodes =
    list.map(task_specs, fn(spec) {
      let #(id, label, owner, x, y) = spec
      task(id, label, owner, parent.id, x, y)
    })
  let task_edges =
    list.map(task_edge_specs, fn(spec) {
      let #(from, to, label) = spec
      flow(from, to, label)
    })
  let entry = case task_specs {
    [#(id, _, _, _, _), ..] -> id
    [] -> ""
  }
  let exit = case list.reverse(task_specs) {
    [#(id, _, _, _, _), ..] -> id
    [] -> ""
  }
  breakdown_graph(
    parent.id,
    entry,
    exit,
    task_nodes,
    task_edges,
    map_edges,
    map_nodes,
  )
}

fn stub_breakdown(
  parent: Node,
  map_edges: List(Edge),
  map_nodes: List(Node),
) -> Graph {
  let NodeId(pid) = parent.id
  let task_id = pid <> "_stub"
  let nodes = [task(task_id, parent.label, "—", parent.id, 660.0, 330.0)]
  breakdown_graph(parent.id, task_id, task_id, nodes, [], map_edges, map_nodes)
}

fn breakdown_graph(
  parent: NodeId,
  entry: String,
  exit: String,
  nodes: List(Node),
  edges: List(Edge),
  map_edges: List(Edge),
  map_nodes: List(Node),
) -> Graph {
  let #(neighbors, bridges) =
    neighbor_nodes_and_edges(parent, entry, exit, map_edges, map_nodes)
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
  map_edges: List(Edge),
  map_nodes: List(Node),
) -> #(List(Node), List(Edge)) {
  let parent_label = case
    list.find(map_nodes, fn(n: Node) { n.id == parent })
  {
    Ok(n) -> n.label
    Error(_) -> ""
  }
  let inbound_ids =
    list.filter_map(map_edges, fn(e: Edge) {
      case e.to == parent && e.kind != Feedback {
        True -> Ok(e.from)
        False -> Error(Nil)
      }
    })
  let outbound_ids =
    list.filter_map(map_edges, fn(e: Edge) {
      case e.from == parent && e.kind != Feedback {
        True -> Ok(e.to)
        False -> Error(Nil)
      }
    })
  let in_nodes = neighbor_column(map_nodes, inbound_ids, Inbound, -240.0)
  let out_nodes = neighbor_column(map_nodes, outbound_ids, Outbound, 1420.0)
  let in_edges =
    list.map(in_nodes, fn(n: Node) {
      let NodeId(nid) = n.id
      edge(nid <> "_bridge_" <> entry, nid, entry, parent_label, Flow)
    })
  let out_edges =
    list.map(out_nodes, fn(n: Node) {
      let NodeId(nid) = n.id
      edge(exit <> "_bridge_" <> nid, exit, nid, parent_label, Flow)
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
          parent: None,
          children_level: Some(Breakdown),
          notes: "",
        )
      })
    }
  }
}

// ==========================================================================
// Shared node / edge helpers
// ==========================================================================

fn activity(
  id: String,
  label: String,
  stage: StageId,
  x: Float,
  y: Float,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Activity(stage),
    position: Point(x, y),
    size: Size(280.0, 82.0),
    parent: None,
    children_level: Some(Breakdown),
    notes: "",
  )
}

fn task(
  id: String,
  label: String,
  owner: String,
  parent: NodeId,
  x: Float,
  y: Float,
) -> Node {
  Node(
    id: NodeId(id),
    label: label,
    kind: Task(owner: owner),
    position: Point(x, y),
    size: Size(300.0, 110.0),
    parent: Some(parent),
    children_level: None,
    notes: "",
  )
}

fn flow(from: String, to: String, label: String) -> Edge {
  edge(from <> "_to_" <> to, from, to, label, Flow)
}

fn handoff(from: String, to: String, label: String) -> Edge {
  edge(from <> "_to_" <> to, from, to, label, Handoff)
}

fn edge(
  id: String,
  from: String,
  to: String,
  label: String,
  kind: atlas.EdgeKind,
) -> Edge {
  Edge(
    id: id,
    from: NodeId(from),
    to: NodeId(to),
    label: label,
    kind: kind,
  )
}

fn visit(id: String, date: String) -> OpportunityVisit {
  OpportunityVisit(node_id: NodeId(id), date: date)
}
