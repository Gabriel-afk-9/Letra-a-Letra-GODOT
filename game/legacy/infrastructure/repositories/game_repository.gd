extends RefCounted
class_name GameRepository

var api: Node

func _init() -> void:
	api = Engine.get_main_loop().root.get_node("ApiManager")

func get_public_games() -> Dictionary:
	var response = await api.get_async("/game")
	var body = response["body"]
	
	if response["code"] == 200 and body.get("success", false) == true:
		var raw_data = body.get("data", {})
		var games_list = raw_data.get("games", [])
		return { "success": true, "data": games_list }
		
	return { "success": false, "message": body.get("message", "Erro ao buscar salas") }
