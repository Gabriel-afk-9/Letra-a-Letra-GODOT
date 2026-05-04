class_name UserRepository

func get_user_by_id(user_id: String) -> Dictionary:
	var path = "/user/" + user_id
	
	var response = await ApiManager.get_async(path)
	
	if response == null or not response.has("body"):
		return { "success": false, "message": "Servidor offline" }
		
	var body = response["body"]
	
	if response["code"] == 200:
		var user_data = body.get("data", body)
		return { "success": true, "data": user_data }
		
	return { "success": false, "message": body.get("message", "Erro ao buscar usuário") }
