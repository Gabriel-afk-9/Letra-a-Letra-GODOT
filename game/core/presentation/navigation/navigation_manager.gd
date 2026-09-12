extends RefCounted
class_name NavigationManager

signal page_changed(page_id: StringName)

var _container: Control
var _scenes: Dictionary = {}
var _instances: Dictionary = {}
var _disabled: Dictionary = {}
var _current_id: StringName = &""

func _init(container: Control) -> void:
	_container = container

func register_page(page_id: StringName, scene_path: String) -> void:
	_scenes[page_id] = scene_path

func set_page_enabled(page_id: StringName, enabled: bool) -> void:
	_disabled[page_id] = not enabled

func is_page_enabled(page_id: StringName) -> bool:
	return not bool(_disabled.get(page_id, false))

func current_page() -> StringName:
	return _current_id

func select(page_id: StringName, params: Dictionary = {}) -> void:
	if _current_id == page_id:
		return
	if not _scenes.has(page_id):
		return
	if not is_page_enabled(page_id):
		return
	var current: Control = _instances.get(_current_id, null) as Control
	if current != null and current.has_method("can_leave"):
		if not bool(current.call("can_leave")):
			return
	if current != null:
		if current.has_method("exit"):
			current.call("exit")
		current.hide()
	var page: Control = _instances.get(page_id, null) as Control
	if page == null:
		page = _create_page(page_id)
		if page == null:
			return
		_instances[page_id] = page
	if page.has_method("enter"):
		page.call("enter", params)
	page.show()
	_current_id = page_id
	page_changed.emit(page_id)

func _create_page(page_id: StringName) -> Control:
	var path: String = str(_scenes[page_id])
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var page: Control = packed.instantiate() as Control
	if page == null:
		return null
	_container.add_child(page)
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.hide()
	return page
