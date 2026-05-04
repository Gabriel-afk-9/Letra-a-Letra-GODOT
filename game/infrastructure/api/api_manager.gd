extends Node

func post_async(endpoint: String, body: Dictionary) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = GlobalEnvironment.API_BASE_URL + endpoint
	var json = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	
	var result = await http_request.request_completed
	http_request.queue_free()
	
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()
	
	var data = {}
	var json_parser = JSON.new()
	if json_parser.parse(response_body) == OK:
		data = json_parser.data
		
	return { "code": response_code, "body": data }

# FEAT
func get_async(endpoint: String) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = GlobalEnvironment.API_BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	var result = await http_request.request_completed
	http_request.queue_free()
	
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()
	
	var data = {}
	if response_body != "":
		var json_parser = JSON.new()
		if json_parser.parse(response_body) == OK:
			data = json_parser.data
			
	return { "code": response_code, "body": data }
