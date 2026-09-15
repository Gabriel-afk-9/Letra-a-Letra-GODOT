extends PanelContainer
class_name InventorySlot


signal slot_pressed(index: int)
signal slot_drag_launch(index: int)
signal slot_drag_discard(index: int)

const ARMED_LIFT_Y := 0.0
const ARMED_LIFT_SCALE := Vector2.ONE
const ARMED_LIFT_DURATION := 0.18
const ARMED_SNAP_DURATION := 0.14
const GLOBAL_SWIPE_THRESHOLD_PX := 40.0
const POWER_GRANT_FLASH_COLOR := Color(1, 0.85, 0.3, 1)
const POWER_GRANT_PULSE_DURATION := 0.16
const POWER_GRANT_SETTLE_DURATION := 0.24
const COLOR_WHITE := Color(1, 1, 1, 1)
const COLOR_NEON_GREEN := Color(0.2, 1.0, 0.4, 1)

var _icon: TextureButton
var _slot_index: int = -1
var _current_power: Variant = null
var _current_power_type: String = ""
var _is_armed_cache: bool = false
var _armed_scope_cache: String = ""
var _is_frozen_cache: bool = false
var _is_defense_armed_cache: bool = false
var _has_defense_pulse_cache: bool = false

var _drag_start_y: float = 0.0
var _dragging: bool = false
var _power_grant_tween: Tween
var _icon_cache: Dictionary = {}
var _is_empty_cache: bool = true


func _ready() -> void:
	_icon = get_node_or_null("Icon") as TextureButton
	if _icon == null:
		_icon = TextureButton.new()
		_icon.name = "Icon"
		add_child(_icon)
	_icon.ignore_texture_size = true
	_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_icon.pressed.connect(func() -> void: slot_pressed.emit(_slot_index))
	_icon.gui_input.connect(_on_icon_gui_input)
	clip_contents = false
	custom_minimum_size = Vector2(52, 52)
	queue_redraw()


func setup(index: int) -> void:
	_slot_index = index


func set_power(power: Variant, is_frozen: bool) -> void:
	_current_power = power
	_is_frozen_cache = is_frozen
	if _icon == null:
		_icon = get_node_or_null("Icon") as TextureButton
	_is_empty_cache = not (power is GamePower)
	if power is GamePower:
		_current_power_type = (power as GamePower).type
		_icon.texture_normal = _power_icon(_current_power_type)
		if not has_meta("defense_pulse"):
			var solid_style := StyleBoxFlat.new()
			solid_style.bg_color = Color(0, 0, 0, 0)
			solid_style.corner_radius_top_left = 8
			solid_style.corner_radius_top_right = 8
			solid_style.corner_radius_bottom_right = 8
			solid_style.corner_radius_bottom_left = 8
			solid_style.border_width_left = 0
			solid_style.border_width_top = 0
			solid_style.border_width_right = 0
			solid_style.border_width_bottom = 0
			solid_style.content_margin_left = 0
			solid_style.content_margin_top = 0
			solid_style.content_margin_right = 0
			solid_style.content_margin_bottom = 0
			add_theme_stylebox_override("panel", solid_style)
		clip_contents = false
		var should_disable: bool = is_frozen and not GamePowerCatalog.can_use_while_frozen(_current_power_type)
		_icon.material = _rounded_icon_material(should_disable)
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0, 0, 0, 0)
		icon_style.corner_radius_top_left = 8
		icon_style.corner_radius_top_right = 8
		icon_style.corner_radius_bottom_right = 8
		icon_style.corner_radius_bottom_left = 8
		_icon.add_theme_stylebox_override("normal", icon_style)
		_icon.add_theme_stylebox_override("hover", icon_style)
		_icon.add_theme_stylebox_override("pressed", icon_style)
		_icon.add_theme_stylebox_override("disabled", icon_style)
		_icon.add_theme_stylebox_override("focus", icon_style)
		_icon.disabled = should_disable
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE if should_disable else Control.MOUSE_FILTER_STOP
		_icon.modulate = Color.WHITE
	else:
		_current_power_type = ""
		_icon.texture_normal = null
		_icon.material = null
		clip_contents = false
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0, 0, 0, 0)
		add_theme_stylebox_override("panel", empty_style)
		var empty_icon_style := StyleBoxFlat.new()
		empty_icon_style.bg_color = Color(0, 0, 0, 0)
		_icon.add_theme_stylebox_override("normal", empty_icon_style)
		_icon.add_theme_stylebox_override("hover", empty_icon_style)
		_icon.add_theme_stylebox_override("pressed", empty_icon_style)
		_icon.disabled = true
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon.modulate = Color.WHITE
	queue_redraw()


func set_armed(is_armed: bool, scope: String, is_defense_armed: bool) -> void:
	_is_armed_cache = is_armed
	_armed_scope_cache = scope
	_is_defense_armed_cache = is_defense_armed
	_animate_slot_lift(is_armed)


func set_defense_pulse(should_pulse: bool) -> void:
	if should_pulse == _has_defense_pulse_cache:
		if should_pulse:
			return
		else:
			_stop_defense_pulse_internal()
			return
	_has_defense_pulse_cache = should_pulse
	if should_pulse:
		_start_defense_pulse_internal()
	else:
		_stop_defense_pulse_internal()


func flash_grant() -> void:
	if _icon == null:
		return
	if is_instance_valid(_power_grant_tween) and _power_grant_tween.is_valid():
		_power_grant_tween.kill()
	_icon.pivot_offset = _icon.size / 2.0
	_power_grant_tween = create_tween()
	_power_grant_tween.tween_property(_icon, "scale", Vector2(1.25, 1.25), POWER_GRANT_PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_power_grant_tween.parallel().tween_property(_icon, "modulate", POWER_GRANT_FLASH_COLOR, POWER_GRANT_PULSE_DURATION)
	_power_grant_tween.tween_property(_icon, "scale", Vector2.ONE, POWER_GRANT_SETTLE_DURATION)
	_power_grant_tween.parallel().tween_property(_icon, "modulate", COLOR_WHITE, POWER_GRANT_SETTLE_DURATION)


func _power_icon(power_type: String) -> Texture2D:
	if _icon_cache.has(power_type):
		return _icon_cache[power_type]
	var path = PlayerCard.POWER_ICON_PATHS.get(power_type)
	if path == null:
		return null
	var texture := load(str(path)) as Texture2D
	_icon_cache[power_type] = texture
	return texture


func _rounded_icon_material(is_gray: bool = false) -> ShaderMaterial:
	var key := "__rounded_gray" if is_gray else "__rounded_mat"
	var cached = _icon_cache.get(key)
	if cached is ShaderMaterial:
		return cached
	var shader: Shader = preload("res://assets/components/game/inventory/rounded_icon.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("radius", 8.0)
	mat.set_shader_parameter("desaturation", 1.0 if is_gray else 0.0)
	_icon_cache[key] = mat
	return mat


func _animate_slot_lift(lifted: bool) -> void:
	if _icon == null:
		return
	_icon.pivot_offset = Vector2(26, 26)
	if _icon.size == Vector2.ZERO:
		_icon.pivot_offset = Vector2(26, 26)
	var meta_key := "lift_tween"
	if _icon.has_meta(meta_key):
		var old = _icon.get_meta(meta_key)
		if old is Tween and old.is_valid():
			old.kill()
	var has_defense_pulse := has_meta("defense_pulse")
	if has_meta("defense_pulse"):
		var fstyle_dp := get_theme_stylebox("panel") as StyleBoxFlat
		if fstyle_dp != null:
			if lifted and _is_defense_armed_cache:
				fstyle_dp.border_width_left = 3
				fstyle_dp.border_width_top = 3
				fstyle_dp.border_width_right = 3
				fstyle_dp.border_width_bottom = 3
				fstyle_dp.border_color = COLOR_NEON_GREEN
				fstyle_dp.bg_color = Color(0, 0, 0, 0)
				fstyle_dp.shadow_color = Color(0.2, 1.0, 0.4, 0.9)
				fstyle_dp.shadow_size = 4
	elif not has_defense_pulse:
		clip_contents = false
		var fstyle := get_theme_stylebox("panel") as StyleBoxFlat
		if fstyle != null:
			if lifted:
				if _is_defense_armed_cache:
					fstyle.border_width_left = 3
					fstyle.border_width_top = 3
					fstyle.border_width_right = 3
					fstyle.border_width_bottom = 3
					fstyle.border_color = COLOR_NEON_GREEN
					fstyle.bg_color = Color(0, 0, 0, 0)
					fstyle.shadow_color = Color(0.2, 1.0, 0.4, 0.9)
					fstyle.shadow_size = 4
				else:
					fstyle.border_width_left = 2
					fstyle.border_width_top = 2
					fstyle.border_width_right = 2
					fstyle.border_width_bottom = 2
					fstyle.border_color = Color.WHITE
					fstyle.bg_color = Color(0, 0, 0, 0)
					fstyle.shadow_color = Color(0.047, 1, 0.396, 0.9)
			else:
				fstyle.border_width_left = 0
				fstyle.border_width_top = 0
				fstyle.border_width_right = 0
				fstyle.border_width_bottom = 0
				fstyle.border_color = Color(0, 0, 0, 0)
				fstyle.bg_color = Color(0, 0, 0, 0)
				fstyle.shadow_color = Color(0, 0, 0, 0)
				fstyle.shadow_size = 0
	var is_disabled_slot: bool = _icon.disabled
	var target_modulate: Color = Color(0.45, 0.45, 0.45, 1) if is_disabled_slot else Color.WHITE
	var tween := create_tween()
	_icon.set_meta(meta_key, tween)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if lifted:
		tween.tween_property(_icon, "position:y", 0.0, ARMED_SNAP_DURATION)
		tween.parallel().tween_property(_icon, "scale", Vector2.ONE, 0.16)
		tween.parallel().tween_property(_icon, "modulate", Color.WHITE, 0.16)
		if not has_defense_pulse:
			var fs := get_theme_stylebox("panel") as StyleBoxFlat
			if fs != null:
				tween.parallel().tween_property(fs, "shadow_size", 4, ARMED_LIFT_DURATION)
		_icon.z_index = 0
		if _armed_scope_cache == GamePowerCatalog.SCOPE_GLOBAL:
			_ensure_global_arrow(true)
		else:
			_ensure_global_arrow(false)
	else:
		tween.tween_property(_icon, "position:y", 0.0, ARMED_SNAP_DURATION)
		tween.parallel().tween_property(_icon, "scale", Vector2.ONE, ARMED_SNAP_DURATION)
		tween.parallel().tween_property(_icon, "modulate", target_modulate, ARMED_SNAP_DURATION)
		_icon.z_index = 0
		_ensure_global_arrow(false)
	var slot_id_lift := _icon.get_instance_id()
	var tween_id_lift := tween.get_instance_id()
	var meta_key_lift := meta_key
	tween.finished.connect(func() -> void:
		var s: Control = instance_from_id(slot_id_lift) as Control
		if not is_instance_valid(s):
			return
		if not s.has_meta(meta_key_lift):
			return
		var cur: Variant = s.get_meta(meta_key_lift)
		if cur == null or not is_instance_valid(cur as Object):
			s.remove_meta(meta_key_lift)
			return
		var cur_id := (cur as Object).get_instance_id()
		if cur_id != tween_id_lift:
			return
		s.remove_meta(meta_key_lift)
	)


func _start_defense_pulse_internal() -> void:
	if _icon == null:
		return
	if has_meta("defense_pulse"):
		return
	_icon.pivot_offset = Vector2(26, 26)
	_icon.position.y = 0
	_icon.scale = Vector2.ONE
	_icon.z_index = 0
	clip_contents = false
	var fstyle := get_theme_stylebox("panel") as StyleBoxFlat
	if fstyle == null:
		fstyle = StyleBoxFlat.new()
		add_theme_stylebox_override("panel", fstyle)
	fstyle.bg_color = Color(0, 0, 0, 0)
	fstyle.border_width_left = 3
	fstyle.border_width_top = 3
	fstyle.border_width_right = 3
	fstyle.border_width_bottom = 3
	fstyle.border_color = COLOR_NEON_GREEN
	fstyle.shadow_color = Color(0.2, 1.0, 0.4, 0.9)
	fstyle.shadow_size = 0
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var fs := get_theme_stylebox("panel") as StyleBoxFlat
	if fs != null:
		tween.tween_property(fs, "shadow_size", 8, 0.30)
		tween.tween_property(fs, "shadow_size", 0, 0.30)
	set_meta("defense_pulse", tween)


func _stop_defense_pulse_internal() -> void:
	if not has_meta("defense_pulse"):
		if not _is_armed_cache:
			var fstyle := get_theme_stylebox("panel") as StyleBoxFlat
			if fstyle != null and _icon != null and not _icon.has_meta("lift_tween"):
				fstyle.border_width_left = 0
				fstyle.border_width_top = 0
				fstyle.border_width_right = 0
				fstyle.border_width_bottom = 0
				fstyle.border_color = Color(0, 0, 0, 0)
				fstyle.shadow_color = Color(0, 0, 0, 0)
				fstyle.shadow_size = 0
		return
	var t = get_meta("defense_pulse")
	if t is Tween and t.is_valid():
		t.kill()
	remove_meta("defense_pulse")
	if _is_armed_cache:
		return
	var fstyle2 := get_theme_stylebox("panel") as StyleBoxFlat
	if fstyle2 != null and _icon != null and not _icon.has_meta("lift_tween"):
		fstyle2.border_width_left = 0
		fstyle2.border_width_top = 0
		fstyle2.border_width_right = 0
		fstyle2.border_width_bottom = 0
		fstyle2.border_color = Color(0, 0, 0, 0)
		fstyle2.shadow_color = Color(0, 0, 0, 0)
		fstyle2.shadow_size = 0
	_has_defense_pulse_cache = false


func _ensure_global_arrow(show: bool) -> void:
	var arrow: Control = get_node_or_null("GlobalArrow") as Control
	if show:
		if arrow == null:
			arrow = Label.new()
			arrow.name = "GlobalArrow"
			arrow.text = "▲"
			(arrow as Label).add_theme_font_size_override("font_size", 18)
			(arrow as Label).add_theme_color_override("font_color", Color(0.18, 0.80, 0.44, 1))
			arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow.size = Vector2(24, 18)
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			arrow.z_index = 15
			arrow.top_level = true
			add_child(arrow)
			var frame_size := size
			if frame_size.x < 1.0:
				frame_size = Vector2(52, 52)
			var target_global := global_position + Vector2((frame_size.x - 24.0) * 0.5, -30.0)
			arrow.global_position = target_global + Vector2(0, 12)
			arrow.modulate.a = 0.0
			var enter := create_tween()
			enter.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			enter.tween_property(arrow, "modulate:a", 1.0, 0.22)
			enter.parallel().tween_property(arrow, "global_position:y", target_global.y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			arrow.set_meta("enter", enter)
			arrow.set_meta("target_global", target_global)
			var arrow_id_enter := arrow.get_instance_id()
			enter.finished.connect(func() -> void:
				var a: Control = instance_from_id(arrow_id_enter) as Control
				if not is_instance_valid(a):
					return
				if a.has_meta("bounce") and a.get_meta("bounce") is Tween and (a.get_meta("bounce") as Tween).is_valid():
					return
				var bounce := create_tween()
				bounce.set_loops()
				bounce.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				var tg: Vector2 = a.get_meta("target_global", a.global_position)
				bounce.tween_property(a, "global_position:y", tg.y - 8.0, 0.30)
				bounce.tween_property(a, "global_position:y", tg.y, 0.30)
				a.set_meta("bounce", bounce)
			)
		else:
			arrow.visible = true
			arrow.modulate.a = 1.0
		arrow.visible = true
	else:
		if arrow != null:
			if arrow.has_meta("bounce"):
				var b = arrow.get_meta("bounce")
				if b is Tween and b.is_valid():
					b.kill()
			if arrow.has_meta("enter"):
				var e = arrow.get_meta("enter")
				if e is Tween and e.is_valid():
					e.kill()
			var fade := create_tween()
			fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			fade.tween_property(arrow, "modulate:a", 0.0, 0.15)
			fade.parallel().tween_property(arrow, "global_position:y", arrow.global_position.y + 8.0, 0.15)
			var arrow_id_fade := arrow.get_instance_id()
			fade.finished.connect(func() -> void:
				var a2: Control = instance_from_id(arrow_id_fade) as Control
				if is_instance_valid(a2):
					a2.queue_free()
			)


func _on_icon_gui_input(event: InputEvent) -> void:
	if _is_empty_cache:
		return
	if not _is_armed_cache:
		return
	if _icon == null:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_drag_start_y = event.position.y
			_dragging = true
			if _icon.has_meta("lift_tween"):
				var lt = _icon.get_meta("lift_tween")
				if lt is Tween and lt.is_valid():
					lt.kill()
					_icon.remove_meta("lift_tween")
			_icon.z_index = 10
		else:
			if _dragging:
				var delta_end: float = event.position.y - _drag_start_y
				if abs(delta_end) < GLOBAL_SWIPE_THRESHOLD_PX:
					_snap_back_slot()
			_dragging = false
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if not _dragging:
			return
		var delta: float = event.position.y - _drag_start_y
		var clamped: float = clamp(delta, -60.0, 60.0)
		_icon.position.y = ARMED_LIFT_Y + clamped
		if delta < -20.0:
			if _armed_scope_cache == GamePowerCatalog.SCOPE_GLOBAL:
				_apply_drag_preview(true, false)
			else:
				_apply_drag_preview(false, false)
		elif delta > 20.0:
			var is_frozen_defense_preview: bool = _is_frozen_cache and GamePowerCatalog.get_counters_for_debuff("PLAYER_FROZEN").has(_current_power_type)
			if is_frozen_defense_preview:
				_apply_drag_preview(false, false)
			else:
				_apply_drag_preview(false, true)
		else:
			_apply_drag_preview(false, false)
			_icon.position.y = ARMED_LIFT_Y + clamped
			_icon.scale = ARMED_LIFT_SCALE if abs(clamped) < 5 else Vector2(0.95, 0.95)
		if delta < -GLOBAL_SWIPE_THRESHOLD_PX:
			if _armed_scope_cache != GamePowerCatalog.SCOPE_GLOBAL:
				_snap_back_slot()
				_dragging = false
				return
			_dragging = false
			_animate_launch_slot()
			slot_drag_launch.emit(_slot_index)
		elif delta > GLOBAL_SWIPE_THRESHOLD_PX:
			var is_frozen_defense_discard: bool = _is_frozen_cache and GamePowerCatalog.get_counters_for_debuff("PLAYER_FROZEN").has(_current_power_type)
			if is_frozen_defense_discard:
				_snap_back_slot()
				_dragging = false
				return
			_dragging = false
			_animate_discard_slot()
			slot_drag_discard.emit(_slot_index)


func _apply_drag_preview(is_using: bool, is_discarding: bool) -> void:
	if _icon == null:
		return
	_icon.pivot_offset = Vector2(26, 26)
	if is_using:
		_icon.scale = Vector2(0.95, 0.95)
		_icon.modulate = Color(1, 1, 1, 1)
		var fs := get_theme_stylebox("panel") as StyleBoxFlat
		if fs != null:
			fs.border_width_left = 2
			fs.border_width_top = 2
			fs.border_width_right = 2
			fs.border_width_bottom = 2
			fs.border_color = Color(0.18, 0.80, 0.44, 1)
			fs.bg_color = Color(0, 0, 0, 0)
			fs.shadow_color = Color(0.18, 0.80, 0.44, 0.8)
			fs.shadow_size = 25
	elif is_discarding:
		_icon.scale = Vector2(0.95, 0.95)
		_icon.modulate = Color(0.6, 0.6, 0.6, 1)
		var fs2 := get_theme_stylebox("panel") as StyleBoxFlat
		if fs2 != null:
			fs2.border_width_left = 2
			fs2.border_width_top = 2
			fs2.border_width_right = 2
			fs2.border_width_bottom = 2
			fs2.border_color = Color(1, 0.28, 0.34, 1)
			fs2.bg_color = Color(0, 0, 0, 0)
			fs2.shadow_color = Color(1, 0.28, 0.34, 0.8)
			fs2.shadow_size = 20
	else:
		_icon.scale = ARMED_LIFT_SCALE
		_icon.modulate = Color.WHITE
		var fs3 := get_theme_stylebox("panel") as StyleBoxFlat
		if fs3 != null:
			fs3.border_width_left = 2
			fs3.border_width_top = 2
			fs3.border_width_right = 2
			fs3.border_width_bottom = 2
			fs3.border_color = Color.WHITE
			fs3.bg_color = Color(0, 0, 0, 0)
			fs3.shadow_color = Color(0.047, 1, 0.396, 0.9)
			fs3.shadow_size = 4


func _snap_back_slot() -> void:
	if _icon == null:
		return
	if _icon.has_meta("drag_tween"):
		var dt = _icon.get_meta("drag_tween")
		if dt is Tween and dt.is_valid():
			dt.kill()
	_icon.pivot_offset = Vector2(26, 26)
	var tween := create_tween()
	_icon.set_meta("drag_tween", tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_icon, "position:y", ARMED_LIFT_Y, 0.22)
	tween.parallel().tween_property(_icon, "scale", ARMED_LIFT_SCALE, 0.22)
	tween.parallel().tween_property(_icon, "modulate", Color.WHITE, 0.16)
	var fs := get_theme_stylebox("panel") as StyleBoxFlat
	if fs != null:
		tween.parallel().tween_property(fs, "border_color", Color.WHITE, 0.16)
		tween.parallel().tween_property(fs, "shadow_size", 4, 0.22)
	var slot_id_drag := _icon.get_instance_id()
	var tween_id_drag := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var s: Control = instance_from_id(slot_id_drag) as Control
		if not is_instance_valid(s):
			return
		if not s.has_meta("drag_tween"):
			return
		var cur: Variant = s.get_meta("drag_tween")
		if cur == null or not is_instance_valid(cur as Object):
			s.remove_meta("drag_tween")
			return
		if (cur as Object).get_instance_id() != tween_id_drag:
			return
		s.remove_meta("drag_tween")
	)


func _animate_launch_slot() -> void:
	if _icon == null:
		return
	_icon.pivot_offset = Vector2(26, 26)
	if _icon.has_meta("lift_tween"):
		var lt = _icon.get_meta("lift_tween")
		if lt is Tween and lt.is_valid():
			lt.kill()
			_icon.remove_meta("lift_tween")
	var tween := create_tween()
	_icon.set_meta("exit_tween", tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_icon, "scale", Vector2(1.18, 1.18), 0.15)
	tween.parallel().tween_property(_icon, "modulate", Color(2, 2, 2, 1), 0.15)
	tween.tween_property(_icon, "scale", Vector2(1.5, 1.5), 0.35)
	tween.parallel().tween_property(_icon, "position:y", -120.0, 0.35)
	tween.parallel().tween_property(_icon, "rotation", deg_to_rad(8), 0.35)
	tween.parallel().tween_property(_icon, "modulate:a", 0.0, 0.35)
	_icon.z_index = 50
	var slot_id_launch := _icon.get_instance_id()
	var tween_id_launch := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var s: Control = instance_from_id(slot_id_launch) as Control
		if not is_instance_valid(s):
			return
		if s.has_meta("exit_tween"):
			var cur: Variant = s.get_meta("exit_tween")
			if cur != null and is_instance_valid(cur as Object) and (cur as Object).get_instance_id() == tween_id_launch:
				s.remove_meta("exit_tween")
		(s as TextureButton).position.y = 0
		(s as TextureButton).scale = Vector2.ONE
		(s as TextureButton).rotation = 0
		(s as TextureButton).modulate = Color.WHITE
		s.z_index = 0
	)


func _animate_discard_slot() -> void:
	if _icon == null:
		return
	_icon.pivot_offset = Vector2(26, 26)
	if _icon.has_meta("lift_tween"):
		var lt = _icon.get_meta("lift_tween")
		if lt is Tween and lt.is_valid():
			lt.kill()
			_icon.remove_meta("lift_tween")
	var tween := create_tween()
	_icon.set_meta("exit_tween", tween)
	_icon.z_index = 30
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_icon, "scale", Vector2(1.08, 1.08), 0.17)
	tween.parallel().tween_property(_icon, "rotation", deg_to_rad(-6), 0.17)
	tween.tween_property(_icon, "scale", Vector2(0.3, 0.3), 0.25)
	tween.parallel().tween_property(_icon, "position:y", 80.0, 0.25)
	tween.parallel().tween_property(_icon, "rotation", deg_to_rad(20), 0.25)
	tween.parallel().tween_property(_icon, "modulate:a", 0.0, 0.25)
	var slot_id_discard := _icon.get_instance_id()
	var tween_id_discard := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var s: Control = instance_from_id(slot_id_discard) as Control
		if not is_instance_valid(s):
			return
		if s.has_meta("exit_tween"):
			var cur: Variant = s.get_meta("exit_tween")
			if cur != null and is_instance_valid(cur as Object) and (cur as Object).get_instance_id() == tween_id_discard:
				s.remove_meta("exit_tween")
		(s as TextureButton).position.y = 0
		(s as TextureButton).scale = Vector2.ONE
		(s as TextureButton).rotation = 0
		(s as TextureButton).modulate = Color.WHITE
		s.z_index = 0
	)


func _draw() -> void:
	if not _is_empty_cache:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var r := 8.0
	var color := Color(0.6, 0.6, 0.6, 1)
	var width := 2.0
	var dash := 6.0
	var gap := 4.0
	draw_dashed_line(Vector2(r, 0), Vector2(rect.size.x - r, 0), color, width, dash, gap)
	draw_dashed_line(Vector2(rect.size.x, r), Vector2(rect.size.x, rect.size.y - r), color, width, dash, gap)
	draw_dashed_line(Vector2(rect.size.x - r, rect.size.y), Vector2(r, rect.size.y), color, width, dash, gap)
	draw_dashed_line(Vector2(0, rect.size.y - r), Vector2(0, r), color, width, dash, gap)
