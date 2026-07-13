extends Node

const SAVE_PATH = "user://profile.cfg"

var user_token   := ""
var user_id      := ""
var user_nickname := ""
var user_email   := ""

func set_user(data: Dictionary) -> void:
	if data.has("token"):    user_token    = data["token"]
	if data.has("id"):       user_id       = data["id"]
	if data.has("nickname"): user_nickname = data["nickname"]
	if data.has("email"):    user_email    = data["email"]
	_save()

func load_profile() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	user_id       = cfg.get_value("profile", "id",       "")
	user_nickname = cfg.get_value("profile", "nickname", "")
	user_email    = cfg.get_value("profile", "email",    "")
	return user_id != ""

func clear_session() -> void:
	user_token = ""; user_id = ""; user_nickname = ""; user_email = ""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("profile", "id",       user_id)
	cfg.set_value("profile", "nickname", user_nickname)
	cfg.set_value("profile", "email",    user_email)
	cfg.save(SAVE_PATH)
