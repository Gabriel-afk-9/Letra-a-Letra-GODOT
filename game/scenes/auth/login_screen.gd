extends Control

@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput

func _ready():
	AuthManager.login_success.connect(_on_login_success)
	AuthManager.login_failed.connect(_on_login_failed)
	
func _on_login_btn_pressed():
	var email = email_input.text
	var password = password_input.text
	
func _on_login_success():
	print("O gerente avisou que o login deu certo! Mudando de tela...")
	get_tree().change_scene_to_file("res://scenes/home/home_screen.tscn")

func _on_login_failed(reason):
	print("O gerente avisou que falhou: ", reason)

#Rever com atenção
func _on_sign_up_link_pressed():
	get_tree().change_scene_to_file("res://Scenes/register_screen.tscn")
