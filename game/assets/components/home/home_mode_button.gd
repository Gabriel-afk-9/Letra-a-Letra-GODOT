extends Button
class_name HomeModeButton

signal mode_pressed(mode: int)

@export var selected_modulate: Color = Color(1, 1, 1, 1)
@export var deselected_modulate: Color = Color(0.92, 0.92, 0.92, 1)

var _mode: int = HomeGameMode.Mode.NORMAL
var _desc_text: String = ""

@onready var _icon: TextureRect = get_node_or_null("CenterBox/IconWrap/Icon") as TextureRect
@onready var _label: Label = get_node_or_null("CenterBox/Label") as Label
@onready var _crown_wrap: Control = get_node_or_null("CenterBox/IconWrap/CrownWrap") as Control

var _select_tween: Tween = null

func _ready() -> void:
	pressed.connect(func() -> void: mode_pressed.emit(_mode))
	pivot_offset = Vector2(55, 55)
	clip_contents = false
	visibility_changed.connect(_on_visibility_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() and is_instance_valid(_select_tween) and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
		scale = Vector2.ONE

func setup(mode: int, icon_texture: Texture2D, text: String, desc: String, use_crown: bool = false) -> void:
	_mode = mode
	_desc_text = desc
	# Fallback: @onready ainda pode ser null se HomeScreen chamar antes do _ready do filho.
	var label_node: Label = _label if is_instance_valid(_label) else get_node_or_null("CenterBox/Label") as Label
	if is_instance_valid(label_node):
		label_node.text = text
		_label = label_node
	var icon_node: TextureRect = _icon if is_instance_valid(_icon) else get_node_or_null("CenterBox/IconWrap/Icon") as TextureRect
	var crown_node: Control = _crown_wrap if is_instance_valid(_crown_wrap) else get_node_or_null("CenterBox/IconWrap/CrownWrap") as Control
	if use_crown:
		if is_instance_valid(icon_node):
			icon_node.visible = false
			_icon = icon_node
		if is_instance_valid(crown_node):
			crown_node.visible = true
			_crown_wrap = crown_node
	else:
		if is_instance_valid(icon_node):
			icon_node.visible = true
			if icon_texture != null:
				icon_node.texture = icon_texture
			_icon = icon_node
		if is_instance_valid(crown_node):
			crown_node.visible = false
			_crown_wrap = crown_node

func get_desc_text() -> String:
	return _desc_text

func get_mode() -> int:
	return _mode

func set_selected(is_selected: bool) -> void:
	modulate = selected_modulate if is_selected else deselected_modulate
	if is_instance_valid(_select_tween) and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	scale = Vector2.ONE
	if is_selected and not disabled:
		_select_tween = create_tween()
		_select_tween.set_loops()
		_select_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_select_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.5)
		_select_tween.tween_property(self, "scale", Vector2.ONE, 0.5)


func _set(property: StringName, value: Variant) -> bool:
	if property == &"disabled" and value == true:
		if is_instance_valid(_select_tween) and _select_tween.is_valid():
			_select_tween.kill()
			_select_tween = null
		scale = Vector2.ONE
	return false
