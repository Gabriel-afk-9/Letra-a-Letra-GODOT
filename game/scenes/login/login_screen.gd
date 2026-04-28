extends Control

@onready var email_input = $CenterContainer/VBoxContainer/EmailInput
@onready var password_input = $CenterContainer/VBoxContainer/PasswordInput
@onready var login_btn = $CenterContainer/VBoxContainer/LoginBtn
@onready var error_label = $CenterContainer/VBoxContainer/ErrorLabel

@onready var auth_service = get_node("/root/AuthService")

func _ready() -> void:
	auth_service.login_success.connect(_on_login_success)
	auth_service.login_failed.connect(_on_login_failed)

func _on_login_btn_pressed() -> void:
	error_label.text = ""
	
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if email.is_empty():
		email_input.shake()
		return
		
	if password.is_empty():
		password_input.shake()
		return
	
	login_btn.disabled = true
	auth_service.login(email, password)

func _on_login_success(data) -> void:
	print("Login deu certo!")
	get_tree().change_scene_to_file("res://scenes/home/home_screen.tscn")

func _on_login_failed(reason: String) -> void:
	login_btn.disabled = false 
	
	show_error_message(reason)
	
	password_input.shake()
	print("Erro no login: ", reason)

func _on_sign_up_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register/register_screen.tscn")

# MANDAR A LOGICA PARA OUTRA PASTA
func show_error_message(message: String) -> void:
	error_label.text = message
	error_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(error_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(3.0)
	
	tween.tween_property(error_label, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): error_label.text = "")
