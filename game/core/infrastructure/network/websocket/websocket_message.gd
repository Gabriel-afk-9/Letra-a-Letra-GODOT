extends RefCounted
class_name WebSocketMessage


var event: String
var message: String
var data: Dictionary
var events: Array
var raw: Dictionary


func _init(
	p_event: String = "",
	p_message: String = "",
	p_data: Dictionary = {},
	p_events: Array = [],
	p_raw: Dictionary = {}
) -> void:
	event = p_event
	message = p_message
	data = p_data
	events = p_events
	raw = p_raw


static func from_dictionary(body: Dictionary) -> WebSocketMessage:
	return WebSocketMessage.new(
		str(body.get("event", "")),
		str(body.get("message", "")),
		_extract_dictionary(body, "data"),
		_extract_array(body, "events"),
		body
	)



# Public API — acesso tipado a campos de nível raiz

func get_string(key: String, default_value := "") -> String:
	return str(raw.get(key, default_value))


func get_dictionary(key: String) -> Dictionary:
	return _extract_dictionary(raw, key)


func get_array(key: String) -> Array:
	return _extract_array(raw, key)


func has(key: String) -> bool:
	return raw.has(key)



# Internal

static func _extract_dictionary(source: Dictionary, key: String) -> Dictionary:
	var value = source.get(key)
	if value is Dictionary:
		return value
	return {}


static func _extract_array(source: Dictionary, key: String) -> Array:
	var value = source.get(key)
	if value is Array:
		return value
	return []
