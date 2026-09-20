extends HubPage
class_name HomeScreen

# Fundo do card sem banner: mesmo azul do blue_button_default.tres.
const CARD_NO_BANNER_BG := Color(0.105882354, 0.6156863, 0.87058824)
# Fundo com banner equipado: verde anterior do BannerStyle.
const CARD_BANNER_BG := Color(0.23, 0.62, 0.32)

# Mapeamento de nomes de cosméticos para recursos
const AVATAR_COSMETICS := {
	"logo": preload("res://assets/cosmetics/avatar/logo.png"),
	"stupid": preload("res://assets/cosmetics/avatar/stupid.png"),
	"pie": preload("res://assets/cosmetics/avatar/pie.png"),
	"evil": preload("res://assets/cosmetics/avatar/evil.png"),
	"arvenis": preload("res://assets/cosmetics/avatar/arvenis.png"),
}

# Mesma máscara de cantos arredondados dos cards do inventário.
const AVATAR_MASK_SHADER := preload("res://assets/styles/rounded_image_mask.gdshader")

const FRAME_COSMETICS := {
	# Frames serão adicionados quando houver assets
}

const BANNER_COSMETICS := {
	# Banners serão adicionados quando houver assets
}

@onready var level_number: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/LevelBadge/LevelNumber
@onready var xp_label: Label = $SafeMargin/RootVBox/ResourceBar/LevelGroup/XpPill/XpMargin/XpLabel
@onready var coins_label: Label = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsLabel
@onready var coins_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/CoinsPill/CoinsMargin/CoinsHBox/CoinsPlusBtn
@onready var gems_label: Label = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsLabel
@onready var gems_plus_btn: Button = $SafeMargin/RootVBox/ResourceBar/GemsPill/GemsMargin/GemsHBox/GemsPlusBtn

@onready var nickname_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/NicknameLabel
@onready var profile_card: PanelContainer = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard
@onready var banner_texture: TextureRect = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/BannerTexture
@onready var avatar_texture: TextureRect = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/AvatarFrame/AvatarTexture
@onready var avatar_frame_texture: TextureRect = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/AvatarFrame/AvatarFrameTexture
@onready var wins_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/WinsBox/WinsValue
@onready var streak_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/StreakBox/StreakValue
@onready var matches_value: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/ProfileRow/ProfileCard/ProfileMargin/ProfileHBox/ProfileInfo/StatsPill/StatsMargin/StatsRow/MatchesBox/MatchesValue
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
@onready var close_btn: Button = $ModePopup/Center/CardWrapper/CloseBtn as Button
@onready var mode_inline_bot_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineBotBtn as HomeModeButton
@onready var mode_inline_casual_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineCasualBtn as HomeModeButton
@onready var mode_inline_rank_btn: HomeModeButton = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow/ModeInlineRankBtn as HomeModeButton
@onready var info_btn: Button = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/InfoBtn as Button
@onready var mode_prompt_label: Label = $SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/ModePromptLabel as Label

var _view_model: HomeViewModel
var _prompt_tween: Tween = null


func _ready() -> void:
	_setup_inline_buttons()
	_view_model = HomeFactory.create()
	_connect_view_model()
	_connect_buttons()
	if _view_model != null:
		_view_model.load_initial()
	_setup_avatar_shader()
	_start_prompt_pulse()


func _setup_inline_buttons() -> void:
	if is_instance_valid(mode_inline_bot_btn):
		mode_inline_bot_btn.setup(HomeGameMode.Mode.BOT, preload("res://assets/images/icons/bot-icon.png") as Texture2D, "BOT", "Treine suas estratégias contra o robô.", false)
	if is_instance_valid(mode_inline_casual_btn):
		mode_inline_casual_btn.setup(HomeGameMode.Mode.NORMAL, preload("res://assets/images/icons/Play.png") as Texture2D, "CASUAL", "Partida rápida contra outro jogador.", false)
	if is_instance_valid(mode_inline_rank_btn):
		mode_inline_rank_btn.setup(HomeGameMode.Mode.RANKED, null, "RANK", "Vença outros jogadores e suba no ranking.", true)


func page_id() -> StringName:
	return &"play"


func enter(_params: Dictionary) -> void:
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()


func _setup_avatar_shader() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = AVATAR_MASK_SHADER
	avatar_texture.material = mat


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
	opt_casual_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.NORMAL))
	opt_bot_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.BOT))
	opt_rank_btn.pressed.connect(_on_mode_option_pressed.bind(HomeGameMode.Mode.RANKED))
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
	menu_btn.pressed.connect(_on_nav_btn_pressed.bind("Menu"))


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
	_apply_card_background(profile.has_banner)
	_apply_cosmetics(profile)


func _apply_card_background(has_banner: bool) -> void:
	var sb := profile_card.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = CARD_BANNER_BG if has_banner else CARD_NO_BANNER_BG


func _apply_cosmetics(profile: HomePlayerProfile) -> void:
	var equipped_item := _view_model.equipped_avatar_item()
	var real_texture: Texture2D = null
	if equipped_item != null:
		real_texture = EquippableAssetPaths.load_local_texture(equipped_item.asset_path)
	if real_texture != null:
		avatar_texture.texture = real_texture
	else:
		avatar_texture.texture = _mock_avatar_texture(profile.equipped_avatar)
	
	var frame_name := profile.equipped_frame.to_lower()
	if FRAME_COSMETICS.has(frame_name):
		avatar_frame_texture.texture = FRAME_COSMETICS[frame_name]
		avatar_frame_texture.visible = true
	else:
		avatar_frame_texture.visible = false
	
	var banner_name := profile.equipped_banner.to_lower()
	if BANNER_COSMETICS.has(banner_name):
		banner_texture.texture = BANNER_COSMETICS[banner_name]
		banner_texture.visible = true
		var sb := profile_card.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.bg_color = Color(0, 0, 0, 0)
	else:
		banner_texture.visible = false
		_apply_card_background(profile.has_banner)


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
	mode_prompt_label.modulate.a = 0.0
	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prompt_tween.tween_property(mode_prompt_label, "modulate:a", 1.0, 0.25)
	_prompt_tween.tween_property(mode_prompt_label, "modulate:a", 0.55, 0.65)
	_prompt_tween.tween_property(mode_prompt_label, "modulate:a", 1.0, 0.65)


func _on_mode_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			if _view_model != null and _view_model.is_loading():
				return
			mode_popup.show()


func _on_mode_option_pressed(mode: int) -> void:
	mode_popup.hide()
	_view_model.select_game_mode(mode)


func _on_inline_mode_pressed(mode: int) -> void:
	if _view_model == null:
		return
	_view_model.select_game_mode(mode)
	_view_model.play()


func _on_info_btn_pressed() -> void:
	if _view_model != null and _view_model.is_loading():
		return
	mode_popup.show()


func _on_close_btn_pressed() -> void:
	mode_popup.hide()


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			mode_popup.hide()


func exit() -> void:
	if is_instance_valid(_prompt_tween) and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		if is_instance_valid(_prompt_tween) and _prompt_tween.is_valid():
			_prompt_tween.kill()
			_prompt_tween = null


func _on_play_btn_pressed() -> void:
	_view_model.play()


func _on_nav_btn_pressed(section: String) -> void:
	_view_model.request_coming_soon(section)


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
