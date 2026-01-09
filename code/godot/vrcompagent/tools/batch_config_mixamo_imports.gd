@tool
extends EditorScript

const BONE_MAP_PATH: String = "res://addons/mixamo_animation_retargeter/mixamo_bone_map.tres"
const SOURCE_DIR: String = "res://assets/Fbx/Animated"
const EXPORT_DIR: String = "res://assets/Fbx/ExportedChosen"
const NAME_KEYWORDS: Array[String] = [
	"idle",
	"angry",
]

func _run() -> void:
	_popup_message("Running batch Mixamo import config...\nSource: %s\nExport: %s\nKeywords: %s" % [SOURCE_DIR, EXPORT_DIR, str(NAME_KEYWORDS)])
	_ensure_dir(EXPORT_DIR)
	var changed := 0
	var considered := 0
	var import_paths := _collect_import_files(SOURCE_DIR)
	for import_path in import_paths:
		if not _should_process_import(import_path):
			continue
		considered += 1
		if _patch_import_file(import_path):
			changed += 1
	print("Batch Mixamo import config done. Updated ", changed, " file(s).")
	print("Now: In FileSystem, right click the folder and choose Reimport (or Reimport All).")
	print("Export dir: ", EXPORT_DIR)
	push_warning("Batch Mixamo import config done. Considered %d file(s), updated %d. Export dir: %s" % [considered, changed, EXPORT_DIR])
	_popup_message("Batch Mixamo import config done.\nConsidered: %d\nUpdated: %d\n\nNext: select an FBX (Idle/Angry) and click Import -> Reimport." % [considered, changed])

func _collect_import_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Cannot open directory: " + dir_path)
		return out
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if dir.current_is_dir():
			if name.begins_with("."):
				continue
			out.append_array(_collect_import_files(dir_path.path_join(name)))
			continue
		if name.ends_with(".fbx.import") or name.ends_with(".Fbx.import"):
			out.append(dir_path.path_join(name))
	dir.list_dir_end()
	return out

func _patch_import_file(import_path: String) -> bool:
	var config := ConfigFile.new()
	var err := config.load(import_path)
	if err != OK:
		push_warning("Failed to load: " + import_path)
		return false

	var subresources: Dictionary = config.get_value("params", "_subresources", {})
	if "nodes" not in subresources:
		subresources["nodes"] = {}

	var nodes: Dictionary = subresources["nodes"]
	if "PATH:RootNode/Skeleton3D" not in nodes:
		nodes["PATH:RootNode/Skeleton3D"] = {}
	if "PATH:Skeleton3D" not in nodes:
		nodes["PATH:Skeleton3D"] = {}

	nodes["PATH:RootNode/Skeleton3D"]["retarget/bone_map"] = load(BONE_MAP_PATH)
	nodes["PATH:Skeleton3D"]["retarget/bone_map"] = load(BONE_MAP_PATH)

	if "animations" not in subresources:
		subresources["animations"] = {}
	var animations: Dictionary = subresources["animations"]
	if "mixamo_com" not in animations:
		animations["mixamo_com"] = {}
	var anim_cfg: Dictionary = animations["mixamo_com"]

	var src_file: String = config.get_value("deps", "source_file", "")
	var base := src_file.get_file().get_basename()
	var snake := _to_snake_case(base)
	var out_path := EXPORT_DIR.path_join(snake + ".res")

	anim_cfg["save_to_file/enabled"] = true
	anim_cfg["save_to_file/keep_custom_tracks"] = ""
	anim_cfg["save_to_file/path"] = out_path
	if not anim_cfg.has("settings/loop_mode"):
		anim_cfg["settings/loop_mode"] = 0

	animations["mixamo_com"] = anim_cfg
	subresources["animations"] = animations
	subresources["nodes"] = nodes
	config.set_value("params", "_subresources", subresources)

	err = config.save(import_path)
	if err != OK:
		push_warning("Failed to save: " + import_path)
		return false
	return true


func _should_process_import(import_path: String) -> bool:
	var config := ConfigFile.new()
	var err := config.load(import_path)
	if err != OK:
		return false
	var src_file: String = config.get_value("deps", "source_file", "")
	var base := src_file.get_file().get_basename()
	var name_lc := base.to_lower()
	for k in NAME_KEYWORDS:
		if k != "" and name_lc.find(k) != -1:
			return true
	return false

func _ensure_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)

func _popup_message(message: String) -> void:
	var ei := get_editor_interface()
	if ei == null:
		return
	var base: Control = ei.get_base_control()
	if base == null:
		return
	var existing := base.get_node_or_null("MixamoBatchImportDialog")
	if existing and existing is AcceptDialog:
		existing.queue_free()
	var d := AcceptDialog.new()
	d.name = "MixamoBatchImportDialog"
	d.exclusive = false
	d.title = "Mixamo Batch Import"
	d.dialog_text = message
	base.add_child(d)
	d.popup()

func _to_snake_case(s: String) -> String:
	return s.to_snake_case().strip_edges().strip_escapes()
