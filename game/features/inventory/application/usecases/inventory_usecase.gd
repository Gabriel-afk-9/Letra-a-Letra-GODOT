extends RefCounted
class_name InventoryUseCase

var _inventory_repository: InventoryRepository


func _init(inventory_repository: InventoryRepository) -> void:
	_inventory_repository = inventory_repository


func fetch_my_inventory() -> Dictionary:
	return await _inventory_repository.fetch_my_inventory()
