extends PanelContainer


@export var dash_color: Color = Color(0.6, 0.6, 0.6, 1)
@export var dash_length: float = 6.0
@export var gap_length: float = 4.0
@export var border_width: float = 2.0
@export var corner_radius: float = 6.0


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var r := corner_radius
	var color := dash_color
	var width := border_width
	var dash := dash_length
	var gap := gap_length

	draw_dashed_line(Vector2(r, 0), Vector2(rect.size.x - r, 0), color, width, dash, gap)
	draw_dashed_line(Vector2(rect.size.x, r), Vector2(rect.size.x, rect.size.y - r), color, width, dash, gap)
	draw_dashed_line(Vector2(rect.size.x - r, rect.size.y), Vector2(r, rect.size.y), color, width, dash, gap)
	draw_dashed_line(Vector2(0, rect.size.y - r), Vector2(0, r), color, width, dash, gap)