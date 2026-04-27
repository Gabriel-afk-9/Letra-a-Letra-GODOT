extends Control

@onready var email_input = $CenterContainer/VBoxContainer/EmailInput
@onready var password_input = $CenterContainer/VBoxContainer/PasswordInput

@onready var auth_service = get_node("/root/AuthService")

func _ready() -> void:
	auth_service.login_success.connect(_on_login_success)
	auth_service.login_failed.connect(_on_login_failed)

func _on_login_btn_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if email.is_empty() or password.is_empty():
		print("Preencha todos os campos")
		return

	auth_service.login(email, password)

func _on_login_success(data):
	print("Login deu certo!")
	get_tree().change_scene_to_file("res://scenes/home/home_screen.tscn")

func _on_login_failed(reason):
	print("Erro no login: ", reason)

func _on_sign_up_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register/register_screen.tscn")
