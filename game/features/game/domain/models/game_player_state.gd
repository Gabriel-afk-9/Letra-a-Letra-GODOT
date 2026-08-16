extends RefCounted
class_name GamePlayerState


const INVENTORY_SIZE := 5


var player_id: String
var inventory: Array[GamePower]


func _init(
	p_player_id: String,
	p_inventory: Array[GamePower] = []
) -> void:
	player_id = p_player_id
	inventory = p_inventory


func to_dictionary() -> Dictionary:
	var parsed_inventory: Array = []

	for slot in inventory:
		if slot is GamePower:
			parsed_inventory.append(slot.to_dictionary())
		else:
			parsed_inventory.append(null)

	return {
		"id": player_id,
		"inventory": parsed_inventory
	}


static func from_dictionary(data: Dictionary) -> GamePlayerState:
	var raw_id = data.get("id")

	var parsed_id := ""
	if raw_id != null:
		parsed_id = str(raw_id)

	var parsed_inventory: Array[GamePower] = []

	var raw_inventory = data.get("inventory")

	if raw_inventory is Array:
		var inventory: Array = raw_inventory

		for index in INVENTORY_SIZE:
			if index >= inventory.size():
				parsed_inventory.append(null)
				continue

			var raw_power = inventory[index]

			if raw_power is Dictionary:
				parsed_inventory.append(GamePower.from_dictionary(raw_power))
			else:
				parsed_inventory.append(null)
	else:
		for index in INVENTORY_SIZE:
			parsed_inventory.append(null)

	return GamePlayerState.new(parsed_id, parsed_inventory)
