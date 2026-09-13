extends GutTest

var _repo: FakeFriendRepository
var _users: FakeUserRepository
var _vm: SocialViewModel


func before_each() -> void:
	_repo = FakeFriendRepository.new()
	_users = FakeUserRepository.new()
	var usecase := FriendsUseCase.new(_repo, _users, SessionStore)
	_vm = SocialViewModel.new(usecase)
	_vm.setup_page_size(6)


func _friendship(first: String, second: String, status: String, friend_id: String = "") -> Friendship:
	var friendship := Friendship.new(first, second, status, "2026-09-01T10:00:00Z")
	friendship.friend_id = friend_id
	return friendship


func test_load_friends_page_updates_list_and_pagination() -> void:
	_repo.friends_result = {
		"friends": [_friendship("me", "f1", "ACCEPT")],
		"page": 0,
		"total_pages": 3,
		"total_elements": 15,
	}

	await _vm.load_friends_page(0)

	assert_eq(_vm.friends().size(), 1)
	assert_eq(_vm.page(), 0)
	assert_eq(_vm.total_pages(), 3)
	assert_eq(_repo.last_page, 0)
	assert_eq(_repo.last_size, 6)


func test_load_friends_error_surfaces_friendly_message() -> void:
	_repo.friends_result = {"error": "the friend request is invalid"}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.load_friends_page(0)

	assert_true(_vm.friends_failed())
	assert_eq(errors.back(), "Pedido inválido ou já existente.")


func test_next_and_prev_paginate_within_bounds() -> void:
	_repo.friends_result = {"friends": [], "page": 0, "total_pages": 2, "total_elements": 7}

	await _vm.load_friends_page(0)
	assert_eq(_vm.page(), 0)
	await _vm.next_friends_page()
	assert_eq(_vm.page(), 1)
	assert_eq(_repo.last_page, 1)
	await _vm.next_friends_page()
	assert_eq(_vm.page(), 1)
	await _vm.prev_friends_page()
	assert_eq(_vm.page(), 0)
	await _vm.prev_friends_page()
	assert_eq(_vm.page(), 0)


func test_accept_removes_pending_and_reloads_friends() -> void:
	_repo.pending_result = {"requests": [_friendship("sender", "me", "PENDING")]}
	_repo.friends_result = {"friends": [], "page": 0, "total_pages": 1, "total_elements": 0}
	var notices: Array = []
	_vm.notice_changed.connect(func(message: String) -> void: notices.append(message))

	await _vm.refresh_pending()
	assert_eq(_vm.pending().size(), 1)
	await _vm.accept_request("sender")

	assert_eq(_repo.last_accepted, "sender")
	assert_true(_vm.pending().is_empty())
	assert_eq(_repo.last_page, 0)
	assert_eq(notices, ["Pedido aceito! Vocês agora são amigos."])


func test_reject_removes_pending_without_reloading_friends() -> void:
	_repo.pending_result = {"requests": [_friendship("sender", "me", "PENDING")]}

	await _vm.refresh_pending()
	await _vm.reject_request("sender")

	assert_eq(_repo.last_rejected, "sender")
	assert_true(_vm.pending().is_empty())
	assert_eq(_repo.last_page, -1)


func test_remove_reloads_current_page() -> void:
	_repo.friends_result = {"friends": [_friendship("me", "f9", "ACCEPT")], "page": 0, "total_pages": 1, "total_elements": 1}

	await _vm.remove_friend("f9")

	assert_eq(_repo.last_removed, "f9")
	assert_eq(_repo.last_page, 0)


func test_remove_pending_reports_still_pending() -> void:
	_repo.mutate_result = {"error": "the friend request is still pending"}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.remove_friend("f9")

	assert_eq(errors.back(), "Ainda há um pedido pendente. Cancele-o antes de remover.")
	_repo.mutate_result = {"ok": true}


func test_refresh_sent_loads_sent_requests() -> void:
	_repo.sent_result = {"requests": [_friendship("me", "target", "PENDING", "target")]}

	await _vm.refresh_sent()

	assert_eq(_vm.sent_requests().size(), 1)


func test_cancel_removes_sent_request() -> void:
	_repo.sent_result = {"requests": [_friendship("me", "target", "PENDING", "target")]}
	var notices: Array = []
	_vm.notice_changed.connect(func(message: String) -> void: notices.append(message))

	await _vm.refresh_sent()
	assert_eq(_vm.sent_requests().size(), 1)
	await _vm.cancel_request("target")

	assert_eq(_repo.last_cancelled, "target")
	assert_true(_vm.sent_requests().is_empty())
	assert_eq(notices, ["Pedido cancelado."])


func test_send_to_missing_user_reports_not_found() -> void:
	_repo.mutate_result = {"error": "the friend was not found"}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.send_request_to("ghost")

	assert_eq(errors.back(), "Usuário não encontrado.")
	_repo.mutate_result = {"ok": true}


func test_stale_search_response_is_discarded_after_clear() -> void:
	_users.search_result = {
		"users": [User.new("u-1", "a@b.c", "Tardio", 1, 0, 0, 0, 0, 0, 0)],
		"page": 0,
		"total_pages": 1,
		"total_elements": 1,
	}

	_vm.search_users("tar")
	_vm.clear_user_search()
	await get_tree().process_frame
	await get_tree().process_frame

	assert_eq(_vm.discover_mode(), "browse")
	assert_true(_vm.discover_users().is_empty())


func test_search_found_and_send_clears_result() -> void:
	_users.search_result = {
		"users": [User.new("u-9", "a@b.c", "Buscado", 4, 10, 0, 0, 0, 0, 0)],
		"page": 0,
		"total_pages": 1,
		"total_elements": 1,
	}
	var notices: Array = []
	_vm.notice_changed.connect(func(message: String) -> void: notices.append(message))

	await _vm.search_users("Busc")

	assert_eq(_vm.discover_mode(), "search")
	assert_eq(_vm.discover_users().size(), 1)
	assert_eq((_vm.discover_users()[0] as User).nickname, "Buscado")
	assert_eq(_users.last_search_term, "Busc")
	assert_eq(_users.last_search_page, 0)
	await _vm.send_request_to("u-9")

	assert_eq(_repo.last_sent, "u-9")
	assert_true(_vm.user_sent("u-9"))
	assert_eq(_vm.discover_users().size(), 1)
	assert_eq(notices, ["Pedido de amizade enviado!"])


func test_search_missing_user_reports_empty() -> void:
	_users.search_result = {"users": [], "page": 0, "total_pages": 1, "total_elements": 0}

	await _vm.search_users("Fantasma")

	assert_eq(_vm.discover_mode(), "search")
	assert_true(_vm.discover_users().is_empty())


func test_search_empty_username_reports_error() -> void:
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.search_users("   ")

	assert_eq(errors.back(), "Digite um nickname para buscar.")
	assert_eq(_vm.discover_mode(), "browse")


func test_clear_search_returns_to_cached_browse() -> void:
	_users.users_result = {
		"users": [User.new("u-1", "a@b.c", "Ana", 2, 0, 0, 0, 0, 0, 0)],
		"page": 0,
		"total_pages": 1,
		"total_elements": 1,
	}
	_users.search_result = {"users": [], "page": 0, "total_pages": 1, "total_elements": 0}

	await _vm.ensure_browse()
	assert_eq(_vm.discover_users().size(), 1)
	await _vm.search_users("zzz")
	assert_eq(_vm.discover_mode(), "search")
	assert_true(_vm.discover_users().is_empty())
	_vm.clear_user_search()

	assert_eq(_vm.discover_mode(), "browse")
	assert_eq(_vm.discover_users().size(), 1)
	assert_eq(_users.last_users_page, 0)


func test_browse_paginates_within_bounds() -> void:
	_users.users_result = {"users": [], "page": 0, "total_pages": 2, "total_elements": 7}

	await _vm.load_browse_page(0)
	assert_eq(_vm.discover_page(), 0)
	await _vm.next_discover_page()
	assert_eq(_vm.discover_page(), 1)
	assert_eq(_users.last_users_page, 1)
	await _vm.next_discover_page()
	assert_eq(_vm.discover_page(), 1)
	await _vm.prev_discover_page()
	assert_eq(_vm.discover_page(), 0)
