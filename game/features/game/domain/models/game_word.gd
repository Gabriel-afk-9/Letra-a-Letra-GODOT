extends RefCounted
class_name GameWord


var word: String
var found: bool
var found_by_player_id: String


func _init(
	p_word: String,
	p_found: bool = false,
	p_found_by_player_id: String = ""
) -> void:
	word = p_word
	found = p_found
	found_by_player_id = p_found_by_player_id


func to_dictionary() -> Dictionary:
	return {
		"word": word,
		"found": found,
		"foundById": found_by_player_id
	}


static func from_dictionary(data: Dictionary) -> GameWord:
	return GameWordMapper.to_domain(data)
