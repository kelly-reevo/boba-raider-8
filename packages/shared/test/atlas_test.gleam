import atlas.{
  type Graph, type Node, Activities, Breakdown, HighTouch, LowTouch,
  MediumTouch,
}
import atlas/lookup
import atlas/seed
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn overview_has_seven_stages_test() {
  let a = seed.atlas()
  list.length(a.overview.nodes) |> should.equal(7)
}

pub fn every_motion_has_an_atlas_test() {
  let a = seed.atlas()
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    should.be_true(list.length(ma.activity_map.nodes) >= 10)
  })
}

pub fn each_motion_atlas_has_all_stages_represented_test() {
  let a = seed.atlas()
  let stages = [
    atlas.Awareness,
    atlas.Education,
    atlas.Selection,
    atlas.Commitment,
    atlas.Onboarding,
    atlas.Adoption,
    atlas.Expansion,
  ]
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    list.each(stages, fn(s) {
      let matching =
        list.filter(ma.activity_map.nodes, fn(n: Node) {
          case n.kind {
            atlas.Activity(stage) -> stage == s
            _ -> False
          }
        })
      should.be_true(list.length(matching) >= 1)
    })
  })
}

pub fn cross_stage_edges_exist_test() {
  let a = seed.atlas()
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    let cross =
      list.filter(ma.activity_map.edges, fn(e) {
        let from_stage = node_stage(ma.activity_map, e.from)
        let to_stage = node_stage(ma.activity_map, e.to)
        from_stage != to_stage
      })
    should.be_true(list.length(cross) >= 5)
  })
}

pub fn every_drillable_activity_has_breakdown_test() {
  let a = seed.atlas()
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    list.each(ma.activity_map.nodes, fn(n: Node) {
      case n.children_level {
        Some(Breakdown) ->
          case lookup.find_breakdown_graph(a, m, n.id) {
            Some(g) -> g.level |> should.equal(Breakdown)
            None -> should.fail()
          }
        _ -> Nil
      }
    })
  })
}

pub fn no_dangling_edges_test() {
  let a = seed.atlas()
  check_graph_edges(a.overview)
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    check_graph_edges(ma.activity_map)
    list.each(ma.breakdowns, fn(pair: #(atlas.NodeId, Graph)) {
      check_graph_edges(pair.1)
    })
  })
}

fn check_graph_edges(graph: Graph) -> Nil {
  let ids = list.map(graph.nodes, fn(n: Node) { n.id })
  list.each(graph.edges, fn(e) {
    should.be_true(list.contains(ids, e.from))
    should.be_true(list.contains(ids, e.to))
  })
}

fn node_stage(
  graph: Graph,
  id: atlas.NodeId,
) -> option.Option(atlas.StageId) {
  case lookup.find_node(graph, id) {
    Some(n) ->
      case n.kind {
        atlas.Activity(s) -> Some(s)
        _ -> None
      }
    None -> None
  }
}

pub fn lookup_overview_test() {
  let a = seed.atlas()
  case lookup.find_graph(a, HighTouch, atlas.Overview, None) {
    Some(_) -> Nil
    None -> should.fail()
  }
}

pub fn lookup_activities_returns_map_test() {
  let a = seed.atlas()
  case lookup.find_graph(a, HighTouch, Activities, None) {
    Some(g) -> g.level |> should.equal(Activities)
    None -> should.fail()
  }
}

pub fn opportunities_tagged_with_matching_motion_test() {
  let a = seed.atlas()
  list.each([HighTouch, MediumTouch, LowTouch], fn(m) {
    let ma = lookup.motion_atlas(a, m)
    list.each(ma.opportunities, fn(o: atlas.Opportunity) {
      o.motion |> should.equal(m)
    })
  })
}
