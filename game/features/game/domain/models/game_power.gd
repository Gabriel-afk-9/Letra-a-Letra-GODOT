extends RefCounted
class_name GamePower


var id: String
var type: String
# Raridade é opcional: o payload atual do backend (InventoryResponse) só manda
# {"id", "name"} — se um dia vier "rarity", ela é preservada; caso contrário,
# cai no fallback da GamePowerCatalog (metadado fixo por tipo, PowerType.java).
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
