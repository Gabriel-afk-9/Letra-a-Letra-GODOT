extends Control


@onready var logo: TextureRect = $Main/Logo
@onready var cell_1: TextureRect = $Main/HBoxContainer/CellSlot1/Cell1
@onready var cell_2: TextureRect = $Main/HBoxContainer/CellSlot2/Cell2
@onready var cell_3: TextureRect = $Main/HBoxContainer/CellSlot3/Cell3
@onready var google_btn: Button = $Main/ButtonsBox/GoogleBtn
@onready var email_btn: Button = $Main/ButtonsBox/EmailBtn
@onready var guest_btn: Button = $Main/ButtonsBox/GuestBtn
@onready var error_label: Label = $Main/ButtonsBox/ErrorLabel
@onready var login_popup: LoginPopup = $LoginPopup
@onready var register_popup: RegisterPopup = $RegisterPopup


var _view_model: MainViewModel


func _ready() -> void:
	_view_model = MainFactory.create()
	_connect_view_model()
	_connect_popups()
	_start_logo_animation()
	_start_top_animation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _is_any_popup_open():
			_close_all_popups()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if _is_any_popup_open():
				_close_all_popups()
				get_viewport().set_input_as_handled()


func _connect_view_model() -> void:
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _connect_popups() -> void:
	login_popup.closed.connect(_close_all_popups)
	login_popup.switch_requested.connect(_open_register)
	register_popup.closed.connect(_close_all_popups)
	register_popup.switch_requested.connect(_open_login)


func _open_login() -> void:
	register_popup.close()
	login_popup.open()


func _open_register() -> void:
	login_popup.close()
	register_popup.open()


func _close_all_popups() -> void:
	login_popup.close()
	register_popup.close()


func _is_any_popup_open() -> bool:
	return login_popup.visible or register_popup.visible


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


func _on_google_btn_pressed() -> void:
	_view_model.login_with_google()


func _on_email_btn_pressed() -> void:
	_open_login()


func _on_guest_btn_pressed() -> void:
	_view_model.continue_as_guest()


func _on_loading_changed(is_loading: bool) -> void:
	google_btn.disabled = is_loading
	email_btn.disabled = is_loading
	guest_btn.disabled = is_loading


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		error_label.hide()
		return

	error_label.show()
	error_label.show_error(message)
