import atlas.{type Motion, type NodeId}

pub type Msg {
  NodeHovered(NodeId)
  NodeUnhovered
  NodeClicked(NodeId)
  BackClicked
  BreadcrumbClicked(Int)
  MotionToggled(Motion)
  ClearMotions
  ResetView
  PanStart
  PanMove(dx: Int, dy: Int, svg_width: Int, svg_height: Int)
  PanEnd
  WheelScroll(delta_y: Float, canvas_x: Float, canvas_y: Float)
}
