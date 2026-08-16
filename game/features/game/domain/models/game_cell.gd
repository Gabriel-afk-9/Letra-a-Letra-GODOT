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
	var raw_letter = data.get("letter")
	var raw_revealed = data.get("revealed")
	var raw_revealed_by_player_id = data.get("revealedBy")

	var parsed_letter := ""
	if raw_letter != null:
		parsed_letter = str(raw_letter)

	var parsed_revealed := false
	if raw_revealed is bool:
		parsed_revealed = raw_revealed

	var parsed_revealed_by_player_id := ""
	if raw_revealed_by_player_id != null:
		parsed_revealed_by_player_id = str(raw_revealed_by_player_id)

	var parsed_effect_type := ""
	var parsed_effect_owner_id := ""
	var parsed_remaining_clicks := 0

	var raw_effect = data.get("effect")

	if raw_effect is Dictionary:
		var effect: Dictionary = raw_effect

		var raw_effect_type = effect.get("effect")
		if raw_effect_type != null:
			parsed_effect_type = str(raw_effect_type)

		var raw_effect_owner_id = effect.get("ownerId")
		if raw_effect_owner_id != null:
			parsed_effect_owner_id = str(raw_effect_owner_id)

		var raw_remaining_clicks = effect.get("remainingClicks")
		if raw_remaining_clicks is int or raw_remaining_clicks is float:
			parsed_remaining_clicks = int(raw_remaining_clicks)

	return GameCell.new(
		p_x,
		p_y,
		parsed_letter,
		parsed_revealed,
		parsed_revealed_by_player_id,
		parsed_effect_type,
		parsed_effect_owner_id,
		parsed_remaining_clicks
	)
