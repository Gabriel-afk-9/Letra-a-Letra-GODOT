extends PanelContainer
class_name WordPill


const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)


func setup(text: String, owner: String) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 2
	style.content_margin_right = 8
	style.content_margin_bottom = 2
	match owner:
		"me":
			style.bg_color = COLOR_BLUE
		"opponent":
			style.bg_color = COLOR_ORANGE
		_:
			style.bg_color = Color(0.2, 0.2, 0.2, 1)
	add_theme_stylebox_override("panel", style)
	var lbl := get_node_or_null("Label") as Label
	if lbl != null:
		lbl.text = text.to_upper()
