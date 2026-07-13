extends RefCounted
class_name AuthRepository

var api: Node

func _init() -> void:
	api = Engine.get_main_loop().root.get_node("ApiManager")

func login(email: String, password: String) -> Dictionary:
	var response = await api.post_async("/auth", { "email": email, "password": password })
	var body = response["body"]
	if response["code"] == 200 and body.get("success", false):
		return { "success": true, "data": body["data"] }
	return { "success": false, "message": body.get("message", "Erro ao logar") }

func register(email: String, password: String) -> Dictionary:
	var response = await api.post_async("/user", { "email": email, "password": password })
	var body = response["body"]
	if response["code"] in [200, 201] and body.get("success", false):
		return { "success": true, "data": body.get("data", {}) }
	return { "success": false, "message": body.get("message", "Erro ao cadastrar") }
