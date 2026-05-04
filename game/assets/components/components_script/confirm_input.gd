extends LineEdit

@onready var toggle_btn: Button = $ToggleConfirmPwdBtn

func _ready() -> void:
	if toggle_btn:
		toggle_btn.pressed.connect(_on_toggle_pressed)

func _on_toggle_pressed() -> void:
	secret = !secret
	
	if secret:
		toggle_btn.texture_normal = preload("res://assets/images/icons/eye_closed.png")
	else:
		toggle_btn.texture_normal = preload("res://assets/images/icons/eye.png")

func shake() -> void:
	var tween: Tween = create_tween()
	var original_x: float = position.x
	
	tween.tween_property(self, "position:x", original_x + 10, 0.05)
	tween.tween_property(self, "position:x", original_x - 10, 0.05)
	tween.tween_property(self, "position:x", original_x + 5, 0.05)
	tween.tween_property(self, "position:x", original_x - 5, 0.05)
	tween.tween_property(self, "position:x", original_x, 0.05)
	
	self.modulate = Color("#ff6b6b")
