extends LoginRepository
class_name RemoteLoginRepository

var _http_client: HttpClient

func _init(http_client: HttpClient) -> void:
	_http_client = http_client

func login(request: LoginRequest) -> LoginResult:
	var response: HttpResponse = await _http_client.http_post(
		"/user/auth",
		request.to_dictionary()
	)
	if not response.success:
		return LoginResult.new(false, null, "", response.error_message)
	return LoginMapper.from_response_body(response.body)
