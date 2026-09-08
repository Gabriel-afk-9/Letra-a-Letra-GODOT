extends RefCounted
class_name PendingNavigationPayload


var _payload: Variant = null


func set_payload(payload: Variant) -> void:
	_payload = payload

func take_payload() -> Variant:
	var payload: Variant = _payload
	_payload = null
	return payload
