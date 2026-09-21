extends VBoxContainer
class_name PlayerInfoBar

@onready var my_card_wrapper: Control = $CardsRow/MyCardWrapper
@onready var opponent_card_wrapper: Control = $CardsRow/OpponentCardWrapper
@onready var my_player_card: PlayerCard = $CardsRow/MyCardWrapper/MyPlayerCard
@onready var opponent_player_card: PlayerCard = $CardsRow/OpponentCardWrapper/OpponentPlayerCard
@onready var timer_label: Label = %TimerLabel
@onready var timer_circle: PanelContainer = $CardsRow/TimerCenter/TimerCircle
@onready var turn_label: Label = $TurnLabel

const HIGHLIGHT_DURATION := 0.15

var _my_nickname: String = ""
var _opponent_nickname: String = ""
var _my_avatar: Texture2D = null
var _opponent_avatar: Texture2D = null
var _is_my_turn: bool = false
var _seconds_remaining: float = 30.0
var _my_inventory: Array = []
var _opponent_inventory: Array = []


func _ready() -> void:
	_shrink_game_cards()


func _shrink_game_cards() -> void:
	for card in [my_player_card, opponent_player_card]:
		if card is PlayerCard:
			(card as PlayerCard).set_compact(true)


func setup_players(my_nickname: String, opponent_nickname: String, my_avatar: Texture2D = null, opponent_avatar: Texture2D = null) -> void:
	_my_nickname = my_nickname
	_opponent_nickname = opponent_nickname
	_my_avatar = my_avatar
	_opponent_avatar = opponent_avatar
	_update_player_cards()
	_apply_turn_highlight(false)


func set_my_avatar(texture: Texture2D) -> void:
	_my_avatar = texture
	if is_instance_valid(my_player_card):
		my_player_card.set_avatar_texture(texture)


func set_opponent_avatar(texture: Texture2D) -> void:
	_opponent_avatar = texture
	if is_instance_valid(opponent_player_card):
		opponent_player_card.set_avatar_texture(texture)


func set_turn(is_my_turn: bool) -> void:
	var changed := _is_my_turn != is_my_turn
	_is_my_turn = is_my_turn
	_apply_turn_highlight(changed)
	_update_turn_label()


func set_turn_seconds(seconds_remaining: float) -> void:
	_seconds_remaining = seconds_remaining
	_update_turn_label()
	if _seconds_remaining <= 10.0 and _seconds_remaining > 0:
		_pulse_timer()


func set_my_inventory(inventory: Array) -> void:
	_my_inventory = inventory
	if is_instance_valid(my_player_card):
		my_player_card.set_power_dots(inventory)


func set_opponent_inventory(inventory: Array) -> void:
	_opponent_inventory = inventory
	if is_instance_valid(opponent_player_card):
		opponent_player_card.set_power_dots(inventory)


func _update_player_cards() -> void:
	if is_instance_valid(my_player_card):
		my_player_card.show_local(_my_nickname, _my_avatar)
		my_player_card.set_power_dots(_my_inventory)
	if is_instance_valid(opponent_player_card):
		opponent_player_card.show_opponent(_opponent_nickname, _opponent_avatar)
		opponent_player_card.set_power_dots(_opponent_inventory)


func _apply_turn_highlight(animated: bool) -> void:
	var tween := create_tween() if animated else null
	if tween:
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for wrapper in [my_card_wrapper, opponent_card_wrapper]:
		if not is_instance_valid(wrapper):
			continue
		var is_active: bool = (wrapper == my_card_wrapper and _is_my_turn) or (wrapper == opponent_card_wrapper and not _is_my_turn)
		wrapper.modulate = Color.WHITE if is_active else Color(1, 1, 1, 0.92)
		if tween:
			wrapper.scale = Vector2.ONE
			tween.parallel().tween_property(wrapper, "scale", Vector2(1.02, 1.02) if is_active else Vector2.ONE, HIGHLIGHT_DURATION)


func _pulse_timer() -> void:
	if not is_instance_valid(timer_circle):
		return
	if timer_circle.has_meta("pulse_tween"):
		var old = timer_circle.get_meta("pulse_tween")
		if old is Tween and old.is_valid():
			return
	var tween := create_tween()
	timer_circle.set_meta("pulse_tween", tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(timer_circle, "scale", Vector2(1.12, 1.12), 0.12)
	tween.tween_property(timer_circle, "scale", Vector2.ONE, 0.14)
	var cid := timer_circle.get_instance_id()
	var tid := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var c: Control = instance_from_id(cid) as Control
		if not is_instance_valid(c):
			return
		if not c.has_meta("pulse_tween"):
			return
		var cur = c.get_meta("pulse_tween")
		if cur == null or not is_instance_valid(cur as Object):
			c.remove_meta("pulse_tween")
			return
		if (cur as Object).get_instance_id() != tid:
			return
		c.remove_meta("pulse_tween")
	)


func _update_turn_label() -> void:
	if not is_instance_valid(timer_label):
		return
	var seconds := int(max(0.0, _seconds_remaining))
	timer_label.text = str(seconds)
	if is_instance_valid(turn_label) and turn_label.visible:
		if _is_my_turn:
			turn_label.text = "Sua vez — %ds" % seconds
		else:
			turn_label.text = "Vez do oponente — %ds" % seconds
