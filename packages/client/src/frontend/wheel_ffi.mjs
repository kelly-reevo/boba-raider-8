// Compute the wheel-event pointer position in the SVG canvas's logical
// 1600x900 coordinate space. Returns [canvas_x, canvas_y] as a Gleam tuple
// (which compiles to a plain JS array on the JavaScript target).
export function pointer_canvas_pos(event) {
  const target = event.currentTarget;
  if (!target || typeof target.getBoundingClientRect !== "function") {
    return [800.0, 450.0];
  }
  const r = target.getBoundingClientRect();
  const w = r.width;
  const h = r.height;
  if (w <= 0 || h <= 0) {
    return [800.0, 450.0];
  }
  const px = event.clientX - r.left;
  const py = event.clientY - r.top;
  const scale = Math.min(w / 1600, h / 900);
  const offset_x = (w - 1600 * scale) / 2;
  const offset_y = (h - 900 * scale) / 2;
  return [(px - offset_x) / scale, (py - offset_y) / scale];
}
