import atlas.{
  type Atlas, type Graph, type Node, type NodeId, type Opportunity,
  type OpportunityId, type StageBand, type StageId, Activities, Activity,
  Breakdown, Overview,
}
import gleam/list
import gleam/option.{type Option, None, Some}

pub fn find_node(graph: Graph, id: NodeId) -> Option(Node) {
  list.find(graph.nodes, fn(n) { n.id == id })
  |> option.from_result
}

pub fn find_breakdown_graph(atlas: Atlas, activity: NodeId) -> Option(Graph) {
  find_in_pairs(atlas.breakdowns, activity)
}

pub fn find_graph(
  atlas: Atlas,
  level: atlas.Level,
  parent: Option(NodeId),
) -> Option(Graph) {
  case level, parent {
    Overview, _ -> Some(atlas.overview)
    Activities, _ -> Some(atlas.activity_map)
    Breakdown, Some(id) -> find_breakdown_graph(atlas, id)
    _, None -> None
  }
}

pub fn find_stage_band(
  bands: List(StageBand),
  stage: atlas.StageId,
) -> Option(StageBand) {
  list.find(bands, fn(b) { b.stage == stage })
  |> option.from_result
}

fn find_in_pairs(
  pairs: List(#(NodeId, Graph)),
  id: NodeId,
) -> Option(Graph) {
  case pairs {
    [] -> None
    [#(pair_id, graph), ..rest] ->
      case pair_id == id {
        True -> Some(graph)
        False -> find_in_pairs(rest, id)
      }
  }
}

pub fn find_opportunity(
  atlas: Atlas,
  id: OpportunityId,
) -> Option(Opportunity) {
  list.find(atlas.opportunities, fn(o: Opportunity) { o.id == id })
  |> option.from_result
}

pub fn opportunities_at_stage(
  atlas: Atlas,
  stage: StageId,
) -> List(Opportunity) {
  list.filter(atlas.opportunities, fn(o: Opportunity) {
    o.current_stage == stage
  })
}

pub fn visit_date(opp: Opportunity, node_id: NodeId) -> Option(String) {
  case list.find(opp.visits, fn(v) { v.node_id == node_id }) {
    Ok(v) -> Some(v.date)
    Error(_) -> None
  }
}

pub fn visited(opp: Opportunity, node_id: NodeId) -> Bool {
  case visit_date(opp, node_id) {
    Some(_) -> True
    None -> False
  }
}

pub fn stage_date(
  atlas: Atlas,
  opp: Opportunity,
  stage: StageId,
) -> Option(String) {
  let matched =
    list.filter_map(opp.visits, fn(v) {
      case find_node(atlas.activity_map, v.node_id) {
        Some(n) ->
          case n.kind {
            Activity(s) ->
              case s == stage {
                True -> Ok(v.date)
                False -> Error(Nil)
              }
            _ -> Error(Nil)
          }
        None -> Error(Nil)
      }
    })
  case matched {
    [] -> None
    [d, ..] -> Some(d)
  }
}
