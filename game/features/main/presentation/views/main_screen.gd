extends Control


@onready var logo: TextureRect = $Main/LogoZone/Logo
@onready var google_btn: Button = $Main/ButtonsBox/GoogleBtn
@onready var email_btn: Button = $Main/ButtonsBox/EmailBtn
@onready var guest_btn: Button = $Main/ButtonsBox/GuestBtn
@onready var error_label: Label = $Main/ButtonsBox/ErrorLabel


var _view_model: MainViewModel


func _ready() -> void:
	_view_model = MainFactory.create()
	_connect_view_model()
	_start_logo_animation()


func _connect_view_model() -> void:
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _start_logo_animation() -> void:
	logo.pivot_offset = logo.get_combined_minimum_size() * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(logo, "scale", Vector2(1.06, 1.06), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


func _on_google_btn_pressed() -> void:
	_view_model.login_with_google()


func _on_email_btn_pressed() -> void:
	_view_model.go_to_login()


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
