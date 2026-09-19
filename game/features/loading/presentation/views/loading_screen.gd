extends Control
class_name LoadingScreen


@onready var logo: TextureRect = $Main/Logo
@onready var cell_1: TextureRect = $Main/HBoxContainer/CellSlot1/Cell1
@onready var cell_2: TextureRect = $Main/HBoxContainer/CellSlot2/Cell2
@onready var cell_3: TextureRect = $Main/HBoxContainer/CellSlot3/Cell3
@onready var status_label: Label = $Main/LoadingBox/StatusLabel
@onready var loading_bar: ProgressBar = $Main/LoadingBox/LoadingBar
@onready var retry_btn: Button = $Main/LoadingBox/RetryBtn
@onready var back_btn: LinkButton = $Main/LoadingBox/BackBtn
@onready var error_label: Label = $Main/LoadingBox/ErrorLabel


var _view_model: LoadingViewModel
var _bar_tween: Tween = null


func _ready() -> void:
	_view_model = LoadingFactory.create()
	_connect_view_model()
	_start_logo_animation()
	_start_top_animation()
	_view_model.start()


func _connect_view_model() -> void:
	_view_model.progress_changed.connect(_on_progress_changed)
	_view_model.status_changed.connect(_on_status_changed)
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _start_logo_animation() -> void:
	logo.pivot_offset = logo.get_combined_minimum_size() * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(logo, "scale", Vector2(1.05, 1.05), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "scale", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


const CELL_FLIGHT_TIME := 0.45
const CELL_LAUNCH_STAGGER := 0.3
const CELL_APEX_HOLD := 0.45
const CELL_FALL_STAGGER := 0.5
const CELL_END_PAUSE := 0.05
const CELL_REST_SCALE := 0.85
const CELL_TILT := 0.15


func _start_top_animation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var cells: Array[TextureRect] = [cell_1, cell_2, cell_3]
	var offsets: Array[Vector2] = [Vector2(-40, -40), Vector2(0, -56), Vector2(40, -44)]
	var tilts: Array[float] = [-CELL_TILT, 0.0, CELL_TILT]
	var rest_shifts: Array[Vector2] = [Vector2(60, 60), Vector2(0, 40), Vector2(-60, 60)]
	var bases: Array[Vector2] = []
	var rests: Array[Vector2] = []
	for i in cells.size():
		if not is_instance_valid(cells[i]):
			return
		cells[i].pivot_offset = cells[i].size * 0.1
		if tilts[i] != 0.0:
			cells[i].scale = Vector2(CELL_REST_SCALE, CELL_REST_SCALE)
		bases.append(cells[i].position)
		rests.append(cells[i].position + rest_shifts[i])
		if rest_shifts[i] != Vector2.ZERO:
			cells[i].position = rests[i]
	var tween := create_tween().set_loops()
	for i in cells.size():
		_add_cell_flight(tween, i == 0, cells[i], bases[i] + offsets[i], CELL_LAUNCH_STAGGER * i, true, tilts[i])
	tween.tween_interval(CELL_APEX_HOLD)
	for i in cells.size():
		_add_cell_flight(tween, i == 0, cells[i], rests[i], CELL_FALL_STAGGER * i, false, tilts[i])
	tween.tween_interval(CELL_END_PAUSE)


func _add_cell_flight(tween: Tween, first: bool, cell: TextureRect, target: Vector2, delay: float, launching: bool, tilt: float) -> void:
	const CELL_FINAL_SCALE := 1.2

	var track_x: PropertyTweener
	if first:
		track_x = tween.tween_property(cell, "position:x", target.x, CELL_FLIGHT_TIME)
	else:
		track_x = tween.parallel().tween_property(cell, "position:x", target.x, CELL_FLIGHT_TIME)
	track_x.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if delay > 0.0:
		track_x.set_delay(delay)
	var track_y := tween.parallel().tween_property(cell, "position:y", target.y, CELL_FLIGHT_TIME)
	if launching:
		track_y.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		track_y.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if delay > 0.0:
		track_y.set_delay(delay)
	if tilt != 0.0:
		var tilt_target := tilt if launching else 0.0
		var track_r := tween.parallel().tween_property(cell, "rotation", tilt_target, CELL_FLIGHT_TIME)
		track_r.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if delay > 0.0:
			track_r.set_delay(delay)

	var rest := Vector2(CELL_REST_SCALE, CELL_REST_SCALE)
	var scale_target := Vector2(CELL_FINAL_SCALE, CELL_FINAL_SCALE) if launching else rest

	var track_s := tween.parallel().tween_property(cell, "scale", scale_target, CELL_FLIGHT_TIME)
	track_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if delay > 0.0:
		track_s.set_delay(delay)


func _on_progress_changed(value: float) -> void:
	if _bar_tween != null and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(loading_bar, "value", value * 100.0, 0.25)


func _on_status_changed(text: String) -> void:
	status_label.text = text


func _on_loading_changed(is_loading: bool) -> void:
	retry_btn.disabled = is_loading
	if is_loading:
		retry_btn.hide()
		back_btn.hide()


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		error_label.hide()
		retry_btn.hide()
		return

	error_label.show()
	error_label.show_error(message)
	retry_btn.show()
	back_btn.show()


func _on_retry_btn_pressed() -> void:
	_view_model.retry()


func _on_back_btn_pressed() -> void:
	_view_model.go_to_login()
