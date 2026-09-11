extends Control


@onready var logo: TextureRect = $Main/LogoZone/Logo
@onready var google_btn: Button = $Main/ButtonsBox/GoogleBtn
@onready var email_btn: Button = $Main/ButtonsBox/EmailBtn
@onready var guest_btn: Button = $Main/ButtonsBox/GuestBtn
@onready var error_label: Label = $Main/ButtonsBox/ErrorLabel
@onready var auth_overlay: Control = $AuthOverlay
@onready var popup_title: Label = $AuthOverlay/AuthPopup/PopupCard/Margin/VBox/PopupHeader/PopupTitle
@onready var login_holder: Control = $AuthOverlay/AuthPopup/PopupCard/Margin/VBox/LoginHolder
@onready var register_holder: Control = $AuthOverlay/AuthPopup/PopupCard/Margin/VBox/RegisterHolder
@onready var login_panel: Control = $AuthOverlay/AuthPopup/PopupCard/Margin/VBox/LoginHolder/LoginPanel
@onready var register_panel: Control = $AuthOverlay/AuthPopup/PopupCard/Margin/VBox/RegisterHolder/RegisterPanel


var _view_model: MainViewModel


func _ready() -> void:
	_view_model = MainFactory.create()
	_connect_view_model()
	_setup_auth_panels()
	_start_logo_animation()


func _connect_view_model() -> void:
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _setup_auth_panels() -> void:
	login_panel.set_popup_mode()
	login_panel.set_switch_handler(_open_register)
	register_panel.set_popup_mode()
	register_panel.set_switch_handler(_open_login)


func _open_login() -> void:
	popup_title.text = "Login"
	register_holder.hide()
	login_holder.show()
	auth_overlay.show()


func _open_register() -> void:
	popup_title.text = "Cadastro"
	login_holder.hide()
	register_holder.show()
	auth_overlay.show()


func _close_auth_popup() -> void:
	auth_overlay.hide()


func _start_logo_animation() -> void:
	logo.pivot_offset = logo.get_combined_minimum_size() * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(logo, "scale", Vector2(1.06, 1.06), 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "scale", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE)


func _on_google_btn_pressed() -> void:
	_view_model.login_with_google()


func _on_email_btn_pressed() -> void:
	_open_login()


func _on_guest_btn_pressed() -> void:
	_view_model.continue_as_guest()


func _on_close_btn_pressed() -> void:
	_close_auth_popup()


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_close_auth_popup()


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
