extends Control


@onready var logo: TextureRect = $Main/Logo
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
