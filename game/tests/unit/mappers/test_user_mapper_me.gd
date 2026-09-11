extends GutTest


func test_me_parses_identity_stats_and_wallet() -> void:
	var body := {
		"success": true,
		"data": {
			"user": {
				"userId": "u-1",
				"email": "jogador@lal.gg",
				"nickname": "Zidan",
				"stats": {
					"totalMatches": 100,
					"totalWins": 15,
					"winStreak": 2,
					"level": 10,
					"experience": 67,
					"rankingPoints": 30,
				},
				"wallet": {"coins": 100, "gems": 1},
			}
		}
	}

	var user := UserMapper.from_response_body(body)

	assert_eq(user.id, "u-1")
	assert_eq(user.nickname, "Zidan")
	assert_eq(user.level, 10)
	assert_eq(user.experience, 67)
	assert_eq(user.coins, 100)
	assert_eq(user.gems, 1)
	assert_eq(user.total_wins, 15)
	assert_eq(user.win_streak, 2)
	assert_eq(user.total_matches, 100)

	var profile := HomePlayerProfile.from_user(user)
	assert_eq(profile.nickname, "Zidan")
	assert_eq(profile.level, 10)
	assert_eq(profile.xp, 67)
	assert_eq(profile.xp_compact(), "67 XP")
	assert_eq(profile.coins, 100)
	assert_eq(profile.gems, 1)
	assert_eq(profile.wins, 15)
	assert_eq(profile.streak, 2)
	assert_eq(profile.matches, 100)


func test_me_missing_stats_and_wallet_default_to_zero() -> void:
	var body := {
		"data": {"user": {"userId": "u-2", "nickname": "Novo"}}
	}

	var user := UserMapper.from_response_body(body)

	assert_not_null(user)
	assert_eq(user.level, 0)
	assert_eq(user.experience, 0)
	assert_eq(user.coins, 0)
	assert_eq(user.gems, 0)
	assert_eq(user.total_wins, 0)
	assert_eq(user.win_streak, 0)
	assert_eq(user.total_matches, 0)


func test_me_empty_user_returns_null() -> void:
	assert_null(UserMapper.from_response_body({"data": {"user": {}}}))
	assert_null(UserMapper.from_response_body({"data": {}}))
	assert_null(UserMapper.from_response_body({}))


func test_user_roundtrip_keeps_profile_fields() -> void:
	var user := User.new("u-3", "a@b.c", "Nick", 5, 40, 10, 2, 7, 3, 20)
	var restored := User.from_dictionary(user.to_dictionary())

	assert_eq(restored.level, 5)
	assert_eq(restored.experience, 40)
	assert_eq(restored.coins, 10)
	assert_eq(restored.gems, 2)
	assert_eq(restored.total_wins, 7)
	assert_eq(restored.win_streak, 3)
	assert_eq(restored.total_matches, 20)
