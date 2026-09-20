extends GutTest

var _page: RoomLobbyScreen


func before_each() -> void:
	ServiceRegistry.pending_navigation_payload().set_payload(RoomCreatedEvent.new("g-1", "Minha Sala"))
	var scene: PackedScene = load("res://features/room/presentation/views/room_lobby_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	_page.queue_free()


func test_lobby_shows_created_room() -> void:
	assert_eq((_page.get_node("Center/VBox/Title") as Label).text, "Sala criada", "título deve identificar a sala")
	assert_eq((_page.get_node("Center/VBox/RoomNameLabel") as Label).text, "Minha Sala", "nome deve vir da criação")
	assert_eq((_page.get_node("Center/VBox/InfoLabel") as Label).text, "Você está na sala.", "texto de permanência deve existir")


func test_lobby_setup_falls_back_without_name() -> void:
	_page.setup("   ")
	assert_eq((_page.get_node("Center/VBox/RoomNameLabel") as Label).text, "Sala", "nome vazio deve usar reserva")
