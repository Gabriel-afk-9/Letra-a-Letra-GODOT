extends Control
class_name MatchmakingScreen

@onready var play_button: Button = $PlayButton
@onready var cancel_button: Button = $CancelButton

@onready var my_player_card = $PlayersContainer/MyPlayerCard
@onready var opponent_player_card = $PlayersContainer/OpponentPlayerCard

@onready var status_label: Label = $StatusLabel
@onready var error_label: Label = $ErrorLabel

var _view_model: MatchmakingViewModel
var _navigation: NavigationService

func _ready() -> void:
	MatchmakingFactory.bind(self)

func setup(view_model: MatchmakingViewModel, navigation: NavigationService) -> void:
	_view_model = view_model
	_navigation = navigation
	
	_connect_view_model()
	_update_ui_for_state(MatchmakingViewModel.MatchmakingState.IDLE)

func _connect_view_model() -> void:
	_view_model.state_changed.connect(_on_state_changed)
	_view_model.opponent_found.connect(_on_opponent_found)
	_view_model.navigate_to_game.connect(_on_navigate_to_game)
	_view_model.error_changed.connect(_on_error_changed)


func _on_state_changed(state: int) -> void:
	_update_ui_for_state(state)

func _on_opponent_found(event: MatchmakingFoundEvent) -> void:
	my_player_card.show_local(event.me.nickname)
	opponent_player_card.show_opponent(event.opponent.nickname)
	
	#if has_node("AnimationPlayer"):
		#$AnimationPlayer.play("found")

func _on_navigate_to_game() -> void:
	_navigation.go_to(AppRoutes.GAME)

func _on_error_changed(message: String) -> void:
	if message.is_empty():
		error_label.hide()
		return
		
	error_label.show()
	error_label.text = message


func _update_ui_for_state(state: int) -> void:
	match state:
		MatchmakingViewModel.MatchmakingState.IDLE:
			play_button.show()
			play_button.disabled = false
			cancel_button.hide()
			status_label.text = "Pronto para jogar"
			
			opponent_player_card.clear()
			my_player_card.show_local("Você")

		MatchmakingViewModel.MatchmakingState.SEARCHING:
			play_button.hide()
			cancel_button.show()
			cancel_button.disabled = false
			status_label.text = "Procurando adversário..."
			
			opponent_player_card.show_searching()

		MatchmakingViewModel.MatchmakingState.FOUND:
			cancel_button.hide()
			status_label.text = "Oponente encontrado!"

		MatchmakingViewModel.MatchmakingState.CONNECTING:
			status_label.text = "Iniciando partida..."

		MatchmakingViewModel.MatchmakingState.ERROR:
			play_button.show()
			cancel_button.hide()
			status_label.text = "Erro ao procurar partida"


func _on_play_button_pressed() -> void:
	_view_model.start_search()

func _on_cancel_button_pressed() -> void:
	_view_model.cancel_search()
