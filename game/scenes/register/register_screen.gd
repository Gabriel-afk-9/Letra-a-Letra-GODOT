extends Control

@onready var nickname_input = $CenterContainer/VBoxContainer/NicknameInput
@onready var email_input = $CenterContainer/VBoxContainer/EmailInput
@onready var password_input = $CenterContainer/VBoxContainer/PasswordInput

@onready var auth_service = get_node("/root/AuthService")

func _ready() -> void:
	auth_service.register_success.connect(_on_register_success)
	auth_service.register_failed.connect(_on_register_failed)

func _on_register_btn_pressed() -> void:
	var nickname = nickname_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if nickname.is_empty() or email.is_empty() or password.is_empty():
		print("Preencha todos os campos!")
		return
		
	auth_service.register(nickname, email, password)
	
func _on_register_success() -> void:
	print("Cadastro realizado com sucesso!")
	get_tree().change_scene_to_file("res://scenes/login/login_screen.tscn")
		
func _on_register_failed(reason: String) -> void:
	print("Erro ao cadastrar: ", reason)
	
func _on_sign_in_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/login/login_screen.tscn")
