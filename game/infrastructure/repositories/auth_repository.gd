extends RefCounted
class_name AuthRepository

var api: Node

func _init() -> void:
	api = Engine.get_main_loop().root.get_node("ApiManager")

func login(email: String, password: String) -> Dictionary:
	var payload = { "email": email, "password": password }
	var response = await api.post_async("/user/login", payload)
	
	var body = response["body"]
	if response["code"] == 200 and body.get("success", false) == true:
		return { "success": true, "data": body["data"] }
	
	return { "success": false, "message": body.get("message", "Erro desconhecido ao logar") }

func register(email: String, password: String) -> Dictionary:
	var payload = { "email": email, "password": password }
	var response = await api.post_async("/user", payload)
	
	var body = response["body"]
	if response["code"] in [200, 201] and body.get("success", false) == true:
		return { "success": true }
		
	return { "success": false, "message": body.get("message", "Erro ao cadastrar") }
