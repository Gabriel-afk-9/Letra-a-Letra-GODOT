extends Control
class_name RoomLobbyScreen


@onready var _room_name_label: Label = $Center/VBox/RoomNameLabel


func _ready() -> void:
	RoomFactory.bind(self)


func setup(game_name: String) -> void:
	var clean := game_name.strip_edges()
	if clean.is_empty():
		clean = "Sala"
	_room_name_label.text = clean
