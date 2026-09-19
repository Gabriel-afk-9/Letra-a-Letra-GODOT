extends UserRepository
class_name RemoteUserRepository

var _http_client: HttpClient

func _init(http_client: HttpClient) -> void:
	_http_client = http_client

func fetch_current_user(access_token: String) -> User:
	var result := await fetch_current_user_result(access_token)
	return result.get("user") as User


func fetch_current_user_result(access_token: String) -> Dictionary:
	var response := await _http_client.http_get(
		"/user/me",
		access_token
	)
	if not response.success:
		return {"user": null, "status_code": response.status_code, "error": _message_or_default(response)}
	return {"user": UserMapper.from_response_body(response.body), "status_code": response.status_code}


func find_by_username(username: String) -> User:
	var response := await _http_client.http_get(
		"/user/username/" + username.uri_encode()
	)
	if not response.success:
		return null
	return UserMapper.from_response_body(response.body)


func fetch_users(page: int, size: int) -> Dictionary:
	var response := await _http_client.http_get(
		"/user?page=%d&size=%d&sort=username,asc" % [page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	var result := UserMapper.users_page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor."}
	return result


func search_users(username: String, page: int, size: int) -> Dictionary:
	var response := await _http_client.http_get(
		"/user/username/" + username.uri_encode() + "?page=%d&size=%d" % [page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	var result := UserMapper.users_page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor."}
	return result


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."
