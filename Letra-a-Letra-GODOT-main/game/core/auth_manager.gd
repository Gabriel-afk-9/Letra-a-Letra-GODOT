extends Node

signal login_success
signal login_failed(reason)

var http_request: HTTPRequest

var user_token: String = ""
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
	var url = "http://localhost:8080/user/login"
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json_parser = JSON.new()
		var error = json_parser.parse(body.get_string_from_utf8())
		if error == OK:
			var response_data = json_parser.data
			if response_data.has("success") and response_data["success"] == true:
				user_id = response_data["data"]["id"]
				user_token = response_data["data"]["token"]
				print("Token recebido", user_token)
				login_success.emit()	
			else:
				login_failed.emit(response_data.get("message", "Erro desconhecido"))
		else:
			login_failed.emit("Erro ao ler resposta da API")
	else:
		login_failed.emit("Erro de servidor ou credencias inválidas. Código:" + str(response_code))
	
