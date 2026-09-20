extends RoomRepository
class_name RemoteRoomRepository

var _http_client: HttpClient


func _init(http_client: HttpClient) -> void:
	_http_client = http_client


func fetch_public_rooms(page: int, size: int) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/public?page=%d&size=%d" % [page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func search_rooms_by_name(room_name: String, page: int, size: int) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/active/room-name/%s?page=%d&size=%d" % [room_name.uri_encode(), page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func find_game_by_code(code: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/code/%s" % code.uri_encode()
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.code_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."
