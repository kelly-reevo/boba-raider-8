import atlas.{type ViewBox}
import gleam/float
import lustre/attribute.{type Attribute, attribute}
import lustre/element.{type Element}
import lustre/element/svg

pub const canvas_width: Float = 1600.0

pub const canvas_height: Float = 900.0

pub fn fattr(name: String, value: Float) -> Attribute(msg) {
  attribute(name, float.to_string(value))
}

pub fn viewbox_transform(vb: ViewBox) -> String {
  let sx = canvas_width /. vb.width
  let sy = canvas_height /. vb.height
  let s = float.min(sx, sy)
  let tx = { canvas_width -. s *. vb.width } /. 2.0 -. vb.x *. s
  let ty = { canvas_height -. s *. vb.height } /. 2.0 -. vb.y *. s
  "translate("
  <> float.to_string(tx)
  <> " "
  <> float.to_string(ty)
  <> ") scale("
  <> float.to_string(s)
  <> ")"
}

pub fn arrow_marker_defs() -> Element(msg) {
  svg.defs([], [
    svg.marker(
      [
        attribute("id", "arrow"),
        attribute("viewBox", "0 0 10 10"),
        attribute("refX", "9"),
        attribute("refY", "5"),
        attribute("markerWidth", "8"),
        attribute("markerHeight", "8"),
        attribute("orient", "auto-start-reverse"),
      ],
      [
        svg.path([
          attribute("d", "M 0 0 L 10 5 L 0 10 z"),
          attribute("fill", "#7e8da3"),
        ]),
      ],
    ),
    svg.marker(
      [
        attribute("id", "arrow-dashed"),
        attribute("viewBox", "0 0 10 10"),
        attribute("refX", "9"),
        attribute("refY", "5"),
        attribute("markerWidth", "8"),
        attribute("markerHeight", "8"),
        attribute("orient", "auto-start-reverse"),
      ],
      [
        svg.path([
          attribute("d", "M 0 0 L 10 5 L 0 10 z"),
          attribute("fill", "#a06bc8"),
        ]),
      ],
    ),
  ])
}
