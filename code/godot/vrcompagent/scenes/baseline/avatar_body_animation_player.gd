extends AnimationPlayer

@export var animation_res_path: String = "res://assets/Fbx/mixamo_com.res"
@export var animation_name: StringName = &"mixamo_com"

@export var exported_dir: String = "res://assets/Fbx/ExportedChosen"
@export var default_clip: StringName = &"idle"
@export var clip_paths: Dictionary = {
	&"idle": "res://assets/Fbx/ExportedChosen/idle.res",
	&"angry": "res://assets/Fbx/ExportedChosen/angry.res",
}

const _LIB_NAME: StringName = &"mixamo"

func _anim_key(anim: StringName) -> StringName:
	return StringName("%s/%s" % [String(_LIB_NAME), String(anim)])

func _ensure_library() -> AnimationLibrary:
	if has_animation_library(_LIB_NAME):
		return get_animation_library(_LIB_NAME)
	var lib := AnimationLibrary.new()
	add_animation_library(_LIB_NAME, lib)
	return lib

func _ready() -> void:
	_ensure_animation_loaded()

func _ensure_animation_loaded() -> void:
	if not clip_paths.is_empty():
		_ensure_clip_loaded(default_clip)
		return
	if has_animation(_anim_key(animation_name)):
		return
	if animation_res_path.is_empty():
		return
	var anim_res: Resource = load(animation_res_path)
	if anim_res == null:
		push_warning("BodyAnimationPlayer: failed to load animation at %s" % animation_res_path)
		return
	if anim_res is Animation:
		var lib := _ensure_library()
		lib.add_animation(animation_name, anim_res as Animation)
		return
	push_warning("BodyAnimationPlayer: resource at %s is not an Animation" % animation_res_path)

func _ensure_clip_loaded(clip: StringName) -> void:
	if has_animation(_anim_key(clip)):
		return
	if clip_paths.is_empty():
		return
	if not clip_paths.has(clip):
		return
	var path := String(clip_paths[clip])
	if path.is_empty():
		return
	var anim_res: Resource = load(path)
	if anim_res == null:
		push_warning("BodyAnimationPlayer: failed to load animation at %s" % path)
		return
	if anim_res is Animation:
		var lib := _ensure_library()
		lib.add_animation(clip, anim_res as Animation)
		return
	push_warning("BodyAnimationPlayer: resource at %s is not an Animation" % path)

func play_body(anim: StringName = animation_name, custom_blend: float = -1.0, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if not clip_paths.is_empty():
		_ensure_clip_loaded(anim)
		var key := _anim_key(anim)
		if has_animation(key):
			play(key, custom_blend, custom_speed, from_end)
			return
	_ensure_animation_loaded()
	var fallback_key := _anim_key(anim)
	if has_animation(fallback_key):
		play(fallback_key, custom_blend, custom_speed, from_end)

func play_mixamo() -> void:
	if not clip_paths.is_empty():
		play_idle()
		return
	play_body(animation_name)

func play_idle(custom_blend: float = -1.0, custom_speed: float = 1.0, from_end: bool = false) -> void:
	play_body(&"idle", custom_blend, custom_speed, from_end)

func play_angry(custom_blend: float = -1.0, custom_speed: float = 1.0, from_end: bool = false) -> void:
	play_body(&"angry", custom_blend, custom_speed, from_end)
