extends RefCounted

class_name LoginMapper


static func from_response_body(
	body: Dictionary
) -> LoginResult:
	var success: bool = body.get("success", false) as bool

	if not success:

		var error_message: String = body.get(
			"message",
			"Erro ao autenticar."
		) as String

		return LoginResult.new(
			false,
			null,
			"",
			error_message
		)

	var data: Dictionary = body.get(
		"data",
		{}
	) as Dictionary

	var user: User = null
	if data.has("email") or data.has("nickname") or data.has("user"):
		var user_variant = data.get("user", data)
		if user_variant is Dictionary and not (user_variant as Dictionary).is_empty():
			user = User.from_dictionary(user_variant)

	var token: String = str(data.get("token", ""))

	var refresh_token: String = str(data.get("refreshToken", data.get("refresh_token", "")))

	var success_message: String = body.get(
		"message",
		""
	) as String

	return LoginResult.new(
		true,
		user,
		token,
		success_message,
		refresh_token
	)
