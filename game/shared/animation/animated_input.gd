extends LineEdit

@export var force_lowercase: bool = false

func _ready() -> void:
	self.text_changed.connect(func(_new_text): self.modulate = Color.WHITE)
	if force_lowercase:
		self.text_changed.connect(_on_text_changed_lowercase)


func _on_text_changed_lowercase(new_text: String) -> void:
	var lowered := new_text.to_lower()
	if lowered == new_text:
		return
	var column := caret_column
	text = lowered
	caret_column = mini(column, lowered.length())

func shake() -> void:
	var tween: Tween = create_tween()
	var original_x: float = position.x
	
	tween.tween_property(self, "position:x", original_x + 10, 0.05)
	tween.tween_property(self, "position:x", original_x - 10, 0.05)
	tween.tween_property(self, "position:x", original_x + 5, 0.05)
	tween.tween_property(self, "position:x", original_x - 5, 0.05)
	tween.tween_property(self, "position:x", original_x, 0.05)
	
	self.modulate = Color("#ff6b6b")
