#extends Control
#
#@onready var email_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/EmailInput
#@onready var password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/PasswordInput
#@onready var confirm_password_input: LineEdit = $ScrollContainer/CenterContainer/VBoxContainer/ConfirmInput
#@onready var register_btn: Button = $ScrollContainer/CenterContainer/VBoxContainer/RegisterBtn
#@onready var error_label: Label = $ScrollContainer/CenterContainer/VBoxContainer/ErrorLabel
#
#var register_use_case: RegisterUseCase
#
#func _ready() -> void:
	#register_use_case = RegisterUseCase.new()
#
#func _on_register_btn_pressed() -> void:
	#var email = email_input.text.strip_edges()
	#var password = password_input.text.strip_edges()
	#var nickname = null
	#var confirm_password = confirm_password_input.text.strip_edges()
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
	#if confirm_password.is_empty():
		#confirm_password_input.shake()
		#has_error = true
		#if first_error_input == null:
			#first_error_input = confirm_password_input
	#
	#if has_error:
		#error_label.show_error("Por favor, preencha todos os campos em vermelho.")
		#first_error_input.grab_focus() 
		#return
		#
	#if password != confirm_password:
		#password_input.shake()
		#confirm_password_input.shake()
		#error_label.show_error("As senhas não coincidem.")
		#confirm_password_input.grab_focus()
		#return
		#
	#register_btn.disabled = true
	#
	#var result = await register_use_case.execute(email, password)
	#
	#if result["success"]:
		#_on_register_success()
	#else:
		#_on_register_failed(result.get("message", "Erro desconhecido ao cadastrar"))
	#
#func _on_register_success() -> void:
	#print("Cadastro realizado com sucesso!")
	#get_tree().change_scene_to_file("res://scenes/login/login_screen.tscn")
		#
#func _on_register_failed(reason: String) -> void:
	#print("Erro ao cadastrar: ", reason)
	#register_btn.disabled = false
	#
	#error_label.show_error(reason)
	#password_input.shake()
	#
#func _on_sign_in_button_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/login/login_screen.tscn")
