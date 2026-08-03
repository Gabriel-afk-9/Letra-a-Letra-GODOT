extends RefCounted
class_name JsonSerializer

static func encode(payload: Dictionary) -> String:
	return JSON.stringify(payload)

static func decode(text: String) -> Dictionary:
	if text.is_empty():
		return {}
		
	var json := JSON.new()
	var error := json.parse(text)
	
	if error == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
		
	return {}
