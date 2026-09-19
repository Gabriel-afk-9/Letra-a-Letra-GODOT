extends GutTest


func test_matchmaking_player_mapper_extracts_avatar() -> void:
	var player := MatchmakingPlayerMapper.to_domain({
		"id": "p1",
		"nickname": "Eu",
		"cosmeticsEquipped": [
			{"itemId": "1", "name": "Ceo", "category": "AVATAR", "equipped": true, "assetPath": "AVATAR/ceo.webp"},
		],
	})
	assert_eq(player.id, "p1")
	assert_eq(player.nickname, "Eu")
	assert_eq(player.avatar_asset_path, "AVATAR/ceo.webp")


func test_matchmaking_player_mapper_without_avatar_returns_empty() -> void:
	var player := MatchmakingPlayerMapper.to_domain({"id": "p2", "nickname": "Adv"})
	assert_eq(player.avatar_asset_path, "")


func test_matchmaking_player_mapper_ignores_order_and_category() -> void:
	var player := MatchmakingPlayerMapper.to_domain({
		"id": "p3",
		"nickname": "X",
		"cosmeticsEquipped": [
			{"name": "B", "category": "BANNER", "equipped": true, "assetPath": "BANNER/green.webp"},
			{"name": "E", "category": "EMOTE", "equipped": true, "assetPath": "EMOTE/x.webp"},
		],
	})
	assert_eq(player.avatar_asset_path, "")


func test_game_player_state_mapper_extracts_avatar() -> void:
	var state := GamePlayerStateMapper.to_domain({
		"id": "me",
		"inventory": [],
		"effects": [],
		"cosmeticsEquipped": [
			{"itemId": "9", "name": "Ceo", "category": "AVATAR", "equipped": true, "assetPath": "AVATAR/ceo.webp"},
		],
	})
	assert_eq(state.player_id, "me")
	assert_eq(state.avatar_asset_path, "AVATAR/ceo.webp")
	assert_eq(state.inventory.size(), GamePlayerState.INVENTORY_SIZE)


func test_game_player_state_mapper_without_cosmetics() -> void:
	var state := GamePlayerStateMapper.to_domain({"id": "opp", "inventory": []})
	assert_eq(state.avatar_asset_path, "")
