extends Button

func _ready() -> void:
	pivot_offset = size / 2 
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _on_hover() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_SINE)

func _on_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_press() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_SINE)

func _on_release() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
