extends Button

signal logout_requested

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	disabled = true
	logout_requested.emit()
