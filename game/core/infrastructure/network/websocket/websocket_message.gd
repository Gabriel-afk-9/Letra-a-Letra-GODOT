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
		body.get("event", ""),
		body.get("message", ""),
		body.get("data", {}),
		body.get("events", []),
		body
	)
