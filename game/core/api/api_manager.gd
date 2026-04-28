extends Node

signal request_completed(response_code, data)

func post(url, body: Dictionary):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_request_completed.bind(http_request))

	var json = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_request_completed(result, response_code, headers, body, http_request):
	http_request.queue_free()

	var data = {}
	var json_parser = JSON.new()
	
	if json_parser.parse(body.get_string_from_utf8()) == OK:
		data = json_parser.data

	emit_signal("request_completed", response_code, data)
