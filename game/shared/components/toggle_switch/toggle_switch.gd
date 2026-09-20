extends Control
class_name ToggleSwitch

signal toggled(value: bool)

const TRACK_SIZE := Vector2(76, 36)
const COLOR_ON := Color(0.2, 0.72, 0.42)
const COLOR_OFF := Color(0.55, 0.58, 0.62)
const COLOR_BORDER := Color(0.118, 0.165, 0.267)
const COLOR_THUMB := Color.WHITE
const COLOR_TEXT := Color.WHITE
const BORDER_WIDTH := 3.0
const FONT_SIZE := 15
const SLIDE_SECONDS := 0.12

@export var initial_on := false

var _on := false
var _disabled := false
var _hover := false
var _thumb_t := 0.0
var _tween: Tween = null


func _init() -> void:
	custom_minimum_size = TRACK_SIZE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	_on = initial_on
	_thumb_t = 1.0 if _on else 0.0
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(queue_redraw)
	queue_redraw()


func is_on() -> bool:
	return _on


func state_text() -> String:
	return "ON" if _on else "OFF"


func is_disabled() -> bool:
	return _disabled


func set_value(value: bool, silent := false) -> void:
	if _on == value:
		return
	_on = value
	_animate_thumb(1.0 if value else 0.0)
	if not silent:
		toggled.emit(value)
	queue_redraw()


func toggle() -> void:
	set_value(not _on)


func set_disabled(value: bool) -> void:
	if _disabled == value:
		return
	_disabled = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if value else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if value else Control.CURSOR_POINTING_HAND
	modulate = Color(1, 1, 1, 0.55) if value else Color.WHITE
	if value:
		release_focus()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			toggle()
			accept_event()
	elif event is InputEventKey and event.is_action_pressed("ui_accept"):
		toggle()
		accept_event()


func _on_mouse_entered() -> void:
	if _disabled:
		return
	_hover = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hover = false
	queue_redraw()


func _animate_thumb(target: float) -> void:
	if is_instance_valid(_tween) and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_thumb_t, _thumb_t, target, SLIDE_SECONDS)


func _set_thumb_t(value: float) -> void:
	_thumb_t = value
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var track := COLOR_ON if _on else COLOR_OFF
	if _hover and not _disabled:
		track = track.lightened(0.12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = track
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(int(BORDER_WIDTH))
	sb.set_corner_radius_all(int(size.y / 2.0))
	draw_style_box(sb, rect)
	var font := get_theme_default_font()
	var label := state_text()
	var ascent := font.get_ascent(FONT_SIZE)
	var descent := font.get_descent(FONT_SIZE)
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var margin := 5.0
	var thumb_d := size.y - margin * 2.0
	var thumb_x := lerpf(margin, size.x - margin - thumb_d, _thumb_t)
	var free_center := thumb_x / 2.0 if _on else (thumb_x + thumb_d + size.x) / 2.0
	var baseline := Vector2(
		free_center - text_w / 2.0,
		size.y / 2.0 + (ascent - descent) / 2.0
	)
	draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, COLOR_BORDER)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_TEXT)
	var thumb_center := Vector2(thumb_x + thumb_d / 2.0, size.y / 2.0)
	draw_circle(thumb_center, thumb_d / 2.0, COLOR_THUMB)
	draw_arc(thumb_center, thumb_d / 2.0, 0.0, TAU, 32, COLOR_BORDER, BORDER_WIDTH)
