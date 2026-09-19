extends RefCounted
class_name InventoryUseCase

var _inventory_repository: InventoryRepository


func _init(inventory_repository: InventoryRepository) -> void:
	_inventory_repository = inventory_repository


func fetch_my_inventory() -> Dictionary:
	return await _inventory_repository.fetch_my_inventory()


func equip_item(item: InventoryItem) -> Dictionary:
	if item == null or item.item_id.strip_edges().is_empty():
		return {"error": "Item inválido."}
	var item_context := item.context.strip_edges().to_upper()
	if item_context != "MATCH" and item_context != "PROFILE":
		item_context = "PROFILE"
	return await _inventory_repository.equip_item(item.item_id, item_context)
