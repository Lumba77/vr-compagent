class_name DemoSceneBase
extends XRToolsSceneBase

const XRToolsUserSettingsScript = preload("res://addons/godot-xr-tools/user_settings/user_settings.gd")

var _ui_visible: bool = true
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

const _UI_DISTANCE: float = 1.6
const _UI_HEIGHT_OFFSET: float = -0.2
const _UI_KEYBOARD_DROP: float = 1.45
const _GRIP_THRESHOLD: float = 0.5
const _TRIGGER_THRESHOLD: float = 0.5

const _UI_OBJECTS_LAYER_BIT: int = 1 << 22

const _IMMERSIVE_SETUP_CONFIG_PATH: String = "user://immersive_setup.cfg"
const _SETUP_GRAB_SPEED: float = 1.2
const _SETUP_ROTATE_SPEED: float = 2.2
const _SETUP_RESIZE_SPEED: float = 1.2
const _SETUP_HEIGHT_SPEED: float = 0.8

enum SetupPhase {
	HEIGHT = 0,
	AREA = 1,
}

var _furniture_root: Node3D
var _immersive_setup_active: bool = false
var _setup_item_index: int = 0
var _setup_grabbing: bool = false
var _setup_grab_distance: float = 1.5
var _setup_prev_grip: bool = false
var _setup_prev_trigger: bool = false
var _setup_prev_skip: bool = false
var _setup_hovering_surface: bool = false

var _setup_items: Array[Dictionary] = []
var _setup_current: Dictionary = {}
var _setup_preview: Node3D
var _setup_skip_button: Node3D

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

@onready var _left_pointer: Node = get_node_or_null("XROrigin3D/LeftHand/FunctionPointer")
@onready var _right_pointer: Node = get_node_or_null("XROrigin3D/RightHand/FunctionPointer")

@onready var _gaze_pointer: Node = get_node_or_null("XROrigin3D/XRCamera3D/FunctionGazePointer")

var _saved_camera_environment: Environment
var _saved_avatar_collision: Dictionary = {}

func _ready():
	super()
	_ensure_passthrough_viewport_transparency()
	_ensure_passthrough_environment()
	_ensure_passthrough_world_environment()
	_ensure_passthrough_no_msaa_halo()
	_disable_player_locomotion()
	_ensure_basic_lighting()
	_ensure_floor()
	_ensure_focus_dimmer()
	_ensure_furniture_root()
	_setup_init_items()
	_load_or_start_immersive_setup()

	_set_ui_visible(true)
	_disable_ui_collisions()
	_force_ui_on_top()
	_configure_pointer_for_ui()
	_configure_pointer_visuals_on_top()
	_disable_gaze_pointer()
	_update_ui_pose()
	_update_avatar_pose()
	call_deferred("_hook_display_ui")

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())


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
	if get_node_or_null("Floor"):
		return

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1

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
		{"key": "bed", "label": "Bed", "height": 0.55, "size": Vector2(2.0, 1.4), "color": Color(0.8, 0.2, 1.0, 1.0)}
	]


func _load_or_start_immersive_setup() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_IMMERSIVE_SETUP_CONFIG_PATH)
	if err == OK and cfg.has_section("anchors"):
		_spawn_saved_furniture(cfg)
		_immersive_setup_active = false
		return

	# No saved config: start setup.
	_start_immersive_setup()


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
	_reconfigure_immersive_setup()


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
	_setup_phase = SetupPhase.HEIGHT
	_setup_current_height = float(_setup_current["height"])
	_setup_phase_time = 0.0
	_setup_grabbing = false
	_setup_prev_grip = false
	_setup_prev_trigger = false
	_setup_prev_skip = false

	if _setup_preview and is_instance_valid(_setup_preview):
		_setup_preview.queue_free()
	_setup_preview = _create_surface_placeholder(
		_setup_current["label"],
		_setup_current["size"],
		_setup_current_height,
		_setup_current["color"],
		true
	)
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
		pos.y = _setup_current_height
		_setup_preview.global_position = pos
		_setup_preview.look_at(camera.global_position, Vector3.UP)
		_setup_preview.rotate_y(PI)
		_setup_update_skip_button_pose()


func _finish_immersive_setup() -> void:
	_immersive_setup_active = false
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

	_set_ui_visible(true)
	_update_ui_pose()


func _process_immersive_setup(delta: float, _left_controller: XRController3D, right_controller: XRController3D) -> void:
	if not _setup_preview or not is_instance_valid(_setup_preview) or not right_controller:
		return

	_setup_update_skip_button_pose()

	# Right-hand controls.
	var grip_down: bool = right_controller.get_float("grip") > _GRIP_THRESHOLD
	var trigger_down: bool = right_controller.get_float("trigger") > _TRIGGER_THRESHOLD
	var stick: Vector2 = right_controller.get_vector2("primary")

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
		if _setup_phase == SetupPhase.HEIGHT:
			# Modifier scheme:
			# - trigger held: stick Y adjusts height
			# - no trigger: stick Y adjusts distance
			# (rotation/resize disabled during height phase)
			if trigger_down:
				_setup_current_height = clamp(
					_setup_current_height + (-stick.y) * (_SETUP_HEIGHT_SPEED * delta),
					0.05,
					2.5
				)
			else:
				_setup_grab_distance = clamp(
					_setup_grab_distance + (-stick.y) * (_SETUP_GRAB_SPEED * delta),
					0.3,
					6.0
				)
		else:
			# AREA phase:
			# - normal: stick Y moves in/out, stick X rotates
			# - modifier: while holding trigger, stick resizes instead
			if trigger_down:
				var resize := Vector2(stick.x, -stick.y)
				if resize != Vector2.ZERO:
					_set_surface_size(
						_setup_preview,
						_setup_get_surface_size(_setup_preview) + resize * (_SETUP_RESIZE_SPEED * delta)
					)
			else:
				_setup_grab_distance = clamp(
					_setup_grab_distance + (-stick.y) * (_SETUP_GRAB_SPEED * delta),
					0.3,
					6.0
				)
				_setup_preview.rotate_y(-stick.x * _SETUP_ROTATE_SPEED * delta)

		# Place along the right controller forward direction.
		var ray_origin := right_controller.global_position
		var ray_dir := (right_controller.global_basis * Vector3.FORWARD).normalized()
		if _right_pointer and (_right_pointer is Node3D):
			ray_origin = (_right_pointer as Node3D).global_position
			ray_dir = ((_right_pointer as Node3D).global_basis * Vector3.FORWARD).normalized()
		var new_pos := ray_origin + ray_dir * _setup_grab_distance
		new_pos.y = _setup_current_height
		_setup_preview.global_position = new_pos
		_setup_apply_phase_visuals()

	# Confirm on trigger press-edge (only when NOT grabbing, so trigger can be used as resize modifier).
	if (not _setup_grabbing) and trigger_down and not _setup_prev_trigger:
		if _setup_phase == SetupPhase.HEIGHT:
			_setup_phase = SetupPhase.AREA
			_setup_phase_time = 0.0
			_setup_apply_phase_visuals()
		else:
			_save_current_setup_item()
			_setup_item_index += 1
			_setup_begin_item()
	_setup_prev_trigger = trigger_down


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

	var key: String = str(_setup_current["key"])
	var pos: Vector3 = _setup_preview.global_position
	var yaw: float = _setup_preview.global_rotation.y
	var size: Vector2 = _setup_get_surface_size(_setup_preview)
	var height: float = _setup_current_height

	# Store a list of enabled anchors.
	var anchors: PackedStringArray = cfg.get_value("anchors", "keys", PackedStringArray())
	if not anchors.has(key):
		anchors.append(key)
	cfg.set_value("anchors", "keys", anchors)

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
	for item in _setup_items:
		var k: String = str(item["key"])
		if not keys.has(k):
			continue
		if not cfg.has_section(k):
			continue

		var pos: Vector3 = cfg.get_value(k, "pos", Vector3.ZERO)
		var yaw: float = float(cfg.get_value(k, "yaw", 0.0))
		var size: Vector2 = cfg.get_value(k, "size", item["size"])
		var height: float = float(cfg.get_value(k, "height", item["height"]))
		pos.y = height

		var surf := _create_surface_placeholder(
			"Saved_" + str(item["label"]),
			size,
			height,
			item["color"],
			false
		)
		_furniture_root.add_child(surf)
		surf.global_position = pos
		surf.global_rotation = Vector3(0.0, yaw, 0.0)


func _create_surface_placeholder(name_str: String, size: Vector2, _height: float, color: Color, placement_mode: bool) -> Node3D:
	var root := Node3D.new()
	root.name = name_str

	# Visual: semi-transparent volume sides + glowing lid.
	const VOL_HEIGHT: float = 0.18

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
	ia.collision_layer = _UI_OBJECTS_LAYER_BIT
	ia.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.02, size.y)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	cs.position = Vector3(0.0, 0.0, 0.0)
	ia.add_child(cs)
	root.add_child(ia)

	ia.pointer_event.connect(self._on_setup_surface_pointer_event)
	return root


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

	if _immersive_setup_active:
		_process_immersive_setup(delta, left_controller, right_controller)
		return

	if left_controller:
		var menu_value: float = left_controller.get_float("menu_button")
		var menu_pressed: bool = menu_value > 0.5
		if menu_pressed and not _prev_menu_button:
			_set_ui_visible(not _ui_visible)
			if _ui_visible:
				_update_ui_pose()
		_prev_menu_button = menu_pressed

	_update_avatar_customization(delta, left_controller, right_controller)
	_update_possession(delta, left_controller, right_controller)

	_update_ui_drag(left_controller, right_controller)

	if _ui_visible and _ui_follow_gaze and not _ui_dragging:
		_update_ui_pose()


func _set_ui_visible(p_visible: bool) -> void:
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


func _update_ui_pose() -> void:
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

	_display.global_position = target_pos
	_display.look_at(cam_xform.origin, Vector3.UP)
	_display.rotate_y(PI)
	_update_keyboard_pose_from_display()


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

	_avatar.global_position += move_dir * (_POSSESS_MOVE_SPEED * delta)
	_avatar.rotate_y(-turn_stick.x * _POSSESS_TURN_SPEED * delta)


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
	_avatar_floor_offset = clamp(_avatar_floor_offset + right_stick.y * (_AVATAR_HEIGHT_SPEED * delta), -1.2, 1.2)

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
	if not _avatar:
		return

	_avatar.scale = Vector3.ONE * _avatar_scale

	# Keep avatar feet anchored to the floor (y = 0), regardless of scale.
	var bottom_y: float = _get_avatar_bottom_world_y()
	if is_finite(bottom_y):
		var pos := _avatar.global_position
		pos.y -= bottom_y
		pos.y += _avatar_floor_offset
		_avatar.global_position = pos


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

	# Keep keyboard aligned to the display and dropped below it in the displays local space.
	var drop := Vector3(0.0, -_UI_KEYBOARD_DROP, 0.0)
	_virtual_keyboard.global_basis = _display.global_basis
	_virtual_keyboard.global_position = _display.global_transform.origin + (_display.global_basis * drop)


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
	unique.no_depth_test = true
	# Keep UI above world, but below pointer visuals.
	unique.render_priority = 100
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
