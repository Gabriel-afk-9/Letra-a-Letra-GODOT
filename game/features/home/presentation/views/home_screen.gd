extends Control


@onready var profile_card: ProfileCard = $MarginContainer/MainLayout/Header/ProfileCard
@onready var setting_btn: Button = $MarginContainer/MainLayout/Header/SettingBtn
@onready var play_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/PlayBtn
@onready var room_btn: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/RoomBtn
@onready var exit_btn: Button = $MarginContainer/MainLayout/ExitButton

var _view_model: HomeViewModel

func _ready() -> void:
	_view_model = HomeFactory.create()
	_connect_view_model()
	_view_model.load_user()


func _connect_view_model() -> void:
	_view_model.user_loaded.connect(_on_user_loaded)
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)

func _on_user_loaded(user: User) -> void:
	profile_card.setup(user.nickname)

func _on_loading_changed(is_loading: bool) -> void:
	exit_btn.disabled = is_loading
	play_btn.disabled = is_loading
	room_btn.disabled = is_loading
	
func _on_play_btn_pressed() -> void:
	_view_model.go_to_matchmaking()

func _on_error_changed(message: String) -> void:
	if message.is_empty():
		return
	push_error("Erro na Home: " + message)
	
func _on_room_btn_pressed() -> void:
	_view_model.go_to_room()


func _on_avatar_pressed() -> void:
	# TODO: abrir galeria/modal de avatar (fora de escopo por enquanto)
	pass


func _on_settings_pressed() -> void:
	# TODO: abrir tela de configurações (fora de escopo por enquanto)
	pass


func _on_exit_button_pressed() -> void:
	_view_model.exit_game()
