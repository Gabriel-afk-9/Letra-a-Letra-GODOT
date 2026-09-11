extends Control
class_name HomeScreen

const SEG_BRIGHT := {
	HomeGameMode.Mode.NORMAL: Color(0.243, 0.573, 0.839),
	HomeGameMode.Mode.BOT: Color(0.184, 0.749, 0.443),
	HomeGameMode.Mode.RANKED: Color(0.961, 0.51, 0.122),
}

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
	_setup_avatar_shader()


func _setup_avatar_shader() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	vec2 uv = UV;

	// Distância normalizada até os quatro cantos.
	vec2 dist = min(uv, 1.0 - uv);

	// Para cada canto, calcula a distância até o centro do arco.
	float d = min(
		length(uv - vec2(corner_radius, corner_radius)),
		min(
			length(uv - vec2(1.0 - corner_radius, corner_radius)),
			min(
				length(uv - vec2(corner_radius, 1.0 - corner_radius)),
				length(uv - vec2(1.0 - corner_radius, 1.0 - corner_radius))
			)
		)
	);

	// Só aplica o círculo nas regiões próximas aos cantos.
	float corner_x = step(uv.x, corner_radius) + step(1.0 - corner_radius, uv.x);
	float corner_y = step(uv.y, corner_radius) + step(1.0 - corner_radius, uv.y);

	float in_corner = min(corner_x, corner_y);

	float mask = 1.0;

	if (in_corner > 0.0) {
		mask = step(d, corner_radius);
	}

	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, color.a * mask);
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader

	mat.set_shader_parameter("corner_radius", 0.03)

	avatar_texture.material = mat


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
	_apply_card_background(profile.has_banner)
	_apply_cosmetics(profile)


func _apply_card_background(has_banner: bool) -> void:
	var sb := profile_card.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = CARD_BANNER_BG if has_banner else CARD_NO_BANNER_BG


func _apply_cosmetics(profile: HomePlayerProfile) -> void:
	# Avatar
	var avatar_name := profile.equipped_avatar.to_lower()
	if AVATAR_COSMETICS.has(avatar_name):
		avatar_texture.texture = AVATAR_COSMETICS[avatar_name]
	else:
		avatar_texture.texture = AVATAR_COSMETICS["logo"]
	
	# Frame
	var frame_name := profile.equipped_frame.to_lower()
	if FRAME_COSMETICS.has(frame_name):
		avatar_frame_texture.texture = FRAME_COSMETICS[frame_name]
		avatar_frame_texture.visible = true
	else:
		avatar_frame_texture.visible = false
	
	# Banner
	var banner_name := profile.equipped_banner.to_lower()
	if BANNER_COSMETICS.has(banner_name):
		banner_texture.texture = BANNER_COSMETICS[banner_name]
		banner_texture.visible = true
		# Hide the color background when banner image is shown
		var sb := profile_card.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.bg_color = Color(0, 0, 0, 0)
	else:
		banner_texture.visible = false
		# Restore color background
		_apply_card_background(profile.has_banner)


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
