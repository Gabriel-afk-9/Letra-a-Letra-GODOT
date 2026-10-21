extends GutTest

var _page: HomeScreen


func before_each() -> void:
	var store := ServiceRegistry.initial_data_store()
	store.clear()
	store.set_user(User.new("u-1", "e@x.com", "Zezinho"))
	var scene: PackedScene = load("res://features/home/presentation/views/home_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	ServiceRegistry.initial_data_store().clear()
	_page.queue_free()


func _mode_row() -> HBoxContainer:
	return _page.get_node("SafeMargin/RootVBox/HomeScroll/ScrollVBox/PlayArea/PlayModesWrapper/PlayModesRow") as HBoxContainer


func test_home_mode_buttons_explain_each_mode() -> void:
	var bot := _mode_row().get_node("ModeInlineBotBtn")
	var desc := bot.get_node("CenterBox/DescLabel") as Label
	assert_eq(desc.text, "Treine contra o robô", "modo bot deve explicar a proposta")
	var casual := _mode_row().get_node("ModeInlineCasualBtn")
	var casual_desc := casual.get_node("CenterBox/DescLabel") as Label
	assert_eq(casual_desc.text, "Partida rápida 1x1", "modo casual deve explicar a proposta")


func test_home_popup_close_button_lives_in_the_card_header() -> void:
	var close := _page.get_node("ModePopup/Center/CardWrapper/ModeCard/ModeCardMargin/ModeCardVBox/ModeHeaderRow/CloseBtn")
	assert_not_null(close, "botão de fechar fica dentro do card")


func test_home_escape_closes_the_modes_popup() -> void:
	_page._on_info_btn_pressed()
	await get_tree().process_frame
	assert_true(_page.mode_popup.visible, "popup de modos deve abrir")

	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	_page._input(event)

	assert_false(_page.mode_popup.visible, "ESC deve fechar o popup")


func test_home_focus_starts_on_casual_mode() -> void:
	_page.enter({})
	await get_tree().process_frame
	await get_tree().process_frame

	var casual := _mode_row().get_node("ModeInlineCasualBtn")
	assert_eq(get_viewport().gui_get_focus_owner(), casual, "a página deve começar focada no modo casual")


func test_home_mode_buttons_form_a_focus_chain() -> void:
	var bot := _mode_row().get_node("ModeInlineBotBtn") as Button
	var casual := _mode_row().get_node("ModeInlineCasualBtn") as Button
	var rank := _mode_row().get_node("ModeInlineRankBtn") as Button

	assert_eq(bot.focus_neighbor_right, bot.get_path_to(casual), "bot leva ao casual")
	assert_eq(casual.focus_neighbor_left, casual.get_path_to(bot), "casual volta ao bot")
	assert_eq(casual.focus_neighbor_right, casual.get_path_to(rank), "casual leva ao rank")
	assert_eq(rank.focus_neighbor_left, rank.get_path_to(casual), "rank volta ao casual")


func test_home_safe_margin_keeps_base_insets() -> void:
	var margin := _page.get_node("SafeMargin") as MarginContainer
	assert_eq(margin.get_theme_constant("margin_left"), 16, "margem lateral base")
	assert_eq(margin.get_theme_constant("margin_top"), 12, "margem superior base")
