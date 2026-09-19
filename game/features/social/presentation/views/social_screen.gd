extends HubPage
class_name SocialScreen

enum Section { FRIENDS, PENDING, SENT, ADD }

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
@onready var _tab_buttons: Array = [
	$Center/VBox/TabsRow/FriendsTab,
	$Center/VBox/TabsRow/PendingTab,
	$Center/VBox/TabsRow/SentTab,
	$Center/VBox/TabsRow/AddTab,
]
@onready var _friends_section: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/FriendsSection
@onready var _pending_section: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/PendingSection
@onready var _sent_section: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/SentSection
@onready var _add_section: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/AddSection
@onready var _friends_rows: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/FriendsSection/FriendsRows
@onready var _refresh_btn: Button = $TopCorner/RefreshBtn
@onready var _friends_status: Label = $Center/VBox/ContentPanel/ContentMargin/FriendsSection/FriendsStatusLabel
@onready var _page_label: Label = $Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/PrevBtn
@onready var _next_btn: Button = $Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/NextBtn
@onready var _pending_rows: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/PendingSection/PendingRows
@onready var _pending_status: Label = $Center/VBox/ContentPanel/ContentMargin/PendingSection/PendingStatusLabel
@onready var _sent_rows: VBoxContainer = $Center/VBox/ContentPanel/ContentMargin/SentSection/SentRows
@onready var _sent_status: Label = $Center/VBox/ContentPanel/ContentMargin/SentSection/SentStatusLabel
@onready var _search_input: LineEdit = $Center/VBox/ContentPanel/ContentMargin/AddSection/SearchRow/SearchInput
@onready var _search_btn: Button = $Center/VBox/ContentPanel/ContentMargin/AddSection/SearchRow/SearchBtn
@onready var _discover_status: Label = $Center/VBox/ContentPanel/ContentMargin/AddSection/DiscoverStatusLabel
@onready var _user_grid: GridContainer = $Center/VBox/ContentPanel/ContentMargin/AddSection/UserScroll/UserGrid
@onready var _discover_label: Label = $Center/VBox/ContentPanel/ContentMargin/AddSection/DiscoverPagerRow/DiscoverPill/DiscoverMargin/DiscoverLabel
@onready var _discover_prev_btn: Button = $Center/VBox/ContentPanel/ContentMargin/AddSection/DiscoverPagerRow/DiscoverPrevBtn
@onready var _discover_next_btn: Button = $Center/VBox/ContentPanel/ContentMargin/AddSection/DiscoverPagerRow/DiscoverNextBtn

var _view_model: SocialViewModel
var _section: int = Section.FRIENDS


func page_id() -> StringName:
	return &"social"


func enter(_params: Dictionary) -> void:
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()


func _ready() -> void:
	_view_model = SocialFactory.create()
	_view_model.setup_page_size(PAGE_SIZE)
	_connect_view_model()
	for i in _tab_buttons.size():
		(_tab_buttons[i] as Button).pressed.connect(_on_tab_pressed.bind(i))
	_prev_btn.pressed.connect(_on_prev_pressed)
	_next_btn.pressed.connect(_on_next_pressed)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	_search_input.text_changed.connect(_on_search_text_changed)
	_discover_prev_btn.pressed.connect(_on_discover_prev_pressed)
	_discover_next_btn.pressed.connect(_on_discover_next_pressed)
	_search_btn.pressed.connect(_on_search_pressed)
	_search_input.text_submitted.connect(_on_search_submitted)
	_refresh_tabs()
	_refresh_sections()
	_refresh_friends()
	_refresh_pending()
	_refresh_sent()
	_refresh_discover()


func _connect_view_model() -> void:
	_view_model.friends_changed.connect(_refresh_friends)
	_view_model.pending_changed.connect(_refresh_pending)
	_view_model.sent_changed.connect(_refresh_sent)
	_view_model.discover_changed.connect(_refresh_discover)
	_view_model.friends_busy_changed.connect(_on_section_busy_changed)
	_view_model.pending_busy_changed.connect(_on_section_busy_changed)
	_view_model.sent_busy_changed.connect(_on_section_busy_changed)
	_view_model.discover_busy_changed.connect(_on_section_busy_changed)
	_view_model.action_changed.connect(_on_action_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.notice_changed.connect(_on_notice_changed)


func _on_tab_pressed(index: int) -> void:
	_section = index
	_feedback_label.text = ""
	_refresh_tabs()
	_refresh_sections()
	if _section == Section.ADD:
		_view_model.ensure_browse()


func _refresh_tabs() -> void:
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i] as Button
		var active: bool = i == _section
		var sb := StyleBoxFlat.new()
		sb.bg_color = TAB_BLUE if active else TAB_GREEN
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = NAVY
		sb.corner_radius_top_left = 14
		sb.corner_radius_top_right = 14
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.custom_minimum_size = Vector2(96, 52) if active else Vector2(72, 44)
		var box := btn.get_child(0)
		var icon := box.get_child(0) as TextureRect
		var label := box.get_child(1) as Label
		icon.custom_minimum_size = Vector2(26, 26) if active else Vector2(22, 22)
		label.add_theme_font_size_override("font_size", 16 if active else 11)


func _refresh_sections() -> void:
	_friends_section.visible = _section == Section.FRIENDS
	_pending_section.visible = _section == Section.PENDING
	_sent_section.visible = _section == Section.SENT
	_add_section.visible = _section == Section.ADD
	_refresh_btn.visible = _section != Section.ADD


func _refresh_friends() -> void:
	for child in _friends_rows.get_children():
		_friends_rows.remove_child(child)
		child.queue_free()
	var friends := _view_model.friends()
	for item_variant in friends:
		var friendship := item_variant as Friendship
		if friendship != null:
			_friends_rows.add_child(_make_friend_row(friendship))
	if _view_model.is_friends_busy():
		_friends_status.text = "Carregando amigos..."
	elif _view_model.friends_failed():
		_friends_status.text = "Não foi possível carregar. Tente de novo."
	elif friends.is_empty():
		_friends_status.text = "Você ainda não tem amigos."
	else:
		_friends_status.text = ""
	_refresh_pager()
	_refresh_buttons()


func _refresh_pager() -> void:
	_page_label.text = "Pág %d" % (_view_model.page() + 1)
	_prev_btn.disabled = _view_model.page() <= 0 or _view_model.is_friends_busy()
	_next_btn.disabled = _view_model.page() >= _view_model.total_pages() - 1 or _view_model.is_friends_busy()


func _refresh_pending() -> void:
	for child in _pending_rows.get_children():
		_pending_rows.remove_child(child)
		child.queue_free()
	var pending := _view_model.pending()
	for item_variant in pending:
		var friendship := item_variant as Friendship
		if friendship != null:
			_pending_rows.add_child(_make_pending_row(friendship))
	if _view_model.is_pending_busy():
		_pending_status.text = "Carregando pedidos..."
	elif _view_model.pending_failed():
		_pending_status.text = "Não foi possível carregar. Tente de novo."
	elif pending.is_empty():
		_pending_status.text = "Nenhum pedido no momento."
	else:
		_pending_status.text = ""
	_refresh_buttons()


func _refresh_sent() -> void:
	for child in _sent_rows.get_children():
		_sent_rows.remove_child(child)
		child.queue_free()
	var sent := _view_model.sent_requests()
	for item_variant in sent:
		var friendship := item_variant as Friendship
		if friendship != null:
			_sent_rows.add_child(_make_sent_row(friendship))
	if _view_model.is_sent_busy():
		_sent_status.text = "Carregando pedidos..."
	elif _view_model.sent_failed():
		_sent_status.text = "Não foi possível carregar. Tente de novo."
	elif sent.is_empty():
		_sent_status.text = "Nenhum pedido enviado."
	else:
		_sent_status.text = ""
	_refresh_buttons()


func _refresh_discover() -> void:
	for child in _user_grid.get_children():
		_user_grid.remove_child(child)
		child.queue_free()
	var users := _visible_users()
	for item_variant in users:
		var user := item_variant as User
		if user != null:
			_user_grid.add_child(_make_user_card(user))
	if _view_model.is_discover_busy():
		if _view_model.discover_mode() == SocialViewModel.MODE_SEARCH:
			_discover_status.text = "Buscando..."
		else:
			_discover_status.text = "Carregando usuários..."
	elif _view_model.discover_failed():
		_discover_status.text = "Não foi possível carregar. Tente de novo."
	elif users.is_empty():
		if _view_model.discover_mode() == SocialViewModel.MODE_SEARCH:
			_discover_status.text = "Nenhum usuário encontrado. Tente pesquisar por outro nome."
		else:
			_discover_status.text = "Nenhum usuário disponível."
	else:
		_discover_status.text = ""
	_refresh_discover_pager()
	_refresh_buttons()


func _visible_users() -> Array:
	var my_id := _view_model.my_id()
	var result: Array = []
	for item_variant in _view_model.discover_users():
		var user := item_variant as User
		if user == null or user.id == my_id:
			continue
		result.append(user)
	return result


func _refresh_discover_pager() -> void:
	_discover_label.text = "Pág %d" % (_view_model.discover_page() + 1)
	var busy := _view_model.is_discover_busy()
	_discover_prev_btn.disabled = _view_model.discover_page() <= 0 or busy
	_discover_next_btn.disabled = _view_model.discover_page() >= _view_model.discover_total_pages() - 1 or busy


func _refresh_buttons() -> void:
	var action: String = _view_model.action_id()
	var locked := not action.is_empty()
	_search_btn.disabled = _view_model.is_discover_busy() or locked
	_search_input.editable = not _view_model.is_discover_busy() and not locked
	_refresh_btn.disabled = locked or _is_current_section_busy()
	for row in _friends_rows.get_children():
		_apply_row_lock(row, locked)
	for row in _pending_rows.get_children():
		_apply_row_lock(row, locked)
	for row in _sent_rows.get_children():
		_apply_row_lock(row, locked)
	for card in _user_grid.get_children():
		_apply_row_lock(card, locked)
	_refresh_pager()
	_refresh_discover_pager()


func _apply_row_lock(row: Node, locked: bool) -> void:
	for btn_variant in row.find_children("*", "Button", true, false):
		(btn_variant as Button).disabled = locked


func _make_friend_row(friendship: Friendship) -> PanelContainer:
	var other := friendship.other_id(_view_model.my_id())
	var card := _player_card_base(friendship.equipped_art("BANNER"))
	var box := _player_row_hbox(card)
	box.add_child(_make_avatar_frame(64, _friendship_avatar(friendship), friendship.equipped_art("FRAME")))
	var info := _make_info(
		friendship.display_name("Amigo", other),
		"desde " + friendship.date_short()
	)
	box.add_child(info)
	var remove_btn := _make_small_btn("Remover", ROW_RED)
	remove_btn.pressed.connect(_on_remove_pressed.bind(other))
	box.add_child(remove_btn)
	return card


func _make_pending_row(friendship: Friendship) -> PanelContainer:
	var sender := friendship.other_id(_view_model.my_id())
	var card := _player_card_base(friendship.equipped_art("BANNER"))
	var box := _player_row_hbox(card)
	box.add_child(_make_avatar_frame(64, _friendship_avatar(friendship), friendship.equipped_art("FRAME")))
	var info := _make_info(
		friendship.display_name("Jogador", sender),
		"quer ser seu amigo"
	)
	box.add_child(info)
	var accept_btn := _make_small_btn("Aceitar", TAB_GREEN)
	accept_btn.pressed.connect(_on_accept_pressed.bind(sender))
	box.add_child(accept_btn)
	var reject_btn := _make_small_btn("Recusar", NAVY)
	reject_btn.pressed.connect(_on_reject_pressed.bind(sender))
	box.add_child(reject_btn)
	return card


func _make_sent_row(friendship: Friendship) -> PanelContainer:
	var target := friendship.other_id(_view_model.my_id())
	var card := _player_card_base(friendship.equipped_art("BANNER"))
	var box := _player_row_hbox(card)
	box.add_child(_make_avatar_frame(64, _friendship_avatar(friendship), friendship.equipped_art("FRAME")))
	var info := _make_info(
		friendship.display_name("Jogador", target),
		"aguardando resposta"
	)
	box.add_child(info)
	var cancel_btn := _make_small_btn("Cancelar", SELECT_ORANGE)
	cancel_btn.pressed.connect(_on_cancel_pressed.bind(target))
	box.add_child(cancel_btn)
	return card


func _make_user_card(user: User) -> PanelContainer:
	var card := _player_card_base(null)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := card.get_meta("content_box") as VBoxContainer
	var frame_box := _make_avatar_frame(56, CosmeticArt.avatar_by_name(user.equipped_avatar), null)
	frame_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(frame_box)
	var name_label := _card_nickname(user.nickname, 16, true)
	inner.add_child(name_label)
	var action := _view_model.action_id()
	var sending := action == "send:" + user.id
	var sent := _view_model.user_sent(user.id)
	var add_btn := Button.new()
	add_btn.custom_minimum_size = Vector2(0, 44)
	add_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if sent:
		add_btn.text = "Enviado"
		add_btn.disabled = true
		_paint_btn(add_btn, SENT_GRAY, Color.WHITE)
	elif sending:
		add_btn.text = "Enviando..."
		add_btn.disabled = true
		_paint_btn(add_btn, SELECT_ORANGE, Color.WHITE)
	else:
		add_btn.text = "Adicionar"
		_paint_btn(add_btn, TAB_GREEN, Color.WHITE)
		add_btn.pressed.connect(_on_add_pressed.bind(user.id))
	inner.add_child(add_btn)
	return card


func _friendship_avatar(friendship: Friendship) -> Texture2D:
	var avatar := friendship.equipped_art("AVATAR")
	if avatar != null:
		return avatar
	return CosmeticArt.FALLBACK_AVATAR


func _player_card_base(banner: Texture2D) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_GREEN if banner != null else CARD_BLUE
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
	if banner != null:
		var banner_rect := TextureRect.new()
		banner_rect.texture = banner
		banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		banner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(banner_rect)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 4)
	margin.add_child(inner)
	card.set_meta("content_box", inner)
	return card


func _player_row_hbox(card: PanelContainer) -> HBoxContainer:
	var inner := card.get_meta("content_box") as VBoxContainer
	inner.alignment = BoxContainer.ALIGNMENT_BEGIN
	inner.add_theme_constant_override("separation", 10)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 10)
	inner.add_child(box)
	return box


func _make_avatar_frame(pixel_size: int, avatar: Texture2D, frame: Texture2D) -> PanelContainer:
	var frame_box := PanelContainer.new()
	frame_box.custom_minimum_size = Vector2(pixel_size, pixel_size)
	frame_box.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.draw_center = false
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color.BLACK
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	frame_box.add_theme_stylebox_override("panel", sb)
	var avatar_rect := TextureRect.new()
	avatar_rect.texture = avatar
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_box.add_child(avatar_rect)
	if frame != null:
		var frame_rect := TextureRect.new()
		frame_rect.texture = frame
		frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame_box.add_child(frame_rect)
	return frame_box


func _card_nickname(text: String, font_size: int, centered: bool) -> Label:
	var name_label := Label.new()
	name_label.text = text
	if centered:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_font_size_override("font_size", font_size)
	return name_label


func _make_info(title: String, subtitle: String) -> VBoxContainer:
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	var title_label := Label.new()
	title_label.text = title
	title_label.clip_text = true
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.add_theme_font_size_override("font_size", 18)
	info.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.clip_text = true
	sub_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	sub_label.add_theme_font_size_override("font_size", 13)
	info.add_child(sub_label)
	return info


func _make_small_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_paint_btn(btn, color, Color.WHITE)
	return btn


func _paint_btn(btn: Button, color: Color, font_color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = NAVY
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_font_size_override("font_size", 16)


func _on_prev_pressed() -> void:
	_view_model.prev_friends_page()


func _on_next_pressed() -> void:
	_view_model.next_friends_page()


func _is_current_section_busy() -> bool:
	match _section:
		Section.FRIENDS:
			return _view_model.is_friends_busy()
		Section.PENDING:
			return _view_model.is_pending_busy()
		Section.SENT:
			return _view_model.is_sent_busy()
	return false


func _on_refresh_pressed() -> void:
	match _section:
		Section.FRIENDS:
			_view_model.load_friends_page(_view_model.page())
		Section.PENDING:
			_view_model.refresh_pending()
		Section.SENT:
			_view_model.refresh_sent()
		_:
			_view_model.ensure_browse()


func _on_search_text_changed(new_text: String) -> void:
	if new_text.strip_edges().is_empty() and _view_model.discover_mode() == SocialViewModel.MODE_SEARCH:
		_view_model.clear_user_search()


func _on_discover_prev_pressed() -> void:
	_view_model.prev_discover_page()


func _on_discover_next_pressed() -> void:
	_view_model.next_discover_page()


func _on_search_pressed() -> void:
	var clean := _search_input.text.strip_edges()
	if clean.is_empty():
		_view_model.clear_user_search()
	else:
		_view_model.search_users(clean)


func _on_search_submitted(_text: String) -> void:
	_on_search_pressed()


func _on_add_pressed(user_id: String) -> void:
	_view_model.send_request_to(user_id)


func _on_accept_pressed(other_id: String) -> void:
	_view_model.accept_request(other_id)


func _on_reject_pressed(other_id: String) -> void:
	_view_model.reject_request(other_id)


func _on_cancel_pressed(other_id: String) -> void:
	_view_model.cancel_request(other_id)


func _on_remove_pressed(other_id: String) -> void:
	_view_model.remove_friend(other_id)


func _on_section_busy_changed(_value: Variant) -> void:
	_refresh_friends()
	_refresh_pending()
	_refresh_sent()
	_refresh_discover()


func _on_action_changed(_action_id: String) -> void:
	_refresh_buttons()


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		return
	_feedback_label.show_error(message)


func _on_notice_changed(message: String) -> void:
	_feedback_label.text = message
