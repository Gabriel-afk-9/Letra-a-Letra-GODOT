extends BaseViewModel
class_name HomeViewModel

signal user_loaded(user: User)
signal profile_changed(profile: HomePlayerProfile)
signal game_mode_changed(mode: int)

var _get_current_user_usecase: GetCurrentUserUseCase
var _navigation: NavigationService
var _data_store: InitialDataStore
var _login_repository: LoginRepository = null
var _logout_session_store = null
var _persistence: SessionPersistence = null
var _profile: HomePlayerProfile = null
var _game_mode: int = HomeGameMode.Mode.NONE


func _init(
	get_current_user_usecase: GetCurrentUserUseCase,
	navigation: NavigationService,
	data_store: InitialDataStore = null,
	login_repository: LoginRepository = null,
	session_store = null,
	persistence: SessionPersistence = null
) -> void:
	_get_current_user_usecase = get_current_user_usecase
	_navigation = navigation
	_data_store = data_store
	_login_repository = login_repository
	_logout_session_store = session_store
	_persistence = persistence


func load_initial() -> void:
	if _data_store != null and _data_store.has_user():
		_apply_user(_data_store.get_user())
		return
	load_user()


func load_user() -> void:
	_set_loading(true)
	var user: User = await _get_current_user_usecase.execute()
	_set_loading(false)

	if user == null:
		_set_error("Usuário não encontrado.")
		return

	_apply_user(user)


func _apply_user(user: User) -> void:
	_profile = HomePlayerProfile.from_user(user)
	user_loaded.emit(user)
	profile_changed.emit(_profile)


func profile() -> HomePlayerProfile:
	return _profile


# Avatar equipado real (com assetPath), vindo do inventário
# pré-carregado. Null quando nada está equipado.
func equipped_avatar_item() -> InventoryItem:
	if _data_store == null or not _data_store.is_inventory_loaded():
		return null
	for item_variant in _data_store.get_inventory():
		var item := item_variant as InventoryItem
		if item == null:
			continue
		if not EquippableAssetPaths.is_equippable(item):
			continue
		if item.category.strip_edges().to_upper() != "AVATAR":
			continue
		if item.equipped:
			return item
	return null


func selected_game_mode() -> int:
	return _game_mode


func select_game_mode(mode: int) -> void:
	if not HomeGameMode.all().has(mode):
		return
	if _game_mode == mode:
		return
	_game_mode = mode
	_clear_error()
	game_mode_changed.emit(_game_mode)


func clear_game_mode() -> void:
	if _game_mode == HomeGameMode.Mode.NONE:
		return
	_game_mode = HomeGameMode.Mode.NONE
	_clear_error()
	game_mode_changed.emit(_game_mode)


func play() -> void:
	match _game_mode:
		HomeGameMode.Mode.NORMAL:
			go_to_matchmaking()
		HomeGameMode.Mode.RANKED:
			_set_error("Ranking em breve!")
		HomeGameMode.Mode.BOT:
			_set_error("Modo Bot em breve!")


func go_to_matchmaking() -> void:
	_navigation.go_to(AppRoutes.MATCHMAKING)


func logout_and_go_to_main() -> void:
	if is_loading():
		return
	_set_loading(true)
	if _login_repository != null:
		await _login_repository.logout()
	if _logout_session_store != null and _logout_session_store.has_method("end_session"):
		_logout_session_store.end_session()
	if _persistence != null:
		_persistence.clear()
	if _data_store != null:
		_data_store.clear()
	_set_loading(false)
	_navigation.go_to(AppRoutes.MAIN)


func go_to_room() -> void:
	request_coming_soon("Salas")


func request_coming_soon(section: String) -> void:
	_set_error("%s em breve!" % section)
