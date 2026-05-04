extends Control

const RoomItemScene = preload("res://assets/components/room_item.tscn")

@onready var back_btn: Button = $MarginContainer/MainLayout/Header/BackBtn
@onready var refresh_btn: Button = $MarginContainer/MainLayout/Header/RefreshBtn

@onready var rooms_list: VBoxContainer = $MarginContainer/MainLayout/RoomListContainer/MarginContainer/ScrollContainer/RoomsList
@onready var empty_message: Label = $MarginContainer/MainLayout/RoomListContainer/MarginContainer/EmptyMessage

@onready var create_room_btn: Button = $MarginContainer/MainLayout/BottomActions/CreateBtn
@onready var join_room_btn: Button = $MarginContainer/MainLayout/BottomActions/JoinBtn

var active_games_usecase: ActiveGamesUseCase

func _ready() -> void:
	active_games_usecase = ActiveGamesUseCase.new()
	
	_load_public_games()

func _load_public_games() -> void:
	empty_message.text = "Buscando salas..."
	empty_message.show()
	
	for child in rooms_list.get_children():
		child.queue_free()
		
	refresh_btn.disabled = true
	var result = await active_games_usecase.execute()
	refresh_btn.disabled = false
	
	if result["success"]:
		_populate_list(result["data"])
	else:
		empty_message.text = "Nenhuma sala disponível"
		empty_message.show()

func _populate_list(games_array: Array) -> void:
	if games_array.is_empty():
		empty_message.text = "Nenhuma sala disponível"
		empty_message.show()
		return
		
	empty_message.hide()

	for game in games_array:
		var room_node = RoomItemScene.instantiate()
		rooms_list.add_child(room_node)
		
		var r_name = str(game.get("gameName", "Sala Sem Nome"))
		var r_token = str(game.get("tokenGameId", ""))
		var participants = game.get("participants", [])
		var r_players = participants.size()
		var r_max = int(game.get("max_players", 2))
		
		var r_host = "Desconhecido"
		if r_players > 0:
			r_host = str(participants[0].get("nickname", "Desconhecido"))
		
		room_node.setup(r_name,r_host, r_players, r_max, r_token)
		room_node.pressed.connect(func(): _on_room_selected(r_token))

func _on_room_selected(token: String) -> void:
	print("Entrando na sala: ", token)

func _on_create_pressed() -> void:
	print("Abrir fluxo de criação...")

func _on_join_pressed() -> void:
	print("Abrir fluxo de código...")

func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home/home_screen.tscn")

func _on_refresh_btn_pressed() -> void:
	_load_public_games()
