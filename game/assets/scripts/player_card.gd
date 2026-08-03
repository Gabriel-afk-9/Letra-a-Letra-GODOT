extends PanelContainer
class_name PlayerCard

enum CardState { CLEAR, SEARCHING, LOCAL, OPPONENT }

@export var local_style: StyleBoxFlat
@export var opponent_style: StyleBoxFlat
@export var searching_style: StyleBoxFlat

@onready var avatar: TextureRect = %AvatarTexture
@onready var spinner: Control = %Spinner
@onready var nickname: Label = %NicknameLabel

var _current_state: CardState = CardState.CLEAR

func clear() -> void:
	_set_state(CardState.CLEAR)

func show_searching() -> void:
	_set_state(CardState.SEARCHING)

func show_local(player_name: String, avatar_texture: Texture2D = null) -> void:
	nickname.text = player_name
	if avatar_texture:
		avatar.texture = avatar_texture
	_set_state(CardState.LOCAL)

func show_opponent(player_name: String, avatar_texture: Texture2D = null) -> void:
	nickname.text = player_name
	if avatar_texture:
		avatar.texture = avatar_texture
	_set_state(CardState.OPPONENT)

func _set_state(new_state: CardState) -> void:
	_current_state = new_state
	
	match _current_state:
		CardState.CLEAR:
			hide()
			
		CardState.SEARCHING:
			show()
			spinner.show()
			avatar.hide()
			nickname.text = "......"
			if searching_style:
				add_theme_stylebox_override("panel", searching_style)
				
		CardState.LOCAL:
			show()
			spinner.hide()
			avatar.show()
			if local_style:
				add_theme_stylebox_override("panel", local_style)
				
		CardState.OPPONENT:
			show()
			spinner.hide()
			avatar.show()
			if opponent_style:
				add_theme_stylebox_override("panel", opponent_style)
