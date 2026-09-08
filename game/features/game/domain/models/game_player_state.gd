extends RefCounted
class_name GamePlayerState


const INVENTORY_SIZE := 5


var player_id: String
var inventory: Array[GamePower]
var effects: Array = []


func _init(
	p_player_id: String,
	p_inventory: Array[GamePower] = [],
	p_effects: Array = []
) -> void:
	player_id = p_player_id
	inventory = p_inventory
	effects = p_effects


func to_dictionary() -> Dictionary:
	var parsed_inventory: Array = []

	for slot in inventory:
		if slot is GamePower:
			parsed_inventory.append(slot.to_dictionary())
		else:
			parsed_inventory.append(null)

	return {
		"id": player_id,
		"inventory": parsed_inventory,
		"effects": effects.duplicate()
	}


static func from_dictionary(data: Dictionary) -> GamePlayerState:
	return GamePlayerStateMapper.to_domain(data)
