import atlas.{
  type Atlas, type Graph, type Node, type NodeId, type StageBand, Activities,
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
