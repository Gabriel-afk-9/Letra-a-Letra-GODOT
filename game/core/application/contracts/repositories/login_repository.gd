extends RefCounted
class_name LoginRepository


func login(_request: LoginRequest) -> LoginResult:
	push_error("Method login() must be implemented.")
	return LoginResult.new(false, null, "", "Not implemented.")


func refresh(_refresh_token: String) -> LoginResult:
	push_error("Method refresh() must be implemented.")
	return LoginResult.new(false, null, "", "Not implemented.")


func logout() -> bool:
	push_error("Method logout() must be implemented.")
	return false
