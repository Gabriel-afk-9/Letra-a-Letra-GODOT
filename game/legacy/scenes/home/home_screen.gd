extends Control

@onready var profile_card: ProfileCard = $MarginContainer/MainLayout/Header/ProfileCard
@onready var setting_btn: Button = $MarginContainer/MainLayout/Header/SettingBtn
@onready var play_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/PlayBtn
@onready var room_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/RoomBtn
@onready var exit_btn: Button = $MarginContainer/MainLayout/ExitButton

func _ready() -> void:
	_load_user_data()

func _load_user_data() -> void:
	var nickname = AuthManager.user_nickname
	
	if nickname == "":
		profile_card.setup("Convidado")
		return
		
	profile_card.setup(nickname)

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/matchmaking/matchmaking_screen.tscn")

func _on_room_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/room/room_screen.tscn")

func _on_avatar_pressed() -> void:
	print("Abrir galeria ou modal para trocar foto de perfil!")

func _on_settings_pressed() -> void:
	print("Abrir configurações")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
