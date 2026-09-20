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
	assert_true((_page.get_node("CreatePopup/Center/Card/Margin/Form/SpectatorsCheck") as CheckBox).button_pressed, "espectadores devem iniciar habilitados")
	assert_false((_page.get_node("CreatePopup/Center/Card/Margin/Form/PrivateCheck") as CheckBox).button_pressed, "sala deve iniciar pública")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/ButtonRow/CancelBtn"), "botão cancelar deve existir")
	assert_not_null(_page.get_node("CreatePopup/Center/Card/Margin/Form/ButtonRow/ConfirmBtn"), "botão criar deve existir")


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
