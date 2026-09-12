extends RefCounted
class_name NavigationManager

signal page_changed(page_id: StringName)

const SLIDE_DURATION := 0.25

var _container: Control
var _scenes: Dictionary = {}
var _order: Array = []
var _instances: Dictionary = {}
var _disabled: Dictionary = {}
var _current_id: StringName = &""
var _animating: bool = false

func _init(container: Control) -> void:
	_container = container

func register_page(page_id: StringName, scene_path: String) -> void:
	_scenes[page_id] = scene_path
	if not _order.has(page_id):
		_order.append(page_id)

func set_page_enabled(page_id: StringName, enabled: bool) -> void:
	_disabled[page_id] = not enabled

func is_page_enabled(page_id: StringName) -> bool:
	return not bool(_disabled.get(page_id, false))

func current_page() -> StringName:
	return _current_id

func page_order() -> Array:
	return _order.duplicate()

func select_next() -> void:
	_step(1)

func select_previous() -> void:
	_step(-1)

func select(page_id: StringName, params: Dictionary = {}) -> void:
	if _current_id == page_id:
		return
	if not _scenes.has(page_id):
		return
	if not is_page_enabled(page_id):
		return
	if _animating:
		return
	var current: Control = _instances.get(_current_id, null) as Control
	if current != null and current.has_method("can_leave"):
		if not bool(current.call("can_leave")):
			return
	var page: Control = _instances.get(page_id, null) as Control
	if page == null:
		page = _create_page(page_id)
		if page == null:
			return
		_instances[page_id] = page
	if page.has_method("enter"):
		page.call("enter", params)
	_slide_to(current, page, _slide_direction(_current_id, page_id))
	_current_id = page_id
	page_changed.emit(page_id)

func _step(direction: int) -> void:
	if _order.is_empty() or _animating:
		return
	var index := _order.find(_current_id)
	if index < 0:
		select(_order[0])
		return
	var next_index := index + direction
	while next_index >= 0 and next_index < _order.size():
		var candidate: StringName = _order[next_index]
		if is_page_enabled(candidate):
			select(candidate)
			return
		next_index += direction

func _slide_direction(from_id: StringName, to_id: StringName) -> int:
	var from_index := _order.find(from_id)
	var to_index := _order.find(to_id)
	if from_index < 0 or to_index < 0 or from_index == to_index:
		return 0
	return 1 if to_index > from_index else -1

func _slide_to(from_page: Control, to_page: Control, direction: int) -> void:
	if from_page != null:
		if from_page.has_method("exit"):
			from_page.call("exit")
		if direction == 0:
			from_page.hide()
	if to_page == null:
		return
	var width := _container.size.x
	var tree := Engine.get_main_loop() as SceneTree
	if from_page == null or direction == 0 or width <= 0.0 or tree == null:
		if from_page != null:
			from_page.hide()
			from_page.position = Vector2.ZERO
		to_page.position = Vector2.ZERO
		to_page.show()
		return
	_animating = true
	to_page.position = Vector2(width * direction, 0)
	to_page.show()
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(from_page, "position:x", -width * direction, SLIDE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(to_page, "position:x", 0.0, SLIDE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_slide_finished.bind(from_page), CONNECT_ONE_SHOT)

func _on_slide_finished(from_page: Control) -> void:
	_animating = false
	if is_instance_valid(from_page):
		from_page.hide()
		from_page.position = Vector2.ZERO

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
