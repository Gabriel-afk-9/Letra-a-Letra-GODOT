extends ColorRect
class_name GameOverOverlay


signal home_requested

@onready var _title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _subtitle_label: Label = $Center/Panel/Margin/VBox/SubtitleLabel
@onready var _home_button: Button = $Center/Panel/Margin/VBox/HomeButton

var _green_normal: StyleBox = preload("res://assets/styles/buttons/green_button_default.tres")
var _green_hover: StyleBox = preload("res://assets/styles/buttons/green_button_hover.tres")
var _green_pressed: StyleBox = preload("res://assets/styles/buttons/green_button_pressed.tres")
var _red_normal: StyleBox = preload("res://assets/styles/buttons/red_button_default.tres")
var _disabled_style: StyleBox = preload("res://assets/styles/buttons/disabled_button.tres")


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	color = Color(0, 0, 0, 0.85)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_home_button.pressed.connect(func() -> void: home_requested.emit())


func show_result(is_winner: bool, title: String, subtitle: String) -> void:
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1) if is_winner else Color(1.0, 0.3, 0.3, 1))
	_subtitle_label.text = subtitle
	if is_winner:
		_home_button.add_theme_stylebox_override("normal", _green_normal)
		_home_button.add_theme_stylebox_override("hover", _green_hover)
		_home_button.add_theme_stylebox_override("pressed", _green_pressed)
	else:
		_home_button.add_theme_stylebox_override("normal", _red_normal)
		_home_button.add_theme_stylebox_override("hover", _red_normal)
		_home_button.add_theme_stylebox_override("pressed", _red_normal)
	_home_button.add_theme_stylebox_override("disabled", _disabled_style)
	visible = true
	_home_button.disabled = false
