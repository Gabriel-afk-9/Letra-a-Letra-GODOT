extends RefCounted
class_name GamePower


var id: String
var type: String


func _init(
	p_id: String,
	p_type: String
) -> void:
	id = p_id
	type = p_type


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": type
	}


static func from_dictionary(data: Dictionary) -> GamePower:
	var raw_id = data.get("id")
	var raw_type = data.get("name")

	var parsed_id := ""
	if raw_id != null:
		parsed_id = str(raw_id)

	var parsed_type := ""
	if raw_type != null:
		parsed_type = str(raw_type)

	return GamePower.new(parsed_id, parsed_type)
