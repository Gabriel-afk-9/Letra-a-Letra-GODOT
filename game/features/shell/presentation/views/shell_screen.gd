extends Control
class_name ShellScreen

@onready var page_container: Control = $PageContainer
@onready var navbar: Navbar = $Navbar

var _manager: NavigationManager

const SWIPE_THRESHOLD_PX := 60.0
const SWIPE_DIRECTION_RATIO := 1.5
const NAVBAR_HEIGHT := 72.0

var _swipe_start := Vector2.ZERO
var _swipe_touch_id := -1
var _mouse_swiping := false
var _swipe_fired := false

func _ready() -> void:
	ShellFactory.bind(self)

func setup(manager: NavigationManager) -> void:
	_manager = manager
	navbar.page_selected.connect(_on_page_selected)
	_manager.page_changed.connect(_on_page_changed)
	_manager.select(Navbar.PAGE_PLAY)

func _on_page_selected(page_id: StringName) -> void:
	_manager.select(page_id)

func _on_page_changed(page_id: StringName) -> void:
	navbar.set_selected(page_id)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _swipe_touch_id == -1:
				_swipe_touch_id = touch.index
				_swipe_start = touch.position
				_swipe_fired = false
		elif touch.index == _swipe_touch_id:
			_swipe_touch_id = -1
			if not _swipe_fired:
				_try_swipe(touch.position - _swipe_start, touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _swipe_touch_id and not _swipe_fired:
			if _try_swipe(drag.position - _swipe_start, drag.position):
				_swipe_fired = true
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index != MOUSE_BUTTON_LEFT:
			return
		if click.pressed:
			_mouse_swiping = true
			_swipe_start = click.position
			_swipe_fired = false
		elif _mouse_swiping:
			_mouse_swiping = false
			if not _swipe_fired:
				_try_swipe(click.position - _swipe_start, click.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _mouse_swiping and not _swipe_fired:
			if _try_swipe(motion.position - _swipe_start, motion.position):
				_swipe_fired = true

func _try_swipe(delta: Vector2, end_pos: Vector2) -> bool:
	if absf(delta.x) < SWIPE_THRESHOLD_PX:
		return false
	if absf(delta.x) < absf(delta.y) * SWIPE_DIRECTION_RATIO:
		return false
	var viewport_size := get_viewport_rect().size
	if end_pos.y > viewport_size.y - NAVBAR_HEIGHT:
		return false
	if _manager == null:
		return false
	if delta.x < 0.0:
		_manager.select_next()
	else:
		_manager.select_previous()
	return true
