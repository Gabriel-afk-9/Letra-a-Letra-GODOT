extends InventoryRepository
class_name RemoteInventoryRepository

var _http_client: HttpClient


func _init(http_client: HttpClient) -> void:
	_http_client = http_client


func fetch_my_inventory() -> Dictionary:
	var response: HttpResponse = await _http_client.http_get("/user/items")
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var items := InventoryMapper.items_from_body(response.body)
	return {"items": items, "status_code": response.status_code}


func equip_item(item_id: String, item_context: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_post(
		"/user/items/%s/equip" % item_id,
		{"context": item_context}
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	return {"status_code": response.status_code}


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."
