import atlas.{
  type Atlas, type Graph, type Motion, type MotionAtlas, type Node, type NodeId,
  type Opportunity, type OpportunityId, type StageBand, type StageId, type ViewBox,
  Activities, Activity, Breakdown, MotionAtlas, Overview, ViewBox,
}
import gleam/list
import gleam/option.{type Option, None, Some}

pub fn find_node(graph: Graph, id: NodeId) -> Option(Node) {
  list.find(graph.nodes, fn(n) { n.id == id })
  |> option.from_result
}

pub fn motion_atlas(atlas: Atlas, motion: Motion) -> MotionAtlas {
  case list.key_find(atlas.motion_atlases, motion) {
    Ok(ma) -> ma
    Error(_) ->
      MotionAtlas(
        activity_map: atlas.overview,
        breakdowns: [],
        opportunities: [],
      )
  }
}

pub fn find_breakdown_graph(
  atlas: Atlas,
  motion: Motion,
  activity: NodeId,
) -> Option(Graph) {
  let ma = motion_atlas(atlas, motion)
  find_in_pairs(ma.breakdowns, activity)
}

pub fn find_graph(
  atlas: Atlas,
  motion: Motion,
  level: atlas.Level,
  parent: Option(NodeId),
) -> Option(Graph) {
  case level, parent {
    Overview, _ -> Some(atlas.overview)
    Activities, _ -> Some(motion_atlas(atlas, motion).activity_map)
    Breakdown, Some(id) -> find_breakdown_graph(atlas, motion, id)
    _, None -> None
  }
}

pub fn find_stage_band(
  bands: List(StageBand),
  stage: StageId,
) -> Option(StageBand) {
  list.find(bands, fn(b) { b.stage == stage })
  |> option.from_result
}

pub fn focus_viewbox(motion_atlas: MotionAtlas, stage: StageId) -> ViewBox {
  let bands = motion_atlas.activity_map.bands
  case find_stage_band(bands, stage) {
    Some(band) -> {
      let pad = 240.0
      ViewBox(
        x: band.x -. pad,
        y: 240.0,
        width: band.width +. { pad *. 2.0 },
        height: 1000.0,
      )
    }
    None -> motion_atlas.activity_map.viewbox
  }
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
  motion: Motion,
  id: OpportunityId,
) -> Option(Opportunity) {
  let opps = motion_atlas(atlas, motion).opportunities
  list.find(opps, fn(o: Opportunity) { o.id == id })
  |> option.from_result
}

pub fn opportunities_at_stage(
  atlas: Atlas,
  motion: Motion,
  stage: StageId,
) -> List(Opportunity) {
  let opps = motion_atlas(atlas, motion).opportunities
  list.filter(opps, fn(o: Opportunity) { o.current_stage == stage })
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
  motion: Motion,
  opp: Opportunity,
  stage: StageId,
) -> Option(String) {
  let activity_map = motion_atlas(atlas, motion).activity_map
  let matched =
    list.filter_map(opp.visits, fn(v) {
      case find_node(activity_map, v.node_id) {
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
