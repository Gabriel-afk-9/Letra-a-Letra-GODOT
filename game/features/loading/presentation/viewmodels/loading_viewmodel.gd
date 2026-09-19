extends BaseViewModel
class_name LoadingViewModel

signal progress_changed(value: float)
signal status_changed(text: String)
signal loaded

var _usecase: LoadInitialDataUseCase
var _navigation: NavigationService
var _session_store
var _data_store: InitialDataStore
var _progress: float = 0.0


func _init(
	usecase: LoadInitialDataUseCase,
	navigation: NavigationService,
	session_store,
	data_store: InitialDataStore
) -> void:
	_usecase = usecase
	_navigation = navigation
	_session_store = session_store
	_data_store = data_store


func progress() -> float:
	return _progress


func start() -> void:
	if is_loading():
		return
	_clear_error()
	_set_loading(true)
	_set_progress(0.0)
	_set_status("Carregando dados...")

	var result: LoadingResult = await _usecase.execute(_on_step)

	_set_loading(false)

	if result.success:
		_set_progress(1.0)
		loaded.emit()
		_navigation.go_to_shell()
		return

	if result.unauthorized:
		_session_store.end_session()
		_data_store.clear()
		_navigation.go_to(AppRoutes.LOGIN)
		return

	_set_error(result.message)


func retry() -> void:
	start()


func go_to_login() -> void:
	_session_store.end_session()
	_data_store.clear()
	_navigation.go_to(AppRoutes.LOGIN)


func _on_step(completed: int, total: int, group_name: String) -> void:
	_set_progress(float(completed) / float(maxi(total, 1)))
	_set_status("%s pronta." % _group_label(group_name))


func _set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	progress_changed.emit(_progress)


func _set_status(text: String) -> void:
	status_changed.emit(text)


func _group_label(group_name: String) -> String:
	match group_name:
		LoadInitialDataUseCase.GROUP_PROFILE:
			return "Perfil pronto."
		LoadInitialDataUseCase.GROUP_SHOP:
			return "Loja pronta."
		LoadInitialDataUseCase.GROUP_INVENTORY:
			return "Inventário pronto."
		LoadInitialDataUseCase.GROUP_FRIENDS:
			return "Amigos prontos."
	return "Carregamento concluído."
