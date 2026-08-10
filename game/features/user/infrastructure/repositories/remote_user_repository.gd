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
