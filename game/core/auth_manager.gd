extends Node

signal login_success
signal login_failed(reason)

var http_request: HTTPRequest

var user_tokken: String = ""
var user_id: String = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
func login(email, password):
	var auth_data = {
		"email": email,
		"password": password
	}
	var json = JSON.stringify(auth_data)
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:8080/"
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		login_success.emit()
	else:
		login_failed.emit("Erro ao logar")
	
