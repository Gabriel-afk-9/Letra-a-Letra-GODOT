extends Button

@onready var name_label = $MarginContainer/HBoxContainer/VBoxContainer/RoomName
@onready var host_label = $MarginContainer/HBoxContainer/VBoxContainer/HostName
@onready var count_label = $MarginContainer/HBoxContainer/BadgeContainer/PlayersCount
@onready var badge_container = $MarginContainer/HBoxContainer/BadgeContainer

var room_token: String = ""

func setup(room_name: String, host_name: String, current_players: int, max_players: int, token: String) -> void:
	room_token = token
	
	host_label.text = "Dono: " + host_name
	name_label.text = room_name
	count_label.text = str(current_players) + "/" + str(max_players)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	
	if current_players >= max_players:
		style.bg_color = Color("#d32f2f")
	else:
		style.bg_color = Color("#388e3c")
		
	badge_container.add_theme_stylebox_override("panel", style)
