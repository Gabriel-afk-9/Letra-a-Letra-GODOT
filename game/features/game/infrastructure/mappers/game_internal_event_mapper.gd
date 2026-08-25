extends RefCounted

class_name GameInternalEventMapper


# Extrai event/data de um item bruto do array "events" do envelope WS
# (lógica antes inline em RemoteGameRepository._handle_internal_events).
static func to_domain(raw_event: Dictionary) -> GameInternalEvent:
	var raw_event_name = raw_event.get("event")
	var raw_event_data = raw_event.get("data")

	var parsed_event_name := ""
	if raw_event_name != null:
		parsed_event_name = str(raw_event_name)

	var parsed_event_data: Dictionary = {}
	if raw_event_data is Dictionary:
		parsed_event_data = raw_event_data

	return GameInternalEvent.from_dictionary(parsed_event_name, parsed_event_data)
