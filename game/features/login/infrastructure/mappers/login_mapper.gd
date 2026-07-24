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

	var user: User = User.from_dictionary(data)

	var token: String = data.get(
		"token",
		""
	) as String

	var success_message: String = body.get(
		"message",
		""
	) as String

	return LoginResult.new(
		true,
		user,
		token,
		success_message
	)
