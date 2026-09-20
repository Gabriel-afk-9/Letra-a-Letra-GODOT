extends GutTest

var _repo: FakeRoomRepository
var _vm: RoomsViewModel


func before_each() -> void:
	_repo = FakeRoomRepository.new()
	var usecase := RoomsUseCase.new(_repo)
	_vm = RoomsViewModel.new(usecase)
	_vm.setup_page_size(6)


func _room(room_id: String, room_name: String) -> Room:
	return Room.new(room_id, room_name, "CUSTOM", "WAITING", [], {}, [])


func test_load_browse_page_updates_list_and_pagination() -> void:
	_repo.browse_result = {
		"rooms": [_room("g-1", "Sala 1")],
		"page": 0,
		"total_pages": 3,
		"total_elements": 15,
	}

	await _vm.load_browse_page(0)

	assert_eq(_vm.rooms().size(), 1)
	assert_eq(_vm.page(), 0)
	assert_eq(_vm.total_pages(), 3)
	assert_eq(_repo.last_page, 0)
	assert_eq(_repo.last_size, 6)


func test_load_browse_error_surfaces_message_and_keeps_data() -> void:
	_repo.browse_result = {"rooms": [_room("g-1", "Sala 1")], "page": 0, "total_pages": 1, "total_elements": 1}
	await _vm.load_browse_page(0)
	_repo.browse_result = {"error": "Falha de conexão. Tente novamente.", "status_code": 500}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.load_browse_page(0)

	assert_eq(errors.back(), "Falha de conexão. Tente novamente.")
	assert_eq(_vm.rooms().size(), 1)


func test_not_found_error_is_friendly() -> void:
	_repo.browse_result = {"error": "not found", "status_code": 404}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.load_browse_page(0)

	assert_true(_vm.rooms_failed())
	assert_eq(errors.back(), "Sala não encontrada. Verifique e tente de novo.")


func test_next_and_prev_paginate_within_bounds() -> void:
	_repo.browse_result = {"rooms": [], "page": 0, "total_pages": 2, "total_elements": 7}

	await _vm.load_browse_page(0)
	assert_eq(_vm.page(), 0)
	await _vm.next_page()
	assert_eq(_vm.page(), 1)
	assert_eq(_repo.last_page, 1)
	await _vm.next_page()
	assert_eq(_vm.page(), 1)
	await _vm.prev_page()
	assert_eq(_vm.page(), 0)
	await _vm.prev_page()
	assert_eq(_vm.page(), 0)


func test_search_uses_search_endpoint_and_mode() -> void:
	_repo.search_result = {"rooms": [_room("g-9", "Copa")], "page": 0, "total_pages": 1, "total_elements": 1}

	await _vm.search_rooms("Copa")

	assert_eq(_vm.mode(), RoomsViewModel.MODE_SEARCH)
	assert_eq(_vm.search_term(), "Copa")
	assert_eq(_repo.last_search_term, "Copa")
	assert_eq(_vm.rooms().size(), 1)


func test_search_empty_shows_validation_error() -> void:
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.search_rooms("   ")

	assert_eq(errors.back(), "Digite o nome da sala para buscar.")
	assert_eq(_repo.last_search_term, "")


func test_clear_search_returns_to_browse() -> void:
	_repo.search_result = {"rooms": [], "page": 0, "total_pages": 1, "total_elements": 0}
	await _vm.search_rooms("Copa")
	assert_eq(_vm.mode(), RoomsViewModel.MODE_SEARCH)

	_vm.clear_search()

	assert_eq(_vm.mode(), RoomsViewModel.MODE_BROWSE)
	assert_eq(_vm.search_term(), "")


func test_refresh_preserves_search_mode() -> void:
	_repo.search_result = {"rooms": [_room("g-9", "Copa")], "page": 0, "total_pages": 1, "total_elements": 1}
	await _vm.search_rooms("Copa")
	_repo.last_search_term = ""

	await _vm.refresh_current()

	assert_eq(_vm.mode(), RoomsViewModel.MODE_SEARCH)
	assert_eq(_repo.last_search_term, "Copa")


func test_find_by_code_returns_game_id_and_notifies() -> void:
	_repo.code_result = {"game_id": "g-42"}
	var notices: Array = []
	_vm.notice_changed.connect(func(message: String) -> void: notices.append(message))

	var result: Dictionary = await _vm.find_by_code("  ABC123  ")

	assert_eq(result["game_id"], "g-42")
	assert_eq(_repo.last_code, "ABC123")
	assert_eq(_vm.action_id(), "")
	assert_eq(notices.size(), 1)


func test_find_by_code_empty_returns_validation_error() -> void:
	var result: Dictionary = await _vm.find_by_code("   ")

	assert_eq(result["error"], "Digite o código da sala.")
	assert_eq(_repo.last_code, "")


func test_find_by_code_error_returns_friendly_message() -> void:
	_repo.code_result = {"error": "gone", "status_code": 404}

	var result: Dictionary = await _vm.find_by_code("XYZ")

	assert_eq(result["error"], "Sala não encontrada. Verifique e tente de novo.")
	assert_eq(_vm.action_id(), "")


func test_create_validates_empty_name() -> void:
	var result: Dictionary = _vm.create_room("   ", true, false)

	assert_eq(result["error"], "Digite o nome da sala.")
	assert_false(_vm.is_creating())
	assert_eq(_repo.last_create_name, "")


func test_create_validates_name_length() -> void:
	var long_name := "Sala com um nome muito longo além do limite"

	var result: Dictionary = _vm.create_room(long_name, true, false)

	assert_eq(result["error"], "O nome da sala deve ter no máximo 32 caracteres.")
	assert_false(_vm.is_creating())
	assert_eq(_repo.last_create_name, "")


func test_create_sends_booleans_and_locks() -> void:
	_repo.create_result = {"ok": true}

	var result: Dictionary = _vm.create_room("Minha Sala", true, false)

	assert_eq(result, {"ok": true})
	assert_eq(_repo.last_create_name, "Minha Sala")
	assert_true(_repo.last_create_allow)
	assert_false(_repo.last_create_private)
	assert_true(_vm.is_creating())
	assert_eq(_vm.action_id(), "create")


func test_create_duplicate_is_ignored() -> void:
	_repo.create_result = {"ok": true}
	_vm.create_room("Minha Sala", true, false)
	_repo.last_create_name = ""

	var result: Dictionary = _vm.create_room("Outra Sala", false, true)

	assert_eq(result, {"error": ""})
	assert_eq(_repo.last_create_name, "")


func test_create_success_emits_and_unlocks() -> void:
	var room := Room.new("g-1", "Minha Sala", "CUSTOM", "WAITING", [], {}, [])
	_repo.create_result = {"room": room}
	var created: Array = []
	_vm.room_created.connect(func(r: Room) -> void: created.append(r))

	_vm.create_room("Minha Sala", false, true)

	assert_eq(created, [room])
	assert_false(_vm.is_creating())
	assert_eq(_vm.action_id(), "")


func test_create_failure_emits_message_and_unlocks() -> void:
	_repo.create_result = {"error": "the room name is invalid"}
	var failures: Array = []
	_vm.create_failed.connect(func(message: String) -> void: failures.append(message))

	_vm.create_room("Minha Sala", true, false)

	assert_eq(failures, ["the room name is invalid"])
	assert_false(_vm.is_creating())
	assert_eq(_vm.action_id(), "")


func test_join_validates_empty_game_id() -> void:
	var result: Dictionary = _vm.join_room("   ")

	assert_eq(result["error"], "Selecione uma sala válida.")
	assert_false(_vm.is_joining())
	assert_eq(_repo.last_join_game_id, "")


func test_join_sends_game_id_and_locks() -> void:
	_repo.join_result = {"ok": true}

	var result: Dictionary = _vm.join_room("g-42")

	assert_eq(result, {"ok": true})
	assert_eq(_repo.last_join_game_id, "g-42")
	assert_true(_vm.is_joining())
	assert_eq(_vm.action_id(), "join")


func test_join_duplicate_is_ignored() -> void:
	_repo.join_result = {"ok": true}
	_vm.join_room("g-1")
	_repo.last_join_game_id = ""

	var result: Dictionary = _vm.join_room("g-2")

	assert_eq(result, {"error": ""})
	assert_eq(_repo.last_join_game_id, "")


func test_join_success_emits_and_unlocks() -> void:
	var room := Room.new("g-42", "Copa", "CUSTOM", "WAITING", [], {}, [])
	_repo.join_result = {"room": room}
	var joined: Array = []
	_vm.room_joined.connect(func(r: Room) -> void: joined.append(r))

	_vm.join_room("g-42")

	assert_eq(joined, [room])
	assert_false(_vm.is_joining())
	assert_eq(_vm.action_id(), "")


func test_join_failure_emits_message_and_unlocks() -> void:
	_repo.join_result = {"error": "the game is full"}
	var failures: Array = []
	_vm.join_failed.connect(func(message: String) -> void: failures.append(message))

	_vm.join_room("g-42")

	assert_eq(failures, ["the game is full"])
	assert_false(_vm.is_joining())
	assert_eq(_vm.action_id(), "")
