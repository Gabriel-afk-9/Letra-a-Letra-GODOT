extends LineEdit

func _ready() -> void:
	self.text_changed.connect(func(_new_text): self.modulate = Color.WHITE)
	
func shake() -> void:
	var tween: Tween = create_tween()
	var original_x: float = position.x
	
	tween.tween_property(self, "position:x", original_x + 10, 0.05)
	tween.tween_property(self, "position:x", original_x - 10, 0.05)
	tween.tween_property(self, "position:x", original_x + 5, 0.05)
	tween.tween_property(self, "position:x", original_x - 5, 0.05)
	tween.tween_property(self, "position:x", original_x, 0.05)
	
	self.modulate = Color("#ff6b6b")
