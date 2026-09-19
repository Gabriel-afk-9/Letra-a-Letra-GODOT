extends ShopRepository
class_name FakeShopRepository

var offers_result: Dictionary = {"offers": [], "status_code": 200}


func fetch_offers() -> Dictionary:
	return offers_result
