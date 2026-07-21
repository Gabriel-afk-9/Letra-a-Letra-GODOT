extends Control


@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
@onready var login_button: Button = $ScrollContainer/CenterContainer/VBoxContainer/LoginBtn
@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel


var _view_model: LoginViewModel


func _ready() -> void:

	_view_model = LoginFactory.create()

	_connect_view_model()


func _connect_view_model() -> void:

	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.login_succeeded.connect(_on_login_succeeded)


func _on_login_btn_pressed() -> void:

	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()

	if not _validate_inputs(email, password):
		return

	await _view_model.login(
		email,
		password
	)


func _validate_inputs(
	email: String,
	password: String
) -> bool:

	var first_invalid: Control

	if email.is_empty():

		email_input.shake()

		first_invalid = email_input

	if password.is_empty():

		password_input.shake()

		if first_invalid == null:
			first_invalid = password_input

	if first_invalid != null:

		first_invalid.grab_focus()

		error_label.show_error(
			"Por favor, preencha todos os campos."
		)

		return false

	return true


func _on_loading_changed(
	is_loading: bool
) -> void:

	login_button.disabled = is_loading


func _on_error_changed(
	message: String
) -> void:

	if message.is_empty():
		error_label.hide()
		return

	error_label.show_error(message)

	password_input.shake()


func _on_login_succeeded(
	_user: User
) -> void:

	get_tree().change_scene_to_file(
		"res://game/features/home/presentation/views/home_screen.tscn"
	)


func _on_sign_up_button_pressed() -> void:

	get_tree().change_scene_to_file(
		"res://game/features/register/presentation/views/register_screen.tscn"
	)
