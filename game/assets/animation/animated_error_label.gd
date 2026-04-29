extends Label

func show_error(message: String) -> void:
	self.text = message
	self.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(3.0)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): self.text = "")
