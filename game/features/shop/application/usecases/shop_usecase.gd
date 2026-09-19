extends RefCounted
class_name ShopUseCase

var _shop_repository: ShopRepository


func _init(shop_repository: ShopRepository) -> void:
	_shop_repository = shop_repository


func fetch_offers() -> Dictionary:
	return await _shop_repository.fetch_offers()
