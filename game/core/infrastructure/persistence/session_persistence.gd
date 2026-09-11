extends RefCounted
class_name SessionPersistence

const SAVE_PATH := "user://session.cfg"

func save(store: Object) -> void:
	if not store.is_authenticated():
		return

	var user: User = store.get_user()
	var user_id: String = str(user.id) if user != null else ""
	var per_user_path := "user://session_%s.cfg" % user_id if not user_id.is_empty() else SAVE_PATH

	var existing_game_id := ""
	var existing_cfg := ConfigFile.new()
	if per_user_path != SAVE_PATH and existing_cfg.load(per_user_path) == OK:
		existing_game_id = str(existing_cfg.get_value("session", "game_id", ""))

	var game_id_to_save: String = str(store.get_current_game_id())
	if game_id_to_save.is_empty() and not existing_game_id.is_empty():
		game_id_to_save = existing_game_id

	var cfg := ConfigFile.new()
	var user_dict: Dictionary = user.to_dictionary()

	cfg.set_value("session", "token", store.get_token())
	cfg.set_value("session", "game_id", game_id_to_save)

	for key in user_dict:
		cfg.set_value("user", key, user_dict[key])

	if not user_id.is_empty():
		cfg.save(per_user_path)
	cfg.save(SAVE_PATH)


func restore(store: SessionStore) -> bool:
	var cfg := ConfigFile.new()
	var loaded := false
	var token: String = ""
	var user_dict: Dictionary = {}
	var game_id: String = ""

	if cfg.load(SAVE_PATH) == OK:
		token = str(cfg.get_value("session", "token", ""))
		if not token.is_empty():
			loaded = true
			game_id = str(cfg.get_value("session", "game_id", ""))
			if cfg.has_section("user"):
				for key in cfg.get_section_keys("user"):
					user_dict[key] = cfg.get_value("user", key)

	if not loaded:
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			var best_time: int = 0
			var best_cfg: ConfigFile = null
			var best_token: String = ""
			var best_dict: Dictionary = {}
			var best_game: String = ""
			while file_name != "":
				if file_name.begins_with("session_") and file_name.ends_with(".cfg"):
					var per_path := "user://%s" % file_name
					var p_cfg := ConfigFile.new()
					if p_cfg.load(per_path) == OK:
						var p_token := str(p_cfg.get_value("session", "token", ""))
						if not p_token.is_empty():
							var mod_time := FileAccess.get_modified_time(per_path)
							if mod_time > best_time:
								best_time = mod_time
								best_cfg = p_cfg
								best_token = p_token
								best_game = str(p_cfg.get_value("session", "game_id", ""))
								best_dict = {}
								if p_cfg.has_section("user"):
									for k in p_cfg.get_section_keys("user"):
										best_dict[k] = p_cfg.get_value("user", k)
				file_name = dir.get_next()
			dir.list_dir_end()
			if best_cfg != null:
				token = best_token
				user_dict = best_dict
				game_id = best_game
				loaded = true

	if token.is_empty():
		return false

	var user := User.from_dictionary(user_dict)
	store.start_session(user, token)
	if not game_id.is_empty():
		store.set_current_game_id(game_id)

	return true


func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
