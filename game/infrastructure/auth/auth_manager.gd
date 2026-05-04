extends Node

var user_token := ""
var user_id := ""

func set_user(data):
	user_token = data["token"]
	user_id = data["id"]

func clear_session() -> void:
	user_token = ""
	user_id = ""
