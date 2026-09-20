extends VBoxContainer
class_name PlayerInfoBar

const CARD_FADE_DURATION := 0.2
const DOT_FILLED_BG := Color(1, 1, 1, 0.95)
const DOT_EMPTY_BG := Color(0.5, 0.5, 0.5, 0.6)

@onready var my_card_wrapper: Control = $CardsCenter/MyCardWrapper
@onready var opponent_card_wrapper: Control = $CardsCenter/OpponentCardWrapper
@onready var my_player_card = $CardsCenter/MyCardWrapper/MyPlayerCard
@onready var my_power_dots: HBoxContainer = $CardsCenter/MyCardWrapper/MyPowerDots
@onready var opponent_player_card = $CardsCenter/OpponentCardWrapper/OpponentPlayerCard
@onready var opponent_power_dots: HBoxContainer = $CardsCenter/OpponentCardWrapper/OpponentPowerDots
@onready var turn_label: Label = $TurnLabel

var _cards_fade_tween: Tween
var _my_nickname: String = ""
var _opponent_nickname: String = ""
var _my_avatar: Texture2D = null
var _opponent_avatar: Texture2D = null
var _is_my_turn: bool = false
var _seconds_remaining: float = 0.0
var _my_dots: Array = []
var _opponent_dots: Array = []


func _ready() -> void:
	_my_dots = my_power_dots.get_children() if is_instance_valid(my_power_dots) and my_power_dots != null else []
	_opponent_dots = opponent_power_dots.get_children() if is_instance_valid(opponent_power_dots) and opponent_power_dots != null else []
	_shrink_game_cards()


func _shrink_game_cards() -> void:
	for card in [my_player_card, opponent_player_card]:
		if card is PlayerCard:
			(card as PlayerCard).custom_minimum_size = Vector2(220, 70)
			var avatar_tex: TextureRect = (card as PlayerCard).get_node_or_null("%AvatarTexture") as TextureRect
			if avatar_tex:
				avatar_tex.custom_minimum_size = Vector2(60, 60)
			var spinner = (card as PlayerCard).get_node_or_null("%Spinner")
			if spinner is Control:
				(spinner as Control).custom_minimum_size = Vector2(60, 60)
			var margin_c := (card as PlayerCard).get_node_or_null("MarginContainer") as MarginContainer
			if margin_c:
				margin_c.add_theme_constant_override("margin_left", 4)
				margin_c.add_theme_constant_override("margin_top", 4)
				margin_c.add_theme_constant_override("margin_right", 4)
				margin_c.add_theme_constant_override("margin_bottom", 4)
				var hbox := margin_c.get_node_or_null("HBoxContainer") as HBoxContainer
				if hbox:
					hbox.add_theme_constant_override("separation", 12)
			var nick: Label = (card as PlayerCard).get_node_or_null("%NicknameLabel") as Label
			if nick:
				nick.add_theme_font_size_override("font_size", 13)
				nick.add_theme_constant_override("outline_size", 2)


func setup_players(my_nickname: String, opponent_nickname: String, my_avatar: Texture2D = null, opponent_avatar: Texture2D = null) -> void:
	_my_nickname = my_nickname
	_opponent_nickname = opponent_nickname
	_my_avatar = my_avatar
	_opponent_avatar = opponent_avatar
	_update_player_cards()


func set_my_avatar(texture: Texture2D) -> void:
	_my_avatar = texture
	_update_player_cards()


func set_opponent_avatar(texture: Texture2D) -> void:
	_opponent_avatar = texture
	_update_player_cards()


func set_turn(is_my_turn: bool) -> void:
	_is_my_turn = is_my_turn
	_update_player_cards()
	_update_turn_label()


func set_turn_seconds(seconds_remaining: float) -> void:
	_seconds_remaining = seconds_remaining
	_update_turn_label()


func set_my_inventory(inventory: Array) -> void:
	if my_player_card != null and my_player_card.has_method("set_power_dots"):
		my_player_card.set_power_dots(inventory)
		return
	_update_power_dots(_my_dots, inventory)


func set_opponent_inventory(inventory: Array) -> void:
	if opponent_player_card != null and opponent_player_card.has_method("set_power_dots"):
		opponent_player_card.set_power_dots(inventory)
		return
	_update_power_dots(_opponent_dots, inventory)


func _update_player_cards() -> void:
	if is_instance_valid(my_power_dots):
		my_power_dots.hide()
	if is_instance_valid(opponent_power_dots):
		opponent_power_dots.hide()
	var appearing_wrapper: Control = my_card_wrapper if _is_my_turn else opponent_card_wrapper
	if _is_my_turn:
		if my_player_card.has_method("show_local"):
			my_player_card.show_local(_my_nickname, _my_avatar)
		if opponent_player_card.has_method("clear"):
			opponent_player_card.clear()
	else:
		if opponent_player_card.has_method("show_opponent"):
			opponent_player_card.show_opponent(_opponent_nickname, _opponent_avatar)
		if my_player_card.has_method("clear"):
			my_player_card.clear()
	if is_instance_valid(_cards_fade_tween) and _cards_fade_tween.is_valid():
		_cards_fade_tween.kill()
	if is_instance_valid(appearing_wrapper):
		appearing_wrapper.modulate.a = 0.0
		_cards_fade_tween = create_tween()
		_cards_fade_tween.tween_property(appearing_wrapper, "modulate:a", 1.0, CARD_FADE_DURATION)


func _update_turn_label() -> void:
	if not is_instance_valid(turn_label):
		return
	var seconds := int(_seconds_remaining)
	if _is_my_turn:
		turn_label.text = "Sua vez — %ds" % seconds
	else:
		turn_label.text = "Vez do oponente — %ds" % seconds


func _count_occupied(inventory: Array) -> int:
	var occupied := 0
	for power in inventory:
		if power is GamePower:
			occupied += 1
	return occupied


func _update_power_dots(dots: Array, inventory: Array) -> void:
	var occupied := _count_occupied(inventory)
	for index in dots.size():
		var dot_variant = dots[index]
		if not dot_variant is Panel:
			continue
		var dot: Panel = dot_variant
		var was_occupied: bool = dot.has_meta("occupied") and bool(dot.get_meta("occupied"))
		var is_occupied: bool = index < occupied
		dot.set_meta("occupied", is_occupied)
		if is_occupied and not was_occupied:
			_ensure_dot_style(dot, DOT_FILLED_BG)
			_pulse_dot(dot)
		elif not is_occupied and was_occupied:
			_ensure_dot_style(dot, DOT_FILLED_BG)
			_fade_dot(dot)
		else:
			var bg := DOT_FILLED_BG if is_occupied else DOT_EMPTY_BG
			_ensure_dot_style(dot, bg)


func _ensure_dot_style(dot: Panel, bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLACK
	style.bg_color = bg
	dot.add_theme_stylebox_override("panel", style)
	dot.scale = Vector2.ONE
	dot.modulate = Color.WHITE


func _pulse_dot(dot: Panel) -> void:
	dot.pivot_offset = dot.size / 2.0
	if dot.size == Vector2.ZERO:
		dot.pivot_offset = Vector2(8, 8)
	if dot.has_meta("dot_tween"):
		var old = dot.get_meta("dot_tween")
		if old is Tween and old.is_valid():
			old.kill()
	var tween := create_tween()
	dot.set_meta("dot_tween", tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "scale", Vector2(1.45, 1.45), 0.16)
	tween.tween_property(dot, "scale", Vector2.ONE, 0.22)
	tween.parallel().tween_property(dot, "modulate", Color(1, 0.9, 0.4, 1), 0.16)
	tween.parallel().tween_property(dot, "modulate", Color.WHITE, 0.22)
	var dot_id_pulse := dot.get_instance_id()
	var tween_id_pulse := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var d: Control = instance_from_id(dot_id_pulse) as Control
		if not is_instance_valid(d):
			return
		if not d.has_meta("dot_tween"):
			return
		var cur: Variant = d.get_meta("dot_tween")
		if cur == null or not is_instance_valid(cur as Object):
			d.remove_meta("dot_tween")
			return
		if (cur as Object).get_instance_id() != tween_id_pulse:
			return
		d.remove_meta("dot_tween")
	)


func _fade_dot(dot: Panel) -> void:
	dot.pivot_offset = dot.size / 2.0
	if dot.size == Vector2.ZERO:
		dot.pivot_offset = Vector2(8, 8)
	if dot.has_meta("dot_tween"):
		var old = dot.get_meta("dot_tween")
		if old is Tween and old.is_valid():
			old.kill()
	var style := dot.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.BLACK
		style.bg_color = DOT_FILLED_BG
		dot.add_theme_stylebox_override("panel", style)
	var tween := create_tween()
	dot.set_meta("dot_tween", tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(dot, "scale", Vector2(0.85, 0.85), 0.18)
	tween.tween_property(dot, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(style, "bg_color", DOT_EMPTY_BG, 0.18)
	var dot_id_fade := dot.get_instance_id()
	var tween_id_fade := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var d: Control = instance_from_id(dot_id_fade) as Control
		if not is_instance_valid(d):
			return
		if not d.has_meta("dot_tween"):
			return
		var cur: Variant = d.get_meta("dot_tween")
		if cur == null or not is_instance_valid(cur as Object):
			d.remove_meta("dot_tween")
			return
		if (cur as Object).get_instance_id() != tween_id_fade:
			return
		d.remove_meta("dot_tween")
	)
