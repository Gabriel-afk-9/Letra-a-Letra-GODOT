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
	return GamePlayerStateMapper.to_domain(data)
