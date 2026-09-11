extends Control
class_name RegisterPopup
## Popup modal de Cadastro, autocontido.
##
## Estrutura visual própria e independente do popup de Login:
## overlay (DimBackground) + centralização (Center) + card (Card) vivem
## dentro desta cena. A Main Page apenas instancia e alterna visibilidade.
## Lógica de cadastro preservada: usa RegisterFactory/RegisterViewModel com
## as mesmas validações da tela de cadastro standalone.

signal closed
signal switch_requested


@onready var email_input: LineEdit = $Center/Card/Margin/Form/EmailInput
@onready var password_input: LineEdit = $Center/Card/Margin/Form/PasswordInput
@onready var confirm_password_input: LineEdit = $Center/Card/Margin/Form/ConfirmInput
@onready var submit_button: Button = $Center/Card/Margin/Form/ButtonRow/SubmitButton
@onready var error_label: Label = $Center/Card/Margin/Form/ErrorLabel


var _view_model: RegisterViewModel


func _ready() -> void:
	_view_model = RegisterFactory.create()
	_connect_view_model()


func open() -> void:
	error_label.hide()
	show()
	await get_tree().process_frame
	email_input.grab_focus()


func close() -> void:
	hide()
	get_viewport().gui_release_focus()


func _connect_view_model() -> void:
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _on_submit_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	var confirm_password := confirm_password_input.text.strip_edges()

	if not _validate_inputs(email, password, confirm_password):
		return

	_view_model.register(email, password)


func _validate_inputs(email: String, password: String, confirm_password: String) -> bool:
	var first_invalid: Control = null

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
		error_label.show()
		error_label.show_error("Por favor, preencha todos os campos.")
		return false

	if password != confirm_password:
		password_input.shake()
		confirm_password_input.shake()
		confirm_password_input.grab_focus()
		error_label.show()
		error_label.show_error("As senhas não coincidem.")
		return false

	return true


func _on_loading_changed(is_loading: bool) -> void:
	submit_button.disabled = is_loading


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		error_label.hide()
		return

	error_label.show()
	error_label.show_error(message)
	password_input.shake()
	confirm_password_input.shake()


func _on_switch_pressed() -> void:
	switch_requested.emit()


func _on_back_pressed() -> void:
	closed.emit()


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			closed.emit()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			closed.emit()
