extends Control


@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
@onready var confirm_password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/ConfirmInput
@onready var register_btn: Button = $ScrollContainer/CenterContainer/VBoxContainer/RegisterBtn
@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel


var _view_model: RegisterViewModel


func _ready() -> void:
	_view_model = RegisterFactory.create()
	_connect_view_model()


func _connect_view_model() -> void:
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _on_register_btn_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	var confirm_password := confirm_password_input.text.strip_edges()

	if not _validate_inputs(email, password, confirm_password):
		return

	_view_model.register(email, password)


func _validate_inputs(
	email: String,
	password: String,
	confirm_password: String
) -> bool:

	var first_invalid: Control

	if email.is_empty():
		email_input.shake()
		first_invalid = email_input

	if password.is_empty():
		password_input.shake()
		if first_invalid == null:
			first_invalid = password_input

	if confirm_password.is_empty():
		confirm_password_input.shake()
		if first_invalid == null:
			first_invalid = confirm_password_input

	if first_invalid != null:
		first_invalid.grab_focus()
		error_label.show_error("Por favor, preencha todos os campos.")
		return false

	if password != confirm_password:
		password_input.shake()
		confirm_password_input.shake()
		confirm_password_input.grab_focus()
		error_label.show_error("As senhas não coincidem.")
		return false

	return true


func _on_loading_changed(is_loading: bool) -> void:
	register_btn.disabled = is_loading


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		error_label.hide()
		return

	error_label.show_error(message)
	password_input.shake()
	confirm_password_input.shake()


func _on_sign_in_button_pressed() -> void:
	_view_model.go_to_login()
