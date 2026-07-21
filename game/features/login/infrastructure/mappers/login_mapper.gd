extends RefCounted
class_name LoginMapper


static func from_response_body(body: Dictionary) -> LoginResult:

	if not body.get("success", false):

		return LoginResult.new(
			false,
			null,
			"",
			body.get("message", "Erro ao autenticar.")
		)

	var data: Dictionary = body.get("data", {})

	var user: User = User.from_dictionary(data)

	return LoginResult.new(
		true,
		user,
		data.get("token", ""),
		body.get("message", "")
	)
