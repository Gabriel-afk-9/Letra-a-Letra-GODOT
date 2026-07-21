extends RefCounted
class_name SessionPersistence

const SAVE_PATH := "user://session.cfg"

func save(store: SessionStore) -> void:
	if not store.is_authenticated():
		return

	var cfg := ConfigFile.new()
	var user_dict := store.get_user().to_dictionary()

	cfg.set_value("session", "token", store.get_token())

	# Agora o SessionPersistence não sabe quais são as variáveis do User, ele só varre o dicionário!
	for key in user_dict:
		cfg.set_value("user", key, user_dict[key])

	cfg.save(SAVE_PATH)


func restore(store: SessionStore) -> bool:
	var cfg := ConfigFile.new()

	if cfg.load(SAVE_PATH) != OK:
		return false

	var token: String = cfg.get_value("session", "token", "") as String

	if token.is_empty():
		return false

	# Lemos todas as chaves da seção "user" e montamos o dicionário
	var user_dict: Dictionary = {}
	if cfg.has_section("user"):
		for key in cfg.get_section_keys("user"):
			user_dict[key] = cfg.get_value("user", key)

	# Delegamos a criação do objeto User para a própria classe User
	var user := User.from_dictionary(user_dict)

	store.start_session(user, token)

	return true


func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
