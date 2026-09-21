extends HttpClient
class_name FakeHttpClient

# Spy leve para HttpClient — registra última chamada e retorna resposta scriptada.
# Uso: var http := FakeHttpClient.new(FakeAuthProvider.new()); http.scripted_response = HttpResponse.new(200,true,{"data":...},"")

var scripted_response: HttpResponse = HttpResponse.new(200, true, {}, "")
var last_endpoint: String = ""
var last_body: Dictionary = {}
var last_method: String = ""
var request_count: int = 0

func _init(auth_provider: AuthProvider = null) -> void:
	if auth_provider == null:
		auth_provider = FakeAuthProvider.new()
	super._init(auth_provider)

func http_get(endpoint: String, _access_token: String = "") -> HttpResponse:
	last_endpoint = endpoint
	last_method = "GET"
	request_count += 1
	return scripted_response

func http_post(endpoint: String, body: Dictionary, _access_token: String = "") -> HttpResponse:
	last_endpoint = endpoint
	last_body = body
	last_method = "POST"
	request_count += 1
	return scripted_response

func http_put(endpoint: String, body: Dictionary, _access_token: String = "") -> HttpResponse:
	last_endpoint = endpoint
	last_body = body
	last_method = "PUT"
	request_count += 1
	return scripted_response

func http_delete(endpoint: String, _access_token: String = "") -> HttpResponse:
	last_endpoint = endpoint
	last_method = "DELETE"
	request_count += 1
	return scripted_response

func http_patch(endpoint: String, body: Dictionary, _access_token: String = "") -> HttpResponse:
	last_endpoint = endpoint
	last_body = body
	last_method = "PATCH"
	request_count += 1
	return scripted_response

func reset() -> void:
	last_endpoint = ""
	last_body = {}
	last_method = ""
	request_count = 0
	scripted_response = HttpResponse.new(200, true, {}, "")
