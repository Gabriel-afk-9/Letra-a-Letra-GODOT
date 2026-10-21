extends HubPage
class_name HomeScreen

const CARD_NO_BANNER_BG := Color(0.105882354, 0.6156863, 0.87058824)
const CARD_BANNER_BG := Color(0.23, 0.62, 0.32)

const AVATAR_COSMETICS := {
	"logo": preload("res://assets/cosmetics/avatar/logo.png"),
	"stupid": preload("res://assets/cosmetics/avatar/stupid.png"),
	"pie": preload("res://assets/cosmetics/avatar/pie.png"),
	"evil": preload("res://assets/cosmetics/avatar/evil.png"),
	"arvenis": preload("res://assets/cosmetics/avatar/arvenis.png"),
}

const AVATAR_MASK_SHADER := preload("res://assets/styles/rounded_image_mask.gdshader")

const FRAME_COSMETICS := {
}

const BANNER_COSMETICS := {
}

@onready var level_number: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/LevelBadge/LevelNumber
@onready var xp_label: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/XpPill/XpMargin/XpLabel
@onready var coins_label: Label = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsLabel
@onready var coins_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsPlusBtn
@onready var gems_label: Label = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsLabel
@onready var gems_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsPlusBtn

@onready var home_player_card: PlayerCard = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/HomePlayerCard
@onready var settings_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/QuickBtns/SettingsBtn
@onready var menu_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/QuickBtns/MenuBtn

@onready var feedback_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/FeedbackLabel

@onready var play_btn: Button = get_node_or_null("SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayBtn") as Button
@onready var mode_bar: PanelContainer = get_node_or_null("SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModeBar") as PanelContainer
@onready var mode_popup: Control = $ModePopup
@onready var dim_background: ColorRect = $ModePopup/DimBackground
@onready var opt_casual_btn: Button = $ModePopup/Center/CardWrapper/ModeCard/ModeCardMargin/ModeCardVBox/OptCasualBtn
@onready var opt_bot_btn: Button = $ModePopup/Center/CardWrapper/ModeCard/ModeCardMargin/ModeCardVBox/OptBotBtn
@onready var opt_rank_btn: Button = $ModePopup/Center/CardWrapper/ModeCard/ModeCardMargin/ModeCardVBox/OptRankBtn
@onready var close_btn: Button = $ModePopup/Center/CardWrapper/ModeCard/ModeCardMargin/ModeCardVBox/ModeHeaderRow/CloseBtn as Button
@onready var mode_inline_bot_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineBotBtn as HomeModeButton
@onready var mode_inline_casual_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineCasualBtn as HomeModeButton
@onready var mode_inline_rank_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineRankBtn as HomeModeButton
@onready var info_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/InfoBtn as Button
@onready var mode_prompt_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModePromptLabel as Label
@onready var safe_margin: MarginContainer = $SafeMargin

var _view_model: HomeViewModel
var _prompt_tween: Tween = null

const BASE_MARGIN_LEFT := 16
const BASE_MARGIN_TOP := 12
const BASE_MARGIN_RIGHT := 16
const BASE_MARGIN_BOTTOM := 12


func _ready() -> void:
	_setup_inline_buttons()
	_view_model = HomeFactory.create()
	_connect_view_model()
	_connect_buttons()
	if _view_model != null:
		_view_model.load_initial()
	_setup_avatar_shader()
	_start_prompt_pulse()
	_setup_focus_chain()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)


func _setup_inline_buttons() -> void:
	if is_instance_valid(mode_inline_bot_btn):
		mode_inline_bot_btn.setup(HomeGameMode.Mode.BOT, preload("res://assets/images/icons/bot-icon.png") as Texture2D, "BOT", "Treine contra o robô", false)
	if is_instance_valid(mode_inline_casual_btn):
		mode_inline_casual_btn.setup(HomeGameMode.Mode.NORMAL, preload("res://assets/images/icons/Play.png") as Texture2D, "CASUAL", "Partida rápida 1x1", false)
	if is_instance_valid(mode_inline_rank_btn):
		mode_inline_rank_btn.setup(HomeGameMode.Mode.RANKED, null, "RANK", "Disputa o ranking", true)


func _setup_focus_chain() -> void:
	coins_plus_btn.focus_neighbor_right = coins_plus_btn.get_path_to(gems_plus_btn)
	gems_plus_btn.focus_neighbor_left = gems_plus_btn.get_path_to(coins_plus_btn)
	gems_plus_btn.focus_neighbor_bottom = gems_plus_btn.get_path_to(mode_inline_casual_btn)
	menu_btn.focus_neighbor_bottom = menu_btn.get_path_to(mode_inline_casual_btn)
	mode_inline_bot_btn.focus_neighbor_right = mode_inline_bot_btn.get_path_to(mode_inline_casual_btn)
	mode_inline_bot_btn.focus_neighbor_bottom = mode_inline_bot_btn.get_path_to(info_btn)
	mode_inline_casual_btn.focus_neighbor_left = mode_inline_casual_btn.get_path_to(mode_inline_bot_btn)
	mode_inline_casual_btn.focus_neighbor_right = mode_inline_casual_btn.get_path_to(mode_inline_rank_btn)
	mode_inline_casual_btn.focus_neighbor_top = mode_inline_casual_btn.get_path_to(coins_plus_btn)
	mode_inline_rank_btn.focus_neighbor_left = mode_inline_rank_btn.get_path_to(mode_inline_casual_btn)
	mode_inline_rank_btn.focus_neighbor_bottom = mode_inline_rank_btn.get_path_to(info_btn)
	info_btn.focus_neighbor_top = info_btn.get_path_to(mode_inline_casual_btn)


func _apply_safe_area() -> void:
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	if window_size.x <= 0 or window_size.y <= 0:
		return
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var window_rect := Rect2i(Vector2i.ZERO, window_size)
	var safe := DisplayServer.get_display_safe_area().intersection(window_rect)
	if safe.size.x <= 0 or safe.size.y <= 0:
		return
	var scale_x := viewport_size.x / float(window_size.x)
	var scale_y := viewport_size.y / float(window_size.y)
	var inset_left := int(round(safe.position.x * scale_x))
	var inset_top := int(round(safe.position.y * scale_y))
	var inset_right := int(round((window_size.x - safe.end.x) * scale_x))
	var inset_bottom := int(round((window_size.y - safe.end.y) * scale_y))
	safe_margin.add_theme_constant_override("margin_left", BASE_MARGIN_LEFT + inset_left)
	safe_margin.add_theme_constant_override("margin_top", BASE_MARGIN_TOP + inset_top)
	safe_margin.add_theme_constant_override("margin_right", BASE_MARGIN_RIGHT + inset_right)
	safe_margin.add_theme_constant_override("margin_bottom", BASE_MARGIN_BOTTOM + inset_bottom)


func page_id() -> StringName:
	return &"play"


func enter(_params: Dictionary) -> void:
	_start_prompt_pulse()
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()
	_focus_default_control()


func _focus_default_control() -> void:
	await get_tree().process_frame
	if not is_visible_in_tree():
		return
	if mode_popup.visible:
		return
	if is_instance_valid(mode_inline_casual_btn):
		mode_inline_casual_btn.grab_focus()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if mode_popup.visible:
		_close_mode_popup()
		get_viewport().set_input_as_handled()


func _setup_avatar_shader() -> void:
	pass


func _connect_view_model() -> void:
	if _view_model == null:
		return
	_view_model.user_loaded.connect(_on_user_loaded)
	_view_model.profile_changed.connect(_on_profile_changed)
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _connect_buttons() -> void:
	if is_instance_valid(mode_bar):
		mode_bar.gui_input.connect(_on_mode_bar_gui_input)
	if is_instance_valid(close_btn):
		close_btn.pressed.connect(_on_close_btn_pressed)
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	if is_instance_valid(play_btn):
		play_btn.pressed.connect(_on_play_btn_pressed)
	if is_instance_valid(mode_inline_bot_btn):
		mode_inline_bot_btn.pressed.connect(_on_inline_mode_pressed.bind(HomeGameMode.Mode.BOT))
	if is_instance_valid(mode_inline_casual_btn):
		mode_inline_casual_btn.pressed.connect(_on_inline_mode_pressed.bind(HomeGameMode.Mode.NORMAL))
	if is_instance_valid(mode_inline_rank_btn):
		mode_inline_rank_btn.pressed.connect(_on_inline_mode_pressed.bind(HomeGameMode.Mode.RANKED))
	if is_instance_valid(info_btn):
		info_btn.pressed.connect(_on_info_btn_pressed)
	coins_plus_btn.pressed.connect(_on_nav_btn_pressed.bind("Loja"))
	gems_plus_btn.pressed.connect(_on_nav_btn_pressed.bind("Loja"))
	settings_btn.pressed.connect(_on_nav_btn_pressed.bind("Configurações"))
	menu_btn.pressed.connect(_on_menu_btn_pressed)


func _on_user_loaded(user: User) -> void:
	if is_instance_valid(home_player_card):
		home_player_card.show_local(user.nickname)


func _on_profile_changed(profile: HomePlayerProfile) -> void:
	level_number.text = str(profile.level)
	xp_label.text = profile.xp_compact()
	coins_label.text = _format_thousands(profile.coins)
	gems_label.text = _format_thousands(profile.gems)
	if is_instance_valid(home_player_card):
		var tex := _resolve_avatar_texture(profile)
		home_player_card.show_local(profile.nickname, tex)
		home_player_card.set_stats_from_profile(profile)
		_apply_cosmetics(profile)


func _apply_card_background(has_banner: bool) -> void:
	if not is_instance_valid(home_player_card):
		return
	var base := home_player_card.get_theme_stylebox("panel") as StyleBoxFlat
	if base == null:
		return
	var sb := base.duplicate() as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = CARD_BANNER_BG if has_banner else CARD_NO_BANNER_BG
	home_player_card.add_theme_stylebox_override("panel", sb)


func _apply_cosmetics(profile: HomePlayerProfile) -> void:
	if not is_instance_valid(home_player_card):
		return
	var tex := _resolve_avatar_texture(profile)
	if tex != null:
		home_player_card.set_avatar_texture(tex)
	var frame_name := profile.equipped_frame.to_lower()
	if FRAME_COSMETICS.has(frame_name):
		home_player_card.set_frame_texture(FRAME_COSMETICS[frame_name])
	else:
		home_player_card.set_frame_texture(null)
	var banner_name := profile.equipped_banner.to_lower()
	if BANNER_COSMETICS.has(banner_name):
		home_player_card.set_banner_texture(BANNER_COSMETICS[banner_name])
	else:
		home_player_card.set_banner_texture(null)
		_apply_card_background(profile.has_banner)


func _resolve_avatar_texture(profile: HomePlayerProfile) -> Texture2D:
	var equipped_item = _view_model.equipped_avatar_item() if _view_model != null else null
	var real_texture: Texture2D = null
	if equipped_item != null:
		real_texture = EquippableAssetPaths.load_local_texture(equipped_item.asset_path)
	if real_texture != null:
		return real_texture
	return _mock_avatar_texture(profile.equipped_avatar)


func _mock_avatar_texture(avatar_name: String) -> Texture2D:
	var key := avatar_name.strip_edges().to_lower()
	if AVATAR_COSMETICS.has(key):
		return AVATAR_COSMETICS[key]
	return AVATAR_COSMETICS["logo"]


func _start_prompt_pulse() -> void:
	if not is_instance_valid(mode_prompt_label):
		return
	if is_instance_valid(_prompt_tween) and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null
	mode_prompt_label.visible = true
	mode_prompt_label.modulate.a = 1.0
	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prompt_tween.tween_property(mode_prompt_label, "modulate:a", 0.95, 1.5)
	_prompt_tween.tween_property(mode_prompt_label, "modulate:a", 1.0, 1.5)


func _on_mode_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			if _view_model != null and _view_model.is_loading():
				return
			_open_mode_popup()


func _open_mode_popup() -> void:
	mode_popup.show()
	await get_tree().process_frame
	if is_instance_valid(close_btn):
		close_btn.grab_focus()


func _close_mode_popup() -> void:
	mode_popup.hide()
	get_viewport().gui_release_focus()
	if is_visible_in_tree() and is_instance_valid(info_btn):
		info_btn.grab_focus()


func _on_mode_option_pressed(_mode: int) -> void:
	return


func _on_inline_mode_pressed(mode: int) -> void:
	if _view_model == null:
		return
	_view_model.select_game_mode(mode)
	_view_model.play()


func _on_info_btn_pressed() -> void:
	if _view_model != null and _view_model.is_loading():
		return
	_open_mode_popup()


func _on_close_btn_pressed() -> void:
	_close_mode_popup()


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_close_mode_popup()


func exit() -> void:
	if is_instance_valid(_prompt_tween) and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null
	if is_instance_valid(mode_prompt_label):
		mode_prompt_label.visible = true
		mode_prompt_label.modulate.a = 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		if is_instance_valid(_prompt_tween) and _prompt_tween.is_valid():
			_prompt_tween.kill()
			_prompt_tween = null
		if is_instance_valid(mode_prompt_label):
			mode_prompt_label.visible = true
			mode_prompt_label.modulate.a = 1.0


func _on_play_btn_pressed() -> void:
	_view_model.play()


func _on_nav_btn_pressed(section: String) -> void:
	_view_model.request_coming_soon(section)


func _on_menu_btn_pressed() -> void:
	_view_model.logout_and_go_to_main()


func _on_loading_changed(is_loading: bool) -> void:
	if is_instance_valid(play_btn):
		play_btn.disabled = is_loading
	if is_instance_valid(mode_inline_bot_btn):
		mode_inline_bot_btn.disabled = is_loading
	if is_instance_valid(mode_inline_casual_btn):
		mode_inline_casual_btn.disabled = is_loading
	if is_instance_valid(mode_inline_rank_btn):
		mode_inline_rank_btn.disabled = is_loading
	if is_instance_valid(info_btn):
		info_btn.disabled = is_loading
	if is_instance_valid(menu_btn):
		menu_btn.disabled = is_loading


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		feedback_label.text = ""
		return
	feedback_label.show_error(message)


func _format_thousands(value: int) -> String:
	var text := str(abs(value))
	var result := ""
	while text.length() > 3:
		result = "." + text.substr(text.length() - 3, 3) + result
		text = text.substr(0, text.length() - 3)
	result = text + result
	if value < 0:
		result = "-" + result
	return result
