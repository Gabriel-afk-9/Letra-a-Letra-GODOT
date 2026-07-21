extends RefCounted

class_name BaseViewModel


# ============================================================================
# Signals
# ============================================================================

signal loading_changed(is_loading: bool)
signal error_changed(message: String)


# ============================================================================
# State
# ============================================================================

var _loading: bool = false
var _error_message: String = ""


# ============================================================================
# Protected
# ============================================================================

func _set_loading(value: bool) -> void:

	if _loading == value:
		return

	_loading = value
	loading_changed.emit(value)


func _set_error(message: String) -> void:

	_error_message = message
	error_changed.emit(message)


func _clear_error() -> void:
	_set_error("")


# ============================================================================
# Public API
# ============================================================================

func is_loading() -> bool:
	return _loading


func has_error() -> bool:
	return not _error_message.is_empty()


func error_message() -> String:
	return _error_message
