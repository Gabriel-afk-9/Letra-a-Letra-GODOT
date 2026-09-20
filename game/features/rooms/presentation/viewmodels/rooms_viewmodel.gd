extends BaseViewModel
class_name RoomsViewModel

signal rooms_changed
signal rooms_busy_changed(is_busy: bool)
signal action_changed(action_id: String)
signal notice_changed(message: String)
signal room_created(room: Room)
signal create_failed(message: String)

const MODE_BROWSE := "browse"
const MODE_SEARCH := "search"
const ACTION_CREATE := "create"

var _usecase: RoomsUseCase
var _navigation: NavigationService
var _pending_navigation_payload: PendingNavigationPayload

var _mode: String = MODE_BROWSE
var _browse_rooms: Array = []
var _browse_page: int = 0
var _browse_total_pages: int = 1
var _browse_loaded: bool = false
var _browse_failed: bool = false
var _search_term: String = ""
var _search_rooms: Array = []
var _search_page: int = 0
var _search_total_pages: int = 1
var _search_failed: bool = false
var _rooms_gen: int = 0

var _rooms_busy: bool = false
var _create_busy: bool = false
var _action_id: String = ""
var _page_size: int = 6


func _init(
	usecase: RoomsUseCase,
	navigation: NavigationService = null,
	pending_navigation_payload: PendingNavigationPayload = null
) -> void:
	_usecase = usecase
	_navigation = navigation
	_pending_navigation_payload = pending_navigation_payload
	_usecase.room_created.connect(_on_room_created)
	_usecase.create_failed.connect(_on_create_failed)


func setup_page_size(size: int) -> void:
	_page_size = maxi(1, size)


func load_initial() -> void:
	if _mode == MODE_SEARCH and not _search_term.is_empty():
		await load_search_page(_search_page)
		return
	if _browse_loaded:
		await load_browse_page(_browse_page)
		return
	await load_browse_page(0)


func refresh_current() -> void:
	if _rooms_busy:
		return
	if _mode == MODE_SEARCH:
		await load_search_page(search_page())
	else:
		await load_browse_page(browse_page())


func rooms() -> Array:
	if _mode == MODE_SEARCH:
		return _search_rooms
	return _browse_rooms


func mode() -> String:
	return _mode


func search_term() -> String:
	return _search_term


func page() -> int:
	if _mode == MODE_SEARCH:
		return _search_page
	return _browse_page


func total_pages() -> int:
	if _mode == MODE_SEARCH:
		return maxi(1, _search_total_pages)
	return maxi(1, _browse_total_pages)


func browse_page() -> int:
	return _browse_page


func search_page() -> int:
	return _search_page


func rooms_failed() -> bool:
	if _mode == MODE_SEARCH:
		return _search_failed and _search_rooms.is_empty()
	return _browse_failed and _browse_rooms.is_empty()


func is_rooms_busy() -> bool:
	return _rooms_busy


func is_creating() -> bool:
	return _create_busy


func action_id() -> String:
	return _action_id


func load_browse_page(page: int) -> void:
	if _rooms_busy:
		return
	_mode = MODE_BROWSE
	_rooms_gen += 1
	var gen := _rooms_gen
	_set_rooms_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_public_rooms(maxi(0, page), _page_size)
	_set_rooms_busy(false)
	if gen != _rooms_gen:
		return
	if result.has("error"):
		_browse_failed = true
		_set_error(_friendly_error(result))
		rooms_changed.emit()
		return
	_browse_failed = false
	_browse_loaded = true
	_browse_rooms = result.get("rooms", [])
	_browse_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_browse_page = mini(maxi(0, page), _browse_total_pages - 1)
	rooms_changed.emit()


func search_rooms(room_name: String) -> void:
	var clean := room_name.strip_edges()
	if clean.is_empty():
		_set_error("Digite o nome da sala para buscar.")
		return
	if _rooms_busy:
		return
	_mode = MODE_SEARCH
	_search_term = clean
	_search_rooms = []
	_rooms_gen += 1
	var gen := _rooms_gen
	_set_rooms_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.search_rooms(clean, 0, _page_size)
	_set_rooms_busy(false)
	if gen != _rooms_gen:
		return
	if result.has("error"):
		_search_failed = true
		_set_error(_friendly_error(result))
		rooms_changed.emit()
		return
	_search_failed = false
	_search_rooms = result.get("rooms", [])
	_search_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_search_page = 0
	rooms_changed.emit()


func load_search_page(page: int) -> void:
	if _rooms_busy or _mode != MODE_SEARCH or _search_term.is_empty():
		return
	_rooms_gen += 1
	var gen := _rooms_gen
	_set_rooms_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.search_rooms(_search_term, maxi(0, page), _page_size)
	_set_rooms_busy(false)
	if gen != _rooms_gen:
		return
	if result.has("error"):
		_search_failed = true
		_set_error(_friendly_error(result))
		rooms_changed.emit()
		return
	_search_failed = false
	_search_rooms = result.get("rooms", [])
	_search_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_search_page = mini(maxi(0, page), _search_total_pages - 1)
	rooms_changed.emit()


func load_current_page(page: int) -> void:
	if _mode == MODE_SEARCH:
		await load_search_page(page)
	else:
		await load_browse_page(page)


func next_page() -> void:
	if page() < total_pages() - 1:
		await load_current_page(page() + 1)


func prev_page() -> void:
	if page() > 0:
		await load_current_page(page() - 1)


func clear_search() -> void:
	_rooms_gen += 1
	_mode = MODE_BROWSE
	_search_term = ""
	_search_rooms = []
	_search_page = 0
	_search_total_pages = 1
	_search_failed = false
	_clear_error()
	rooms_changed.emit()


func find_by_code(code: String) -> Dictionary:
	var clean := code.strip_edges()
	if clean.is_empty():
		return {"error": "Digite o código da sala."}
	if _rooms_busy or not _action_id.is_empty():
		return {"error": ""}
	if clean.length() > 64:
		return {"error": "Código inválido. Verifique e tente de novo."}
	_set_action("code:" + clean)
	_clear_error()
	var result: Dictionary = await _usecase.find_game_by_code(clean)
	_set_action("")
	if result.has("error"):
		return {"error": _friendly_error(result)}
	_notice("Sala encontrada! A entrada direta estará disponível em breve.")
	return {"game_id": str(result.get("game_id", ""))}


func _set_rooms_busy(value: bool) -> void:
	if _rooms_busy == value:
		return
	_rooms_busy = value
	rooms_busy_changed.emit(value)


func _set_action(value: String) -> void:
	_action_id = value
	action_changed.emit(value)


func _notice(message: String) -> void:
	notice_changed.emit(message)


func _friendly_error(result: Dictionary) -> String:
	var raw := str(result.get("error", ""))
	var status_code := int(result.get("status_code", 0))
	if status_code == 404:
		return "Sala não encontrada. Verifique e tente de novo."
	if raw.is_empty():
		return "Falha de conexão. Tente novamente."
	return raw


func create_room(room_name: String, allow_spectators: bool, private_game: bool) -> Dictionary:
	if _create_busy or not _action_id.is_empty():
		return {"error": ""}
	_set_create_busy(true)
	_clear_error()
	var result: Dictionary = _usecase.create_room(room_name, allow_spectators, private_game)
	if result.has("error"):
		_set_create_busy(false)
		return result
	return {"ok": true}


func _on_room_created(room: Room) -> void:
	_set_create_busy(false)
	room_created.emit(room)
	if _pending_navigation_payload != null:
		_pending_navigation_payload.set_payload(RoomCreatedEvent.new(room.game_id, room.display_name()))
	if _navigation != null:
		_navigation.go_to(AppRoutes.ROOM)


func _on_create_failed(message: String) -> void:
	_set_create_busy(false)
	var text := message.strip_edges()
	if text.is_empty():
		text = "Falha de conexão. Tente novamente."
	create_failed.emit(text)


func _set_create_busy(value: bool) -> void:
	if _create_busy == value:
		return
	_create_busy = value
	_set_action(ACTION_CREATE if value else "")
