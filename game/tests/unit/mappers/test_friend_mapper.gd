extends GutTest


func test_from_dictionary_parses_friend_response() -> void:
	var friendship := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"status": "PENDING",
		"requestDate": "2026-09-01T12:00:00Z",
	})

	assert_not_null(friendship)
	assert_eq(friendship.user_id_1, "aaa")
	assert_eq(friendship.user_id_2, "bbb")
	assert_eq(friendship.status, "PENDING")
	assert_eq(friendship.sender_id(), "aaa")
	assert_eq(friendship.other_id("aaa"), "bbb")
	assert_eq(friendship.other_id("bbb"), "aaa")
	assert_eq(friendship.date_short(), "2026-09-01")


func test_from_dictionary_empty_returns_null() -> void:
	assert_null(FriendMapper.from_dictionary({}))


func test_from_dictionary_parses_friend_id_and_direction() -> void:
	var friendship := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"friendId": "bbb",
		"direction": "RECEIVED",
		"status": "PENDING",
		"requestDate": "2026-09-01T12:00:00Z",
	})

	assert_not_null(friendship)
	assert_eq(friendship.friend_id, "bbb")
	assert_eq(friendship.direction, "RECEIVED")
	assert_true(friendship.is_sent() == false)
	assert_eq(friendship.other_id("aaa"), "bbb")

	var sent := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"friendId": "bbb",
		"direction": "SENT",
		"status": "PENDING",
		"requestDate": "",
	})
	assert_true(sent.is_sent())


func test_from_dictionary_without_new_fields_falls_back() -> void:
	var friendship := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"status": "ACCEPT",
	})

	assert_eq(friendship.friend_id, "")
	assert_eq(friendship.other_id("aaa"), "bbb")
	assert_eq(friendship.other_id("bbb"), "aaa")


func test_page_from_body_parses_content_and_pagination() -> void:
	var body := {
		"success": true,
		"data": {
			"content": [
				{"userId1": "a", "userId2": "b", "status": "ACCEPT", "requestDate": "2026-01-02T00:00:00Z"},
				{"userId1": "c", "userId2": "d", "status": "ACCEPT", "requestDate": "2026-01-03T00:00:00Z"},
			],
			"page": 0,
			"size": 6,
			"totalElements": 2,
			"totalPages": 1,
			"first": true,
			"last": true,
		}
	}

	var result := FriendMapper.page_from_body(body)

	assert_eq((result["friends"] as Array).size(), 2)
	assert_eq(result["page"], 0)
	assert_eq(result["total_pages"], 1)
	assert_eq(result["total_elements"], 2)
	var first := (result["friends"] as Array)[0] as Friendship
	assert_eq(first.status, "ACCEPT")


func test_page_from_body_without_data_returns_empty() -> void:
	assert_true(FriendMapper.page_from_body({}).is_empty())
	assert_true(FriendMapper.page_from_body({"data": {}}).is_empty())


func test_pending_from_body_parses_requests() -> void:
	var body := {
		"success": true,
		"data": {
			"requests": [
				{"userId1": "x", "userId2": "y", "status": "PENDING", "requestDate": "2026-05-01T00:00:00Z"},
			]
		}
	}

	var requests := FriendMapper.pending_from_body(body)

	assert_eq(requests.size(), 1)
	assert_eq((requests[0] as Friendship).sender_id(), "x")


func test_pending_from_body_without_data_returns_empty() -> void:
	assert_true(FriendMapper.pending_from_body({}).is_empty())


func test_short_id_truncates_long_ids() -> void:
	assert_eq(Friendship.short_id("abcdef123456"), "abcdef12")
	assert_eq(Friendship.short_id("curto"), "curto")


func test_from_dictionary_parses_profile_with_nickname_and_equipped() -> void:
	var friendship := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"friendId": "bbb",
		"direction": "RECEIVED",
		"status": "PENDING",
		"requestDate": "2026-09-01T12:00:00Z",
		"profile": {
			"userId": "bbb",
			"nickname": "Samuel",
			"equipped": [
				{"name": "X", "type": "AVATAR", "equipped": true, "assetPath": "AVATAR/logo.png"},
				{"name": "Y", "type": "BANNER", "equipped": true, "assetPath": "BANNER/y.png"},
			],
		},
	})

	assert_not_null(friendship)
	assert_eq(friendship.nickname, "Samuel")
	assert_eq(friendship.equipped.size(), 2)
	assert_eq(friendship.display_name("Jogador", "bbb"), "Samuel")
	assert_not_null(friendship.equipped_art("AVATAR"))
	assert_null(friendship.equipped_art("BANNER"))


func test_from_dictionary_without_profile_uses_fallback_name() -> void:
	var friendship := FriendMapper.from_dictionary({
		"userId1": "aaa",
		"userId2": "bbb",
		"status": "ACCEPT",
	})

	assert_eq(friendship.nickname, "")
	assert_eq(friendship.equipped, [])
	assert_eq(friendship.display_name("Amigo", "bbb"), "Amigo bbb")
	assert_null(friendship.equipped_art("AVATAR"))
