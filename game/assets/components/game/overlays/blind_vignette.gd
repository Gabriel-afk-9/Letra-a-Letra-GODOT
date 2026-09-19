extends Control
class_name BlindVignette


const EFFECT_OVERLAY_FADE := 0.3

var _blind_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	if has_node("Vignette"):
		var v := get_node("Vignette") as Control
		if v != null:
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_vignette() -> void:
	visible = true
	if is_instance_valid(_blind_tween) and _blind_tween.is_valid():
		_blind_tween.kill()
	_blind_tween = create_tween()
	_blind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_blind_tween.tween_property(self, "modulate:a", 1.0, EFFECT_OVERLAY_FADE)


func hide_vignette() -> void:
	if is_instance_valid(_blind_tween) and _blind_tween.is_valid():
		_blind_tween.kill()
	_blind_tween = create_tween()
	_blind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_blind_tween.tween_property(self, "modulate:a", 0.0, EFFECT_OVERLAY_FADE)
	_blind_tween.tween_callback(hide)
