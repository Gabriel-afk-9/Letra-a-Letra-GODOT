extends RefCounted
class_name GamePower


var id: String
var type: String
var rarity: String = ""


func _init(
	p_id: String,
	p_type: String,
	p_rarity: String = ""
) -> void:
	id = p_id
	type = p_type
	rarity = p_rarity


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": type,
		"rarity": rarity
	}


static func from_dictionary(data: Dictionary) -> GamePower:
	return GamePowerMapper.to_domain(data)
