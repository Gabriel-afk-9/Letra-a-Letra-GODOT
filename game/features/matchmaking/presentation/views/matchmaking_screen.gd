extends Control
class_name MatchmakingScreen

@onready var cancel_button: Button = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/CancelButton

@onready var my_player_card = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/PlayersContainer/MyPlayerCard
@onready var opponent_player_card = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/PlayersContainer/OpponentPlayerCard

@onready var status_label: Label = $MarginContainer/MainLayout/CenterPanel/MarginContainer/ContentVBox/StatusLabel

var _view_model: MatchmakingViewModel


func _ready() -> void:
	MatchmakingFactory.bind(self)


func setup(view_model: MatchmakingViewModel) -> void:
	_view_model = view_model

	_connect_view_model()
	_update_local_player()
	_update_ui_for_state(MatchmakingViewModel.MatchmakingState.IDLE)

	_view_model.start_search()


# Internal — wiring

func _connect_view_model() -> void:
	if not _view_model.state_changed.is_connected(_on_state_changed):
		_view_model.state_changed.connect(_on_state_changed)

	if not _view_model.opponent_found.is_connected(_on_opponent_found):
		_view_model.opponent_found.connect(_on_opponent_found)

	if not _view_model.error_changed.is_connected(_on_error_changed):
		_view_model.error_changed.connect(_on_error_changed)


# Internal — reações a sinais

func _on_state_changed(state: MatchmakingViewModel.MatchmakingState) -> void:
	_update_ui_for_state(state)


func _on_opponent_found(event: MatchmakingFoundEvent) -> void:
	opponent_player_card.show_opponent(event.opponent.nickname)


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		return

	status_label.text = message


# Internal — UI

func _update_ui_for_state(state: MatchmakingViewModel.MatchmakingState) -> void:
	match state:
		MatchmakingViewModel.MatchmakingState.IDLE:
			cancel_button.hide()
			cancel_button.disabled = true
			status_label.text = "Pronto para jogar"
			opponent_player_card.clear()

		MatchmakingViewModel.MatchmakingState.SEARCHING:
			cancel_button.show()
			cancel_button.disabled = false
			status_label.text = "Procurando adversário..."
			opponent_player_card.show_searching()

		MatchmakingViewModel.MatchmakingState.FOUND:
			cancel_button.hide()
			cancel_button.disabled = true
			status_label.text = "Oponente encontrado!"

		MatchmakingViewModel.MatchmakingState.CONNECTING:
			status_label.text = "Iniciando partida..."

		MatchmakingViewModel.MatchmakingState.ERROR:
			cancel_button.show()
			cancel_button.disabled = false
			opponent_player_card.clear()


func _update_local_player() -> void:
	my_player_card.show_local(_view_model.current_player_nickname())


func _on_cancel_button_pressed() -> void:
	_view_model.cancel_search()
