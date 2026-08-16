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
	var raw_word = data.get("word")
	var raw_found = data.get("found")
	var raw_found_by_player_id = data.get("foundById")

	var parsed_word := ""
	if raw_word != null:
		parsed_word = str(raw_word)

	var parsed_found := false
	if raw_found is bool:
		parsed_found = raw_found

	var parsed_found_by_player_id := ""
	if raw_found_by_player_id != null:
		parsed_found_by_player_id = str(raw_found_by_player_id)

	return GameWord.new(parsed_word, parsed_found, parsed_found_by_player_id)
