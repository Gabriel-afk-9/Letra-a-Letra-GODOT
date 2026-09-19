extends FriendRepository
class_name RemoteFriendRepository

const FRIENDS_PAGE_SORT := "requestDate,desc"

var _http_client: HttpClient


func _init(http_client: HttpClient) -> void:
	_http_client = http_client


func fetch_friends(page: int, size: int) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/friend?page=%d&size=%d&sort=%s" % [page, size, FRIENDS_PAGE_SORT]
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := FriendMapper.page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func fetch_pending() -> Dictionary:
	var response: HttpResponse = await _http_client.http_get("/friend/pending")
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	return {"requests": FriendMapper.pending_from_body(response.body), "status_code": response.status_code}


func fetch_sent() -> Dictionary:
	var response: HttpResponse = await _http_client.http_get("/friend/pending/sent")
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	return {"requests": FriendMapper.pending_from_body(response.body), "status_code": response.status_code}


func send_request(friend_id: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_post(
		"/friend/request",
		{"friendId": friend_id}
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	return {"ok": true}


func accept_request(friend_id: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_patch(
		"/friend/accept",
		{"friendId": friend_id}
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	return {"ok": true}


func reject_request(friend_id: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_patch(
		"/friend/reject",
		{"friendId": friend_id}
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	return {"ok": true}


func cancel_request(friend_id: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_patch(
		"/friend/cancel",
		{"friendId": friend_id}
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	return {"ok": true}


func remove_friend(friend_id: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_patch(
		"/friend/remove",
		{"friendId": friend_id}
	)
	if not response.success:
		return {"error": _message_or_default(response)}
	return {"ok": true}


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."
