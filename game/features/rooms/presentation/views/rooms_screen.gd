extends HubPage
class_name RoomsScreen

const PAGE_SIZE := 6
const NAVY := Color(0.118, 0.165, 0.267)
const TAB_BLUE := Color(0.16, 0.6, 0.85)
const TAB_GREEN := Color(0.2, 0.72, 0.42)
const SELECT_ORANGE := Color(0.96, 0.51, 0.12)
const ROW_RED := Color(0.78, 0.24, 0.24)
const SENT_GRAY := Color(0.55, 0.58, 0.62)
const CARD_BLUE := Color(0.105882354, 0.6156863, 0.87058824)
const CARD_GREEN := Color(0.23, 0.62, 0.32)

const ART_REFRESH := preload("res://assets/images/icons/refresh.png")

@onready var _feedback_label: Label = $Center/VBox/FeedbackLabel
@onready var _create_btn: Button = $Center/VBox/ActionsRow/CreateBtn
@onready var _code_btn: Button = $Center/VBox/ActionsRow/CodeBtn
@onready var _search_input: LineEdit = $Center/VBox/SearchRow/SearchInput
@onready var _search_btn: Button = $Center/VBox/SearchRow/SearchBtn
@onready var _rooms_rows: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsScroll/RoomsRows
@onready var _rooms_status: Label = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsStatusLabel
@onready var _page_label: Label = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PrevBtn
@onready var _next_btn: Button = $Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/NextBtn
@onready var _refresh_btn: Button = $TopCorner/RefreshBtn
@onready var _create_popup: Control = $CreatePopup
@onready var _create_name_input: LineEdit = $CreatePopup/Center/Card/Margin/Form/NameInput
@onready var _create_error: Label = $CreatePopup/Center/Card/Margin/Form/ErrorLabel
@onready var _create_spectators: CheckBox = $CreatePopup/Center/Card/Margin/Form/SpectatorsCheck
@onready var _create_private: CheckBox = $CreatePopup/Center/Card/Margin/Form/PrivateCheck
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

var _view_model: RoomsViewModel


func page_id() -> StringName:
	return &"rooms"


func enter(_params: Dictionary) -> void:
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()


func exit() -> void:
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
	_refresh_rooms()


func _connect_view_model() -> void:
	_view_model.rooms_changed.connect(_refresh_rooms)
	_view_model.rooms_busy_changed.connect(_on_rooms_busy_changed)
	_view_model.action_changed.connect(_on_action_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.notice_changed.connect(_on_notice_changed)
	_view_model.room_created.connect(_on_room_created)
	_view_model.create_failed.connect(_on_create_failed)


func close_popups() -> void:
	if is_instance_valid(_create_popup):
		_create_popup.hide()
	if is_instance_valid(_code_popup):
		_code_popup.hide()
	get_viewport().gui_release_focus()


func _refresh_rooms() -> void:
	for child in _rooms_rows.get_children():
		_rooms_rows.remove_child(child)
		child.queue_free()
	var rooms := _view_model.rooms()
	for item_variant in rooms:
		var room := item_variant as Room
		if room != null:
			_rooms_rows.add_child(_make_room_card(room))
	if _view_model.is_rooms_busy():
		if _view_model.mode() == RoomsViewModel.MODE_SEARCH:
			_rooms_status.text = "Buscando..."
		else:
			_rooms_status.text = "Carregando salas..."
	elif _view_model.rooms_failed():
		_rooms_status.text = "Não foi possível carregar. Tente de novo."
	elif rooms.is_empty():
		if _view_model.mode() == RoomsViewModel.MODE_SEARCH:
			_rooms_status.text = "Nenhuma sala encontrada para \"%s\"." % _view_model.search_term()
		else:
			_rooms_status.text = "Nenhuma sala pública no momento."
	else:
		_rooms_status.text = ""
	_refresh_pager()
	_refresh_buttons()


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


func _make_room_card(room: Room) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = _card_color_for(room)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color.BLACK
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	card.add_theme_stylebox_override("panel", sb)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	margin.add_child(info)
	var title_label := Label.new()
	title_label.text = room.display_name()
	title_label.clip_text = true
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.add_theme_font_size_override("font_size", 18)
	info.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = _room_subtitle(room)
	sub_label.clip_text = true
	sub_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	sub_label.add_theme_font_size_override("font_size", 13)
	info.add_child(sub_label)
	return card


func _card_color_for(room: Room) -> Color:
	match room.status:
		Room.STATUS_WAITING:
			return CARD_GREEN
		Room.STATUS_RUNNING:
			return CARD_BLUE
	return SENT_GRAY


func _room_subtitle(room: Room) -> String:
	var count := room.players_count()
	var people := "1 participante" if count == 1 else "%d participantes" % count
	return "por %s • %s • %s" % [room.host_name(), people, room.status_label()]


func _on_prev_pressed() -> void:
	_view_model.prev_page()


func _on_next_pressed() -> void:
	_view_model.next_page()


func _on_refresh_pressed() -> void:
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
	_create_spectators.button_pressed = true
	_create_private.button_pressed = false
	_create_error.hide()
	_set_create_loading(false)
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
		_create_spectators.button_pressed,
		_create_private.button_pressed
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
	_create_spectators.disabled = loading
	_create_private.disabled = loading
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


func _on_rooms_busy_changed(_value: Variant) -> void:
	_refresh_rooms()


func _on_action_changed(_action_id: String) -> void:
	_refresh_buttons()


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		return
	_feedback_label.show_error(message)


func _on_notice_changed(message: String) -> void:
	_feedback_label.text = message
