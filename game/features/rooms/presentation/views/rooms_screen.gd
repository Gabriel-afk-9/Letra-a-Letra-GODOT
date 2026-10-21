extends HubPage
class_name RoomsScreen

const PAGE_SIZE := 6

const NAVY := Color(0.118, 0.165, 0.267)
const INK := Color(0.145, 0.184, 0.251)
const MUTED := Color(0.4, 0.45, 0.53)
const SELECT_ORANGE := Color(0.96, 0.51, 0.12)

const CARD_BG_WAITING := Color(0.898, 0.957, 0.914)
const CARD_BG_RUNNING := Color(0.882, 0.937, 0.973)
const CARD_BG_IDLE := Color(0.929, 0.937, 0.949)
const ACCENT_WAITING := Color(0.145, 0.573, 0.325)
const ACCENT_RUNNING := Color(0.098, 0.478, 0.733)
const ACCENT_IDLE := Color(0.42, 0.45, 0.51)

const TAP_SLOP := 12.0
const CARD_RADIUS := 16
const CARD_BORDER := 4
const CARD_BORDER_SELECTED := 6
const FOCUS_RING_COLOR := Color(0.16, 0.6, 0.85)

const BASE_MARGIN_LEFT := 16
const BASE_MARGIN_TOP := 10
const BASE_MARGIN_RIGHT := 16
const BASE_MARGIN_BOTTOM := 8

const AUTO_REFRESH_SECONDS := 30.0

const ART_ROOM := preload("res://assets/images/icons/room-icon.png")

@onready var _center: MarginContainer = $Center
@onready var _feedback_label: Label = $Center/VBox/FeedbackLabel
@onready var _create_btn: Button = $Center/VBox/ActionsRow/CreateBtn
@onready var _code_btn: Button = $Center/VBox/ActionsRow/CodeBtn
@onready var _search_input: LineEdit = $Center/VBox/SearchRow/SearchInput
@onready var _search_btn: Button = $Center/VBox/SearchRow/SearchBtn
@onready var _rooms_scroll: ScrollContainer = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsScroll
@onready var _rooms_rows: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsScroll/RoomsRows
@onready var _rooms_status: Label = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsStatusLabel
@onready var _page_label: Label = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PrevBtn
@onready var _next_btn: Button = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/NextBtn
@onready var _refresh_btn: Button = $TopCorner/RefreshBtn
@onready var _create_popup: Control = $CreatePopup
@onready var _create_name_input: LineEdit = $CreatePopup/Center/Card/Margin/Form/NameInput
@onready var _create_error: Label = $CreatePopup/Center/Card/Margin/Form/ErrorLabel
@onready var _create_spectators: ToggleSwitch = $CreatePopup/Center/Card/Margin/Form/SpectatorsRow/SpectatorsSwitch
@onready var _create_private: ToggleSwitch = $CreatePopup/Center/Card/Margin/Form/PrivateRow/PrivateSwitch
@onready var _create_cancel_btn: Button = $CreatePopup/Center/Card/Margin/Form/ButtonRow/CancelBtn
@onready var _create_confirm_btn: Button = $CreatePopup/Center/Card/Margin/Form/ButtonRow/ConfirmBtn
@onready var _create_dim: ColorRect = $CreatePopup/DimBackground
@onready var _code_popup: Control = $CodePopup
@onready var _code_input: LineEdit = $CodePopup/Center/Card/Margin/Form/CodeInput
@onready var _code_error: Label = $CodePopup/Center/Card/Margin/Form/ErrorLabel
@onready var _code_result: Label = $CodePopup/Center/Card/Margin/Form/ResultLabel
@onready var _code_cancel_btn: Button = $CodePopup/Center/Card/Margin/Form/ButtonRow/CancelBtn
@onready var _code_confirm_btn: Button = $CodePopup/Center/Card/Margin/Form/ButtonRow/ConfirmBtn
@onready var _code_dim: ColorRect = $CodePopup/DimBackground
@onready var _auto_refresh: Timer = $AutoRefreshTimer

var _view_model: RoomsViewModel
var _selected_game_id: String = ""
var _press_game_id: String = ""
var _press_position := Vector2.ZERO
var _spin_tween: Tween = null
var _focus_return: Control = null


func page_id() -> StringName:
	return &"rooms"


func enter(_params: Dictionary) -> void:
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()
	_auto_refresh.start(AUTO_REFRESH_SECONDS)
	_focus_default_control()


func exit() -> void:
	_auto_refresh.stop()
	close_popups()


func _ready() -> void:
	_view_model = RoomsFactory.create()
	_view_model.setup_page_size(PAGE_SIZE)
	_connect_view_model()
	_create_btn.pressed.connect(_on_create_pressed)
	_code_btn.pressed.connect(_on_code_pressed)
	_prev_btn.pressed.connect(_on_prev_pressed)
	_next_btn.pressed.connect(_on_next_pressed)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	_search_input.text_changed.connect(_on_search_text_changed)
	_search_btn.pressed.connect(_on_search_pressed)
	_search_input.text_submitted.connect(_on_search_submitted)
	_create_cancel_btn.pressed.connect(close_popups)
	_create_confirm_btn.pressed.connect(_on_create_confirm_pressed)
	_create_name_input.text_submitted.connect(_on_create_name_submitted)
	_create_dim.gui_input.connect(_on_popup_dim_gui_input)
	_code_cancel_btn.pressed.connect(close_popups)
	_code_confirm_btn.pressed.connect(_on_code_confirm_pressed)
	_code_input.text_submitted.connect(_on_code_submitted)
	_code_dim.gui_input.connect(_on_popup_dim_gui_input)
	_auto_refresh.timeout.connect(_on_auto_refresh)
	_setup_focus_chain()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_refresh_rooms()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _create_popup.visible or _code_popup.visible:
		close_popups()
		get_viewport().set_input_as_handled()


func _connect_view_model() -> void:
	_view_model.rooms_changed.connect(_refresh_rooms)
	_view_model.rooms_busy_changed.connect(_on_rooms_busy_changed)
	_view_model.action_changed.connect(_on_action_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.notice_changed.connect(_on_notice_changed)
	_view_model.room_created.connect(_on_room_created)
	_view_model.create_failed.connect(_on_create_failed)
	_view_model.room_joined.connect(_on_room_joined)
	_view_model.join_failed.connect(_on_join_failed)


func _setup_focus_chain() -> void:
	_create_btn.focus_neighbor_right = _create_btn.get_path_to(_code_btn)
	_create_btn.focus_neighbor_bottom = _create_btn.get_path_to(_search_input)
	_code_btn.focus_neighbor_left = _code_btn.get_path_to(_create_btn)
	_code_btn.focus_neighbor_bottom = _code_btn.get_path_to(_search_input)
	_search_input.focus_neighbor_top = _search_input.get_path_to(_create_btn)
	_search_input.focus_neighbor_bottom = _search_input.get_path_to(_search_btn)
	_search_btn.focus_neighbor_left = _search_btn.get_path_to(_search_input)
	_search_btn.focus_neighbor_top = _search_btn.get_path_to(_code_btn)
	_refresh_btn.focus_neighbor_bottom = _refresh_btn.get_path_to(_create_btn)
	_prev_btn.focus_neighbor_right = _prev_btn.get_path_to(_next_btn)
	_next_btn.focus_neighbor_left = _next_btn.get_path_to(_prev_btn)


func _focus_default_control() -> void:
	await get_tree().process_frame
	if not is_visible_in_tree():
		return
	if _create_popup.visible or _code_popup.visible:
		return
	_create_btn.grab_focus()


func _apply_safe_area() -> void:
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	if window_size.x <= 0 or window_size.y <= 0:
		return
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var window_rect := Rect2i(Vector2i.ZERO, window_size)
	# A safe area do SO pode ser maior que a janela (ex.: monitor sem recorte),
	# por isso ela é interseccionada antes de virar margem.
	var safe := DisplayServer.get_display_safe_area().intersection(window_rect)
	if safe.size.x <= 0 or safe.size.y <= 0:
		return
	var scale_x := viewport_size.x / float(window_size.x)
	var scale_y := viewport_size.y / float(window_size.y)
	var inset_left := int(round(safe.position.x * scale_x))
	var inset_top := int(round(safe.position.y * scale_y))
	var inset_right := int(round((window_size.x - safe.end.x) * scale_x))
	var inset_bottom := int(round((window_size.y - safe.end.y) * scale_y))
	_center.add_theme_constant_override("margin_left", BASE_MARGIN_LEFT + inset_left)
	_center.add_theme_constant_override("margin_top", BASE_MARGIN_TOP + inset_top)
	_center.add_theme_constant_override("margin_right", BASE_MARGIN_RIGHT + inset_right)
	_center.add_theme_constant_override("margin_bottom", BASE_MARGIN_BOTTOM + inset_bottom)


func close_popups() -> void:
	var had_popup := false
	if is_instance_valid(_create_popup) and _create_popup.visible:
		_create_popup.hide()
		had_popup = true
	if is_instance_valid(_code_popup) and _code_popup.visible:
		_code_popup.hide()
		had_popup = true
	get_viewport().gui_release_focus()
	if had_popup and is_visible_in_tree() and is_instance_valid(_focus_return):
		_focus_return.grab_focus()
	_focus_return = null


func _refresh_rooms() -> void:
	var scroll_offset := _rooms_scroll.scroll_vertical
	for child in _rooms_rows.get_children():
		_rooms_rows.remove_child(child)
		child.queue_free()
	var rooms := _view_model.rooms()
	_reconcile_selection(rooms)
	var locked := not _view_model.action_id().is_empty()
	var joining := _view_model.is_joining()
	for item_variant in rooms:
		var room := item_variant as Room
		if room != null:
			_rooms_rows.add_child(_make_room_card(room, room.game_id == _selected_game_id, joining, locked))
	_rooms_scroll.scroll_vertical = scroll_offset
	_refresh_status(rooms)
	_refresh_pager()
	_refresh_buttons()


func _refresh_status(rooms: Array) -> void:
	var busy := _view_model.is_rooms_busy()
	var failed := _view_model.rooms_failed()
	var empty := rooms.is_empty()
	var message := ""
	if busy:
		if _view_model.mode() == RoomsViewModel.MODE_SEARCH:
			message = "Buscando..."
		else:
			message = "Carregando salas..."
	elif failed:
		message = "Não foi possível carregar. Tente de novo."
	elif empty:
		if _view_model.mode() == RoomsViewModel.MODE_SEARCH:
			message = "Nenhuma sala encontrada para \"%s\"." % _view_model.search_term()
		else:
			message = "Nenhuma sala pública no momento."
	_rooms_status.text = message
	if empty:
		_rooms_rows.add_child(_make_empty_state(message, busy))
	_rooms_status.visible = not empty and not message.is_empty()


func _make_empty_state(message: String, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 120)
	box.add_child(spacer)
	if not busy:
		var holder := CenterContainer.new()
		box.add_child(holder)
		var icon := TextureRect.new()
		icon.texture = ART_ROOM
		icon.custom_minimum_size = Vector2(88, 88)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(0.118, 0.165, 0.267, 0.22)
		holder.add_child(icon)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 15)
	box.add_child(label)
	return box


func _reconcile_selection(rooms: Array) -> void:
	if _selected_game_id.is_empty():
		return
	for item_variant in rooms:
		var room := item_variant as Room
		if room != null and room.game_id == _selected_game_id:
			return
	_selected_game_id = ""


func _selected_room() -> Room:
	if _selected_game_id.is_empty():
		return null
	for item_variant in _view_model.rooms():
		var room := item_variant as Room
		if room != null and room.game_id == _selected_game_id:
			return room
	return null


func _refresh_pager() -> void:
	_page_label.text = "Pág %d" % (_view_model.page() + 1)
	_prev_btn.disabled = _view_model.page() <= 0 or _view_model.is_rooms_busy()
	_next_btn.disabled = _view_model.page() >= _view_model.total_pages() - 1 or _view_model.is_rooms_busy()


func _refresh_buttons() -> void:
	var locked := not _view_model.action_id().is_empty()
	var busy := _view_model.is_rooms_busy()
	_search_btn.disabled = busy or locked
	_search_input.editable = not busy and not locked
	_refresh_btn.disabled = busy or locked
	_create_btn.disabled = busy or locked
	_code_btn.disabled = busy or locked
	for card in _rooms_rows.get_children():
		_apply_row_lock(card, locked)
	_refresh_pager()


func _apply_row_lock(row: Node, locked: bool) -> void:
	for btn_variant in row.find_children("*", "Button", true, false):
		(btn_variant as Button).disabled = locked


func _make_room_card(room: Room, selected: bool, joining: bool, locked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("game_id", room.game_id)
	card.set_meta("room", room)
	card.add_theme_stylebox_override("panel", _card_style(room, selected))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var accent := PanelContainer.new()
	accent.custom_minimum_size = Vector2(6, 40)
	accent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.add_theme_stylebox_override("panel", _accent_style(room))
	row.add_child(accent)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 3)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var title_label := Label.new()
	title_label.text = room.display_name()
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_color_override("font_color", INK)
	title_label.add_theme_font_size_override("font_size", 17)
	info.add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = _room_subtitle(room)
	sub_label.clip_text = true
	sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_label.add_theme_color_override("font_color", MUTED)
	sub_label.add_theme_font_size_override("font_size", 13)
	info.add_child(sub_label)

	var side := VBoxContainer.new()
	side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	side.add_theme_constant_override("separation", 6)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("side", side)
	row.add_child(side)

	var chip := _make_chip(_status_chip_text(room), _accent_color(room))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	side.add_child(chip)

	if selected:
		side.add_child(_make_join_btn(joining, locked, room.game_id))

	var ring := _make_focus_ring()
	card.add_child(ring)
	card.focus_entered.connect(func() -> void: ring.visible = true)
	card.focus_exited.connect(func() -> void: ring.visible = false)

	card.gui_input.connect(_on_card_gui_input.bind(room.game_id))
	return card


func _make_chip(text: String, color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.content_margin_left = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 4.0
	sb.set_corner_radius_all(9)
	chip.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 11)
	chip.add_child(label)
	return chip


func _make_focus_ring() -> PanelContainer:
	# Oanel de foco é um overlay sem mouse filter, desenhado por cima do card
	# para não alterar a cor da borda usada para indicar seleção.
	var ring := PanelContainer.new()
	ring.visible = false
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = FOCUS_RING_COLOR
	sb.set_corner_radius_all(CARD_RADIUS + 2)
	sb.expand_margin_left = 3.0
	sb.expand_margin_top = 3.0
	sb.expand_margin_right = 3.0
	sb.expand_margin_bottom = 3.0
	ring.add_theme_stylebox_override("panel", sb)
	return ring


func _make_join_btn(joining: bool, locked: bool, game_id: String) -> Button:
	var btn := Button.new()
	btn.name = "JoinBtn"
	btn.text = "Entrando..." if joining else "Entrar"
	btn.custom_minimum_size = Vector2(104, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_stylebox_override("normal", _pill_style(SELECT_ORANGE))
	btn.add_theme_stylebox_override("hover", _pill_style(SELECT_ORANGE.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", _pill_style(SELECT_ORANGE.darkened(0.15)))
	btn.add_theme_stylebox_override("disabled", _pill_style(Color(0.62, 0.65, 0.7)))
	btn.add_theme_stylebox_override("focus", _focus_style(SELECT_ORANGE))
	btn.disabled = locked
	btn.pressed.connect(_on_join_pressed.bind(game_id))
	return btn


func _pill_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = NAVY
	sb.set_corner_radius_all(12)
	return sb


func _focus_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = color
	sb.set_corner_radius_all(14)
	sb.expand_margin_left = 3.0
	sb.expand_margin_top = 3.0
	sb.expand_margin_right = 3.0
	sb.expand_margin_bottom = 3.0
	return sb


func _card_style(room: Room, selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _card_color_for(room)
	sb.border_width_left = CARD_BORDER_SELECTED if selected else CARD_BORDER
	sb.border_width_top = CARD_BORDER_SELECTED if selected else CARD_BORDER
	sb.border_width_right = CARD_BORDER_SELECTED if selected else CARD_BORDER
	sb.border_width_bottom = CARD_BORDER_SELECTED if selected else CARD_BORDER
	sb.border_color = SELECT_ORANGE if selected else Color.BLACK
	sb.set_corner_radius_all(CARD_RADIUS)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 4 if selected else 2
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _accent_style(room: Room) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _accent_color(room)
	sb.set_corner_radius_all(4)
	return sb


func _card_color_for(room: Room) -> Color:
	match room.status:
		Room.STATUS_WAITING:
			return CARD_BG_WAITING
		Room.STATUS_RUNNING:
			return CARD_BG_RUNNING
	return CARD_BG_IDLE


func _accent_color(room: Room) -> Color:
	match room.status:
		Room.STATUS_WAITING:
			return ACCENT_WAITING
		Room.STATUS_RUNNING:
			return ACCENT_RUNNING
	return ACCENT_IDLE


func _status_chip_text(room: Room) -> String:
	match room.status:
		Room.STATUS_WAITING:
			return "AGUARDANDO"
		Room.STATUS_RUNNING:
			return "EM ANDAMENTO"
		Room.STATUS_CLOSED:
			return "FECHADA"
		Room.STATUS_CANCELED:
			return "CANCELADA"
	return room.status_label().to_upper()


func _room_subtitle(room: Room) -> String:
	var count := room.players_count()
	var people := "1 participante" if count == 1 else "%d participantes" % count
	return "por %s  •  %s" % [room.host_name(), people]


func _on_card_gui_input(event: InputEvent, game_id: String) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press_game_id = game_id
			_press_position = mb.position
		elif _press_game_id == game_id and _press_position.distance_to(mb.position) <= TAP_SLOP:
			_press_game_id = ""
			_select_room(game_id)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_game_id = game_id
			_press_position = touch.position
		elif _press_game_id == game_id and _press_position.distance_to(touch.position) <= TAP_SLOP:
			_press_game_id = ""
			_select_room(game_id)
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.is_action_pressed("ui_accept"):
			_select_room(game_id)
			accept_event()


func _select_room(game_id: String) -> void:
	if _view_model.is_rooms_busy() or not _view_model.action_id().is_empty():
		return
	if _selected_game_id == game_id:
		_focus_join_button(game_id)
		return
	_selected_game_id = game_id
	_clear_feedback()
	_update_card_selection()
	_refresh_buttons()


func _update_card_selection() -> void:
	# A seleção é aplicada nos cards já existentes para não recriar a lista
	# (evita perder o scroll e o foco a cada toque).
	var locked := not _view_model.action_id().is_empty()
	var joining := _view_model.is_joining()
	for card in _rooms_rows.get_children():
		var room := card.get_meta("room", null) as Room
		if room == null:
			continue
		var selected := room.game_id == _selected_game_id
		card.add_theme_stylebox_override("panel", _card_style(room, selected))
		var side := card.get_meta("side", null) as VBoxContainer
		if side == null:
			continue
		var join_btn := side.get_node_or_null("JoinBtn") as Button
		if selected and join_btn == null:
			var btn := _make_join_btn(joining, locked, room.game_id)
			side.add_child(btn)
			if card.has_focus():
				btn.grab_focus()
		elif not selected and join_btn != null:
			side.remove_child(join_btn)
			join_btn.queue_free()
		elif join_btn != null:
			join_btn.text = "Entrando..." if joining else "Entrar"
			join_btn.disabled = locked


func _focus_join_button(game_id: String) -> void:
	for card in _rooms_rows.get_children():
		if str(card.get_meta("game_id", "")) != game_id:
			continue
		var side := card.get_meta("side", null) as VBoxContainer
		if side == null:
			return
		var join_btn := side.get_node_or_null("JoinBtn") as Button
		if join_btn != null:
			join_btn.grab_focus()
		return


func _on_join_pressed(game_id: String) -> void:
	if _view_model.is_joining():
		return
	_selected_game_id = game_id
	var room := _selected_room()
	if room == null:
		_refresh_rooms()
		return
	_clear_feedback()
	var result: Dictionary = _view_model.join_room(room.game_id)
	if not is_inside_tree():
		return
	if result.has("error"):
		var message := str(result["error"])
		if message.is_empty():
			return
		_show_feedback_error(message)
		_refresh_rooms()


func _on_room_joined(_room: Room) -> void:
	_selected_game_id = ""
	_refresh_rooms()


func _on_join_failed(message: String) -> void:
	_show_feedback_error(message)
	_refresh_rooms()


func _on_prev_pressed() -> void:
	_view_model.prev_page()


func _on_next_pressed() -> void:
	_view_model.next_page()


func _on_refresh_pressed() -> void:
	_view_model.refresh_current()


func _on_auto_refresh() -> void:
	if _view_model.is_rooms_busy():
		return
	if _create_popup.visible or _code_popup.visible:
		return
	_view_model.refresh_current()


func _on_search_text_changed(new_text: String) -> void:
	if new_text.strip_edges().is_empty() and _view_model.mode() == RoomsViewModel.MODE_SEARCH:
		_view_model.clear_search()


func _on_search_pressed() -> void:
	var clean := _search_input.text.strip_edges()
	if clean.is_empty():
		_view_model.clear_search()
	else:
		_view_model.search_rooms(clean)


func _on_search_submitted(_text: String) -> void:
	_on_search_pressed()


func _on_create_pressed() -> void:
	_code_popup.hide()
	_create_name_input.text = ""
	_create_spectators.set_value(true, true)
	_create_private.set_value(false, true)
	_create_error.hide()
	_set_create_loading(false)
	_focus_return = _create_btn
	_create_popup.show()
	await get_tree().process_frame
	if is_instance_valid(_create_name_input):
		_create_name_input.grab_focus()


func _on_create_name_submitted(_text: String) -> void:
	_on_create_confirm_pressed()


func _on_create_confirm_pressed() -> void:
	if _view_model.is_creating():
		return
	var clean := _create_name_input.text.strip_edges()
	if clean.is_empty():
		_create_name_input.shake()
		_create_name_input.grab_focus()
		_create_error.show()
		_create_error.show_error("Digite o nome da sala.")
		return
	_create_error.hide()
	_set_create_loading(true)
	var result: Dictionary = _view_model.create_room(
		clean,
		_create_spectators.is_on(),
		_create_private.is_on()
	)
	if not is_inside_tree():
		return
	if result.has("error"):
		_set_create_loading(false)
		var message := str(result["error"])
		if message.is_empty():
			return
		_create_name_input.shake()
		_create_error.show()
		_create_error.show_error(message)


func _set_create_loading(loading: bool) -> void:
	_create_confirm_btn.disabled = loading
	_create_cancel_btn.disabled = loading
	_create_name_input.editable = not loading
	_create_spectators.set_disabled(loading)
	_create_private.set_disabled(loading)
	_create_confirm_btn.text = "Criando..." if loading else "CRIAR"


func _on_room_created(_room: Room) -> void:
	_set_create_loading(false)
	close_popups()


func _on_create_failed(message: String) -> void:
	if not _create_popup.visible:
		return
	_set_create_loading(false)
	_create_error.show()
	_create_error.show_error(message)


func _on_code_pressed() -> void:
	_create_popup.hide()
	_code_input.text = ""
	_code_error.hide()
	_code_result.text = ""
	_focus_return = _code_btn
	_code_popup.show()
	await get_tree().process_frame
	if is_instance_valid(_code_input):
		_code_input.grab_focus()


func _on_code_submitted(_text: String) -> void:
	_on_code_confirm_pressed()


func _on_code_confirm_pressed() -> void:
	var clean := _code_input.text.strip_edges()
	if clean.is_empty():
		_code_input.shake()
		_code_input.grab_focus()
		_code_error.show()
		_code_error.show_error("Digite o código da sala.")
		return
	_code_error.hide()
	_code_result.text = ""
	_code_confirm_btn.disabled = true
	_code_cancel_btn.disabled = true
	_code_input.editable = false
	var result: Dictionary = await _view_model.find_by_code(clean)
	if not is_inside_tree():
		return
	_code_confirm_btn.disabled = false
	_code_cancel_btn.disabled = false
	_code_input.editable = true
	if result.has("error"):
		var message := str(result["error"])
		if not message.is_empty():
			_code_input.shake()
			_code_error.show()
			_code_error.show_error(message)
		return
	_code_result.text = "Sala encontrada! A entrada direta estará disponível em breve."


func _on_popup_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			close_popups()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			close_popups()


func _on_rooms_busy_changed(value: Variant) -> void:
	_set_spinning(bool(value))
	_refresh_rooms()


func _set_spinning(active: bool) -> void:
	if active:
		if _spin_tween != null and _spin_tween.is_valid():
			return
		_spin_tween = create_tween()
		_spin_tween.set_loops()
		_spin_tween.tween_property(_refresh_btn, "rotation", TAU, 0.9).from(0.0).set_trans(Tween.TRANS_LINEAR)
		return
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()
	_spin_tween = null
	_refresh_btn.rotation = 0.0


func _on_action_changed(_action_id: String) -> void:
	_refresh_buttons()


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		return
	_show_feedback_error(message)


func _on_notice_changed(message: String) -> void:
	_show_feedback_notice(message)


func _clear_feedback() -> void:
	_feedback_label.text = ""
	_feedback_label.visible = false


func _show_feedback_error(message: String) -> void:
	_feedback_label.visible = true
	_feedback_label.show_error(message)


func _show_feedback_notice(message: String) -> void:
	_feedback_label.text = message
	_feedback_label.visible = true
