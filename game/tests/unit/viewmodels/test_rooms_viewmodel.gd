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
