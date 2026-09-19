extends GutTest

var _repo: FakeInventoryRepository
var _vm: InventoryViewModel


func before_each() -> void:
	_repo = FakeInventoryRepository.new()
	var usecase := InventoryUseCase.new(_repo)
	_vm = InventoryViewModel.new(usecase, EquippableAssetService.new(), null)


func _item(data: Dictionary) -> InventoryItem:
	return InventoryItem.from_dictionary(data)


func _avatar(item_id: String, equipped: bool = false) -> InventoryItem:
	return _item({
		"itemId": item_id,
		"name": "Avatar",
		"kind": "EQUIPPABLE",
		"category": "AVATAR",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": equipped,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": "AVATAR/ceo.webp",
	})


func _consumable(item_id: String) -> InventoryItem:
	return _item({
		"itemId": item_id,
		"name": "Gelo",
		"kind": "CONSUMABLE",
		"category": "EMOTE",
		"context": "MATCH",
		"quantity": 2,
		"equipped": false,
		"acquiredAt": "2026-01-02T00:00:00Z",
		"expiresAt": "",
		"assetPath": "",
	})


func test_refresh_loads_items_and_notifies() -> void:
	_repo.inventory_result = {"items": [_avatar("a-1", true)], "status_code": 200}
	var changed := 0
	_vm.inventory_changed.connect(func() -> void: changed += 1)

	await _vm.refresh()

	assert_eq(_vm.items().size(), 1, "um item carregado")
	assert_eq(changed, 1, "inventory_changed emitido")
	assert_false(_vm.is_loading(), "loading finalizado")
	assert_false(_vm.has_error(), "sem erro")


func test_refresh_error_surfaces_message() -> void:
	_repo.inventory_result = {"error": "Falha de conexão. Tente novamente.", "status_code": 0}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.refresh()

	assert_true(_vm.load_failed(), "falha com lista vazia")
	assert_eq(errors.back(), "Falha de conexão. Tente novamente.", "mensagem amigável do repositório")


func test_load_initial_seeds_from_store_then_refreshes() -> void:
	var store := InitialDataStore.new()
	store.set_inventory([_avatar("seed-1")])
	_repo.inventory_result = {"items": [_avatar("fresh-1"), _consumable("c-1")], "status_code": 200}
	var usecase := InventoryUseCase.new(_repo)
	var seeded_vm := InventoryViewModel.new(usecase, EquippableAssetService.new(), store)
	var seen: Array = []
	seeded_vm.inventory_changed.connect(func() -> void: seen.append(seeded_vm.items().size()))

	await seeded_vm.load_initial()

	assert_eq(seen, [1, 2], "semeia do store e depois atualiza pela API")
	assert_eq(seeded_vm.items().size(), 2, "itens finais vêm da API")


func test_sections_and_cosmetic_categories_always_visible() -> void:
	_repo.inventory_result = {
		"items": [
			_consumable("c-1"),
			_item({"itemId": "b-1", "name": "Tab", "kind": "EQUIPPABLE", "category": "BOARD", "context": "MATCH", "quantity": 1, "equipped": false, "assetPath": "BOARD/t1.webp"}),
			_avatar("a-1"),
		],
		"status_code": 200,
	}

	await _vm.refresh()

	assert_eq(_vm.sections(), ["COSMETICS", "OTHERS"], "duas seções fixas")
	assert_eq(_vm.cosmetic_categories(), ["AVATAR", "BANNER", "FRAME", "EMOTE", "BOARD", "CELL"], "sub-seletor completo")
	assert_eq(_vm.cosmetic_items("AVATAR").size(), 1, "filtro por categoria")
	assert_eq(_vm.cosmetic_items("BANNER").size(), 0, "categoria vazia retorna lista vazia")
	assert_eq(_vm.other_items().size(), 1, "não equipáveis na seção outros")
	assert_true(_vm.is_cosmetics_section("COSMETICS"), "identifica seção de cosméticos")
	assert_false(_vm.is_cosmetics_section("OTHERS"), "outros não é cosméticos")


func test_sections_full_without_items() -> void:
	_repo.inventory_result = {"items": [], "status_code": 200}

	await _vm.refresh()

	assert_eq(_vm.sections(), ["COSMETICS", "OTHERS"], "seções visíveis mesmo sem itens")
	assert_eq(_vm.cosmetic_categories(), ["AVATAR", "BANNER", "FRAME", "EMOTE", "BOARD", "CELL"], "categorias visíveis mesmo sem itens")
	assert_false(_vm.has_items(), "sem itens")


func test_download_guards_without_network() -> void:
	var missing := _avatar("a-1")
	var consumable := _consumable("c-1")

	assert_true(_vm.needs_download(missing), "asset ausente precisa de download")
	assert_false(_vm.needs_download(consumable), "consumível nunca precisa de download")
	assert_false(_vm.is_downloading(missing), "nada em download inicialmente")

	var changed: Array = []
	_vm.download_changed.connect(func(item_id: String) -> void: changed.append(item_id))
	_vm.download_asset(consumable)
	_vm.download_asset(null)
	assert_true(changed.is_empty(), "chamadas inválidas não emitem nada")


func test_equip_posts_context_and_refreshes() -> void:
	_repo.inventory_result = {"items": [_avatar("a-1"), _avatar("a-2")], "status_code": 200}
	await _vm.refresh()
	var unequipped := _avatar("a-1")
	var equipped := _avatar("a-2")
	equipped.equipped = true
	_repo.inventory_result = {"items": [unequipped, equipped], "status_code": 200}
	var actions: Array = []
	_vm.action_changed.connect(func(action_id: String) -> void: actions.append(action_id))

	await _vm.equip_item(_vm.items()[1] as InventoryItem)

	assert_eq(_repo.last_equip_id, "a-2", "POST com o id do item")
	assert_eq(_repo.last_equip_context, "PROFILE", "contexto do item no corpo")
	assert_eq(actions, ["equip:a-2", ""], "ação abre e fecha")
	assert_true((_vm.items()[1] as InventoryItem).equipped, "recarrega com o novo estado do servidor")


func test_equip_error_surfaces_and_skips_refresh() -> void:
	_repo.inventory_result = {"items": [_avatar("a-1")], "status_code": 200}
	await _vm.refresh()
	_repo.equip_result = {"error": "Item indisponível.", "status_code": 422}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.equip_item(_vm.items()[0] as InventoryItem)

	assert_eq(_repo.last_equip_id, "a-1", "tentou equipar")
	assert_eq(errors.back(), "Item indisponível.", "erro exibido na tela")
	assert_false((_vm.items()[0] as InventoryItem).equipped, "sem refresh em caso de erro")


func test_equip_guards_invalid_calls() -> void:
	await _vm.equip_item(null)
	await _vm.equip_item(_consumable("c-1"))
	await _vm.equip_item(_avatar("a-1", true))
	assert_true(_repo.last_equip_id.is_empty(), "nenhuma requisição inválida")
