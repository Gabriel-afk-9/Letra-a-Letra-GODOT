extends Control


@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
@onready var login_button: Button = $ScrollContainer/CenterContainer/VBoxContainer/LoginBtn
@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel


var _view_model: LoginViewModel

var _switch_handler: Callable

var _popup_mode: bool = false


func _ready() -> void:

	_view_model = LoginFactory.create()

	_connect_view_model()

	if _popup_mode:
		_apply_popup_mode()


func set_switch_handler(handler: Callable) -> void:
	_switch_handler = handler


func set_popup_mode() -> void:
	_popup_mode = true
	if is_node_ready():
		_apply_popup_mode()


func _apply_popup_mode() -> void:
	$Background.hide()
	$Logo.hide()
	$ScrollContainer.anchor_top = 0.0


func _connect_view_model() -> void:

	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _on_login_btn_pressed() -> void:

	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()

	if not _validate_inputs(email, password):
		return

	_view_model.login(
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


func _on_sign_up_button_pressed() -> void:
	if _switch_handler.is_valid():
		_switch_handler.call()
		return
	_view_model.go_to_register()
