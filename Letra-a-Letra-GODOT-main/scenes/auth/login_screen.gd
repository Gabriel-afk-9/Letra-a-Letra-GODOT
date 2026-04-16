extends Control

@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var auth_request = $AuthRequest

func _on_login_btn_pressed():
	var email = email_input.text
	var password = password_input.text
	
	var auth_data = {
		"email": email,
		"password": password
	}
	
	var json = JSON.stringify(auth_data)
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:8080"
	
	auth_request.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_auth_request_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Login success!")
		get_tree().change_scene_to_file("res://Scenes/home_screen.tscn")
	else:
		print("Login failed. Check credentials.")

#Rever com atenção
func _on_sign_up_link_pressed():
	get_tree().change_scene_to_file("res://Scenes/register_screen.tscn")
