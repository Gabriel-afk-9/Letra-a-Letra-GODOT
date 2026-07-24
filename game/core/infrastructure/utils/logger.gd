extends RefCounted
class_name AppLogger

const DEBUG_ENABLED := true

static func debug(message: String) -> void:
	if DEBUG_ENABLED:
		print("[DEBUG] " + message)

static func info(message: String) -> void:
	print("[INFO] " + message)

static func error(message: String) -> void:
	push_error("[ERROR] " + message)
