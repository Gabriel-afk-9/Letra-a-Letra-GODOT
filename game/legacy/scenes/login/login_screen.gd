#extends Control
#
#@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
#@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
#@onready var login_btn: Button = $ScrollContainer/CenterContainer/VBoxContainer/LoginBtn
#@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel
#
#var login_usecase: LoginUseCase
#
#func _ready() -> void:
	#login_usecase = LoginUseCase.new()
#
#func _on_login_btn_pressed() -> void:
	#var email = email_input.text.strip_edges()
	#var password = password_input.text.strip_edges()
#
	#var has_error = false
	#var first_error_input = null
#
	#if email.is_empty():
		#email_input.shake()
		#has_error = true
		#first_error_input = email_input
		#
	#if password.is_empty():
		#password_input.shake()
		#has_error = true
		#
		#if first_error_input == null: 
			#first_error_input = password_input
			#
	#if has_error:
		#error_label.show_error("Por favor, preencha todos os campos em vermelho.")
		#first_error_input.grab_focus() 
		#return
		#
	#login_btn.disabled = true
	#
	#var result = await login_usecase.execute(email, password)
	#
	#if result["success"]:
		#_on_login_success(result.get("data", {}))
	#else:
		#_on_login_failed(result.get("message", "Erro desconhecido ao logar"))
#
#func _on_login_success(data) -> void:
	#print("Login deu certo!")
	#get_tree().change_scene_to_file("res://scenes/home/home_screen.tscn")
#
#func _on_login_failed(reason: String) -> void:
	#login_btn.disabled = false 
	#
	#error_label.show_error(reason)
	#
	#password_input.shake()
	#print("Erro no login: ", reason)
#
#func _on_sign_up_button_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/register/register_screen.tscn")
