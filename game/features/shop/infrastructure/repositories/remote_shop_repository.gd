extends ShopRepository
class_name RemoteShopRepository

var _http_client: HttpClient


func _init(http_client: HttpClient) -> void:
	_http_client = http_client


func fetch_offers() -> Dictionary:
	var response: HttpResponse = await _http_client.http_get("/shop/offers")
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var offers := ShopMapper.offers_from_body(response.body)
	return {"offers": offers, "status_code": response.status_code}


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."
