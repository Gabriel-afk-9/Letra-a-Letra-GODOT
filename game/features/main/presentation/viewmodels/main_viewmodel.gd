extends BaseViewModel
class_name MainViewModel


var _navigation: NavigationService
var _refresh_usecase: RefreshSessionUseCase = null
var _session_store = null
var _persistence: SessionPersistence = null


func _init(
	navigation: NavigationService,
	refresh_usecase: RefreshSessionUseCase = null,
	session_store = null,
	persistence: SessionPersistence = null
) -> void:
	_navigation = navigation
	_refresh_usecase = refresh_usecase
	_session_store = session_store
	_persistence = persistence


func try_auto_login() -> bool:
	if _refresh_usecase == null or _session_store == null:
		return false
	if _persistence != null and not _session_store.is_authenticated():
		_persistence.restore(_session_store)
	if not _session_store.has_refresh_token():
		return false
	_set_loading(true)
	var result: LoginResult = await _refresh_usecase.execute()
	_set_loading(false)
	if not result.success:
		return false
	_navigation.go_to(AppRoutes.LOADING)
	return true


func login_with_google() -> void:
	AppLogger.debug("MainViewModel: login_with_google ainda não implementado")
	_set_error("Login com Google em breve!")


func continue_as_guest() -> void:
	AppLogger.debug("MainViewModel: continue_as_guest ainda não implementado")
	_set_error("Entrada como convidado em breve!")
