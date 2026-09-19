extends ColorRect
class_name EffectOverlay


const EFFECT_OVERLAY_FADE := 0.3

var _effect_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0


func show_with_color(color: Color) -> void:
	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()
	color.a = color.a
	self.color = color
	visible = true
	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()
	_effect_tween = create_tween()
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(self, "modulate:a", 1.0, EFFECT_OVERLAY_FADE)


func hide_overlay() -> void:
	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()
	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()
	_effect_tween = create_tween()
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(self, "modulate:a", 0.0, EFFECT_OVERLAY_FADE)
	_effect_tween.tween_callback(hide)


func flash(color: Color, hold_seconds: float) -> void:
	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()
	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()
	self.color = color
	visible = true
	modulate.a = 0.0
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_flash_tween.tween_interval(hold_seconds)
	_flash_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	_flash_tween.tween_callback(hide)
