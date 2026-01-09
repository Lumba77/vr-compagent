## Overview
- Godot 4.2.2 project with XRTools addon for Quest/PC VR passthrough.
- Demo scenes: `demo_staging.tscn` → `scenes/baseline/vrcomp_minimal.tscn`.
- Focus: unified manipulation (UI/avatar/props) instead of XRTools pickup.

## Architecture
- `demo_scene_base.gd`: top-level VR interaction logic (UI, avatar possession, immersive setup workflow, unified manipulation, XR passthrough config).
- XRToolsPlayerBody exists but locomotion providers (`MovementDirect/Turn/Teleport`) disabled; now PlayerBody disabled at startup to avoid physics conflicts.
- UI rendered via `XRToolsViewport2DIn3D` (Display + VirtualKeyboard) anchored in world space.
- Config persistence via `user://ui_settings.cfg` (UI transform/scale) and `user://immersive_setup.cfg`.

## Components
### Unified manipulation (`demo_scene_base.gd`)
- Single-grip uses gripping hand joystick for translate/spin/distance, tilt only when trigger held.
- Two-hand grip toggles `_manip_two_hand_scale` for pinch scaling; clamps scale and rotation.
- Avatar manipulation suppresses avatar collisions and PlayerBody physics; re-enables on release.

### Immersive setup workflow
- Placement wizard: place → resize (two-hand pinch) → height adjust (single-hand) with persistent furniture config.
- Furniture hidden/inert in normal mode; immersive setup menu should be top/center world-space menu toggled from top UI.

### XR passthrough cleanup
- Transparent root/XR viewports, environment cleared, focus dimmer disabled.

## Patterns / Tips
- Use groups (`liftable`) for props eligible for unified manipulation.
- PlayerBody: disable `enabled` when manipulating avatar/UI to prevent rig drop.
- UI toggle via left menu/meta button; persists transforms.

## User Defined Namespaces
- frontend
- backend
- database
