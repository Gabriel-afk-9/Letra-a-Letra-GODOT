extends RefCounted
class_name RegisterRepository


func register(_request: RegisterRequest) -> RegisterResult:
	push_error("Method register() must be implemented.")
	return RegisterResult.new(false, null, "", "Not implemented.")
