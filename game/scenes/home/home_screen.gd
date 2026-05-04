extends Control

#BOTAO DE LOGOUT

@onready var profile_card: PanelContainer = $MarginContainer/MainLayout/Header/ProfileCard
@onready var setting_btn: Button = $MarginContainer/MainLayout/Header/SettingBtn
@onready var play_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/PlayBtn
@onready var room_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/RoomBtn
#@onready var training_btn = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/TrainingBtn

var matchmaking_usecase: MatchmakingUseCase
var ws_manager: Node
var user_usecase: UserUseCase

func _ready() -> void:
	
	matchmaking_usecase = MatchmakingUseCase.new()
	user_usecase = UserUseCase.new()
	
	ws_manager = get_node("/root/WebSocketManager")
	ws_manager.message_received.connect(_on_game_event_received)
	ws_manager.error_occurred.connect(_on_ws_error)
	
	_load_user_data()
	
func _load_user_data() -> void:
	profile_card.set_loading()
	
	var current_user_id = AuthManager.user_id
	
	if current_user_id == "":
		profile_card.setup("Convidado")
		return
		
	var result = await user_usecase.execute(current_user_id)
	
	if result["success"]:
		var user_data = result["data"]
		print("🚨 DADOS DO USUÁRIO DA API: ", user_data)
		
		var nickname = str(user_data.get("nickname", "Sem Nome"))
		profile_card.setup(nickname)
	else:
		print("Erro ao carregar usuário: ", result.get("message"))
		profile_card.setup("Erro de Conexão")
	
	
func _on_play_btn_pressed() -> void:
	play_btn.disabled = true
	play_btn.text = "Buscando..."
	
	matchmaking_usecase.execute()

func _on_room_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/room/room_screen.tscn")

func _on_game_event_received(event_name: String, data: Dictionary) -> void:
	print("Evento do Servidor: ", event_name)
	
	if event_name in ["GAME_CREATED", "GAME_STARTED"]:
		play_btn.text = "Partida Encontrada!"
		
func _on_avatar_pressed() -> void:
	print("Abrir galeria ou modal para trocar foto de perfil!")

func _on_settings_pressed() -> void:
	print("Abrir configurações")
	
func _on_ws_error(msg: String) -> void:
	print("Falha no Matchmaking: ", msg)
	play_btn.disabled = false
	play_btn.text = "Jogar"
