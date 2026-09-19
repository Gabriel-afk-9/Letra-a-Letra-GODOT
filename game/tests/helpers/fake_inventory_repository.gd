extends InventoryRepository
class_name FakeInventoryRepository

var inventory_result: Dictionary = {"items": [], "status_code": 200}


func fetch_my_inventory() -> Dictionary:
	return inventory_result
