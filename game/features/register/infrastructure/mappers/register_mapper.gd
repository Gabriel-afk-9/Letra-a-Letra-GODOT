extends RefCounted
class_name RegisterMapper


static func from_response_body(
	body: Dictionary
) -> RegisterResult:

	var success: bool = body.get("success", false) as bool

	if not success:

		var error_message: String = body.get(
			"message",
			"Erro ao cadastrar."
		) as String

		return RegisterResult.new(
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

	var token: String = str(data.get("token", ""))

	var success_message: String = body.get(
		"message",
		""
	) as String

	return RegisterResult.new(
		true,
		user,
		token,
		success_message
	)
