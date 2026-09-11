extends Control


@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
@onready var confirm_password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/ConfirmInput
@onready var register_btn: Button = $ScrollContainer/CenterContainer/VBoxContainer/RegisterBtn
@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel
@onready var aux_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/HBoxContainer/YesAccount
@onready var aux_link: Control = $ScrollContainer/CenterContainer/VBoxContainer/HBoxContainer/SignInButton


var _view_model: RegisterViewModel

var _switch_handler: Callable

var _back_handler: Callable

var _popup_mode: bool = false

var _popup_actions_added: bool = false


func _ready() -> void:
	_view_model = RegisterFactory.create()
	_connect_view_model()
	if _popup_mode:
		_apply_popup_mode()


func set_switch_handler(handler: Callable) -> void:
	_switch_handler = handler


func set_popup_mode() -> void:
	_popup_mode = true
	if is_node_ready():
		_apply_popup_mode()


func set_back_handler(handler: Callable) -> void:
	_back_handler = handler


func _apply_popup_mode() -> void:
	$Background.hide()
	$Logo.hide()
	$ScrollContainer/CenterContainer/VBoxContainer/Separation.hide()
	$ScrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	aux_label.add_theme_font_size_override("font_size", 14)
	aux_link.add_theme_font_size_override("font_size", 14)
	_add_back_button()


func _add_back_button() -> void:
	if _popup_actions_added:
		return
	_popup_actions_added = true
	var form := $ScrollContainer/CenterContainer/VBoxContainer
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	var back_style := load("res://assets/styles/buttons/transparent_button.tres") as StyleBox
	var back_btn := Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(96, 48)
	back_btn.add_theme_font_size_override("font_size", 15)
	back_btn.add_theme_color_override("font_color", Color(0.102, 0.137, 0.251))
	back_btn.add_theme_color_override("font_hover_color", Color(0.102, 0.137, 0.251))
	back_btn.add_theme_color_override("font_pressed_color", Color(0.102, 0.137, 0.251))
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_stylebox_override("hover", back_style)
	back_btn.add_theme_stylebox_override("pressed", back_style)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.pressed.connect(_on_back_button_pressed)
	form.add_child(actions)
	form.move_child(actions, register_btn.get_index())
	form.remove_child(register_btn)
	actions.add_child(back_btn)
	actions.add_child(register_btn)


func _on_back_button_pressed() -> void:
	if _back_handler.is_valid():
		_back_handler.call()


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
	if _switch_handler.is_valid():
		_switch_handler.call()
		return
	_view_model.go_to_login()
