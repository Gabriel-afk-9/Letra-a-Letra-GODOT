extends RefCounted
class_name GameCell


var x: int
var y: int
var letter: String
var revealed: bool
var revealed_by_player_id: String
var effect_type: String
var effect_owner_id: String
var remaining_clicks: int


func _init(
	p_x: int = 0,
	p_y: int = 0,
	p_letter: String = "",
	p_revealed: bool = false,
	p_revealed_by_player_id: String = "",
	p_effect_type: String = "",
	p_effect_owner_id: String = "",
	p_remaining_clicks: int = 0
) -> void:
	x = p_x
	y = p_y
	letter = p_letter
	revealed = p_revealed
	revealed_by_player_id = p_revealed_by_player_id
	effect_type = p_effect_type
	effect_owner_id = p_effect_owner_id
	remaining_clicks = p_remaining_clicks


func to_dictionary() -> Dictionary:
	var effect_dict := {}

	if not effect_type.is_empty():
		effect_dict = {
			"effect": effect_type,
			"ownerId": effect_owner_id,
			"remainingClicks": remaining_clicks
		}

	return {
		"x": x,
		"y": y,
		"letter": letter,
		"revealed": revealed,
		"revealedBy": revealed_by_player_id,
		"effect": effect_dict
	}


static func from_dictionary(
	data: Dictionary,
	p_x: int = 0,
	p_y: int = 0
) -> GameCell:
	return GameCellMapper.to_domain(data, p_x, p_y)
