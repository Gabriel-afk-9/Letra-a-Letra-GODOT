extends RefCounted
class_name GamePlayerState


const INVENTORY_SIZE := 5


var player_id: String
var inventory: Array[GamePower]
var effects: Array = []
var avatar_asset_path: String = ""


func _init(
	p_player_id: String,
	p_inventory: Array[GamePower] = [],
	p_effects: Array = [],
	p_avatar_asset_path: String = ""
) -> void:
	player_id = p_player_id
	inventory = p_inventory
	effects = p_effects
	avatar_asset_path = p_avatar_asset_path


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
		"effects": effects.duplicate(),
		"avatar_asset_path": avatar_asset_path
	}


static func from_dictionary(data: Dictionary) -> GamePlayerState:
	return GamePlayerStateMapper.to_domain(data)
