extends BaseViewModel
class_name HomeViewModel

signal user_loaded(user: User)
signal profile_changed(profile: HomePlayerProfile)
signal game_mode_changed(mode: int)

var _get_current_user_usecase: GetCurrentUserUseCase
var _navigation: NavigationService
var _profile: HomePlayerProfile = null
var _game_mode: int = HomeGameMode.Mode.NORMAL


func _init(
	get_current_user_usecase: GetCurrentUserUseCase,
	navigation: NavigationService
) -> void:
	_get_current_user_usecase = get_current_user_usecase
	_navigation = navigation


func load_user() -> void:
	_set_loading(true)
	var user: User = await _get_current_user_usecase.execute()
	_set_loading(false)

	if user == null:
		_set_error("Usuário não encontrado.")
		return

	_profile = HomePlayerProfile.from_user(user)
	user_loaded.emit(user)
	profile_changed.emit(_profile)


func profile() -> HomePlayerProfile:
	return _profile


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


func go_to_room() -> void:
	request_coming_soon("Salas")


func request_coming_soon(section: String) -> void:
	_set_error("%s em breve!" % section)
