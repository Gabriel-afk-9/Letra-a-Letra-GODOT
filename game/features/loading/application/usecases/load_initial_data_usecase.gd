extends RefCounted
class_name LoadInitialDataUseCase

# Coordena o pré-carregamento dos dados iniciais (perfil, loja,
# inventário e amigos) e grava cada grupo no InitialDataStore.
const TOTAL_GROUPS := 4
# Mesmo tamanho de página da SocialScreen (PAGE_SIZE), para que o
# InitialDataStore alimente a aba sem inconsistência de paginação.
const FRIENDS_PAGE_SIZE := 6

const GROUP_PROFILE := "perfil"
const GROUP_SHOP := "loja"
const GROUP_INVENTORY := "inventário"
const GROUP_FRIENDS := "amigos"

var _user_repository: UserRepository
var _shop_repository: ShopRepository
var _inventory_repository: InventoryRepository
var _friend_repository: FriendRepository
var _session_store
var _data_store: InitialDataStore
var _login_repository: LoginRepository = null
var _persistence: SessionPersistence = null


func _init(
	user_repository: UserRepository,
	shop_repository: ShopRepository,
	inventory_repository: InventoryRepository,
	friend_repository: FriendRepository,
	session_store,
	data_store: InitialDataStore,
	login_repository: LoginRepository = null,
	persistence: SessionPersistence = null
) -> void:
	_user_repository = user_repository
	_shop_repository = shop_repository
	_inventory_repository = inventory_repository
	_friend_repository = friend_repository
	_session_store = session_store
	_data_store = data_store
	_login_repository = login_repository
	_persistence = persistence


func execute(on_step: Callable = Callable()) -> LoadingResult:
	# Godot 4.7 exige await direto em coroutines (chamada sem await
	# é erro de parse), por isso as 4 cargas rodam em sequência.
	# Cada conclusão notifica o progresso; o contrato externo
	# (callback, agregação de erro, escrita no store) é o mesmo.
	var completed := 0
	var first_error := {}

	# O progresso só avança nos grupos concluídos com sucesso, de modo
	# que a barra chega a 100% somente quando todos estão disponíveis.
	var profile_result: Dictionary = await _load_profile()
	if profile_result.has("error"):
		if first_error.is_empty():
			first_error = profile_result
	else:
		completed += 1
		_notify(on_step, completed, GROUP_PROFILE)

	var shop_result: Dictionary = await _load_shop()
	if shop_result.has("error"):
		if first_error.is_empty():
			first_error = shop_result
	else:
		completed += 1
		_notify(on_step, completed, GROUP_SHOP)

	var inventory_result: Dictionary = await _load_inventory()
	if inventory_result.has("error"):
		if first_error.is_empty():
			first_error = inventory_result
	else:
		completed += 1
		_notify(on_step, completed, GROUP_INVENTORY)

	var friends_result: Dictionary = await _load_friends()
	if friends_result.has("error"):
		if first_error.is_empty():
			first_error = friends_result
	else:
		completed += 1
		_notify(on_step, completed, GROUP_FRIENDS)

	if not first_error.is_empty():
		return LoadingResult.failure(
			str(first_error.get("group", "")),
			str(first_error.get("error", "Falha ao carregar dados iniciais.")),
			bool(first_error.get("unauthorized", false))
		)
	return LoadingResult.ok()


func _notify(on_step: Callable, completed: int, group_name: String) -> void:
	if on_step.is_valid():
		on_step.call(completed, TOTAL_GROUPS, group_name)


func _load_profile() -> Dictionary:
	var token: String = _session_store.get_token()
	if token.is_empty():
		return _auth_error(GROUP_PROFILE)
	var result: Dictionary = await _user_repository.fetch_current_user_result(token)
	var user: User = result.get("user") as User
	if user == null:
		if int(result.get("status_code", 0)) == 401:
			var renewed_token := await _try_silent_refresh()
			if not renewed_token.is_empty():
				result = await _user_repository.fetch_current_user_result(renewed_token)
				user = result.get("user") as User
				token = renewed_token
		if user == null:
			return _group_error(GROUP_PROFILE, "Não foi possível carregar o perfil.", result)
	_session_store.start_session(user, token)
	if _persistence != null:
		_persistence.save(_session_store)
	_data_store.set_user(user)
	return {"ok": true}


func _try_silent_refresh() -> String:
	if _login_repository == null:
		return ""
	if not _session_store.has_method("get_refresh_token"):
		return ""
	var stored_refresh := str(_session_store.get_refresh_token())
	if stored_refresh.is_empty():
		return ""
	var refresh_result: LoginResult = await _login_repository.refresh(stored_refresh)
	if not refresh_result.success or refresh_result.access_token.is_empty():
		return ""
	if _session_store.has_method("set_tokens"):
		_session_store.set_tokens(refresh_result.access_token, refresh_result.refresh_token)
	elif _session_store.has_method("get_user"):
		_session_store.start_session(_session_store.get_user(), refresh_result.access_token)
	if _persistence != null:
		_persistence.save(_session_store)
	return refresh_result.access_token


func _load_shop() -> Dictionary:
	var result: Dictionary = await _shop_repository.fetch_offers()
	if result.has("error"):
		return _group_error(GROUP_SHOP, "Não foi possível carregar a loja.", result)
	_data_store.set_offers(result.get("offers", []))
	return {"ok": true}


func _load_inventory() -> Dictionary:
	var result: Dictionary = await _inventory_repository.fetch_my_inventory()
	if result.has("error"):
		return _group_error(GROUP_INVENTORY, "Não foi possível carregar o inventário.", result)
	_data_store.set_inventory(result.get("items", []))
	return {"ok": true}


func _load_friends() -> Dictionary:
	var friends_result: Dictionary = await _friend_repository.fetch_friends(0, FRIENDS_PAGE_SIZE)
	if friends_result.has("error"):
		return _group_error(GROUP_FRIENDS, "Não foi possível carregar os amigos.", friends_result)
	var pending_result: Dictionary = await _friend_repository.fetch_pending()
	if pending_result.has("error"):
		return _group_error(GROUP_FRIENDS, "Não foi possível carregar os amigos.", pending_result)
	var sent_result: Dictionary = await _friend_repository.fetch_sent()
	if sent_result.has("error"):
		return _group_error(GROUP_FRIENDS, "Não foi possível carregar os amigos.", sent_result)
	_data_store.set_friends(
		friends_result.get("friends", []),
		int(friends_result.get("page", 0)),
		int(friends_result.get("total_pages", 1)),
		int(friends_result.get("total_elements", 0))
	)
	_data_store.set_pending(pending_result.get("requests", []))
	_data_store.set_sent(sent_result.get("requests", []))
	_data_store.mark_friends_loaded()
	return {"ok": true}


func _group_error(group: String, fallback: String, result: Dictionary) -> Dictionary:
	# A mensagem indica o grupo que falhou; o detalhe do servidor
	# fica registrado no dicionário para diagnóstico.
	return {
		"error": fallback,
		"group": group,
		"unauthorized": int(result.get("status_code", 0)) == 401,
		"detail": str(result.get("error", "")),
	}


func _auth_error(group: String) -> Dictionary:
	return {
		"error": "Sessão expirada. Entre novamente.",
		"group": group,
		"unauthorized": true,
	}
