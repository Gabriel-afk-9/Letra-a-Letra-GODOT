extends Node
class_name HttpClient

const DEBUG_HTTP := true
var _auth_provider: AuthProvider


func _init(auth_provider: AuthProvider) -> void:
	_auth_provider = auth_provider


func http_get(endpoint: String) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_GET,
		endpoint
	)


func http_post(
	endpoint: String,
	body: Dictionary
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_POST,
		endpoint,
		body
	)


func http_put(
	endpoint: String,
	body: Dictionary
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_PUT,
		endpoint,
		body
	)


func http_delete(endpoint: String) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_DELETE,
		endpoint
	)


func _request(
	method: HTTPClient.Method,
	endpoint: String,
	body: Dictionary = {}
) -> HttpResponse:

	var request := HTTPRequest.new()
	add_child(request)

	var payload := ""

	if not body.is_empty():
		payload = JSON.stringify(body)
	print("[HTTP] Iniciando request para: ", _build_url(endpoint)) 

	var error: Error = request.request(
		_build_url(endpoint),
		_build_headers(),
		method,
		payload
	)

	if error != OK:
		print("[HTTP] ERRO ao iniciar request: ", error)
		request.queue_free()

		return HttpResponse.new(0, false, {}, "Failed to execute request.")
	print("[HTTP] Aguardando resposta...") 

	var result: Array = await request.request_completed
	print("[HTTP] Resposta recebida!")

	request.queue_free()

	return _parse_response(result)


func _build_headers() -> PackedStringArray:
	var headers = PackedStringArray(["Content-Type: application/json"])
	var token = _auth_provider.get_token()
	
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	
	return headers


func _build_url(endpoint: String) -> String:
	return "%s%s" % [
		GlobalEnvironment.API_BASE_URL,
		endpoint
	]


func _parse_response(result: Array) -> HttpResponse:

	var request_result: int = result[0]
	var response_code: int = result[1]
	var raw_body: PackedByteArray = result[3]
	var response_text: String = raw_body.get_string_from_utf8()
	print("[HTTP] request_result: ", request_result, " | response_code: ", response_code)

	var parsed_body: Dictionary = {}

	if not response_text.is_empty():

		var json := JSON.new()

		if json.parse(response_text) == OK:

			if json.data is Dictionary:

				parsed_body = json.data

	var success: bool = response_code >= 200 and response_code < 300

	var error_message: String = ""

	if parsed_body.has("message"):
		error_message = parsed_body["message"] as String
	
	return HttpResponse.new(
		response_code,
		success,
		parsed_body,
		error_message
	)
	
