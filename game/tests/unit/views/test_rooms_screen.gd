extends GutTest

var _page: RoomsScreen


func before_each() -> void:
	var scene: PackedScene = load("res://features/rooms/presentation/views/rooms_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	_page.queue_free()


func test_rooms_page_id_and_title() -> void:
	assert_eq(_page.page_id(), &"rooms", "page_id deve ser rooms")
	assert_eq((_page.get_node("Center/VBox/Title") as Label).text, "Salas Personalizadas", "título deve ser Salas Personalizadas")


func test_rooms_header_actions_and_search_exist() -> void:
	assert_not_null(_page.get_node("Center/VBox/ActionsRow/CreateBtn"), "botão criar deve existir")
	assert_not_null(_page.get_node("Center/VBox/ActionsRow/CodeBtn"), "botão entrar com código deve existir")
	assert_not_null(_page.get_node("Center/VBox/SearchRow/SearchInput"), "campo de busca deve existir")
	assert_not_null(_page.get_node("Center/VBox/SearchRow/SearchBtn"), "botão buscar deve existir")
	assert_not_null(_page.get_node("TopCorner/RefreshBtn"), "botão atualizar deve existir fora do painel")


func test_rooms_list_and_pager_exist() -> void:
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsScroll/RoomsRows"), "lista de salas deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsStatusLabel"), "status da lista deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PrevBtn"), "botão anterior deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/NextBtn"), "botão próximo deve existir")
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/PagerRow/PagePill/PageMargin/PageLabel") as Label).text, "Pág 1", "deve iniciar na página 1")


func test_rooms_empty_state_without_backend() -> void:
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsStatusLabel") as Label).text, "Nenhuma sala pública no momento.", "lista vazia deve informar")


func test_rooms_popups_open_and_close() -> void:
	assert_false(_page.get_node("CreatePopup").visible, "popup de criar inicia oculto")
	assert_false(_page.get_node("CodePopup").visible, "popup de código inicia oculto")
	_page._on_create_pressed()
	assert_true(_page.get_node("CreatePopup").visible, "popup de criar deve abrir")
	assert_false(_page.get_node("CodePopup").visible, "popup de código segue oculto")
	_page._on_code_pressed()
	assert_true(_page.get_node("CodePopup").visible, "popup de código deve abrir")
	assert_false(_page.get_node("CreatePopup").visible, "popup de criar deve fechar ao abrir o outro")
	_page.close_popups()
	assert_false(_page.get_node("CodePopup").visible, "popups devem fechar")


func test_rooms_clearing_search_returns_to_browse() -> void:
	_page._view_model.search_rooms("zzz")
	await get_tree().process_frame
	await get_tree().process_frame
	_page._search_input.text = ""
	_page._on_search_text_changed("")
	assert_eq(_page._view_model.mode(), RoomsViewModel.MODE_BROWSE, "limpar a busca deve voltar à listagem")


func test_rooms_create_popup_has_name_and_options() -> void:
	_page._on_create_pressed()

	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/NameInput"), "campo de nome deve existir")
	assert_eq((_page.get_node("CreatePopup/Center/Card/Margin/Form/NameInput") as LineEdit).placeholder_text, "Nome da sala", "placeholder deve indicar o nome")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/SpectatorsRow/SpectatorsLabel"), "label de espectadores deve existir")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/PrivateRow/PrivateLabel"), "label de sala privada deve existir")
	assert_true((_page.get_node("CreatePopup/Center/Card/Margin/Form/SpectatorsRow/SpectatorsSwitch") as ToggleSwitch).is_on(), "espectadores devem iniciar habilitados")
	assert_false((_page.get_node("CreatePopup/Center/Card/Margin/Form/PrivateRow/PrivateSwitch") as ToggleSwitch).is_on(), "sala deve iniciar pública")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/ButtonRow/CancelBtn"), "botão cancelar deve existir")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/ButtonRow/ConfirmBtn"), "botão criar deve existir")


func test_rooms_create_switches_drive_payload() -> void:
	_page._on_create_pressed()
	var spectators := _page.get_node("CreatePopup/Center/Card/Margin/Form/SpectatorsRow/SpectatorsSwitch") as ToggleSwitch
	var private_sw := _page.get_node("CreatePopup/Center/Card/Margin/Form/PrivateRow/PrivateSwitch") as ToggleSwitch
	spectators.set_value(false)
	private_sw.set_value(true)

	assert_false(spectators.is_on())
	assert_true(private_sw.is_on())
	assert_eq(spectators.state_text(), "OFF")
	assert_eq(private_sw.state_text(), "ON")


func test_rooms_create_popup_labels_stay_black() -> void:
	var title := _page.get_node("CreatePopup/Center/Card/Margin/Form/Title") as Label
	var spectators_label := _page.get_node("CreatePopup/Center/Card/Margin/Form/SpectatorsRow/SpectatorsLabel") as Label
	var private_label := _page.get_node("CreatePopup/Center/Card/Margin/Form/PrivateRow/PrivateLabel") as Label

	assert_eq(title.get_theme_color("font_color"), Color(0, 0, 0, 1), "título deve ser preto")
	assert_eq(spectators_label.get_theme_color("font_color"), Color(0, 0, 0, 1), "label deve ser preto")
	assert_eq(private_label.get_theme_color("font_color"), Color(0, 0, 0, 1), "label deve ser preto")
	assert_false(title.has_theme_color("font_hover_color"), "label não deve ter cor de hover")
	assert_false(spectators_label.has_theme_color("font_hover_color"), "label não deve ter cor de hover")
	assert_false(private_label.has_theme_color("font_hover_color"), "label não deve ter cor de hover")
	var popup := _page.get_node("CreatePopup")
	assert_true(popup.find_children("*", "CheckBox", true, false).is_empty(), "popup não deve usar CheckBox")
	assert_true(popup.find_children("*", "CheckButton", true, false).is_empty(), "popup não deve usar CheckButton")


func test_rooms_create_empty_name_shows_error() -> void:
	_page._on_create_pressed()
	(_page.get_node("CreatePopup/Center/Card/Margin/Form/NameInput") as LineEdit).text = "   "
	_page._on_create_confirm_pressed()

	assert_eq((_page.get_node("CreatePopup/Center/Card/Margin/Form/ErrorLabel") as Label).text, "Digite o nome da sala.", "nome vazio deve validar")
	assert_false(_page._view_model.is_creating(), "não deve enviar com nome inválido")
	assert_true(_page.get_node("CreatePopup").visible, "popup deve permanecer aberto")


func test_rooms_create_failure_restores_popup() -> void:
	_page._on_create_pressed()
	(_page.get_node("CreatePopup/Center/Card/Margin/Form/NameInput") as LineEdit).text = "Minha Sala"
	_page._view_model._on_create_failed("the room name is invalid")

	assert_eq((_page.get_node("CreatePopup/Center/Card/Margin/Form/ErrorLabel") as Label).text, "the room name is invalid", "erro deve aparecer no popup")
	assert_false((_page.get_node("CreatePopup/Center/Card/Margin/Form/ButtonRow/ConfirmBtn") as Button).disabled, "botão deve liberar nova tentativa")


func _inject_rooms() -> Array:
	var rooms := [
		Room.new("g-1", "Sala Um", "CUSTOM", "WAITING", [], {}, []),
		Room.new("g-2", "Sala Dois", "CUSTOM", "WAITING", [], {}, []),
	]
	_page._view_model._browse_rooms = rooms
	_page._view_model._browse_loaded = true
	_page._refresh_rooms()
	return rooms


func _cards() -> Array:
	return _page.get_node("Center/VBox/ContentPanel/ContentMargin/RoomsSection/RoomsScroll/RoomsRows").get_children()


func _join_buttons() -> Array:
	var found: Array = []
	for card in _cards():
		found.append_array(card.find_children("*", "Button", true, false))
	return found


func _card_border(card: PanelContainer) -> Color:
	return (card.get_theme_stylebox("panel") as StyleBoxFlat).border_color


func test_select_room_highlights_card_and_shows_join_only_there() -> void:
	_inject_rooms()

	assert_true(_join_buttons().is_empty(), "sem seleção não há botão Entrar")
	_page._select_room("g-2")

	var cards := _cards()
	assert_eq(_card_border(cards[0]), Color.BLACK, "card não selecionado mantém borda preta")
	assert_eq(_card_border(cards[1]), _page.SELECT_ORANGE, "card selecionado recebe destaque laranja")
	assert_eq(_join_buttons().size(), 1, "apenas o card selecionado tem botão")
	assert_eq((_join_buttons()[0] as Button).text, "Entrar")


func test_select_room_can_switch_and_reconciles_on_refresh() -> void:
	_inject_rooms()
	_page._select_room("g-1")
	_page._select_room("g-2")

	assert_eq(_join_buttons().size(), 1)
	_page._view_model._browse_rooms = [Room.new("g-1", "Sala Um", "CUSTOM", "WAITING", [], {}, [])]
	_page._refresh_rooms()

	assert_true(_join_buttons().is_empty(), "seleção inválida deve sumir após reconciliação")


func test_join_failure_keeps_selection_and_shows_error() -> void:
	_inject_rooms()
	_page._select_room("g-1")
	_page._view_model._set_join_busy(true)
	_page._refresh_rooms()

	assert_eq((_join_buttons()[0] as Button).text, "Entrando...", "botão deve indicar carregamento")
	_page._view_model._set_join_busy(false)
	_page._on_join_failed("the game is full")

	assert_eq(_join_buttons().size(), 1, "seleção deve ser mantida para nova tentativa")
	assert_eq((_page.get_node("Center/VBox/FeedbackLabel") as Label).text, "the game is full")
	assert_eq((_join_buttons()[0] as Button).text, "Entrar", "botão deve sair do loading")


func test_join_success_clears_selection() -> void:
	_inject_rooms()
	_page._select_room("g-1")
	_page._on_room_joined(Room.new("g-1", "Sala Um", "CUSTOM", "WAITING", [], {}, []))

	assert_true(_join_buttons().is_empty(), "após sucesso não há mais seleção")
