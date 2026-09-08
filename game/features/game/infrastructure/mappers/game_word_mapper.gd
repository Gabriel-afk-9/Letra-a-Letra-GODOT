extends RefCounted

class_name GameWordMapper


static func to_domain(data: Dictionary) -> GameWord:
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
