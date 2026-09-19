extends GutTest

var _panel: InventoryPanel

func before_each() -> void:
	var scene: PackedScene = load("res://assets/components/game/inventory/inventory_panel.tscn")
	_panel = scene.instantiate()
	add_child(_panel)
	await get_tree().process_frame

func after_each() -> void:
	_panel.queue_free()

func test_apply_responsive_clamps() -> void:
	_panel.apply_responsive(300.0)
	assert_almost_eq(_panel.custom_minimum_size.x, 280.0, 0.01, "300*0.68=204 clamp 280")
	assert_eq(_panel.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "SHRINK_CENTER")
	_panel.apply_responsive(480.0)
	assert_almost_eq(_panel.custom_minimum_size.x, 326.4, 0.01, "480*0.68=326.4")
	_panel.apply_responsive(600.0)
	assert_almost_eq(_panel.custom_minimum_size.x, 340.0, 0.01, "600*0.68=408 clamp 340")
	_panel.apply_responsive(456.0)
	assert_almost_eq(_panel.custom_minimum_size.x, 310.08, 0.01, "456*0.68=310.08")

func test_update_inventory_sorts_by_seen_seq() -> void:
	var p1 : GamePower = GamePower.new("id-1", "FREEZE", "RARE")
	var p2 : GamePower = GamePower.new("id-2", "BLIND", "EPIC")
	_panel.update_inventory([p2, p1], false)
	assert_eq(_panel.get_power_id_at(0), "id-2", "ordem vista p2 primeiro")
	assert_eq(_panel.get_power_id_at(1), "id-1", "ordem vista p1 segundo")
	_panel.update_inventory([p1, p2], false)
	assert_eq(_panel.get_power_id_at(0), "id-2", "deve manter ordem original por seen_seq")
	assert_eq(_panel.get_power_id_at(1), "id-1", "deve manter ordem original")
	_panel.update_inventory([p1], false)
	assert_eq(_panel.get_power_id_at(0), "id-1", "após remover p2, p1 sozinho")
	assert_eq(_panel.get_power_id_at(1), "", "slot 1 vazio")

func test_update_inventory_frozen_disables_non_defense() -> void:
	var p_freeze : GamePower = GamePower.new("id-freeze", "FREEZE", "RARE")
	var p_trap : GamePower = GamePower.new("id-trap", "TRAP", "COMMON")
	_panel.update_inventory([p_freeze, p_trap], true)
	var slots: Array = _panel.get_node("InventoryContainer").get_children()
	var slot_trap: InventorySlot = slots[1] as InventorySlot
	var icon_trap: TextureButton = slot_trap.get_node("Icon") as TextureButton
	assert_true(icon_trap.disabled, "TRAP deve desabilitar quando frozen")
	var slot_freeze: InventorySlot = slots[0] as InventorySlot
	var icon_freeze: TextureButton = slot_freeze.get_node("Icon") as TextureButton
	assert_true(icon_freeze.disabled, "FREEZE deve desabilitar quando frozen")
	var p_unfreeze : GamePower = GamePower.new("id-unfreeze", "UNFREEZE", "RARE")
	_panel.update_inventory([p_unfreeze], true)
	var slot_unfreeze: InventorySlot = slots[0] as InventorySlot
	var icon_unfreeze: TextureButton = slot_unfreeze.get_node("Icon") as TextureButton
	assert_false(icon_unfreeze.disabled, "UNFREEZE deve estar habilitado enquanto frozen")
	var p_immunity : GamePower = GamePower.new("id-immunity", "IMMUNITY", "LEGENDARY")
	_panel.update_inventory([p_immunity], true)
	var slot_imm: InventorySlot = slots[0] as InventorySlot
	var icon_imm: TextureButton = slot_imm.get_node("Icon") as TextureButton
	assert_false(icon_imm.disabled, "IMMUNITY deve estar habilitado enquanto frozen")

func test_set_armed_and_defense_pulse_and_flash() -> void:
	var p1 : GamePower = GamePower.new("id-a", "FREEZE", "RARE")
	var p2 : GamePower = GamePower.new("id-b", "UNFREEZE", "RARE")
	_panel.update_inventory([p1, p2], false)
	_panel.set_armed("id-a", GamePowerCatalog.SCOPE_GLOBAL, false, false)
	await get_tree().process_frame
	_panel.set_defense_pulse(["id-b"])
	await get_tree().process_frame
	var slots: Array = _panel.get_node("InventoryContainer").get_children()
	var slot_b: InventorySlot = slots[1] as InventorySlot
	assert_true(slot_b.has_meta("defense_pulse"), "UNFREEZE deve ter pulse")
	_panel.set_defense_pulse([])
	await get_tree().process_frame
	assert_false(slot_b.has_meta("defense_pulse"), "pulse deve limpar")
	_panel.flash_grant("id-a")
	await get_tree().process_frame
	assert_not_null(slot_b, "flash não deve quebrar")

func test_get_power_id_at_bounds() -> void:
	var p1 : GamePower = GamePower.new("id-x", "SPY", "RARE")
	_panel.update_inventory([p1], false)
	assert_eq(_panel.get_power_id_at(0), "id-x", "slot 0 deve retornar id")
	assert_eq(_panel.get_power_id_at(1), "", "slot vazio deve retornar vazio")
	assert_eq(_panel.get_power_id_at(-1), "", "negativo deve retornar vazio")
	assert_eq(_panel.get_power_id_at(10), "", "out of bounds deve retornar vazio")
