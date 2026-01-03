extends Node2D


@onready var _chat_log: TextEdit = $Container/ChatScroll/ChatLog
@onready var _chat_scroll: ScrollContainer = $Container/ChatScroll
@onready var _input: LineEdit = $Container/Prompt/Input
@onready var _tts_toggle: CheckButton = $Container/Toggles/TTS
@onready var _stt_toggle: CheckButton = $Container/Toggles/STT
@onready var _image_toggle: CheckButton = $Container/Toggles/Image


func is_tts_enabled() -> bool:
	return _tts_toggle.button_pressed


func is_stt_enabled() -> bool:
	return _stt_toggle.button_pressed


func is_image_enabled() -> bool:
	return _image_toggle.button_pressed


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
