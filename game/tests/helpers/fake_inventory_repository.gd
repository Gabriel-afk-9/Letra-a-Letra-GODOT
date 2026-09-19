extends InventoryRepository
class_name FakeInventoryRepository

var inventory_result: Dictionary = {"items": [], "status_code": 200}
var equip_result: Dictionary = {"status_code": 200}
var last_equip_id: String = ""
var last_equip_context: String = ""


func fetch_my_inventory() -> Dictionary:
	return inventory_result


func equip_item(item_id: String, item_context: String) -> Dictionary:
	last_equip_id = item_id
	last_equip_context = item_context
	return equip_result
