extends UserRepository
class_name RemoteUserRepository

var _http_client: HttpClient

func _init(http_client: HttpClient) -> void:
	_http_client = http_client

func fetch_current_user(access_token: String) -> User:
	var response := await _http_client.http_get(
		"/user/me",
		access_token
	)
	if not response.success:
		return null
	return UserMapper.from_response_body(response.body)


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
