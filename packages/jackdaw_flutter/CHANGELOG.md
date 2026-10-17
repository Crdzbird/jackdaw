## 1.0.0

First stable release.

- ChatController and ChatView with frame-merged streaming, approval cards
  and a composer with stop.
- UiSurfaceController and UiSurfaceView: agent-built UI on A2UI v1.0 with
  all 18 components of the basic catalog. A data write rebuilds and
  repaints only the components that read it; `trusted` skips the checks
  for messages from a source the app fully trusts.
