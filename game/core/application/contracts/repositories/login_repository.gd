extends RefCounted
class_name LoginRepository


func login(_request: LoginRequest) -> LoginResult:
	push_error("Method login() must be implemented.")
	return LoginResult.new(false, null, "", "Not implemented.")
