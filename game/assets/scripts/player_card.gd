extends PanelContainer
class_name PlayerCard

enum CardState { CLEAR, SEARCHING, LOCAL, OPPONENT }

@export_group("Card Styles")
@export var local_style: StyleBoxFlat
@export var opponent_style: StyleBoxFlat
@export var searching_style: StyleBoxFlat

@export_group("Avatar Styles")
@export var local_avatar_style: StyleBoxFlat
@export var opponent_avatar_style: StyleBoxFlat
@export var searching_avatar_style: StyleBoxFlat

@onready var avatar_frame: PanelContainer = %AvatarFrame
@onready var avatar: TextureRect = %AvatarTexture
@onready var spinner: Spinner = %Spinner
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
			spinner.status = Spinner.Status.EMPTY

		CardState.SEARCHING:
			show()
			spinner.show()
			avatar.hide()
			nickname.text = "......"
			_apply_style(searching_style, searching_avatar_style)
			spinner.status = Spinner.Status.SPINNING

		CardState.LOCAL:
			show()
			spinner.hide()
			avatar.show()
			_apply_style(local_style, local_avatar_style)
			spinner.status = Spinner.Status.EMPTY

		CardState.OPPONENT:
			show()
			spinner.hide()
			avatar.show()
			_apply_style(opponent_style, opponent_avatar_style)
			spinner.status = Spinner.Status.EMPTY


func _apply_style(
	card_style: StyleBoxFlat,
	avatar_style: StyleBoxFlat
) -> void:
	if card_style:
		add_theme_stylebox_override("panel", card_style)

	if avatar_style:
		avatar_frame.add_theme_stylebox_override("panel", avatar_style)
