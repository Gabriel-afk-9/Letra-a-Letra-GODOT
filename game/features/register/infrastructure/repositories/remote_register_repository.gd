extends RegisterRepository
class_name RemoteRegisterRepository

var _http_client: HttpClient

func _init(http_client: HttpClient) -> void:
	_http_client = http_client

func register(request: RegisterRequest) -> RegisterResult:
	var response: HttpResponse = await _http_client.http_post(
		"/user",
		request.to_dictionary()
	)
	if not response.success:
		return RegisterResult.new(false, null, "", response.error_message)
	return RegisterMapper.from_response_body(response.body)
