extends Control
class_name HomeScreen

const SEG_BRIGHT := {
	HomeGameMode.Mode.NORMAL: Color(0.243, 0.573, 0.839),
	HomeGameMode.Mode.BOT: Color(0.184, 0.749, 0.443),
	HomeGameMode.Mode.RANKED: Color(0.961, 0.51, 0.122),
}

@onready var level_number: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/LevelBadge/LevelNumber
@onready var xp_label: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/XpPill/XpMargin/XpLabel
@onready var coins_label: Label = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsLabel
@onready var coins_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsPlusBtn
@onready var gems_label: Label = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsLabel
@onready var gems_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsPlusBtn

@onready var nickname_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/NicknameLabel
@onready var wins_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/WinsValue
@onready var streak_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/StreakValue
@onready var matches_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/MatchesValue
@onready var settings_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/QuickBtns/SettingsBtn
@onready var menu_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/QuickBtns/MenuBtn

@onready var feedback_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/FeedbackLabel

@onready var play_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayBtn
@onready var seg_casual_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModeBar/ModeBarMargin/ModeSegRow/SegCasualBtn
@onready var seg_bot_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModeBar/ModeBarMargin/ModeSegRow/SegBotBtn
@onready var seg_rank_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModeBar/ModeBarMargin/ModeSegRow/SegRankBtn

@onready var mode_popup: Control = $ModePopup
@onready var dim_background: ColorRect = $ModePopup/DimBackground
@onready var opt_casual_btn: Button = $ModePopup/Center/ModeCard/ModeCardMargin/ModeCardVBox/OptCasualBtn
@onready var opt_bot_btn: Button = $ModePopup/Center/ModeCard/ModeCardMargin/ModeCardVBox/OptBotBtn
@onready var opt_rank_btn: Button = $ModePopup/Center/ModeCard/ModeCardMargin/ModeCardVBox/OptRankBtn

@onready var nav_shop_btn: Button = $BottomNav/NavMargin/NavRow/NavShopBtn
@onready var nav_items_btn: Button = $BottomNav/NavMargin/NavRow/NavItemsBtn
@onready var nav_play_btn: Button = $BottomNav/NavMargin/NavRow/NavPlayBtn
@onready var nav_social_btn: Button = $BottomNav/NavMargin/NavRow/NavSocialBtn
@onready var nav_rooms_btn: Button = $BottomNav/NavMargin/NavRow/NavRoomsBtn

var _view_model: HomeViewModel


func _ready() -> void:
	_view_model = HomeFactory.create()
	_connect_view_model()
	_connect_buttons()
	_refresh_game_mode(_view_model.selected_game_mode())
	_view_model.load_user()


func _connect_view_model() -> void:
	_view_model.user_loaded.connect(_on_user_loaded)
	_view_model.profile_changed.connect(_on_profile_changed)
	_view_model.game_mode_changed.connect(_on_game_mode_changed)
	_view_model.loading_changed.connect(_on_loading_changed)
	_view_model.error_changed.connect(_on_error_changed)


func _connect_buttons() -> void:
	seg_casual_btn.pressed.connect(_on_mode_selector_btn_pressed)
	seg_bot_btn.pressed.connect(_on_mode_selector_btn_pressed)
	seg_rank_btn.pressed.connect(_on_mode_selector_btn_pressed)
	opt_casual_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.NORMAL))
	opt_bot_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.BOT))
	opt_rank_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.RANKED))
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	play_btn.pressed.connect(_on_play_btn_pressed)
	coins_plus_btn.pressed.connect(_on_nav_btn_pressed.bind("Loja"))
	gems_plus_btn.pressed.connect(_on_nav_btn_pressed.bind("Loja"))
	settings_btn.pressed.connect(_on_nav_btn_pressed.bind("Configurações"))
	menu_btn.pressed.connect(_on_nav_btn_pressed.bind("Menu"))
	nav_shop_btn.pressed.connect(_on_nav_btn_pressed.bind("Loja"))
	nav_items_btn.pressed.connect(_on_nav_btn_pressed.bind("Itens"))
	nav_play_btn.pressed.connect(_on_nav_btn_pressed.bind("Play"))
	nav_social_btn.pressed.connect(_on_nav_btn_pressed.bind("Amigos"))
	nav_rooms_btn.pressed.connect(_on_nav_btn_pressed.bind("Salas Personalizadas"))


func _on_user_loaded(user: User) -> void:
	nickname_label.text = user.nickname


func _on_profile_changed(profile: HomePlayerProfile) -> void:
	nickname_label.text = profile.nickname
	level_number.text = str(profile.level)
	xp_label.text = profile.xp_compact()
	coins_label.text = _format_thousands(profile.coins)
	gems_label.text = _format_thousands(profile.gems)
	wins_value.text = str(profile.wins)
	streak_value.text = str(profile.streak)
	matches_value.text = str(profile.matches)


func _on_game_mode_changed(mode: int) -> void:
	_refresh_game_mode(mode)


func _refresh_game_mode(mode: int) -> void:
	_paint_button(play_btn, SEG_BRIGHT[mode])


func _paint_button(btn: Button, color: Color) -> void:
	var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = color


func _on_mode_selector_btn_pressed() -> void:
	mode_popup.show()


func _on_mode_option_pressed(mode: int) -> void:
	mode_popup.hide()
	_view_model.select_game_mode(mode)


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			mode_popup.hide()


func _on_play_btn_pressed() -> void:
	_view_model.play()


func _on_nav_btn_pressed(section: String) -> void:
	if section == "Play":
		return
	_view_model.request_coming_soon(section)


func _on_loading_changed(is_loading: bool) -> void:
	play_btn.disabled = is_loading
	seg_casual_btn.disabled = is_loading
	seg_bot_btn.disabled = is_loading
	seg_rank_btn.disabled = is_loading


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
