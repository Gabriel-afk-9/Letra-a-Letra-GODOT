extends BaseViewModel
class_name SocialViewModel

signal friends_changed
signal pending_changed
signal sent_changed
signal discover_changed
signal friends_busy_changed(is_busy: bool)
signal pending_busy_changed(is_busy: bool)
signal sent_busy_changed(is_busy: bool)
signal discover_busy_changed(is_busy: bool)
signal action_changed(action_id: String)
signal notice_changed(message: String)

const DISCOVER_PAGE_SIZE := 6
const MODE_BROWSE := "browse"
const MODE_SEARCH := "search"

const ERROR_INVALID_REQUEST := "the friend request is invalid"
const ERROR_CANNOT_ACCEPT := "the friend request cannot be accepted"
const ERROR_CANNOT_DECLINE := "the friend request cannot be declined"
const ERROR_FRIEND_NOT_FOUND := "the friend was not found"
const ERROR_STILL_PENDING := "the friend request is still pending"

var _usecase: FriendsUseCase

var _friends: Array = []
var _pending: Array = []
var _sent_requests: Array = []
var _page: int = 0
var _total_pages: int = 1
var _page_size: int = 6
var _friends_failed: bool = false
var _pending_failed: bool = false
var _sent_failed: bool = false

var _discover_mode: String = MODE_BROWSE
var _browse_users: Array = []
var _browse_page: int = 0
var _browse_total_pages: int = 1
var _browse_loaded: bool = false
var _browse_failed: bool = false
var _search_term: String = ""
var _search_users: Array = []
var _search_page: int = 0
var _search_total_pages: int = 1
var _search_failed: bool = false
var _discover_gen: int = 0
var _sent_ids: Dictionary = {}

var _friends_busy: bool = false
var _pending_busy: bool = false
var _sent_busy: bool = false
var _discover_busy: bool = false
var _action_id: String = ""


func _init(usecase: FriendsUseCase) -> void:
	_usecase = usecase


func setup_page_size(size: int) -> void:
	_page_size = maxi(1, size)


func friends() -> Array:
	return _friends


func pending() -> Array:
	return _pending


func sent_requests() -> Array:
	return _sent_requests


func page() -> int:
	return _page


func total_pages() -> int:
	return maxi(1, _total_pages)


func friends_failed() -> bool:
	return _friends_failed and _friends.is_empty()


func pending_failed() -> bool:
	return _pending_failed and _pending.is_empty()


func sent_failed() -> bool:
	return _sent_failed and _sent_requests.is_empty()


func has_searched() -> bool:
	return _discover_mode == MODE_SEARCH


func discover_mode() -> String:
	return _discover_mode


func discover_users() -> Array:
	if _discover_mode == MODE_SEARCH:
		return _search_users
	return _browse_users


func discover_page() -> int:
	if _discover_mode == MODE_SEARCH:
		return _search_page
	return _browse_page


func discover_total_pages() -> int:
	if _discover_mode == MODE_SEARCH:
		return maxi(1, _search_total_pages)
	return maxi(1, _browse_total_pages)


func discover_failed() -> bool:
	if _discover_mode == MODE_SEARCH:
		return _search_failed and _search_users.is_empty()
	return _browse_failed and _browse_users.is_empty()


func user_sent(user_id: String) -> bool:
	return bool(_sent_ids.get(user_id, false))


func is_friends_busy() -> bool:
	return _friends_busy


func is_pending_busy() -> bool:
	return _pending_busy


func is_sent_busy() -> bool:
	return _sent_busy


func is_discover_busy() -> bool:
	return _discover_busy


func action_id() -> String:
	return _action_id


func my_id() -> String:
	return _usecase.my_id()


func load_all() -> void:
	_page = 0
	await load_friends_page(0)
	await refresh_pending()
	await refresh_sent()


func load_friends_page(page: int) -> void:
	if _friends_busy:
		return
	_set_friends_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_friends(maxi(0, page), _page_size)
	_set_friends_busy(false)
	if result.has("error"):
		_friends_failed = true
		_set_error(_friendly_error(str(result["error"])))
		friends_changed.emit()
		return
	_friends_failed = false
	_friends = result.get("friends", [])
	_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_page = mini(maxi(0, page), _total_pages - 1)
	friends_changed.emit()


func next_friends_page() -> void:
	if _page < total_pages() - 1:
		await load_friends_page(_page + 1)


func prev_friends_page() -> void:
	if _page > 0:
		await load_friends_page(_page - 1)


func refresh_pending() -> void:
	if _pending_busy:
		return
	_set_pending_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_pending()
	_set_pending_busy(false)
	if result.has("error"):
		_pending_failed = true
		_set_error(_friendly_error(str(result["error"])))
		pending_changed.emit()
		return
	_pending_failed = false
	_pending = result.get("requests", [])
	pending_changed.emit()


func refresh_sent() -> void:
	if _sent_busy:
		return
	_set_sent_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_sent()
	_set_sent_busy(false)
	if result.has("error"):
		_sent_failed = true
		_set_error(_friendly_error(str(result["error"])))
		sent_changed.emit()
		return
	_sent_failed = false
	_sent_requests = result.get("requests", [])
	sent_changed.emit()


func accept_request(other_id: String) -> void:
	await _resolve_pending(other_id, "accept")


func reject_request(other_id: String) -> void:
	await _resolve_pending(other_id, "reject")


func cancel_request(other_id: String) -> void:
	if not _action_id.is_empty():
		return
	_set_action("cancel:" + other_id)
	_clear_error()
	var result: Dictionary = await _usecase.cancel_request(other_id)
	_set_action("")
	if result.has("error"):
		_set_error(_friendly_error(str(result["error"]), "cancel"))
		return
	_remove_sent(other_id)
	_notice("Pedido cancelado.")


func remove_friend(other_id: String) -> void:
	if not _action_id.is_empty():
		return
	_set_action("remove:" + other_id)
	_clear_error()
	var result: Dictionary = await _usecase.remove_friend(other_id)
	_set_action("")
	if result.has("error"):
		_set_error(_friendly_error(str(result["error"])))
		return
	_notice("Amizade desfeita.")
	await load_friends_page(_page)


func ensure_browse() -> void:
	if _browse_loaded or _discover_busy:
		return
	await load_browse_page(0)


func load_browse_page(page: int) -> void:
	if _discover_busy:
		return
	_discover_mode = MODE_BROWSE
	_set_discover_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_users(maxi(0, page), DISCOVER_PAGE_SIZE)
	_set_discover_busy(false)
	if result.has("error"):
		_browse_failed = true
		_set_error(_friendly_error(str(result["error"])))
		discover_changed.emit()
		return
	_browse_failed = false
	_browse_loaded = true
	_browse_users = result.get("users", [])
	_browse_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_browse_page = mini(maxi(0, page), _browse_total_pages - 1)
	discover_changed.emit()


func search_users(username: String) -> void:
	var clean := username.strip_edges()
	if clean.is_empty():
		_set_error("Digite um nickname para buscar.")
		return
	if _discover_busy:
		return
	_discover_mode = MODE_SEARCH
	_search_term = clean
	_search_users = []
	_discover_gen += 1
	var gen := _discover_gen
	_set_discover_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.search_users(clean, 0, DISCOVER_PAGE_SIZE)
	_set_discover_busy(false)
	if gen != _discover_gen:
		return
	if result.has("error"):
		_search_failed = true
		_set_error(_friendly_error(str(result["error"])))
		discover_changed.emit()
		return
	_search_failed = false
	_search_users = result.get("users", [])
	_search_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_search_page = 0
	discover_changed.emit()


func load_search_page(page: int) -> void:
	if _discover_busy or _discover_mode != MODE_SEARCH or _search_term.is_empty():
		return
	_discover_gen += 1
	var gen := _discover_gen
	_set_discover_busy(true)
	_clear_error()
	var result: Dictionary = await _usecase.search_users(_search_term, maxi(0, page), DISCOVER_PAGE_SIZE)
	_set_discover_busy(false)
	if gen != _discover_gen:
		return
	if result.has("error"):
		_search_failed = true
		_set_error(_friendly_error(str(result["error"])))
		discover_changed.emit()
		return
	_search_failed = false
	_search_users = result.get("users", [])
	_search_total_pages = maxi(1, int(result.get("total_pages", 1)))
	_search_page = mini(maxi(0, page), _search_total_pages - 1)
	discover_changed.emit()


func load_discover_page(page: int) -> void:
	if _discover_mode == MODE_SEARCH:
		await load_search_page(page)
	else:
		await load_browse_page(page)


func next_discover_page() -> void:
	if discover_page() < discover_total_pages() - 1:
		await load_discover_page(discover_page() + 1)


func prev_discover_page() -> void:
	if discover_page() > 0:
		await load_discover_page(discover_page() - 1)


func clear_user_search() -> void:
	_discover_gen += 1
	_discover_mode = MODE_BROWSE
	_search_term = ""
	_search_users = []
	_search_page = 0
	_search_total_pages = 1
	_search_failed = false
	_clear_error()
	discover_changed.emit()


func send_request_to(user_id: String) -> void:
	if user_id.is_empty() or not _action_id.is_empty():
		return
	_set_action("send:" + user_id)
	_clear_error()
	var result: Dictionary = await _usecase.send_request(user_id)
	_set_action("")
	if result.has("error"):
		_set_error(_friendly_error(str(result["error"]), "send"))
		return
	_sent_ids[user_id] = true
	discover_changed.emit()
	_notice("Pedido de amizade enviado!")


func _resolve_pending(other_id: String, kind: String) -> void:
	if not _action_id.is_empty():
		return
	_set_action(kind + ":" + other_id)
	_clear_error()
	var result: Dictionary = {}
	if kind == "accept":
		result = await _usecase.accept_request(other_id)
	else:
		result = await _usecase.reject_request(other_id)
	_set_action("")
	if result.has("error"):
		_set_error(_friendly_error(str(result["error"])))
		return
	_remove_pending(other_id)
	if kind == "accept":
		_notice("Pedido aceito! Vocês agora são amigos.")
		await load_friends_page(0)
	else:
		_notice("Pedido recusado.")


func _remove_pending(other_id: String) -> void:
	_pending = _without_other(_pending, other_id)
	pending_changed.emit()


func _remove_sent(other_id: String) -> void:
	_sent_requests = _without_other(_sent_requests, other_id)
	sent_changed.emit()


func _without_other(items: Array, other_id: String) -> Array:
	var kept: Array = []
	for item_variant in items:
		var friendship := item_variant as Friendship
		if friendship == null:
			continue
		if friendship.other_id(my_id()) != other_id:
			kept.append(friendship)
	return kept


func _set_friends_busy(value: bool) -> void:
	if _friends_busy == value:
		return
	_friends_busy = value
	friends_busy_changed.emit(value)


func _set_pending_busy(value: bool) -> void:
	if _pending_busy == value:
		return
	_pending_busy = value
	pending_busy_changed.emit(value)


func _set_sent_busy(value: bool) -> void:
	if _sent_busy == value:
		return
	_sent_busy = value
	sent_busy_changed.emit(value)


func _set_discover_busy(value: bool) -> void:
	if _discover_busy == value:
		return
	_discover_busy = value
	discover_busy_changed.emit(value)


func _set_action(value: String) -> void:
	_action_id = value
	action_changed.emit(value)


func _notice(message: String) -> void:
	notice_changed.emit(message)


func _friendly_error(raw: String, context: String = "") -> String:
	match raw:
		ERROR_INVALID_REQUEST:
			return "Pedido inválido ou já existente."
		ERROR_CANNOT_ACCEPT:
			return "Você não pode aceitar este pedido."
		ERROR_CANNOT_DECLINE:
			return "Você não pode cancelar este pedido." if context == "cancel" else "Você não pode recusar este pedido."
		ERROR_FRIEND_NOT_FOUND:
			return "Usuário não encontrado." if context == "send" else "Amizade não encontrada."
		ERROR_STILL_PENDING:
			return "Ainda há um pedido pendente. Cancele-o antes de remover."
	if raw.is_empty():
		return "Falha de conexão. Tente novamente."
	return raw
