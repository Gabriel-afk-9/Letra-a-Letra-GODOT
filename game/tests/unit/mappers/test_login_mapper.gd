extends GutTest


func test_auth_response_parses_tokens_without_user() -> void:
	var body := {
		"success": true,
		"message": "Autenticado.",
		"data": {"id": "u-1", "token": "access-123", "refreshToken": "refresh-123"},
	}

	var result := LoginMapper.from_response_body(body)

	assert_true(result.success)
	assert_eq(result.access_token, "access-123")
	assert_eq(result.refresh_token, "refresh-123")
	assert_null(result.user)


func test_auth_failure_returns_message() -> void:
	var result := LoginMapper.from_response_body({"success": false, "message": "Credenciais inválidas."})

	assert_false(result.success)
	assert_eq(result.message, "Credenciais inválidas.")


func test_legacy_shape_with_user_fields_still_parses() -> void:
	var body := {
		"success": true,
		"data": {"id": "u-9", "email": "a@b.c", "nickname": "Nick", "token": "t", "refreshToken": "r"},
	}

	var result := LoginMapper.from_response_body(body)

	assert_true(result.success)
	assert_not_null(result.user)
	assert_eq(result.user.nickname, "Nick")
	assert_eq(result.access_token, "t")
	assert_eq(result.refresh_token, "r")
