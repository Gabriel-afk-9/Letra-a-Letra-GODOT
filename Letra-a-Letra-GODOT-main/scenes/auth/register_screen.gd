extends Control

@onready var nickname_input = $VBoxContainer/NicknameInput
@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var register_request = $RegisterRequest

func _on_register_btn_pressed():
	var user_data = {
		"nickname": nickname_input.text,
		"email": email_input.text,
		"password": password_input.text
	}
	
	var json = JSON.stringify(user_data)
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:8080"
	
	register_request.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_register_request_request_completed(result, response_code, headers, body):
	if response_code == 201 or response_code == 200:
		print("Registration successful!")
		
		get_tree().change_scene_to_file("res://Scenes/home_screen.tscn")
	else:
		print("Registration error. Code: ", response_code)

func _on_login_link_pressed():
	get_tree().change_scene_to_file("res://Scenes/login_screen.tscn")
