extends Node

signal login_success(data)
signal login_failed(msg)

signal register_success
signal register_failed(msg)

@onready var api = get_node("/root/ApiManager")
@onready var auth_manager = get_node("/root/AuthManager")

var current_action = ""

func _ready():
	api.request_completed.connect(_on_api_response)

func login(email, password):
	current_action = "login"
	api.post("http://localhost:8080/user/login", {
		"email": email,
		"password": password
	})

func register(nickname, email, password):
	current_action = "register"
	api.post("http://localhost:8080/user", {
		"nickname": nickname,
		"email": email,
		"password": password
	})
	
func _on_api_response(response_code, data):
	if current_action == "login":
		if response_code == 200 and data.has("success") and data["success"] == true:
			auth_manager.set_user(data["data"]) 
			login_success.emit(data["data"])
		else:
			login_failed.emit(data.get("message", "Erro desconhecido ao logar"))

	elif current_action == "register":

		if response_code in [200, 201] and data.has("success") and data["success"] == true:
			register_success.emit()
		else:
			register_failed.emit(data.get("message", "Erro ao cadastrar"))

	current_action = ""
