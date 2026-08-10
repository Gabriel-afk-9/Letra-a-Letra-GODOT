extends Node
class_name HttpClient


var _auth_provider: AuthProvider

func _init(auth_provider: AuthProvider) -> void:
	_auth_provider = auth_provider


func http_get(
	endpoint: String,
	access_token: String = ""
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_GET,
		endpoint,
		{},
		access_token
	)


func http_post(
	endpoint: String,
	body: Dictionary,
	access_token: String = ""
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_POST,
		endpoint,
		body,
		access_token
	)


func http_put(
	endpoint: String,
	body: Dictionary,
	access_token: String = ""
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_PUT,
		endpoint,
		body,
		access_token
	)


func http_delete(
	endpoint: String,
	access_token: String = ""
) -> HttpResponse:
	return await _request(
		HTTPClient.METHOD_DELETE,
		endpoint,
		{},
		access_token
	)


func _request(
	method: HTTPClient.Method,
	endpoint: String,
	body: Dictionary = {},
	access_token: String = ""
) -> HttpResponse:

	var request := HTTPRequest.new()
	add_child(request)

	var url := _build_url(endpoint)
	var payload := _build_payload(body)

	AppLogger.debug("[HTTP] -> %s" % url)

	var error: Error = request.request(
		url,
		_build_headers(access_token),
		method,
		payload
	)

	if error != OK:
		AppLogger.error("[HTTP] Failed to start request (%s): %s" % [url, error])
		request.queue_free()
		return HttpResponse.new(0, false, {}, "Failed to execute request.")

	var result: Array = await request.request_completed

	request.queue_free()

	return _parse_response(result)


func _build_headers(
	access_token: String = ""
) -> PackedStringArray:

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var token := access_token

	if token.is_empty():
		token = _auth_provider.get_token()

	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)

	return headers


func _build_payload(body: Dictionary) -> String:

	if body.is_empty():
		return ""

	return JSON.stringify(body)


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

	AppLogger.debug(
		"[HTTP] <- status=%d result=%d" % [response_code, request_result]
	)

	var parsed_body := _parse_json(response_text)
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


func _parse_json(text: String) -> Dictionary:

	if text.is_empty():
		return {}

	var json := JSON.new()

	if json.parse(text) != OK:
		return {}

	if json.data is Dictionary:
		return json.data

	return {}
