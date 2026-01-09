extends Node2D

signal immersive_setup_reconfigure_requested
signal focus_mode_changed(focused)

const _USER_PROFILE_CONFIG_PATH: String = "user://user_profile.cfg"


@onready var _chat_log: TextEdit = $Container/ChatScroll/ChatLog
@onready var _chat_scroll: ScrollContainer = $Container/ChatScroll
@onready var _input: LineEdit = $Container/Prompt/Input
@onready var _tts_toggle: CheckButton = $Container/Toggles/TTS
@onready var _stt_toggle: CheckButton = $Container/Toggles/STT
@onready var _image_toggle: CheckButton = $Container/Toggles/Image

@onready var _settings_panel: Control = $SettingsPanel
@onready var _username: LineEdit = $SettingsPanel/VBox/Username
@onready var _instruction: TextEdit = $SettingsPanel/VBox/Instruction

@onready var _advanced_toggle: Button = $SettingsPanel/VBox/AdvancedToggle
@onready var _advanced_container: Control = $SettingsPanel/VBox/AdvancedContainer

@onready var _memory_list: ItemList = $SettingsPanel/VBox/AdvancedContainer/MemoryList
@onready var _memory_editor: Control = $SettingsPanel/VBox/AdvancedContainer/MemoryEditor
@onready var _memory_edit: TextEdit = $SettingsPanel/VBox/AdvancedContainer/MemoryEditor/EditorVBox/MemoryEdit

@onready var _bg: ColorRect = $ColorRect

const _BG_NORMAL := Color(0.92, 0.95, 1.0, 0.62)
const _BG_FOCUS := Color(0.95, 0.98, 1.0, 0.88)

var _last_focus_mode: bool = false

var _memories: PackedStringArray = PackedStringArray()
var _editing_memory_index: int = -1


func is_tts_enabled() -> bool:
	return _tts_toggle.button_pressed


func is_stt_enabled() -> bool:
	return _stt_toggle.button_pressed


func is_image_enabled() -> bool:
	return _image_toggle.button_pressed


func get_username() -> String:
	return _username.text


func get_instruction_prompt() -> String:
	return _instruction.text


func get_memories() -> PackedStringArray:
	return _memories


func _ready() -> void:
	_load_user_profile()
	_update_focus_mode()


func _process(_delta: float) -> void:
	_update_focus_mode()


func _update_focus_mode() -> void:
	if not _bg:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	var has_focus := false
	if focus_owner:
		has_focus = true
	# Also consider settings open as a "reading" mode.
	if _settings_panel and _settings_panel.visible:
		has_focus = true
	_bg.color = _BG_FOCUS if has_focus else _BG_NORMAL
	if has_focus != _last_focus_mode:
		_last_focus_mode = has_focus
		focus_mode_changed.emit(has_focus)


func _append_message(role: String, message: String) -> void:
	var msg := message.strip_edges()
	if msg.is_empty():
		return
	_chat_log.text += "%s: %s\n" % [role, msg]
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	var sb := _chat_scroll.get_v_scroll_bar()
	if sb:
		_chat_scroll.scroll_vertical = ceili(sb.max_value)


func _send_current_input() -> void:
	var msg := _input.text
	_input.text = ""
	_append_message("You", msg)


func _on_SendButton_pressed() -> void:
	_send_current_input()


func _on_Input_text_submitted(_text: String) -> void:
	_send_current_input()


func _on_ClearButton_pressed() -> void:
	_chat_log.text = ""
	_input.text = ""


func _on_ImmersiveSetupButton_pressed() -> void:
	immersive_setup_reconfigure_requested.emit()


func _on_SettingsButton_pressed() -> void:
	_settings_panel.visible = not _settings_panel.visible
	if _settings_panel.visible:
		_load_user_profile()


func _on_SaveButton_pressed() -> void:
	_save_user_profile()


func _on_CloseButton_pressed() -> void:
	_settings_panel.visible = false
	_advanced_container.visible = false
	_advanced_toggle.text = "Show Advanced"


func _load_user_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_USER_PROFILE_CONFIG_PATH) != OK:
		_memories = PackedStringArray()
		_refresh_memory_list()
		return
	_username.text = str(cfg.get_value("profile", "username", ""))
	_instruction.text = str(cfg.get_value("profile", "instruction_prompt", ""))
	_memories = cfg.get_value("profile", "memories", PackedStringArray())
	_refresh_memory_list()


func _save_user_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_USER_PROFILE_CONFIG_PATH)
	cfg.set_value("profile", "username", _username.text)
	cfg.set_value("profile", "instruction_prompt", _instruction.text)
	cfg.set_value("profile", "memories", _memories)
	cfg.save(_USER_PROFILE_CONFIG_PATH)


func _on_AdvancedToggle_pressed() -> void:
	_advanced_container.visible = not _advanced_container.visible
	_advanced_toggle.text = "Hide Advanced" if _advanced_container.visible else "Show Advanced"


func _refresh_memory_list() -> void:
	if not _memory_list:
		return
	_memory_list.clear()
	for m in _memories:
		var s := str(m).strip_edges()
		if s.is_empty():
			continue
		_memory_list.add_item(s)


func _open_memory_editor(text: String, index: int) -> void:
	_editing_memory_index = index
	_memory_edit.text = text
	_memory_editor.visible = true


func _close_memory_editor() -> void:
	_memory_editor.visible = false
	_editing_memory_index = -1
	_memory_edit.text = ""


func _selected_memory_index() -> int:
	if not _memory_list:
		return -1
	var sel := _memory_list.get_selected_items()
	if sel.is_empty():
		return -1
	return int(sel[0])


func _on_AddMemoryButton_pressed() -> void:
	_open_memory_editor("", -1)


func _on_EditMemoryButton_pressed() -> void:
	var idx := _selected_memory_index()
	if idx < 0 or idx >= _memories.size():
		return
	_open_memory_editor(str(_memories[idx]), idx)


func _on_DeleteMemoryButton_pressed() -> void:
	var idx := _selected_memory_index()
	if idx < 0 or idx >= _memories.size():
		return
	_memories.remove_at(idx)
	_refresh_memory_list()
	_save_user_profile()


func _on_SaveMemoryButton_pressed() -> void:
	var s := _memory_edit.text.strip_edges()
	if s.is_empty():
		_close_memory_editor()
		return
	if _editing_memory_index >= 0 and _editing_memory_index < _memories.size():
		_memories[_editing_memory_index] = s
	else:
		_memories.append(s)
	_refresh_memory_list()
	_save_user_profile()
	_close_memory_editor()


func _on_CancelMemoryButton_pressed() -> void:
	_close_memory_editor()
