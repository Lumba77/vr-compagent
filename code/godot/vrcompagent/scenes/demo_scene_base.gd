class_name DemoSceneBase
extends XRToolsSceneBase

const XRToolsUserSettingsScript = preload("res://addons/godot-xr-tools/user_settings/user_settings.gd")

var _ui_visible: bool = true
var _prev_menu_button: bool = false
var _ui_follow_gaze: bool = false
var _ui_dragging: bool = false
var _drag_controller: XRController3D
var _drag_offset: Transform3D

const _UI_DISTANCE: float = 1.6
const _UI_HEIGHT_OFFSET: float = -0.2
const _UI_KEYBOARD_DROP: float = 0.9
const _GRIP_THRESHOLD: float = 0.5

@onready var _display: Node3D = get_node_or_null("Display")
@onready var _virtual_keyboard: Node3D = get_node_or_null("VirtualKeyboard")
@onready var _avatar: Node3D = get_node_or_null("Avatar")

func _ready():
	super()

	_set_ui_visible(false)
	_disable_ui_collisions()
	_update_ui_pose()
	_update_avatar_pose()

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())


func _process(_delta: float) -> void:
	var left_controller := XRHelpers.get_left_controller(self)
	var right_controller := XRHelpers.get_right_controller(self)
	if left_controller:
		var menu_value: float = left_controller.get_float("menu_button")
		var menu_pressed: bool = menu_value > 0.5
		if menu_pressed and not _prev_menu_button:
			_set_ui_visible(not _ui_visible)
			if _ui_visible:
				_update_ui_pose()
			_update_avatar_pose()
		_prev_menu_button = menu_pressed

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


func _update_ui_pose() -> void:
	if not _display:
		return

	var camera := get_node_or_null("XROrigin3D/XRCamera3D") as Node3D
	if not camera:
		return

	var cam_xform: Transform3D = camera.global_transform
	var forward: Vector3 = -cam_xform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var target_pos: Vector3 = cam_xform.origin + forward * _UI_DISTANCE
	target_pos.y = cam_xform.origin.y + _UI_HEIGHT_OFFSET

	_display.global_position = target_pos
	_display.look_at(cam_xform.origin, Vector3.UP)
	_update_keyboard_pose_from_display()


func _update_ui_drag(left_controller: XRController3D, right_controller: XRController3D) -> void:
	if not _ui_visible or not _display:
		_ui_dragging = false
		_drag_controller = null
		return

	# If currently dragging, keep following the controller until grip is released.
	if _ui_dragging:
		if _drag_controller:
			var grip_value: float = _drag_controller.get_float("grip")
			if grip_value <= _GRIP_THRESHOLD:
				_ui_dragging = false
				_drag_controller = null
				return

			_display.global_transform = _drag_controller.global_transform * _drag_offset
			_update_keyboard_pose_from_display()
			return

	# Not dragging - start drag when grip is pressed on either controller.
	var start_controller: XRController3D = null
	if left_controller and left_controller.get_float("grip") > _GRIP_THRESHOLD:
		start_controller = left_controller
	elif right_controller and right_controller.get_float("grip") > _GRIP_THRESHOLD:
		start_controller = right_controller

	if start_controller:
		_ui_dragging = true
		_drag_controller = start_controller
		_drag_offset = start_controller.global_transform.affine_inverse() * _display.global_transform


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
			b.collision_layer = 0
			b.collision_mask = 0
	if _virtual_keyboard:
		var kb := _virtual_keyboard.get_node_or_null("StaticBody3D") as StaticBody3D
		if kb:
			kb.collision_layer = 0
			kb.collision_mask = 0


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
