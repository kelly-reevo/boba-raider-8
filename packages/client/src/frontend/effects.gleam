import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Placeholder for API effects
pub fn fetch_data() -> Effect(Msg) {
  effect.none()
}
