extends LineEdit

func shake() -> void:
	var tween: Tween = create_tween()
	var original_x: float = position.x
	
	tween.tween_property(self, "position:x", original_x + 10, 0.05)
	tween.tween_property(self, "position:x", original_x - 10, 0.05)
	tween.tween_property(self, "position:x", original_x + 5, 0.05)
	tween.tween_property(self, "position:x", original_x - 5, 0.05)
	tween.tween_property(self, "position:x", original_x, 0.05)
	
	self.modulate = Color.RED
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
