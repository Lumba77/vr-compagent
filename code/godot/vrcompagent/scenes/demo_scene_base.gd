class_name DemoSceneBase
extends XRToolsSceneBase

const XRToolsUserSettingsScript = preload("res://addons/godot-xr-tools/user_settings/user_settings.gd")

var _ui_visible: bool = true
var _prev_menu_button: bool = false

@onready var _display: Node3D = get_node_or_null("Display")
@onready var _virtual_keyboard: Node3D = get_node_or_null("VirtualKeyboard")
@onready var _avatar: Node3D = get_node_or_null("Avatar")

func _ready():
	super()

	_set_ui_visible(false)
	_update_avatar_pose()

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())


func _process(_delta: float) -> void:
	var left_controller := XRHelpers.get_left_controller(self)
	if left_controller:
		var menu_down: bool = bool(left_controller.get_bool("menu_button"))
		if menu_down and not _prev_menu_button:
			_set_ui_visible(not _ui_visible)
			_update_avatar_pose()
		_prev_menu_button = menu_down


func _set_ui_visible(visible: bool) -> void:
	_ui_visible = visible
	if _display:
		_display.visible = visible
	if _virtual_keyboard:
		_virtual_keyboard.visible = visible


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
