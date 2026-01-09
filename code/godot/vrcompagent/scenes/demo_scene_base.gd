class_name DemoSceneBase
extends XRToolsSceneBase

const XRToolsUserSettingsScript = preload("res://addons/godot-xr-tools/user_settings/user_settings.gd")

var _ui_visible: bool = false
var _prev_menu_button: bool = false
var _ui_follow_gaze: bool = false
var _ui_dragging: bool = false
var _drag_controller: XRController3D
var _drag_offset: Transform3D
var _prev_left_grip: bool = false
var _prev_right_grip: bool = false

const _UI_DRAG_TRIGGER_GRACE_MS: int = 160
var _ui_drag_candidate: bool = false
var _ui_drag_candidate_controller: XRController3D
var _ui_drag_candidate_start_ms: int = 0

var _manipulating: bool = false
var _manip_double_grip: bool = false
var _manip_two_hand_scale: bool = false
var _manip_target: Node3D = null
var _manip_single_controller_is_left: bool = false
var _manip_prev_left_grip: bool = false
var _manip_prev_right_grip: bool = false

var _manip_target_is_ui: bool = false
var _manip_target_floor_lock: bool = true
var _manip_target_allow_tilt: bool = false
var _manip_distance: float = 1.2
var _manip_scale: float = 1.0
var _manip_prev_toggle_left: bool = false
var _manip_prev_toggle_right: bool = false

var _manip_scale_start_hands_dist: float = 0.0
var _manip_scale_start_scale: float = 1.0

var _possessing: bool = false

var _customizing: bool = false
var _prev_customize_toggle_left: bool = false
var _prev_customize_toggle_right: bool = false

var _avatar_scale: float = 1.0
var _avatar_floor_offset: float = 0.0

const _POSSESS_MOVE_SPEED: float = 1.5
const _POSSESS_TURN_SPEED: float = 2.2

const _AVATAR_SCALE_SPEED: float = 0.8
const _AVATAR_HEIGHT_SPEED: float = 0.8
const _AVATAR_SCALE_MIN: float = 0.6
const _AVATAR_SCALE_MAX: float = 1.6

const _UI_DISTANCE: float = 1.0
const _UI_HEIGHT_OFFSET: float = -0.2
const _UI_KEYBOARD_DROP: float = 1.45
const _UI_KEYBOARD_GAP: float = 0.03
const _UI_FOLLOW_SMOOTH_TIME: float = 0.08
const _UI_RESIZE_SMOOTH_TIME: float = 0.03
const _UI_SCALE_MIN: float = 0.6
const _UI_SCALE_MAX: float = 2.4
const _KEYBOARD_SCREEN_SIZE_MULT: float = 2.0

const _UI_SETTINGS_PATH: String = "user://ui_settings.cfg"

const _HAND_VISUAL_ROLL_DEG: float = -90.0
const _GRIP_THRESHOLD: float = 0.5
const _TRIGGER_THRESHOLD: float = 0.5

const _UI_OBJECTS_LAYER_BIT: int = 1 << 22

# Layer masks for context-sensitive input gating.
const _PICKABLE_OBJECTS_LAYER_BIT: int = 1 << 2
const _POINTABLE_OBJECTS_LAYER_BIT: int = 1 << 20
const _INTERACTABLE_MASK: int = _UI_OBJECTS_LAYER_BIT | _PICKABLE_OBJECTS_LAYER_BIT | _POINTABLE_OBJECTS_LAYER_BIT

const _IMMERSIVE_SETUP_CONFIG_PATH: String = "user://immersive_setup.cfg"
const _FURNITURE_VOL_HEIGHT: float = 0.18
const _SETUP_GRAB_SPEED: float = 1.2
const _SETUP_ROTATE_SPEED: float = 2.2
const _SETUP_RESIZE_SPEED: float = 1.2
const _SETUP_HEIGHT_SPEED: float = 0.8

enum SetupPhase {
	PLACE = 0,
	RESIZE = 1,
	HEIGHT = 2,
}

var _furniture_root: Node3D
var _immersive_setup_active: bool = false
var _immersive_setup_mode: bool = false
var _setup_item_index: int = 0
var _setup_grabbing: bool = false
var _setup_grab_distance: float = 1.5
var _setup_prev_grip: bool = false
var _setup_prev_trigger: bool = false
var _setup_prev_skip: bool = false
var _setup_hovering_surface: bool = false

var _setup_two_hand_scale: bool = false
var _setup_scale_start_hands_dist: float = 1.0
var _setup_scale_start_size: Vector2 = Vector2.ONE

var _setup_items: Array[Dictionary] = []
var _setup_current: Dictionary = {}	
var _setup_preview: Node3D
var _setup_skip_button: Node3D

var _setup_top_menu: Node3D
var _setup_prompt: Label3D
var _ui_visible_before_setup_place: bool = true
var _setup_single_item: bool = false
var _setup_delete_mode: bool = false

var _setup_phase: int = SetupPhase.HEIGHT
var _setup_current_height: float = 0.0
var _setup_phase_time: float = 0.0

var _display_ui_hooked: bool = false
var _user_profile_username: String = ""
var _user_profile_instruction: String = ""
var _user_profile_memories: PackedStringArray = PackedStringArray()

var _ui_focus_mode: bool = false
var _focus_dimmer: Node3D

@onready var _display: Node3D = get_node_or_null("Display")
@onready var _virtual_keyboard: Node3D = get_node_or_null("VirtualKeyboard")
@onready var _avatar: Node3D = get_node_or_null("Avatar")

var _body_animation_player: AnimationPlayer

@onready var _left_pointer: Node = get_node_or_null("XROrigin3D/LeftAim/FunctionPointer")
@onready var _right_pointer: Node = get_node_or_null("XROrigin3D/RightAim/FunctionPointer")

@onready var _gaze_pointer: Node = get_node_or_null("XROrigin3D/XRCamera3D/FunctionGazePointer")

var _saved_camera_environment: Environment
var _saved_avatar_collision: Dictionary = {}

var _ui_scale: float = 1.0
var _display_base_screen_size: Vector2 = Vector2.ZERO
var _keyboard_base_screen_size: Vector2 = Vector2.ZERO

var _ui_follow_smoothed: bool = false
var _ui_follow_smoothed_xform: Transform3D

var _ui_resizing: bool = false
var _ui_resize_start_hands_dist: float = 0.0
var _ui_resize_start_scale: float = 1.0

var _avatar_lie_clips: Array[StringName] = []
var _avatar_lie_clip_index: int = 0
var _avatar_lie_rng := RandomNumberGenerator.new()

var _avatar_collision_suppressed_for_manip: bool = false
var _manip_target_collision_saved: Dictionary = {}
var _manip_target_collision_suppressed: bool = false

var _manip_raycast_exclude: Array[RID] = []

var _rig_y_lock_active: bool = false
var _rig_y_lock_value: float = 0.0

var _rig_y_lock_due_to_pickup: bool = false

var _player_body: Node
var _player_body_saved_enabled: bool = true
var _player_body_suppressed_for_manip: bool = false

func _ready():
	super()
	_ensure_passthrough_viewport_transparency()
	_ensure_passthrough_environment()
	_ensure_passthrough_world_environment()
	_ensure_passthrough_no_msaa_halo()
	_disable_player_locomotion()
	_disable_xrtools_pickup()
	_hook_avatar_body_animation_player()
	_hide_arm_ui()
	_apply_hand_visual_offsets()
	_rebuild_manip_raycast_exclude()

	if _gaze_pointer and ("enabled" in _gaze_pointer):
		_gaze_pointer.enabled = false

	_hook_display_ui()
	_ensure_basic_lighting()
	_ensure_floor()
	_ensure_focus_dimmer()
	_ensure_furniture_root()
	_setup_init_items()
	_load_or_start_immersive_setup()

	_set_ui_visible(false)
	_disable_ui_collisions()
	_force_ui_on_top()
	_configure_pointer_for_ui()
	_configure_pointer_visuals_on_top()
	_disable_gaze_pointer()
	_prepare_ui_scaling()
	_load_ui_settings()
	_update_ui_pose()
	_update_avatar_pose()
	call_deferred("_hook_display_ui")

	_player_body = get_node_or_null("XROrigin3D/PlayerBody") as Node
	# This project currently disables locomotion and uses unified manipulation.
	# Keeping the XRTools PlayerBody active can still cause floor push-through issues
	# due to penetration resolution and physics-step ordering in XR.
	# Disable it by default to keep the rig stable while interacting.
	if _player_body and is_instance_valid(_player_body) and ("enabled" in _player_body):
		_player_body_saved_enabled = bool(_player_body.get("enabled"))
		_set_player_body_enabled(false)

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())


func _disable_xrtools_pickup() -> void:
	# The project goal is unified manipulation (grip + stick + two-hand pinch).
	# XRToolsFunctionPickup + collision-hands provide a separate physical grab system
	# which can steal grip input and can push PlayerBody through the floor.
	var rig := get_node_or_null("XROrigin3D") as Node
	if not rig:
		return
	var stack: Array[Node] = [rig]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		for c in n.get_children():
			stack.append(c)
		if n.has_method("is_xr_class"):
			if n.call("is_xr_class", "XRToolsFunctionPickup"):
				if "enabled" in n:
					n.enabled = false
				if n.has_method("drop_object"):
					n.call("drop_object")
			elif n.call("is_xr_class", "XRToolsCollisionHand"):
				if "mode" in n:
					n.mode = 0
				if "collision_layer" in n:
					n.collision_layer = 0
				if "collision_mask" in n:
					n.collision_mask = 0


func _rebuild_manip_raycast_exclude() -> void:
	_manip_raycast_exclude = []
	var rig := get_node_or_null("XROrigin3D") as Node
	if not rig:
		return
	var stack: Array[Node] = [rig]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		for c in n.get_children():
			stack.append(c)
		if n is CollisionObject3D:
			_manip_raycast_exclude.append((n as CollisionObject3D).get_rid())


func _hide_arm_ui() -> void:
	var cp := get_node_or_null("XROrigin3D/ControlPad") as Node
	if cp and ("visible" in cp):
		cp.visible = false
	for p in ["XROrigin3D/LeftHand/ControlPadLocationLeft", "XROrigin3D/RightHand/ControlPadLocationRight"]:
		var n := get_node_or_null(p) as Node
		if n and ("visible" in n):
			n.visible = false


func _apply_hand_visual_offsets() -> void:
	for p in ["XROrigin3D/LeftHand/LeftHand", "XROrigin3D/RightHand/RightHand"]:
		var n := get_node_or_null(p) as Node3D
		if not n:
			continue
		# Only apply if the scene hasn't already set an explicit roll.
		if abs(n.rotation_degrees.z) < 1.0:
			n.rotation_degrees.z = _HAND_VISUAL_ROLL_DEG

func _hook_avatar_body_animation_player() -> void:
	_body_animation_player = null
	if not _avatar or not is_instance_valid(_avatar):
		return
	var ap := _avatar.get_node_or_null("BodyAnimationPlayer")
	if ap and ap is AnimationPlayer:
		_body_animation_player = ap as AnimationPlayer
		if _body_animation_player.has_method("play_mixamo"):
			_body_animation_player.call("play_mixamo")
		_refresh_avatar_lie_clips()
		_avatar_lie_rng.randomize()


func _get_controller_stick(controller: XRController3D) -> Vector2:
	if not controller:
		return Vector2.ZERO
	# Controller action names differ per runtime/device. Try common names.
	for action_name in ["primary", "primary_stick", "thumbstick", "joy", "stick"]:
		var v: Variant = controller.get_vector2(action_name)
		if typeof(v) == TYPE_VECTOR2:
			return v as Vector2
	# Some runtimes only expose separate axes.
	var x := float(controller.get_float("primary_x"))
	var y := float(controller.get_float("primary_y"))
	if absf(x) > 0.001 or absf(y) > 0.001:
		return Vector2(x, y)
	return Vector2.ZERO


func _set_rig_y_lock(enabled: bool) -> void:
	var rig := get_node_or_null("XROrigin3D") as Node3D
	if not rig:
		_rig_y_lock_active = false
		return
	_rig_y_lock_active = enabled
	if enabled:
		_rig_y_lock_value = rig.global_position.y
	else:
		_rig_y_lock_value = 0.0


func _any_hand_holding_pickable() -> bool:
	var left_pickup := XRToolsFunctionPickup.find_left(self)
	if left_pickup and is_instance_valid(left_pickup.picked_up_object):
		return true
	var right_pickup := XRToolsFunctionPickup.find_right(self)
	if right_pickup and is_instance_valid(right_pickup.picked_up_object):
		return true
	return false


func _apply_rig_y_lock() -> void:
	if not _rig_y_lock_active:
		return
	var rig := get_node_or_null("XROrigin3D") as Node3D
	if not rig:
		_rig_y_lock_active = false
		return
	var p := rig.global_position
	p.y = _rig_y_lock_value
	rig.global_position = p


func _set_player_body_enabled(enabled: bool) -> void:
	if not _player_body or not is_instance_valid(_player_body):
		_player_body = get_node_or_null("XROrigin3D/PlayerBody") as Node
	if not _player_body or not is_instance_valid(_player_body):
		return
	if not ("enabled" in _player_body):
		return
	_player_body.set("enabled", enabled)


func _restore_player_body_after_manip() -> void:
	if not _player_body_suppressed_for_manip:
		return
	_player_body_suppressed_for_manip = false
	_set_player_body_enabled(_player_body_saved_enabled)


func _refresh_avatar_lie_clips() -> void:
	_avatar_lie_clips = []
	_avatar_lie_clip_index = 0
	if not _body_animation_player or not is_instance_valid(_body_animation_player):
		return
	if not ("clip_paths" in _body_animation_player):
		return
	var clip_paths: Dictionary = _body_animation_player.get("clip_paths") as Dictionary
	if clip_paths.is_empty():
		return
	for k in clip_paths.keys():
		var clip_name := String(k)
		var lower := clip_name.to_lower()
		if lower.find("lie") != -1 or lower.find("lying") != -1 or lower.find("laying") != -1 or lower.find("lay") != -1 or lower.find("sleep") != -1 or lower.find("rest") != -1 or lower.find("prone") != -1 or lower.find("supine") != -1:
			_avatar_lie_clips.append(StringName(clip_name))


func _play_avatar_idle() -> void:
	if not _body_animation_player or not is_instance_valid(_body_animation_player):
		return
	if _body_animation_player.has_method("play_idle"):
		_body_animation_player.call("play_idle")
		return
	_body_animation_player.play(&"idle")


func _play_avatar_lie_pose() -> void:
	if not _body_animation_player or not is_instance_valid(_body_animation_player):
		return
	if _avatar_lie_clips.is_empty():
		_play_avatar_idle()
		return
	# Cycle through available lying clips to provide variety.
	_avatar_lie_clip_index = int(posmod(_avatar_lie_clip_index, _avatar_lie_clips.size()))
	var clip := _avatar_lie_clips[_avatar_lie_clip_index]
	_avatar_lie_clip_index += 1
	if _body_animation_player.has_method("play_body"):
		_body_animation_player.call("play_body", clip)
		return
	_body_animation_player.play(clip)


func _unhandled_input(event: InputEvent) -> void:
	if not _body_animation_player or not is_instance_valid(_body_animation_player):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_I:
			if _body_animation_player.has_method("play_idle"):
				_body_animation_player.call("play_idle")
			else:
				_body_animation_player.play(&"idle")
			return
		if key_event.keycode == KEY_A:
			if _body_animation_player.has_method("play_angry"):
				_body_animation_player.call("play_angry")
			else:
				_body_animation_player.play(&"angry")
			return


func _ensure_passthrough_viewport_transparency() -> void:
	# Passthrough requires the main/root viewport to have a transparent background.
	# We set it as a safe fallback whenever XR is active.
	var vp := get_viewport()
	if vp and vp.use_xr:
		vp.transparent_bg = true
		if get_tree() and get_tree().root:
			get_tree().root.transparent_bg = true


func _ensure_passthrough_no_msaa_halo() -> void:
	# With a transparent background, MSAA commonly produces dark "halos" around
	# all rendered geometry when composited over passthrough.
	var vp := get_viewport()
	if not vp or not vp.use_xr or not vp.transparent_bg:
		return
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.msaa_2d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	if get_tree() and get_tree().root:
		get_tree().root.msaa_3d = Viewport.MSAA_DISABLED
		get_tree().root.msaa_2d = Viewport.MSAA_DISABLED
		get_tree().root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA


func _ensure_passthrough_environment() -> void:
	# The XRTools staging camera can have a Sky environment assigned.
	# In passthrough this can show up as a dark "backdrop" behind everything.
	var vp := get_viewport()
	if not vp or not vp.use_xr or not vp.transparent_bg:
		return
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as XRCamera3D
	if not camera:
		return
	if camera.environment and not _saved_camera_environment:
		_saved_camera_environment = camera.environment
	camera.environment = null


func _ensure_passthrough_world_environment() -> void:
	# Some scenes/resources may add a WorldEnvironment with a Sky background.
	# In passthrough this can appear as a second "surface" behind everything.
	var vp := get_viewport()
	if not vp or not vp.use_xr or not vp.transparent_bg:
		return
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		for c in n.get_children():
			stack.append(c)
		if n is WorldEnvironment:
			(n as WorldEnvironment).environment = null


func _set_avatar_collision_enabled(enabled: bool) -> void:
	if not _avatar:
		return
	var stack: Array[Node] = [_avatar]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		for c in n.get_children():
			stack.append(c)
		if not (n is CollisionObject3D):
			continue
		var co := n as CollisionObject3D
		if enabled:
			if _saved_avatar_collision.has(co):
				var saved: Dictionary = _saved_avatar_collision[co] as Dictionary
				co.collision_layer = int(saved.get("layer", co.collision_layer))
				co.collision_mask = int(saved.get("mask", co.collision_mask))
		else:
			if not _saved_avatar_collision.has(co):
				_saved_avatar_collision[co] = {"layer": co.collision_layer, "mask": co.collision_mask}
			co.collision_layer = 0
			co.collision_mask = 0


func _ensure_basic_lighting() -> void:
	# VRM/MToon models can appear pitch-black if there's no scene lighting.
	# Add a minimal key+fill light only if none exists.
	var has_dir := false
	for c in get_children():
		if c is DirectionalLight3D:
			has_dir = true
			break
	if has_dir:
		return

	var key := DirectionalLight3D.new()
	key.name = "AutoKeyLight"
	key.light_color = Color(1.0, 0.97, 0.9)
	key.light_energy = 1.2
	key.light_indirect_energy = 1.0
	key.shadow_enabled = false
	key.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.name = "AutoFillLight"
	fill.light_color = Color(0.75, 0.85, 1.0)
	fill.light_energy = 0.45
	fill.light_indirect_energy = 0.8
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-20.0, -145.0, 0.0)
	add_child(fill)


func _ensure_floor() -> void:
	var existing := get_node_or_null("Floor") as StaticBody3D
	if existing and is_instance_valid(existing):
		# Some scenes (e.g. vrcomp_minimal.tscn) include a Floor with a too-restrictive
		# collision mask (often 1), which doesn't collide with PlayerBody.
		existing.collision_layer = 1
		existing.collision_mask = -1
		return

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = -1

	var shape := BoxShape3D.new()
	shape.size = Vector3(50.0, 1.0, 50.0)

	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0.0, -0.5, 0.0)

	floor_body.add_child(cs)
	add_child(floor_body)


func _ensure_furniture_root() -> void:
	if _furniture_root and is_instance_valid(_furniture_root):
		return
	var existing := get_node_or_null("Furniture") as Node3D
	if existing:
		_furniture_root = existing
		return
	_furniture_root = Node3D.new()
	_furniture_root.name = "Furniture"
	add_child(_furniture_root)


func _setup_init_items() -> void:
	# Defaults are intentionally simple and can be tuned later.
	_setup_items = [
		{"key": "sofa", "label": "Sofa", "height": 0.45, "size": Vector2(1.8, 0.9), "color": Color(0.2, 0.9, 1.0, 1.0)},
		{"key": "desk", "label": "Desk", "height": 0.75, "size": Vector2(1.2, 0.6), "color": Color(0.9, 0.7, 0.2, 1.0)},
		{"key": "bed", "label": "Bed", "height": 0.55, "size": Vector2(2.0, 1.4), "color": Color(0.8, 0.2, 1.0, 1.0)},
		{"key": "window", "label": "Window", "height": 1.2, "size": Vector2(1.2, 0.15), "color": Color(0.2, 0.8, 0.6, 1.0)},
		{"key": "door", "label": "Door", "height": 1.0, "size": Vector2(0.95, 0.18), "color": Color(0.7, 0.5, 0.2, 1.0)},
		{"key": "chair", "label": "Chair", "height": 0.45, "size": Vector2(0.55, 0.55), "color": Color(0.95, 0.35, 0.2, 1.0)},
		{"key": "wall_art", "label": "Wall Art", "height": 1.4, "size": Vector2(0.75, 0.08), "color": Color(0.7, 0.2, 0.9, 1.0)},
		{"key": "lamp", "label": "Lamp", "height": 1.1, "size": Vector2(0.35, 0.35), "color": Color(1.0, 0.95, 0.35, 1.0)}
	]


func _load_or_start_immersive_setup() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH)
	if err == OK and cfg.has_section("anchors"):
		_spawn_saved_furniture(cfg)
	_immersive_setup_active = false
	# Do not auto-start immersive setup. The user explicitly triggers setup per item
	# via the setup menu.
	return


func _set_saved_furniture_visible(enabled: bool) -> void:
	if not _furniture_root:
		return
	for c in _furniture_root.get_children():
		var n := c as Node3D
		if n and n.name.begins_with("Saved_"):
			n.visible = enabled


func _set_immersive_setup_mode(enabled: bool) -> void:
	_immersive_setup_mode = enabled
	_ensure_immersive_setup_top_menu()
	if _setup_top_menu and is_instance_valid(_setup_top_menu):
		_setup_top_menu.visible = enabled
	# Furniture is invisible in normal mode; visible in setup mode.
	_set_saved_furniture_visible(enabled)
	# Delete mode only makes sense in setup mode.
	if not enabled and _setup_delete_mode:
		_setup_delete_mode = false
		_apply_setup_delete_mode(false)


func _ensure_immersive_setup_top_menu() -> void:
	if _setup_top_menu and is_instance_valid(_setup_top_menu):
		return
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return
	var root := Node3D.new()
	root.name = "ImmersiveSetupTopMenu"
	# Top-of-view, slightly forward.
	root.position = Vector3(0.0, 0.22, -0.75)
	root.rotation = Vector3(0.0, 0.0, 0.0)
	camera.add_child(root)
	_setup_top_menu = root
	_setup_top_menu.visible = false
	var prompt := Label3D.new()
	prompt.name = "SetupPrompt"
	prompt.text = ""
	prompt.font_size = 20
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.position = Vector3(0.0, -0.12, 0.0)
	prompt.modulate = Color(1, 1, 1, 1)
	root.add_child(prompt)
	_setup_prompt = prompt

	var x := -0.55
	var y := 0.0
	var done := _create_setup_menu_button("Setup_Done", "Done")
	done.position = Vector3(x, y, 0.0)
	root.add_child(done)
	var done_ia := done.get_node_or_null("Interactable")
	if done_ia and done_ia is XRToolsInteractableArea:
		(done_ia as XRToolsInteractableArea).pointer_event.connect(self._on_setup_top_menu_pointer_event.bind("__done__"))
	x += 0.28
	var del := _create_setup_menu_button("Setup_Delete", "Delete")
	del.position = Vector3(x, y, 0.0)
	root.add_child(del)
	var del_ia := del.get_node_or_null("Interactable")
	if del_ia and del_ia is XRToolsInteractableArea:
		(del_ia as XRToolsInteractableArea).pointer_event.connect(self._on_setup_top_menu_pointer_event.bind("__delete__"))
	x += 0.32
	for item in _setup_items:
		var key: String = str(item.get("key", ""))
		var label: String = str(item.get("label", key))
		if key.is_empty():
			continue
		var b := _create_setup_menu_button("Setup_" + key, label)
		b.position = Vector3(x, y, 0.0)
		root.add_child(b)
		var ia := b.get_node_or_null("Interactable")
		if ia and ia is XRToolsInteractableArea:
			(ia as XRToolsInteractableArea).pointer_event.connect(self._on_setup_top_menu_pointer_event.bind(key))
		x += 0.28


func _on_setup_top_menu_pointer_event(event: XRToolsPointerEvent, key: String) -> void:
	if event.event_type != XRToolsPointerEvent.Type.PRESSED:
		return
	if key == "__done__":
		_set_immersive_setup_mode(false)
		return
	if key == "__delete__":
		_setup_delete_mode = not _setup_delete_mode
		_apply_setup_delete_mode(_setup_delete_mode)
		return
	_start_immersive_setup_for_key(key)


func _create_setup_menu_button(name_str: String, label: String) -> Node3D:
	var root := Node3D.new()
	root.name = name_str

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.24, 0.085)
	visual.mesh = qm
	# Keep buttons upright (facing camera); do not rotate flat.
	visual.rotation_degrees = Vector3(0.0, 0.0, 0.0)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 25
	mat.albedo_color = Color(0.1, 0.1, 0.1, 0.55)
	visual.material_override = mat
	root.add_child(visual)

	# Click target
	var ia := XRToolsInteractableArea.new()
	ia.name = "Interactable"
	ia.collision_layer = _UI_OBJECTS_LAYER_BIT
	ia.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.01, 0.085)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	cs.position = Vector3(0.0, 0.0, 0.0)
	ia.add_child(cs)
	root.add_child(ia)

	# Text label (simple 3D label)
	var tl := Label3D.new()
	tl.name = "Label"
	tl.text = label
	tl.font_size = 18
	tl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tl.position = Vector3(0.0, 0.0, 0.01)
	tl.modulate = Color(1, 1, 1, 1)
	root.add_child(tl)

	return root


func _start_immersive_setup_for_key(key: String) -> void:
	if key.is_empty():
		return
	# Find matching item index.
	var index := -1
	for ii in range(_setup_items.size()):
		if str(_setup_items[ii].get("key", "")) == key:
			index = ii
			break
	if index < 0:
		return

	_immersive_setup_active = true
	_setup_single_item = true
	_setup_item_index = index
	_setup_grabbing = false
	_setup_prev_grip = false
	_setup_prev_trigger = false
	_setup_prev_skip = false
	_setup_current = {}
	_ui_visible_before_setup_place = _ui_visible
	_set_ui_visible(false)
	# Hide top menu while placing.
	if _setup_top_menu and is_instance_valid(_setup_top_menu):
		_setup_top_menu.visible = false
	_apply_setup_delete_mode(false)
	_setup_create_skip_button()
	_setup_begin_item()


func _hook_display_ui() -> void:
	if _display_ui_hooked:
		return
	if not _display:
		return
	var scene_node: Node = _display.get("scene_node")
	if not scene_node:
		return
	if scene_node.has_signal("immersive_setup_reconfigure_requested"):
		var reconfig_cb := Callable(self, "_on_immersive_setup_reconfigure_requested")
		if not scene_node.immersive_setup_reconfigure_requested.is_connected(reconfig_cb):
			scene_node.immersive_setup_reconfigure_requested.connect(reconfig_cb)
		if scene_node.has_signal("focus_mode_changed"):
			var focus_cb := Callable(self, "_on_ui_focus_mode_changed")
			if not scene_node.focus_mode_changed.is_connected(focus_cb):
				scene_node.focus_mode_changed.connect(focus_cb)
		_display_ui_hooked = true
		_update_user_profile_from_display(scene_node)
		_apply_ui_focus_visuals(_ui_focus_mode)


func _on_ui_focus_mode_changed(focused: bool) -> void:
	_ui_focus_mode = focused
	_apply_ui_focus_visuals(_ui_focus_mode)


func _ensure_focus_dimmer() -> void:
	if _focus_dimmer and is_instance_valid(_focus_dimmer):
		return
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return

	var root := Node3D.new()
	root.name = "FocusDimmer"
	root.visible = false

	var mi := MeshInstance3D.new()
	mi.name = "Quad"
	var qm := QuadMesh.new()
	qm.size = Vector2(4.0, 4.0)
	mi.mesh = qm
	mi.position = Vector3(0.0, 0.0, -0.6)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 127
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
	mi.material_override = mat

	root.add_child(mi)
	camera.add_child(root)
	_focus_dimmer = root


func _apply_ui_focus_visuals(focused: bool) -> void:
	# Disable passthrough dimmer overlay (it can look like a second, misaligned surface in VR).
	if _focus_dimmer and is_instance_valid(_focus_dimmer):
		_focus_dimmer.visible = false

	# Make UI screen less transparent/brighter on focus.
	for panel in [_display, _virtual_keyboard]:
		if not panel:
			continue
		var screen := (panel as Node).get_node_or_null("Screen") as MeshInstance3D
		if not screen:
			continue
		var mat := screen.get_surface_override_material(0) as BaseMaterial3D
		if not mat:
			mat = screen.get_active_material(0) as BaseMaterial3D
		if mat and mat is BaseMaterial3D:
			var unique := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			if unique is StandardMaterial3D:
				var sm := unique as StandardMaterial3D
				var a := 1.0 if focused else 0.75
				sm.albedo_color = Color(1, 1, 1, a)
			screen.set_surface_override_material(0, unique)


func _disable_player_locomotion() -> void:
	# In immersive/passthrough mode we don't want the user rig to move the world.
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f and ("enabled" in f):
				f.enabled = false


func _update_user_profile_from_display(scene_node: Node) -> void:
	if scene_node and scene_node.has_method("get_username"):
		var new_username := str(scene_node.call("get_username"))
		if new_username != _user_profile_username:
			_user_profile_username = new_username
			print("User profile username: ", _user_profile_username)
	if scene_node and scene_node.has_method("get_instruction_prompt"):
		var new_instruction := str(scene_node.call("get_instruction_prompt"))
		if new_instruction != _user_profile_instruction:
			_user_profile_instruction = new_instruction
			print("User profile instruction prompt updated")
	if scene_node and scene_node.has_method("get_memories"):
		var new_memories: PackedStringArray = scene_node.call("get_memories")
		if new_memories is PackedStringArray and new_memories != _user_profile_memories:
			_user_profile_memories = new_memories
			print("User profile memories updated: ", str(_user_profile_memories.size()))


func _on_immersive_setup_reconfigure_requested() -> void:
	# UI button toggles immersive setup mode (do not wipe config).
	_set_immersive_setup_mode(not _immersive_setup_mode)


func _reconfigure_immersive_setup() -> void:
	# Clear existing saved visuals
	if _furniture_root:
		for c in _furniture_root.get_children():
			var n := c as Node
			if n and n.name.begins_with("Saved_"):
				n.queue_free()

	# Clear saved config (fresh remap)
	var cfg := ConfigFile.new()
	cfg.save(_IMMERSIVE_SETUP_CONFIG_PATH)

	_start_immersive_setup()


func _start_immersive_setup() -> void:
	_immersive_setup_active = true
	_setup_item_index = 0
	_setup_grabbing = false
	_setup_prev_grip = false
	_setup_prev_trigger = false
	_setup_prev_skip = false
	_setup_current = {}
	_set_ui_visible(false)
	_setup_create_skip_button()
	_setup_begin_item()


func _setup_begin_item() -> void:
	if _setup_item_index >= _setup_items.size():
		_finish_immersive_setup()
		return

	_setup_current = _setup_items[_setup_item_index]
	_setup_phase = SetupPhase.PLACE
	_setup_current_height = float(_setup_current["height"])
	_setup_phase_time = 0.0
	_setup_grabbing = false
	_setup_prev_grip = false
	_setup_prev_trigger = false
	_setup_prev_skip = false
	_setup_two_hand_scale = false
	_setup_scale_start_hands_dist = 1.0
	_setup_scale_start_size = Vector2.ONE

	if _setup_preview and is_instance_valid(_setup_preview):
		_setup_preview.queue_free()
	_setup_preview = _create_surface_placeholder(
		_setup_current["label"],
		_setup_current["size"],
		_setup_current_height,
		_setup_current["color"],
		true
	)
	_setup_scale_start_size = _setup_get_surface_size(_setup_preview)
	_furniture_root.add_child(_setup_preview)
	_setup_apply_phase_visuals()

	# Place it in front of the camera.
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if camera:
		var forward := camera.global_basis * Vector3.FORWARD
		forward.y = 0.0
		if forward.length() < 0.001:
			forward = Vector3.FORWARD
		forward = forward.normalized()
		_setup_grab_distance = 1.6
		var pos := camera.global_position + forward * _setup_grab_distance
		pos.y = _setup_current_height + _FURNITURE_VOL_HEIGHT
		_setup_preview.global_position = pos
		# Face the camera, but keep upright (yaw-only) so the preview never leans.
		var cam_flat := camera.global_position
		cam_flat.y = _setup_preview.global_position.y
		_setup_preview.look_at(cam_flat, Vector3.UP)
		_setup_preview.rotate_y(PI)
		var r := _setup_preview.global_rotation
		r.x = 0.0
		r.z = 0.0
		_setup_preview.global_rotation = r
		_setup_update_skip_button_pose()


func _finish_immersive_setup() -> void:
	_immersive_setup_active = false
	_setup_single_item = false
	_setup_delete_mode = false
	if _setup_preview and is_instance_valid(_setup_preview):
		_setup_preview.queue_free()
	if _setup_skip_button and is_instance_valid(_setup_skip_button):
		_setup_skip_button.queue_free()
	_setup_preview = null
	_setup_skip_button = null
	_setup_current = {}

	# Re-spawn using saved data in "normal" subtle mode.
	var cfg := ConfigFile.new()
	if cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH) == OK:
		_spawn_saved_furniture(cfg)
	_set_saved_furniture_visible(_immersive_setup_mode)
	if _setup_top_menu and is_instance_valid(_setup_top_menu):
		_setup_top_menu.visible = _immersive_setup_mode
	_apply_setup_delete_mode(false)

	_set_ui_visible(true)
	_update_ui_pose()


func _process_immersive_setup(delta: float, _left_controller: XRController3D, right_controller: XRController3D) -> void:
	var left_controller := _left_controller
	if not _setup_preview or not is_instance_valid(_setup_preview) or not right_controller:
		return

	_setup_update_skip_button_pose()

	# Right-hand controls.
	var grip_down: bool = right_controller.get_float("grip") > _GRIP_THRESHOLD
	var trigger_down: bool = right_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	var stick: Vector2 = right_controller.get_vector2("primary")
	var left_grip_down: bool = false
	if left_controller:
		left_grip_down = left_controller.get_float("grip") > _GRIP_THRESHOLD

	if _setup_prompt and is_instance_valid(_setup_prompt):
		if _setup_phase == SetupPhase.PLACE:
			_setup_prompt.text = "Place: grip + stick (Y in/out, X rotate). Trigger to resize."
		elif _setup_phase == SetupPhase.RESIZE:
			_setup_prompt.text = "Resize: hold BOTH grips and pinch hands. Trigger to height."
		else:
			_setup_prompt.text = "Height: grip + stick Y. Trigger to save."

	# Optional hardware skip fallback (in addition to the ghost button).
	var skip_down: bool = false
	var skip_value: float = right_controller.get_float("by_button")
	skip_down = skip_value > 0.5
	if skip_down and not _setup_prev_skip:
		_setup_skip_to_next()
	_setup_prev_skip = skip_down

	# Grip toggles grab (require hovering the surface to start grabbing).
	if grip_down and not _setup_prev_grip:
		if _setup_hovering_surface:
			_setup_grabbing = true
			_setup_grab_distance = max(0.3, (right_controller.global_position.distance_to(_setup_preview.global_position)))
	elif (not grip_down) and _setup_prev_grip:
		_setup_grabbing = false
	_setup_prev_grip = grip_down

	if _setup_grabbing:
		_setup_phase_time += delta
		if _setup_phase == SetupPhase.PLACE:
			_setup_grab_distance = clamp(
				_setup_grab_distance + (stick.y) * (_SETUP_GRAB_SPEED * delta),
				0.3,
				6.0
			)
			_setup_preview.rotate_y(-stick.x * _SETUP_ROTATE_SPEED * delta)
		elif _setup_phase == SetupPhase.RESIZE:
			if left_controller and left_grip_down and grip_down:
				var hands_dist: float = max(0.001, left_controller.global_position.distance_to(right_controller.global_position))
				if not _setup_two_hand_scale:
					_setup_two_hand_scale = true
					_setup_scale_start_hands_dist = hands_dist
					_setup_scale_start_size = _setup_get_surface_size(_setup_preview)
				else:
					var ratio: float = hands_dist / max(0.001, _setup_scale_start_hands_dist)
					var desired: Vector2 = _setup_scale_start_size * ratio
					_set_surface_size(_setup_preview, desired)
			else:
				_setup_two_hand_scale = false
		elif _setup_phase == SetupPhase.HEIGHT:
			_setup_current_height = clamp(
				_setup_current_height + (stick.y) * (_SETUP_HEIGHT_SPEED * delta),
				0.05,
				2.5
			)

		# Place along the right controller forward direction.
		var ray_origin := right_controller.global_position
		var ray_dir := (right_controller.global_basis * Vector3.FORWARD).normalized()
		if _right_pointer and (_right_pointer is Node3D):
			ray_origin = (_right_pointer as Node3D).global_position
			ray_dir = ((_right_pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
		var new_pos := ray_origin + ray_dir * _setup_grab_distance
		new_pos.y = max(0.0, _setup_current_height + _FURNITURE_VOL_HEIGHT)
		_setup_preview.global_position = new_pos
		# Ensure the preview remains upright even after rotations/resize.
		var r := _setup_preview.global_rotation
		r.x = 0.0
		r.z = 0.0
		_setup_preview.global_rotation = r
		_setup_apply_phase_visuals()

	# Confirm on trigger press-edge (only when NOT grabbing).
	if (not _setup_grabbing) and trigger_down and not _setup_prev_trigger:
		if _setup_phase == SetupPhase.PLACE:
			_setup_phase = SetupPhase.RESIZE
			_setup_phase_time = 0.0
			_setup_apply_phase_visuals()
		elif _setup_phase == SetupPhase.RESIZE:
			_setup_phase = SetupPhase.HEIGHT
			_setup_phase_time = 0.0
			_setup_apply_phase_visuals()
		else:
			_save_current_setup_item()
			if _setup_single_item:
				_finish_single_item_setup()
				return
			_setup_item_index += 1
			_setup_begin_item()
	_setup_prev_trigger = trigger_down


func _finish_single_item_setup() -> void:
	# End placement, return to setup mode menu.
	_immersive_setup_active = false
	_setup_single_item = false
	_setup_grabbing = false
	_setup_prev_grip = false
	_setup_prev_trigger = false
	_setup_prev_skip = false
	_setup_current = {}
	if _setup_preview and is_instance_valid(_setup_preview):
		_setup_preview.queue_free()
	if _setup_skip_button and is_instance_valid(_setup_skip_button):
		_setup_skip_button.queue_free()
	_setup_preview = null
	_setup_skip_button = null
	# Re-spawn using saved data (refresh) and keep visibility based on setup mode.
	var cfg := ConfigFile.new()
	if cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH) == OK:
		_spawn_saved_furniture(cfg)
	_set_saved_furniture_visible(_immersive_setup_mode)
	_set_ui_visible(_ui_visible_before_setup_place)
	if _ui_visible:
		_update_ui_pose()
	if _setup_top_menu and is_instance_valid(_setup_top_menu):
		_setup_top_menu.visible = _immersive_setup_mode


func _setup_apply_phase_visuals() -> void:
	if not _setup_preview or not is_instance_valid(_setup_preview):
		return

	var lid := _setup_preview.get_node_or_null("Surface") as MeshInstance3D
	var sides := _setup_preview.get_node_or_null("Sides") as MeshInstance3D
	if not lid and not sides:
		return

	# HEIGHT: pulsing lid (tells you "adjust height"); sides stay faint.
	# AREA: steady lid; sides slightly stronger to suggest footprint/area.
	var t := _setup_phase_time
	var pulse := 0.5 + 0.5 * sin(t * 6.0)

	if lid:
		var mat := lid.material_override as StandardMaterial3D
		if mat:
			var base_a := 0.32
			var base_em := 3.0
			if _setup_phase == SetupPhase.HEIGHT:
				mat.albedo_color.a = lerp(base_a * 0.75, base_a * 1.15, pulse)
				mat.emission_energy_multiplier = lerp(base_em * 0.6, base_em * 1.1, pulse)
			else:
				mat.albedo_color.a = base_a * 0.95
				mat.emission_energy_multiplier = base_em * 0.75

	if sides:
		var smat := sides.material_override as StandardMaterial3D
		if smat:
			var sides_a := 0.12
			var sides_em := 0.9
			if _setup_phase == SetupPhase.HEIGHT:
				smat.albedo_color.a = sides_a * 0.55
				smat.emission_energy_multiplier = sides_em * 0.55
			else:
				smat.albedo_color.a = sides_a * 0.95
				smat.emission_energy_multiplier = sides_em * 0.85


func _setup_skip_to_next() -> void:
	if _setup_single_item:
		_finish_immersive_setup()
		return
	_setup_item_index += 1
	_setup_begin_item()


func _setup_create_skip_button() -> void:
	if _setup_skip_button and is_instance_valid(_setup_skip_button):
		return

	var root := Node3D.new()
	root.name = "ImmersiveSetupSkip"

	# Visual: slightly brighter than the furniture surface so it reads as a button.
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.22, 0.08)
	visual.mesh = qm
	visual.rotation_degrees.x = -90.0

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 30
	mat.albedo_color = Color(0.9, 0.9, 1.0, 0.35)
	visual.material_override = mat
	root.add_child(visual)

	# Click target: XRToolsInteractableArea (Area3D) + CollisionShape3D.
	var ia := XRToolsInteractableArea.new()
	ia.name = "Interactable"
	ia.collision_layer = _UI_OBJECTS_LAYER_BIT
	ia.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.22, 0.01, 0.08)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0.0, 0.0, 0.0)
	ia.add_child(cs)
	root.add_child(ia)

	ia.pointer_event.connect(self._on_setup_skip_pointer_event)

	_furniture_root.add_child(root)
	_setup_skip_button = root
	_setup_update_skip_button_pose()


func _setup_update_skip_button_pose() -> void:
	if not _setup_skip_button or not is_instance_valid(_setup_skip_button):
		return
	if not _setup_preview or not is_instance_valid(_setup_preview):
		return

	# Place it just in front of the current preview, slightly to the right.
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	var base := _setup_preview.global_transform
	var pos := base.origin + base.basis.x * 0.35
	pos.y = base.origin.y + 0.02
	_setup_skip_button.global_position = pos
	if camera:
		_setup_skip_button.look_at(camera.global_position, Vector3.UP)
		_setup_skip_button.rotate_y(PI)


func _on_setup_skip_pointer_event(event: XRToolsPointerEvent) -> void:
	if not _immersive_setup_active:
		return
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		_setup_skip_to_next()


func _save_current_setup_item() -> void:
	if _setup_current.is_empty() or not _setup_preview or not is_instance_valid(_setup_preview):
		return

	var cfg := ConfigFile.new()
	cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH)

	var template_key: String = str(_setup_current["key"])
	var key: String = _alloc_anchor_instance_key(cfg, template_key)
	var pos: Vector3 = _setup_preview.global_position
	var yaw: float = _setup_preview.global_rotation.y
	var size: Vector2 = _setup_get_surface_size(_setup_preview)
	var height: float = max(0.0, _setup_current_height)
	pos.y = max(0.0, pos.y)

	# Store a list of enabled anchors.
	var anchors: PackedStringArray = cfg.get_value("anchors", "keys", PackedStringArray())
	if not anchors.has(key):
		anchors.append(key)
	cfg.set_value("anchors", "keys", anchors)

	cfg.set_value(key, "template", template_key)
	cfg.set_value(key, "pos", pos)
	cfg.set_value(key, "yaw", yaw)
	cfg.set_value(key, "size", size)
	cfg.set_value(key, "height", height)

	cfg.save(_IMMERSIVE_SETUP_CONFIG_PATH)


func _spawn_saved_furniture(cfg: ConfigFile) -> void:
	if not _furniture_root:
		return

	# Clear existing saved furniture (but keep any active preview separate).
	for c in _furniture_root.get_children():
		var n := c as Node
		if n and n.name.begins_with("Saved_"):
			n.queue_free()

	var keys: PackedStringArray = cfg.get_value("anchors", "keys", PackedStringArray())
	for inst_key in keys:
		var k: String = str(inst_key)
		if not cfg.has_section(k):
			continue
		var template_key: String = str(cfg.get_value(k, "template", k))
		var tmpl := _get_setup_item_by_key(template_key)
		var label: String = template_key
		var color := Color(0.6, 0.6, 0.6, 1.0)
		var default_size := Vector2(1.0, 1.0)
		var default_height: float = 0.0
		if not tmpl.is_empty():
			label = str(tmpl.get("label", template_key))
			color = tmpl.get("color", color)
			default_size = tmpl.get("size", default_size)
			default_height = float(tmpl.get("height", default_height))
		var height: float = max(0.0, float(cfg.get_value(k, "height", default_height)))
		var yaw: float = float(cfg.get_value(k, "yaw", 0.0))
		var size: Vector2 = cfg.get_value(k, "size", Vector2(float(default_size.x), float(default_size.y)))
		var pos: Vector3 = cfg.get_value(k, "pos", Vector3(0, height + _FURNITURE_VOL_HEIGHT, 0))
		pos.y = height + _FURNITURE_VOL_HEIGHT

		var surf := _create_surface_placeholder(
			"Saved_" + label,
			size,
			height,
			color,
			false
		)
		surf.set_meta("anchor_key", k)
		_furniture_root.add_child(surf)
		surf.global_position = pos
		surf.global_rotation = Vector3(0.0, yaw, 0.0)


func _create_surface_placeholder(name_str: String, size: Vector2, _height: float, color: Color, placement_mode: bool) -> Node3D:
	var root := Node3D.new()
	root.name = name_str

	# Visual: semi-transparent volume sides + glowing lid.
	const VOL_HEIGHT: float = _FURNITURE_VOL_HEIGHT

	var sides := MeshInstance3D.new()
	sides.name = "Sides"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, VOL_HEIGHT, size.y)
	sides.mesh = bm
	# Center box under the lid (lid is at y=0). Top of box touches lid.
	sides.position = Vector3(0.0, -VOL_HEIGHT * 0.5, 0.0)

	var sides_mat := StandardMaterial3D.new()
	sides_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sides_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sides_mat.cull_mode = BaseMaterial3D.CULL_BACK
	sides_mat.no_depth_test = placement_mode
	sides_mat.render_priority = 19 if placement_mode else 0
	sides_mat.emission_enabled = true
	sides_mat.emission = Color(color.r, color.g, color.b, 1.0)
	sides_mat.emission_energy_multiplier = 0.9 if placement_mode else 0.35
	var sides_a := 0.12 if placement_mode else 0.06
	sides_mat.albedo_color = Color(color.r, color.g, color.b, sides_a)
	sides.material_override = sides_mat
	root.add_child(sides)

	var mi := MeshInstance3D.new()
	mi.name = "Surface"
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.rotation_degrees.x = -90.0
	mi.position.y = 0.0

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.no_depth_test = placement_mode
	mat.render_priority = 20 if placement_mode else 0
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 3.0 if placement_mode else 0.45
	var a := 0.32 if placement_mode else 0.04
	mat.albedo_color = Color(color.r, color.g, color.b, a)
	mi.material_override = mat

	root.add_child(mi)

	# Ray-interactable target for XR pointer (Area3D).
	var ia := XRToolsInteractableArea.new()
	ia.name = "Interactable"
	ia.collision_layer = _UI_OBJECTS_LAYER_BIT if placement_mode else 0
	ia.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.02, size.y)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	cs.position = Vector3(0.0, 0.0, 0.0)
	ia.add_child(cs)
	root.add_child(ia)

	if placement_mode:
		ia.pointer_event.connect(self._on_setup_surface_pointer_event)
	return root


func _get_setup_item_by_key(key: String) -> Dictionary:
	for item in _setup_items:
		if str(item.get("key", "")) == key:
			return item
	return {}


func _alloc_anchor_instance_key(cfg: ConfigFile, template_key: String) -> String:
	var anchors: PackedStringArray = cfg.get_value("anchors", "keys", PackedStringArray())
	var best: int = 0
	for a in anchors:
		var s := str(a)
		if not s.begins_with(template_key + "_"):
			continue
		var suffix := s.get_slice("_", s.get_slice_count("_") - 1)
		var n := int(suffix)
		best = max(best, n)
	var next := best + 1
	return "%s_%d" % [template_key, next]


func _apply_setup_delete_mode(enabled: bool) -> void:
	if not _furniture_root:
		return
	for c in _furniture_root.get_children():
		var n := c as Node
		if not n or not n.name.begins_with("Saved_"):
			continue
		var ia := n.get_node_or_null("Interactable") as XRToolsInteractableArea
		if not ia:
			continue
		ia.collision_layer = _UI_OBJECTS_LAYER_BIT if enabled else 0
		if enabled:
			var cb := Callable(self, "_on_saved_furniture_pointer_event")
			if not ia.pointer_event.is_connected(cb):
				ia.pointer_event.connect(cb)
		else:
			var cb2 := Callable(self, "_on_saved_furniture_pointer_event")
			if ia.pointer_event.is_connected(cb2):
				ia.pointer_event.disconnect(cb2)


func _on_saved_furniture_pointer_event(event: XRToolsPointerEvent) -> void:
	if not _setup_delete_mode:
		return
	if event.event_type != XRToolsPointerEvent.Type.PRESSED:
		return
	var target := event.target as Node
	if not target:
		return
	var root := target
	while root and not root.name.begins_with("Saved_"):
		root = root.get_parent() as Node
	if not root:
		return
	if not root.has_meta("anchor_key"):
		return
	var key := str(root.get_meta("anchor_key"))
	var cfg := ConfigFile.new()
	if cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH) != OK:
		return
	var anchors: PackedStringArray = cfg.get_value("anchors", "keys", PackedStringArray())
	if anchors.has(key):
		anchors.remove_at(anchors.find(key))
	cfg.set_value("anchors", "keys", anchors)
	if cfg.has_section(key):
		cfg.erase_section(key)
	cfg.save(_IMMERSIVE_SETUP_CONFIG_PATH)
	_spawn_saved_furniture(cfg)
	_apply_setup_delete_mode(true)


func _setup_get_surface_size(node: Node3D) -> Vector2:
	var mi := node.get_node_or_null("Surface") as MeshInstance3D
	if not mi:
		return Vector2.ONE
	var qm := mi.mesh as QuadMesh
	if not qm:
		return Vector2.ONE
	return qm.size


func _set_surface_size(node: Node3D, size: Vector2) -> void:
	var s := Vector2(max(0.2, size.x), max(0.2, size.y))
	var mi := node.get_node_or_null("Surface") as MeshInstance3D
	if not mi:
		return
	var qm := mi.mesh as QuadMesh
	if not qm:
		return
	qm.size = s
	var sides := node.get_node_or_null("Sides") as MeshInstance3D
	if sides:
		var bm := sides.mesh as BoxMesh
		if bm:
			bm.size = Vector3(s.x, bm.size.y, s.y)
	var ia := node.get_node_or_null("Interactable") as Area3D
	if ia:
		var cs := ia.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if cs and cs.shape is BoxShape3D:
			(cs.shape as BoxShape3D).size = Vector3(s.x, 0.02, s.y)


func _on_setup_surface_pointer_event(event: XRToolsPointerEvent) -> void:
	if not _immersive_setup_active:
		return
	if event.event_type == XRToolsPointerEvent.Type.ENTERED:
		_setup_hovering_surface = true
	elif event.event_type == XRToolsPointerEvent.Type.EXITED:
		_setup_hovering_surface = false


func _process(delta: float) -> void:
	var left_controller := XRHelpers.get_left_controller(self)
	var right_controller := XRHelpers.get_right_controller(self)

	if not _display_ui_hooked:
		_hook_display_ui()

	_apply_rig_y_lock()

	# Safety: if either XRTools pickup is holding a physical object, keep the rig Y locked.
	# This prevents collision-hand / penetration resolution from forcing PlayerBody down
	# through the floor while the grab is held.
	var should_lock_due_to_pickup := _any_hand_holding_pickable()
	if should_lock_due_to_pickup != _rig_y_lock_due_to_pickup:
		_rig_y_lock_due_to_pickup = should_lock_due_to_pickup
		if _rig_y_lock_due_to_pickup:
			_set_rig_y_lock(true)
		elif not _avatar_collision_suppressed_for_manip:
			# Only unlock if we are not in avatar-manip mode (which also locks Y).
			_set_rig_y_lock(false)

	if _immersive_setup_active:
		_process_immersive_setup(delta, left_controller, right_controller)
		return

	if _update_unified_manipulation(delta, left_controller, right_controller):
		return

	if left_controller:
		var menu_value: float = left_controller.get_float("menu_button")
		var menu_pressed: bool = menu_value > 0.5
		if menu_pressed and not _prev_menu_button:
			_set_ui_visible(not _ui_visible)
			if _ui_visible:
				_update_ui_pose()
		_prev_menu_button = menu_pressed

	_update_ui_drag(left_controller, right_controller)

	if _ui_visible and _ui_follow_gaze and not _ui_dragging:
		_update_ui_pose(delta)

	_update_ui_resize(delta, left_controller, right_controller)


func _set_ui_visible(p_visible: bool) -> void:
	if _ui_visible and not p_visible:
		_save_ui_settings()
	_ui_visible = p_visible
	if _display:
		_display.visible = p_visible
	if _virtual_keyboard:
		_virtual_keyboard.visible = p_visible
	if not p_visible:
		_ui_dragging = false
		_drag_controller = null
	else:
		# UI open: ensure we are not possessing (grip is used to drag UI).
		_set_possessing(false)
		_load_ui_settings()
		_update_ui_pose()


func _load_ui_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_UI_SETTINGS_PATH) != OK:
		_apply_ui_scale(1.0)
		return
	var saved_scale := float(cfg.get_value("ui", "scale", 1.0))
	_apply_ui_scale(saved_scale)
	if _display:
		var pos: Variant = cfg.get_value("ui", "pos", _display.global_position)
		var rot: Variant = cfg.get_value("ui", "rot", _display.global_rotation)
		if pos is Vector3:
			_display.global_position = pos
		if rot is Vector3:
			_display.global_rotation = rot
			_update_keyboard_pose_from_display()


func _save_ui_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "scale", float(_ui_scale))
	if _display:
		cfg.set_value("ui", "pos", _display.global_position)
		cfg.set_value("ui", "rot", _display.global_rotation)
	cfg.save(_UI_SETTINGS_PATH)


func _update_ui_pose(delta: float = 0.0) -> void:
	if not _display:
		return

	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return

	var cam_xform: Transform3D = camera.global_transform
	var forward: Vector3 = cam_xform.basis * Vector3.FORWARD
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var target_pos: Vector3 = cam_xform.origin + forward * _UI_DISTANCE
	target_pos.y = cam_xform.origin.y + _UI_HEIGHT_OFFSET

	# If something is in the way, place the UI slightly in front of it.
	var space_state := get_world_3d().direct_space_state
	if space_state:
		var ray_params := PhysicsRayQueryParameters3D.new()
		ray_params.from = cam_xform.origin
		ray_params.to = target_pos
		ray_params.exclude = []
		var display_body := _display.get_node_or_null("StaticBody3D") as CollisionObject3D
		if display_body:
			ray_params.exclude.append(display_body.get_rid())
		if _virtual_keyboard:
			var keyboard_body := (_virtual_keyboard as Node).get_node_or_null("StaticBody3D") as CollisionObject3D
			if keyboard_body:
				ray_params.exclude.append(keyboard_body.get_rid())
		ray_params.collision_mask = 1
		var hit := space_state.intersect_ray(ray_params)
		if not hit.is_empty() and hit.has("position") and hit.has("normal"):
			var hit_pos: Vector3 = hit["position"]
			var hit_normal: Vector3 = hit["normal"]
			var pushed := hit_pos + hit_normal * 0.06
			pushed.y = target_pos.y
			target_pos = pushed

	var desired := _display.global_transform
	desired.origin = target_pos
	# Align UI to face the camera (yaw-only already handled by target_pos height and forward flattening).
	_display.global_position = desired.origin
	_display.look_at(cam_xform.origin, Vector3.UP)
	_display.rotate_y(PI)
	desired = _display.global_transform

	# Smooth UI follow to reduce jitter.
	if delta > 0.0:
		var alpha := _smooth_alpha(delta, _UI_FOLLOW_SMOOTH_TIME)
		if not _ui_follow_smoothed:
			_ui_follow_smoothed = true
			_ui_follow_smoothed_xform = desired
			_display.global_transform = desired
		else:
			_ui_follow_smoothed_xform = _ui_follow_smoothed_xform.interpolate_with(desired, alpha)
			_display.global_transform = _ui_follow_smoothed_xform
	else:
		_ui_follow_smoothed = false
		_display.global_transform = desired
	_update_keyboard_pose_from_display()


func _set_target_collision_enabled(target: Node3D, enabled: bool) -> void:
	if not target or not is_instance_valid(target):
		return
	# Never touch UI collisions here.
	if target == _display or target == _virtual_keyboard:
		return

	if enabled:
		_set_saved_target_collision(true)
		return

	# If we're manipulating a physics body, freeze it so we can move it kinematically.
	if target is RigidBody3D:
		var rb := target as RigidBody3D
		if not _manip_target_collision_saved.has(rb):
			_manip_target_collision_saved[rb] = {"freeze": rb.freeze}
		rb.freeze = true

	# Disable collisions for all CollisionObject3D nodes under the target.
	var stack: Array[Node] = [target]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		for c in n.get_children():
			stack.append(c)
		if not (n is CollisionObject3D):
			continue
		var co := n as CollisionObject3D
		if not _manip_target_collision_saved.has(co):
			_manip_target_collision_saved[co] = {"layer": co.collision_layer, "mask": co.collision_mask}
		co.collision_layer = 0
		co.collision_mask = 0
	_manip_target_collision_suppressed = true


func _set_saved_target_collision(enabled: bool) -> void:
	if not enabled:
		return
	if _manip_target_collision_saved.is_empty():
		_manip_target_collision_suppressed = false
		return
	for co_key in _manip_target_collision_saved.keys():
		var co := co_key as Object
		if not co or not is_instance_valid(co):
			continue
		var saved: Dictionary = _manip_target_collision_saved[co_key] as Dictionary
		if co is CollisionObject3D:
			var cobj := co as CollisionObject3D
			cobj.collision_layer = int(saved.get("layer", cobj.collision_layer))
			cobj.collision_mask = int(saved.get("mask", cobj.collision_mask))
		elif co is RigidBody3D:
			var rb := co as RigidBody3D
			# Always unfreeze on release so liftable physics props reliably drop with gravity.
			rb.freeze = false
	_manip_target_collision_saved = {}
	_manip_target_collision_suppressed = false


func _smooth_alpha(delta: float, smooth_time: float) -> float:
	if smooth_time <= 0.0:
		return 1.0
	return 1.0 - exp(-delta / smooth_time)


func _pointer_is_hitting(mask: int) -> bool:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return false
	var max_dist := 10.0
	for p in [_left_pointer, _right_pointer]:
		if not p or not (p is Node3D):
			continue
		var origin := (p as Node3D).global_position
		var dir := ((p as Node3D).global_basis * Vector3.FORWARD).normalized()
		var ray := PhysicsRayQueryParameters3D.new()
		ray.from = origin
		ray.to = origin + dir * max_dist
		ray.exclude = []
		ray.collision_mask = mask
		var hit := space_state.intersect_ray(ray)
		if not hit.is_empty():
			return true
	return false


func _node_pointer_is_hitting(pointer: Node, mask: int, max_dist: float = 10.0) -> bool:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return false
	if not pointer or not (pointer is Node3D):
		return false
	var origin := (pointer as Node3D).global_position
	var dir := ((pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
	var ray := PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + dir * max_dist
	ray.exclude = []
	ray.collision_mask = mask
	var hit := space_state.intersect_ray(ray)
	return not hit.is_empty()


func _update_ui_drag(left_controller: XRController3D, right_controller: XRController3D) -> void:
	if not _ui_visible or not _display:
		_ui_dragging = false
		_drag_controller = null
		_ui_drag_candidate = false
		_ui_drag_candidate_controller = null
		return

	# If currently dragging, keep following the controller until grip is released.
	if _ui_dragging:
		if _drag_controller:
			var grip_value: float = _drag_controller.get_float("grip")
			var trigger_value: float = _drag_controller.get_float("trigger")
			# If trigger is pressed while dragging, release UI drag so grip+trigger can
			# be used for avatar/furniture controls.
			if trigger_value > _TRIGGER_THRESHOLD:
				_ui_dragging = false
				_drag_controller = null
				return
			if grip_value <= _GRIP_THRESHOLD:
				_ui_dragging = false
				_drag_controller = null
				return

			_display.global_transform = _drag_controller.global_transform * _drag_offset
			_update_keyboard_pose_from_display()
			return

	# Not dragging - grip press-edge starts a *candidate* drag. We only begin dragging
	# after a short grace period, unless trigger becomes pressed (then we cancel).
	var start_controller: XRController3D = null
	var left_grip: bool = false
	var right_grip: bool = false
	if left_controller:
		left_grip = left_controller.get_float("grip") > _GRIP_THRESHOLD
	if right_controller:
		right_grip = right_controller.get_float("grip") > _GRIP_THRESHOLD

	if left_grip and not _prev_left_grip:
		start_controller = left_controller
	elif right_grip and not _prev_right_grip:
		start_controller = right_controller

	_prev_left_grip = left_grip
	_prev_right_grip = right_grip

	# Begin a candidate drag on grip press, but only if trigger is not already held.
	if start_controller:
		# Only allow UI drag if this controller is actually pointing at the UI.
		var pointer: Node = null
		if start_controller == left_controller:
			pointer = _left_pointer
		elif start_controller == right_controller:
			pointer = _right_pointer
		if not _node_pointer_is_hitting(pointer, _UI_OBJECTS_LAYER_BIT):
			_ui_drag_candidate = false
			_ui_drag_candidate_controller = null
			return

		var trig := start_controller.get_float("trigger")
		if trig <= _TRIGGER_THRESHOLD:
			_ui_drag_candidate = true
			_ui_drag_candidate_controller = start_controller
			_ui_drag_candidate_start_ms = int(Time.get_ticks_msec())
		else:
			_ui_drag_candidate = false
			_ui_drag_candidate_controller = null

	# Resolve candidate drag.
	if _ui_drag_candidate and _ui_drag_candidate_controller:
		var now_ms := int(Time.get_ticks_msec())
		var elapsed := now_ms - _ui_drag_candidate_start_ms
		var cand_grip := _ui_drag_candidate_controller.get_float("grip")
		var cand_trigger := _ui_drag_candidate_controller.get_float("trigger")
		# Cancel if grip released or trigger pressed (avatar/furniture combo).
		if cand_grip <= _GRIP_THRESHOLD or cand_trigger > _TRIGGER_THRESHOLD:
			_ui_drag_candidate = false
			_ui_drag_candidate_controller = null
			return
		# Start dragging after grace period.
		if elapsed >= _UI_DRAG_TRIGGER_GRACE_MS:
			_ui_drag_candidate = false
			_ui_dragging = true
			_drag_controller = _ui_drag_candidate_controller
			_ui_drag_candidate_controller = null
			_drag_offset = _drag_controller.global_transform.affine_inverse() * _display.global_transform
			_set_possessing(false)


func _update_possession(delta: float, left_controller: XRController3D, right_controller: XRController3D) -> void:
	# If UI is actively being dragged, reserve the controls for UI.
	if _ui_dragging:
		_set_possessing(false)
		return

	# While immersive setup is active we reserve controls for setup manipulation.
	if _immersive_setup_active:
		_set_possessing(false)
		return

	# While customizing we reserve controls for customization.
	if _customizing:
		_set_possessing(false)
		return

	if not left_controller or not right_controller or not _avatar:
		_set_possessing(false)
		return

	# Possession gate: left grip + left trigger
	var left_grip_down: bool = left_controller.get_float("grip") > _GRIP_THRESHOLD
	var left_trigger_down: bool = left_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	_set_possessing(left_grip_down and left_trigger_down)
	if not _possessing:
		return

	# Movement: right stick on right controller
	var move_stick: Vector2 = right_controller.get_vector2("primary")
	# Turn: x-axis of left stick on left controller
	var turn_stick: Vector2 = left_controller.get_vector2("primary")

	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	var move_basis := _avatar.global_basis
	if camera:
		# Move relative to camera forward on the floor plane
		move_basis = camera.global_basis

	var forward: Vector3 = move_basis * Vector3.FORWARD
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = move_basis * Vector3.RIGHT
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = (forward * move_stick.y) + (right * move_stick.x)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var desired_pos := _avatar.global_position + move_dir * (_POSSESS_MOVE_SPEED * delta)
	desired_pos = _constrain_position_against_ui_wall(desired_pos)
	_avatar.global_position = desired_pos
	_avatar.rotate_y(-turn_stick.x * _POSSESS_TURN_SPEED * delta)
	_apply_avatar_customization()


func _resolve_manip_target_from_collider(collider: Object) -> Node3D:
	if collider == null:
		return null
	var n := collider as Node
	if not n:
		return null

	# UI can be manipulated as a single object when visible. Always return the
	# Display root so the keyboard remains docked.
	if _ui_visible and _display and (n == _display or _display.is_ancestor_of(n)):
		return _display
	if _ui_visible and _display and _virtual_keyboard and (n == _virtual_keyboard or _virtual_keyboard.is_ancestor_of(n)):
		return _display

	# If the collider belongs to the avatar hierarchy, always manipulate the avatar root.
	if _avatar and (n == _avatar or _avatar.is_ancestor_of(n)):
		return _avatar

	# Never manipulate the player rig itself (hands, pointers, player body, etc.).
	var rig := get_node_or_null("XROrigin3D") as Node
	if rig and (n == rig or rig.is_ancestor_of(n)):
		return null

	var cur: Node = n
	while cur and not (cur is Node3D):
		cur = cur.get_parent()
	var candidate := cur as Node3D
	if not candidate:
		return null
	# Prefer the parent of StaticBody3D in Viewport2Din3D setups.
	if candidate is StaticBody3D:
		var p := candidate.get_parent() as Node3D
		if p:
			candidate = p
	return candidate


func _is_liftable_target(target: Node3D) -> bool:
	if not target or not is_instance_valid(target):
		return false
	return target.is_in_group("liftable")


func _apply_upright_bias_if_needed(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
	# If the object is only slightly tilted, snap it upright (preserve yaw).
	# If it's significantly tilted, let it remain (so it can topple).
	var up := (target.global_basis * Vector3.UP).normalized()
	var tilt := acos(clamp(up.dot(Vector3.UP), -1.0, 1.0))
	if tilt <= deg_to_rad(35.0):
		var yaw := target.global_rotation.y
		target.global_rotation = Vector3(0.0, yaw, 0.0)


func _raycast_manip_target() -> Node3D:
	return _raycast_manip_target_from_pointer(_right_pointer)


func _raycast_manip_target_from_pointer(pointer: Node) -> Node3D:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return null
	var origin := Vector3.ZERO
	var dir := Vector3.FORWARD
	if pointer and (pointer is Node3D):
		origin = (pointer as Node3D).global_position
		dir = ((pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
	else:
		var cam := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
		if cam:
			origin = cam.global_position
			dir = (cam.global_basis * Vector3.FORWARD).normalized()
	var ray := PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + dir * 12.0
	ray.exclude = _manip_raycast_exclude
	ray.collision_mask = -1
	ray.collide_with_bodies = true
	ray.collide_with_areas = true
	var hit := space_state.intersect_ray(ray)
	if hit.is_empty():
		return null
	if not hit.has("collider"):
		return null
	return _resolve_manip_target_from_collider(hit["collider"])


func _update_unified_manipulation(delta: float, left_controller: XRController3D, right_controller: XRController3D) -> bool:
	var left_grip: bool = false
	var right_grip: bool = false
	if left_controller:
		left_grip = left_controller.get_float("grip") > _GRIP_THRESHOLD
	if right_controller:
		right_grip = right_controller.get_float("grip") > _GRIP_THRESHOLD
	var left_trigger: bool = false
	var right_trigger: bool = false
	if left_controller:
		left_trigger = left_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	if right_controller:
		right_trigger = right_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	var double_grip := left_grip and right_grip

	# When UI is visible, reserve double-grip for UI resize.
	# Allow an explicit override (hold either trigger) to use avatar double-grip manipulation.
	var pointing_at_interactable := _pointer_is_hitting(_INTERACTABLE_MASK)
	var allow_avatar_double_grip := ((not _ui_visible) and (not pointing_at_interactable)) or left_trigger or right_trigger
	if _ui_visible and _manip_double_grip and not allow_avatar_double_grip:
		_manipulating = false
		_manip_double_grip = false
		_manip_target = null
		_manip_two_hand_scale = false
	var start_single_left := left_grip and not _manip_prev_left_grip and not double_grip
	var start_single_right := right_grip and not _manip_prev_right_grip and not double_grip
	var start_single := start_single_left or start_single_right
	var stop_single := false
	var start_double := double_grip and allow_avatar_double_grip and not (_manip_prev_left_grip and _manip_prev_right_grip)
	var stop_double := (not double_grip) and (_manip_prev_left_grip and _manip_prev_right_grip)
	_manip_prev_left_grip = left_grip
	_manip_prev_right_grip = right_grip

	# Two-hand pinch scaling for the currently manipulated target.
	# This includes the avatar when it's being manipulated as an object.
	if start_double and _manipulating and is_instance_valid(_manip_target) and not _manip_double_grip:
		_manip_two_hand_scale = true
		_manip_scale_start_scale = _manip_scale
		if left_controller and right_controller:
			_manip_scale_start_hands_dist = max(0.001, left_controller.global_position.distance_to(right_controller.global_position))
		# Do not enter avatar double-grip drive mode.
		return true
	if stop_double and _manip_two_hand_scale:
		_manip_two_hand_scale = false
		# Continue manipulating the object with single right-grip if still held.
		if _manipulating and not _manip_double_grip:
			return true

	# Avatar double-grip drive mode is optional; only allow when not already manipulating
	# another target (or when already driving the avatar).
	if start_double and (not _manipulating or _manip_target == _avatar) and not _manip_two_hand_scale:
		_manipulating = true
		_manip_double_grip = true
		_manip_target = _avatar
		_set_possessing(false)
		_set_customizing(false)
		_ui_dragging = false
		_drag_controller = null
		return true
	if stop_double and _manip_double_grip:
		_manipulating = false
		_manip_double_grip = false
		_manip_target = null
		_manip_prev_toggle_left = false
		_manip_prev_toggle_right = false
		_manip_two_hand_scale = false
		if _manip_target_collision_suppressed:
			_set_saved_target_collision(true)
		return false

	if start_single:
		_manip_single_controller_is_left = start_single_left and not start_single_right
		var pointer: Node = _left_pointer if _manip_single_controller_is_left else _right_pointer
		_manip_target = _raycast_manip_target_from_pointer(pointer)
		if _manip_target:
			var liftable := _is_liftable_target(_manip_target)
			_manip_target_is_ui = (_display and _manip_target == _display)
			_manip_target_floor_lock = (not _manip_target_is_ui) and (_manip_target != _avatar) and (not liftable)
			_manip_target_allow_tilt = _manip_target_is_ui or _manip_target == _avatar or liftable
			_manipulating = true
			_manip_double_grip = false
			_manip_two_hand_scale = false
			var start_active_controller := left_controller if _manip_single_controller_is_left else right_controller
			var start_ray_origin := (start_active_controller.global_position if start_active_controller else Vector3.ZERO)
			var start_ray_dir := ((start_active_controller.global_basis * Vector3.FORWARD).normalized() if start_active_controller else Vector3.FORWARD)
			if pointer and (pointer is Node3D):
				start_ray_origin = (pointer as Node3D).global_position
				start_ray_dir = ((pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
			var along: float = ( _manip_target.global_position - start_ray_origin ).dot(start_ray_dir)
			if along <= 0.0:
				along = (start_ray_origin.distance_to(_manip_target.global_position) if start_active_controller else 1.2)
			_manip_distance = clamp(along, 0.25, 10.0)
			_manip_scale = float(_manip_target.scale.x) if _manip_target else 1.0
			_set_possessing(false)
			_set_customizing(false)
			_ui_dragging = false
			_drag_controller = null
			# Prevent manipulated targets from pushing/pulling the player body while we move them.
			# This is especially important on Quest/SteamVR where the PlayerBody may get forced
			# through the floor by penetration resolution.
			_manip_target_collision_saved = {}
			_manip_target_collision_suppressed = false
			_set_target_collision_enabled(_manip_target, false)
			# Prevent the avatar colliders from pushing/pulling the player rig while we move it.
			if _manip_target == _avatar:
				_set_avatar_collision_enabled(false)
				_avatar_collision_suppressed_for_manip = true
				if _player_body and is_instance_valid(_player_body) and ("enabled" in _player_body) and not _player_body_suppressed_for_manip:
					_player_body_saved_enabled = bool(_player_body.get("enabled"))
					_player_body_suppressed_for_manip = true
					_set_player_body_enabled(false)
				_set_rig_y_lock(true)
			return true
	if _manipulating and not _manip_double_grip:
		stop_single = ((not left_grip) if _manip_single_controller_is_left else (not right_grip))
	if stop_single and _manipulating and not _manip_double_grip:
		var released_target := _manip_target
		_manipulating = false
		_manip_target = null
		_manip_target_is_ui = false
		_manip_target_floor_lock = true
		_manip_target_allow_tilt = false
		_manip_two_hand_scale = false
		if _manip_target_collision_suppressed:
			_set_saved_target_collision(true)
		if released_target == _avatar and _avatar_collision_suppressed_for_manip and not _possessing and not _customizing:
			_set_avatar_collision_enabled(true)
			_avatar_collision_suppressed_for_manip = false
			_restore_player_body_after_manip()
			_set_rig_y_lock(false)
		# On release, let objects "land" upright on the nearest surface below.
		# UI and liftable props are allowed to remain floating/tilted.
		if released_target and released_target != _display and released_target != _virtual_keyboard:
			if _is_liftable_target(released_target):
				_apply_upright_bias_if_needed(released_target)
			else:
				_land_object(released_target)
		return false

	if not _manipulating or not is_instance_valid(_manip_target):
		if _manip_target_collision_suppressed:
			_set_saved_target_collision(true)
		_manipulating = false
		_manip_target = null
		_manip_target_is_ui = false
		_manip_target_floor_lock = true
		_manip_target_allow_tilt = false
		_manip_two_hand_scale = false
		_restore_player_body_after_manip()
		_set_rig_y_lock(false)
		return false

	if _manip_double_grip:
		if not left_controller or not right_controller or not _avatar:
			_manipulating = false
			_manip_target = null
			_manip_double_grip = false
			return false
		var move_stick: Vector2 = right_controller.get_vector2("primary")
		var left_stick: Vector2 = left_controller.get_vector2("primary")
		var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
		var move_basis := _avatar.global_basis
		if camera:
			move_basis = camera.global_basis
		var forward: Vector3 = move_basis * Vector3.FORWARD
		forward.y = 0.0
		forward = forward.normalized()
		var right: Vector3 = move_basis * Vector3.RIGHT
		right.y = 0.0
		right = right.normalized()
		var move_dir: Vector3 = (forward * move_stick.y) + (right * move_stick.x)
		if move_dir.length() > 1.0:
			move_dir = move_dir.normalized()
		var desired_pos := _avatar.global_position + move_dir * (_POSSESS_MOVE_SPEED * delta)
		desired_pos = _constrain_position_against_ui_wall(desired_pos)
		_avatar.global_position = desired_pos
		_avatar.rotate_y(-left_stick.x * _POSSESS_TURN_SPEED * delta)
		_avatar_floor_offset = clamp(_avatar_floor_offset + left_stick.y * (_AVATAR_HEIGHT_SPEED * delta), 0.0, 1.2)
		var toggle_right: bool = move_stick.x > 0.85
		var toggle_left: bool = move_stick.x < -0.85
		if toggle_right and not _manip_prev_toggle_right:
			_toggle_avatar_part_by_keywords(["hair", "Hair", "bang", "Bang", "ponytail", "Ponytail"])
		if toggle_left and not _manip_prev_toggle_left:
			_toggle_avatar_part_by_keywords(["cloth", "Cloth", "clothes", "Clothes", "outfit", "Outfit", "dress", "Dress", "shirt", "Shirt", "skirt", "Skirt", "top", "Top", "jacket", "Jacket"])
		_manip_prev_toggle_right = toggle_right
		_manip_prev_toggle_left = toggle_left
		_apply_avatar_customization()
		return true

	var active_controller := left_controller if _manip_single_controller_is_left else right_controller
	var other_controller := right_controller if _manip_single_controller_is_left else left_controller
	var active_pointer: Node = _left_pointer if _manip_single_controller_is_left else _right_pointer
	if not active_controller:
		_manipulating = false
		_manip_target = null
		_manip_two_hand_scale = false
		return false
	var rs: Vector2 = active_controller.get_vector2("primary")
	if rs == Vector2.ZERO:
		rs = _get_controller_stick(active_controller)
	# Distance/spin are controlled by the same hand that is gripping the target.
	# For UI/avatar we allow a trigger-modifier tilt mode using the *same* stick.
	var tilt_mode := _manip_target_allow_tilt and (active_controller.get_float("trigger") > _TRIGGER_THRESHOLD)
	if not tilt_mode:
		_manip_distance = clamp(_manip_distance + (rs.y) * (_SETUP_GRAB_SPEED * delta), 0.25, 10.0)
	var ray_origin := active_controller.global_position
	var ray_dir := (active_controller.global_basis * Vector3.FORWARD).normalized()
	if active_pointer and (active_pointer is Node3D):
		ray_origin = (active_pointer as Node3D).global_position
		ray_dir = ((active_pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
	var new_pos: Vector3 = ray_origin + ray_dir * _manip_distance
	if _manip_target_floor_lock:
		# Keep object height fixed (floor-locked behavior).
		new_pos.y = _manip_target.global_position.y
	_manip_target.global_position = new_pos
	if _manip_target_floor_lock:
		_manip_target.global_rotation = Vector3(0.0, _manip_target.global_rotation.y, 0.0)
	# Rotation: yaw is controlled by the active stick X. In tilt-mode we use the
	# active stick for pitch/roll and keep yaw unchanged until trigger released.
	if not tilt_mode:
		_manip_target.rotate_y(-(rs.x) * _SETUP_ROTATE_SPEED * delta)
	else:
		var pitch_axis: float = float(clamp(rs.y, -1.0, 1.0))
		var roll_axis: float = float(clamp(rs.x, -1.0, 1.0))
		_manip_target.rotate_object_local(Vector3.RIGHT, pitch_axis * (_SETUP_ROTATE_SPEED * 0.65) * delta)
		_manip_target.rotate_object_local(Vector3.FORWARD, -roll_axis * (_SETUP_ROTATE_SPEED * 0.65) * delta)
		# Keep tilt reasonable.
		var r := _manip_target.rotation
		r.x = clamp(r.x, deg_to_rad(-70.0), deg_to_rad(70.0))
		r.z = clamp(r.z, deg_to_rad(-70.0), deg_to_rad(70.0))
		_manip_target.rotation = r

	# Scale: two-hand pinch (while both grips are held) scales the target.
	if _manip_two_hand_scale and left_controller and right_controller:
		var hands_dist: float = max(0.001, left_controller.global_position.distance_to(right_controller.global_position))
		var denom: float = max(0.001, _manip_scale_start_hands_dist)
		var desired_scale: float = _manip_scale_start_scale * (hands_dist / denom)
		_manip_scale = clamp(desired_scale, 0.25, 3.0)
	_manip_target.scale = Vector3.ONE * _manip_scale
	return true


func _constrain_position_against_ui_wall(p: Vector3) -> Vector3:
	if not _display:
		return p
	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return p
	var origin := _display.global_position
	var n := (_display.global_basis * Vector3.FORWARD).normalized()
	var cam_side := n.dot(camera.global_position - origin)
	var old_side := n.dot(_avatar.global_position - origin)
	var new_side := n.dot(p - origin)
	if cam_side == 0.0:
		return p
	if (old_side * cam_side) >= 0.0 and (new_side * cam_side) < 0.0:
		var q := p - n * (new_side)
		q += n * (0.05 if cam_side > 0.0 else -0.05)
		q.y = p.y
		return q
	return p


func _set_possessing(enable: bool) -> void:
	if _possessing == enable:
		return
	_possessing = enable
	_set_avatar_collision_enabled(not enable)

	# Keep player locomotion disabled permanently.
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f and ("enabled" in f):
				f.enabled = false


func _update_avatar_customization(delta: float, left_controller: XRController3D, right_controller: XRController3D) -> void:
	# Allow customization even when UI is visible, but never while the UI is
	# actively being dragged.
	if _ui_dragging:
		_set_customizing(false)
		return

	if not right_controller or not _avatar:
		_set_customizing(false)
		return

	# Customization gate: right grip + right trigger, but only when NOT in the
	# both-grips avatar-control mode (left grip not held).
	var right_grip_down: bool = right_controller.get_float("grip") > _GRIP_THRESHOLD
	var right_trigger_down: bool = right_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	var left_grip_down: bool = false
	if left_controller:
		left_grip_down = left_controller.get_float("grip") > _GRIP_THRESHOLD
	_set_customizing((not left_grip_down) and right_grip_down and right_trigger_down)
	if not _customizing:
		return

	# Ensure we don't fight possession.
	_set_possessing(false)

	# Scale: left stick Y (if left controller present)
	var scale_axis: float = 0.0
	if left_controller:
		scale_axis = left_controller.get_vector2("primary").y
	_avatar_scale = clamp(_avatar_scale + scale_axis * (_AVATAR_SCALE_SPEED * delta), _AVATAR_SCALE_MIN, _AVATAR_SCALE_MAX)

	# Height offset: right stick Y raises/lowers the avatar relative to the floor.
	var right_stick: Vector2 = right_controller.get_vector2("primary")
	_avatar_floor_offset = clamp(_avatar_floor_offset + right_stick.y * (_AVATAR_HEIGHT_SPEED * delta), 0.0, 1.2)

	# Toggle visibility (debounced): right stick X
	var toggle_right: bool = right_stick.x > 0.85
	var toggle_left: bool = right_stick.x < -0.85
	if toggle_right and not _prev_customize_toggle_right:
		_toggle_avatar_part_by_keywords(["hair", "Hair", "bang", "Bang", "ponytail", "Ponytail"])
	if toggle_left and not _prev_customize_toggle_left:
		_toggle_avatar_part_by_keywords(["cloth", "Cloth", "clothes", "Clothes", "outfit", "Outfit", "dress", "Dress", "shirt", "Shirt", "skirt", "Skirt", "top", "Top", "jacket", "Jacket"])
	_prev_customize_toggle_right = toggle_right
	_prev_customize_toggle_left = toggle_left

	_apply_avatar_customization()


func _set_customizing(enable: bool) -> void:
	if _customizing == enable:
		return
	_customizing = enable
	_prev_customize_toggle_left = false
	_prev_customize_toggle_right = false
	_set_avatar_collision_enabled(not enable)

	# Keep player locomotion disabled permanently.
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f and ("enabled" in f):
				f.enabled = false


func _apply_avatar_customization() -> void:
	if not _avatar or not is_instance_valid(_avatar):
		return

	# During telekinetic manipulation we allow lifting the avatar freely. On release we
	# re-run customization which drops it back to the floor.
	if _manipulating and _manip_target == _avatar and (not _manip_double_grip or _manip_two_hand_scale):
		_avatar.scale = Vector3.ONE * _avatar_scale
		return

	_avatar.scale = Vector3.ONE * _avatar_scale

	# Keep avatar feet anchored to the floor (y = 0), regardless of scale.
	var bottom_y: float = _get_avatar_bottom_world_y()
	if is_finite(bottom_y):
		var pos := _avatar.global_position
		pos.y -= bottom_y
		pos.y += _avatar_floor_offset
		_avatar.global_position = pos


func _land_object(node: Node3D) -> void:
	if not node or not is_instance_valid(node):
		return

	# Choose a stable landing orientation.
	# If the target is heavily tilted (>45 degrees), prefer a lying orientation.
	# Otherwise, preserve yaw but remove pitch/.oll so it lands "on its bottom".
	var up := (node.global_basis * Vector3.UP).normalized()
	var tilt := acos(clamp(up.dot(Vector3.UP), -1.0, 1.0))
	var yaw := node.global_rotation.y
	var landed_lying := false
	if tilt > (PI * 0.25):
		landed_lying = true
		var current_q := node.global_basis.get_rotation_quaternion()
		var candidates: Array[Quaternion] = []
		# Keep yaw but choose a lying pitch/roll.
		candidates.append(Basis.from_euler(Vector3(-PI * 0.5, yaw, 0.0)).get_rotation_quaternion())
		candidates.append(Basis.from_euler(Vector3( PI * 0.5, yaw, 0.0)).get_rotation_quaternion())
		candidates.append(Basis.from_euler(Vector3(0.0, yaw, -PI * 0.5)).get_rotation_quaternion())
		candidates.append(Basis.from_euler(Vector3(0.0, yaw,  PI * 0.5)).get_rotation_quaternion())

		var best_q := candidates[0]
		var best_d := current_q.angle_to(best_q)
		for i in range(1, candidates.size()):
			var d := current_q.angle_to(candidates[i])
			if d < best_d:
				best_d = d
				best_q = candidates[i]
		node.global_basis = Basis(best_q)
	else:
		node.global_rotation = Vector3(0.0, yaw, 0.0)

	# Drop to rest on the nearest surface below using a raycast.
	var bottom_y := _get_node_bottom_world_y(node)
	if not is_finite(bottom_y):
		return
	var drop_origin := node.global_position
	# Cast from slightly above current to far below.
	drop_origin.y += 0.5
	var drop_to := drop_origin + Vector3(0.0, -50.0, 0.0)
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return
	var ray := PhysicsRayQueryParameters3D.new()
	ray.from = drop_origin
	ray.to = drop_to
	ray.exclude = []
	ray.collision_mask = 1
	var hit := space_state.intersect_ray(ray)
	var target_floor_y := 0.0
	if not hit.is_empty() and hit.has("position"):
		target_floor_y = (hit["position"] as Vector3).y

	# Shift so the current bottom sits on the hit surface.
	var pos := node.global_position
	pos.y += (target_floor_y - bottom_y)
	node.global_position = pos

	# Avatar also needs its internal customization state updated after landing.
	if node == _avatar:
		_avatar_floor_offset = 0.0
		_apply_avatar_customization()
		if landed_lying:
			_play_avatar_lie_pose()
		else:
			_play_avatar_idle()


func _get_node_bottom_world_y(root: Node3D) -> float:
	var found := false
	var min_y := 0.0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n == null:
			continue
		if n is GeometryInstance3D:
			var gi := n as GeometryInstance3D
			var aabb: AABB = gi.get_aabb()
			var xf: Transform3D = gi.global_transform
			for ix in [0, 1]:
				for iy in [0, 1]:
					for iz in [0, 1]:
						var local_corner := Vector3(
							aabb.position.x + aabb.size.x * float(ix),
							aabb.position.y + aabb.size.y * float(iy),
							aabb.position.z + aabb.size.z * float(iz)
						)
						var world_corner: Vector3 = xf * local_corner
						if not found:
							found = true
							min_y = world_corner.y
						else:
							min_y = min(min_y, world_corner.y)
		for c in n.get_children():
			stack.append(c)
	return min_y if found else NAN


func _get_avatar_bottom_world_y() -> float:
	if not _avatar:
		return NAN

	var found: bool = false
	var min_y: float = 0.0

	var stack: Array[Node] = [_avatar]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		for c in n.get_children():
			stack.append(c)

		if not (n is GeometryInstance3D):
			continue

		var gi := n as GeometryInstance3D
		var aabb: AABB = gi.get_aabb()
		var xf: Transform3D = gi.global_transform

		# Evaluate the 8 AABB corners in world space to find the bottom y.
		for ix in [0, 1]:
			for iy in [0, 1]:
				for iz in [0, 1]:
					var local_corner := Vector3(
						aabb.position.x + aabb.size.x * float(ix),
						aabb.position.y + aabb.size.y * float(iy),
						aabb.position.z + aabb.size.z * float(iz)
					)
					var world_corner: Vector3 = xf * local_corner
					if not found:
						min_y = world_corner.y
						found = true
					else:
						min_y = min(min_y, world_corner.y)

	if not found:
		# If we couldn't find a mesh, keep behavior safe.
		return _avatar.global_position.y
	return min_y


func _toggle_avatar_part_by_keywords(keywords: Array[String]) -> void:
	if not _avatar:
		return

	var any_found := false
	var new_visible: bool = true

	var stack: Array[Node] = [_avatar]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		for c in n.get_children():
			stack.append(c)

		var node_name: String = str(n.name)
		var matches := false
		for k in keywords:
			if node_name.find(k) != -1:
				matches = true
				break
		if not matches:
			continue

		# Toggle MeshInstance3D, or if it's a plain Node3D toggle all MeshInstance3D under it.
		if n is GeometryInstance3D:
			any_found = true
			new_visible = not (n as GeometryInstance3D).visible
			(n as GeometryInstance3D).visible = new_visible
		elif n is Node3D:
			var sub_stack: Array[Node] = [n]
			while not sub_stack.is_empty():
				var s: Node = sub_stack.pop_back() as Node
				for sc in s.get_children():
					sub_stack.append(sc)
				if s is GeometryInstance3D:
					any_found = true
					new_visible = not (s as GeometryInstance3D).visible
					(s as GeometryInstance3D).visible = new_visible

	# If we didn't find named parts, fall back to toggling the first mesh we can find.
	if not any_found:
		var fallback: GeometryInstance3D = null
		var find_stack: Array[Node] = [_avatar]
		while not find_stack.is_empty() and not fallback:
			var fnode: Node = find_stack.pop_back() as Node
			if fnode is GeometryInstance3D:
				fallback = fnode as GeometryInstance3D
				break
			for fc in fnode.get_children():
				find_stack.append(fc)
		if fallback:
			fallback.visible = not fallback.visible


func _update_keyboard_pose_from_display() -> void:
	if not _display or not _virtual_keyboard:
		return

	# Keep keyboard aligned to the display and docked below its bottom edge.
	# Use screen sizes when available; fall back to the legacy constant drop.
	var display_size := _get_screen_size(_display)
	var kb_size := _get_screen_size(_virtual_keyboard)
	var drop_y := _UI_KEYBOARD_DROP
	if display_size != Vector2.ZERO and kb_size != Vector2.ZERO:
		drop_y = (display_size.y * 0.5) + (kb_size.y * 0.5) + _UI_KEYBOARD_GAP
	var drop := Vector3(0.0, -drop_y, 0.0)
	_virtual_keyboard.global_basis = _display.global_basis
	_virtual_keyboard.global_position = _display.global_transform.origin + (_display.global_basis * drop)


func _get_screen_size(node: Node) -> Vector2:
	if not node:
		return Vector2.ZERO
	if ("screen_size" in node):
		var s: Variant = node.get("screen_size")
		if s is Vector2:
			return s as Vector2
	return Vector2.ZERO


func _prepare_ui_scaling() -> void:
	if _display and _display_base_screen_size == Vector2.ZERO:
		_display_base_screen_size = _get_screen_size(_display)
	if _virtual_keyboard and _keyboard_base_screen_size == Vector2.ZERO:
		_keyboard_base_screen_size = _get_screen_size(_virtual_keyboard)
		if _keyboard_base_screen_size != Vector2.ZERO:
			_keyboard_base_screen_size *= _KEYBOARD_SCREEN_SIZE_MULT


func _apply_ui_scale(new_scale: float) -> void:
	_ui_scale = clamp(new_scale, _UI_SCALE_MIN, _UI_SCALE_MAX)
	_prepare_ui_scaling()
	if _display and _display_base_screen_size != Vector2.ZERO:
		_display.set("screen_size", _display_base_screen_size * _ui_scale)
	if _virtual_keyboard and _keyboard_base_screen_size != Vector2.ZERO:
		_virtual_keyboard.set("screen_size", _keyboard_base_screen_size * _ui_scale)
	_update_keyboard_pose_from_display()


func _update_ui_resize(delta: float, left_controller: XRController3D, right_controller: XRController3D) -> void:
	if not _ui_visible or _immersive_setup_active:
		_ui_resizing = false
		return
	if not left_controller or not right_controller:
		_ui_resizing = false
		return

	# Gesture: two-hand pinch/resize.
	# On Quest, users naturally do "pinch" (trigger) for grab/resize.
	# We accept either BOTH grips or BOTH triggers, but only while actually pointing at UI.
	var left_grip := left_controller.get_float("grip") > _GRIP_THRESHOLD
	var right_grip := right_controller.get_float("grip") > _GRIP_THRESHOLD
	var left_trigger := left_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	var right_trigger := right_controller.get_float("trigger") > _TRIGGER_THRESHOLD

	var any_pointer_on_ui := _node_pointer_is_hitting(_left_pointer, _UI_OBJECTS_LAYER_BIT) or _node_pointer_is_hitting(_right_pointer, _UI_OBJECTS_LAYER_BIT)
	# Be permissive: if the UI is already being interacted with (dragging or candidate-dragging),
	# allow the second hand to join and resize even if the ray briefly slips off the UI.
	if not any_pointer_on_ui and not _ui_dragging and not _ui_drag_candidate:
		_ui_resizing = false
		return

	var resize_active := (left_grip and right_grip) or (left_trigger and right_trigger)
	if not resize_active:
		_ui_resizing = false
		return

	# If the user is currently dragging the UI with one controller, allow the other
	# controller to join to start a two-hand resize by cancelling the drag.
	if _ui_dragging:
		_ui_dragging = false
		_drag_controller = null
		_ui_drag_candidate = false
		_ui_drag_candidate_controller = null

	var left_pos := left_controller.global_transform.origin
	var right_pos := right_controller.global_transform.origin
	var hands_dist := left_pos.distance_to(right_pos)
	if hands_dist < 0.001:
		return

	if not _ui_resizing:
		_ui_resizing = true
		_ui_resize_start_hands_dist = hands_dist
		_ui_resize_start_scale = _ui_scale
		return

	var desired_scale: float = _ui_resize_start_scale * (hands_dist / _ui_resize_start_hands_dist)
	# Slight smoothing so resizing feels stable.
	var alpha := _smooth_alpha(delta, _UI_RESIZE_SMOOTH_TIME)
	_apply_ui_scale(lerp(_ui_scale, desired_scale, alpha))


func _disable_ui_collisions() -> void:
	if _display:
		var b := _display.get_node_or_null("StaticBody3D") as StaticBody3D
		if b:
			b.collision_layer = _UI_OBJECTS_LAYER_BIT | 1
			b.collision_mask = 1
	if _virtual_keyboard:
		var kb := _virtual_keyboard.get_node_or_null("StaticBody3D") as StaticBody3D
		if kb:
			kb.collision_layer = _UI_OBJECTS_LAYER_BIT | 1
			kb.collision_mask = 1


func _configure_pointer_for_ui() -> void:
	_configure_single_pointer_for_ui(_left_pointer)
	_configure_single_pointer_for_ui(_right_pointer)


func _configure_single_pointer_for_ui(pointer: Node) -> void:
	if not pointer:
		return

	# XRToolsFunctionPointer exposes collision_mask/collide_with_bodies as exported properties.
	# Keep laser stable while interacting with UI.
	if "show_laser" in pointer:
		pointer.show_laser = 1
	if "laser_length" in pointer:
		pointer.laser_length = 0
	if "suppress_radius" in pointer:
		pointer.suppress_radius = 0.0
	if "suppress_mask" in pointer:
		pointer.suppress_mask = 0

	if "active_button_action" in pointer:
		# Pointer uses button_pressed/button_released events; bind to click action.
		pointer.active_button_action = "trigger_click"
	if "collide_with_bodies" in pointer:
		pointer.collide_with_bodies = true
	if "collide_with_areas" in pointer:
		pointer.collide_with_areas = true
	if "collision_mask" in pointer:
		pointer.collision_mask = int(pointer.collision_mask) | _UI_OBJECTS_LAYER_BIT


func _configure_pointer_visuals_on_top() -> void:
	_configure_single_pointer_visuals_on_top(_left_pointer)
	_configure_single_pointer_visuals_on_top(_right_pointer)


func _configure_single_pointer_visuals_on_top(pointer: Node) -> void:
	if not pointer:
		return

	# Pointer script may re-apply its exported materials during runtime. Configure those
	# materials directly so the laser remains visible above the UI.
	if "laser_material" in pointer and pointer.laser_material is BaseMaterial3D:
		var lm := (pointer.laser_material as BaseMaterial3D).duplicate() as BaseMaterial3D
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lm.no_depth_test = true
		lm.render_priority = 127
		pointer.laser_material = lm
	if "laser_hit_material" in pointer and pointer.laser_hit_material is BaseMaterial3D:
		var lhm := (pointer.laser_hit_material as BaseMaterial3D).duplicate() as BaseMaterial3D
		lhm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lhm.no_depth_test = true
		lhm.render_priority = 127
		pointer.laser_hit_material = lhm
	if "target_material" in pointer and pointer.target_material is BaseMaterial3D:
		var tm := (pointer.target_material as BaseMaterial3D).duplicate() as BaseMaterial3D
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.no_depth_test = true
		tm.render_priority = 127
		pointer.target_material = tm

	# Ensure the laser/target are visible even when UI is rendered on top.
	var laser := pointer.get_node_or_null("Laser") as MeshInstance3D
	if laser:
		var lmat := laser.get_surface_override_material(0) as BaseMaterial3D
		if not lmat:
			lmat = laser.get_active_material(0) as BaseMaterial3D
		if lmat:
			var unique_l := lmat.duplicate() as BaseMaterial3D
			# render_priority only affects transparent materials, so force transparency.
			unique_l.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			unique_l.no_depth_test = true
			unique_l.render_priority = 127
			laser.set_surface_override_material(0, unique_l)

	var target := pointer.get_node_or_null("Target") as MeshInstance3D
	if target:
		var tmat := target.get_surface_override_material(0) as BaseMaterial3D
		if not tmat:
			tmat = target.get_active_material(0) as BaseMaterial3D
		if tmat:
			var unique_t := tmat.duplicate() as BaseMaterial3D
			unique_t.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			unique_t.no_depth_test = true
			unique_t.render_priority = 127
			target.set_surface_override_material(0, unique_t)


func _disable_gaze_pointer() -> void:
	if not _gaze_pointer:
		return

	if "click_on_hold" in _gaze_pointer:
		_gaze_pointer.click_on_hold = false
	if "enabled" in _gaze_pointer:
		_gaze_pointer.enabled = false


func _force_ui_on_top() -> void:
	_force_viewport_screen_on_top(_display)
	_force_viewport_screen_on_top(_virtual_keyboard)


func _force_viewport_screen_on_top(node: Node3D) -> void:
	if not node:
		return

	var screen := node.get_node_or_null("Screen") as MeshInstance3D
	if not screen:
		return

	var mat := screen.get_surface_override_material(0) as BaseMaterial3D
	if not mat:
		mat = screen.get_active_material(0) as BaseMaterial3D
	if not mat:
		return

	# Duplicate so we don't accidentally affect other instances.
	var unique := mat.duplicate() as BaseMaterial3D
	# Respect depth so the avatar (and other geometry) can occlude the UI when in front.
	unique.no_depth_test = false
	unique.render_priority = 0
	screen.set_surface_override_material(0, unique)


func _update_avatar_pose() -> void:
	if not _avatar:
		return

	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return

	var base_transform := Transform3D.IDENTITY
	if _display:
		base_transform = _display.global_transform

	# Place avatar beside the display (to the right of the panel) and on the floor.
	var target_pos := base_transform.origin + base_transform.basis.x * 1.2
	target_pos.y = 0.0

	var look_target := camera.global_transform.origin
	look_target.y = target_pos.y

	_avatar.global_transform = Transform3D.IDENTITY
	_avatar.global_transform.origin = target_pos
	_avatar.look_at(look_target, Vector3.UP)
	_avatar.rotate_y(PI)
	_apply_avatar_customization()


func _on_webxr_primary_changed(webxr_primary: int) -> void:
	# Default to thumbstick.
	if webxr_primary == 0:
		webxr_primary = XRToolsUserSettings.WebXRPrimary.THUMBSTICK

	# Re-assign the action name on all the applicable functions.
	var action_name = XRToolsUserSettingsScript.get_webxr_primary_action(webxr_primary)
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f:
				if "input_action" in f:
					f.input_action = action_name
				if "rotation_action" in f:
					f.rotation_action = action_name
