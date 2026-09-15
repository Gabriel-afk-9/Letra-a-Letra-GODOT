extends PanelContainer
class_name InventoryPanel

signal slot_pressed(index: int)
signal slot_drag_launch(index: int)
signal slot_drag_discard(index: int)

var _slots: Array = []
var _cached_inventory: Array = []
var _power_seen_seq: Dictionary = {}
var _power_seq_counter: int = 0
var _armed_id: String = ""
var _armed_scope: String = ""
var _is_frozen: bool = false
var _is_blinded: bool = false
var _pulse_ids: Array = []

@onready var _container: HBoxContainer = $InventoryContainer


func _ready() -> void:
	_container = get_node_or_null("InventoryContainer") as HBoxContainer
	if _container == null:
		return
	_slots.clear()
	for i in _container.get_child_count():
		var child := _container.get_child(i)
		if child is InventorySlot:
			var slot: InventorySlot = child as InventorySlot
			slot.setup(i)
			if not slot.slot_pressed.is_connected(_on_slot_pressed):
				slot.slot_pressed.connect(_on_slot_pressed)
			if not slot.slot_drag_launch.is_connected(_on_slot_drag_launch):
				slot.slot_drag_launch.connect(_on_slot_drag_launch)
			if not slot.slot_drag_discard.is_connected(_on_slot_drag_discard):
				slot.slot_drag_discard.connect(_on_slot_drag_discard)
			_slots.append(slot)


func update_inventory(inventory: Array, is_frozen: bool) -> void:
	_is_frozen = is_frozen
	var present: Array = []
	for item in inventory:
		if not (item is GamePower):
			continue
		var power: GamePower = item
		if not _power_seen_seq.has(power.id):
			_power_seq_counter += 1
			_power_seen_seq[power.id] = _power_seq_counter
		present.append(power)
	present.sort_custom(func(a: GamePower, b: GamePower) -> bool: return int(_power_seen_seq[a.id]) < int(_power_seen_seq[b.id]))
	var present_ids := {}
	for p in present:
		present_ids[(p as GamePower).id] = true
	for seen_id in _power_seen_seq.keys():
		if not present_ids.has(seen_id):
			_power_seen_seq.erase(seen_id)
	_cached_inventory = present
	_refresh_slots_power()


func _refresh_slots_power() -> void:
	for idx in _slots.size():
		var power: Variant = _cached_inventory[idx] if idx < _cached_inventory.size() else null
		_slots[idx].set_power(power, _is_frozen)
	_refresh_armed()
	_refresh_defense_pulse()


func set_armed(armed_id: String, scope: String, is_frozen: bool, is_blinded: bool) -> void:
	_armed_id = armed_id
	_armed_scope = scope
	_is_frozen = is_frozen
	_is_blinded = is_blinded
	_refresh_armed()


func _refresh_armed() -> void:
	for idx in _slots.size():
		var power: Variant = _cached_inventory[idx] if idx < _cached_inventory.size() else null
		var is_armed: bool = power is GamePower and (power as GamePower).id == _armed_id
		var is_defense_armed: bool = false
		if is_armed and power is GamePower:
			var t: String = (power as GamePower).type
			if _is_frozen and GamePowerCatalog.get_counters_for_debuff("PLAYER_FROZEN").has(t):
				is_defense_armed = true
			elif _is_blinded and GamePowerCatalog.get_counters_for_debuff("PLAYER_BLINDED").has(t):
				is_defense_armed = true
		_slots[idx].set_armed(is_armed, _armed_scope, is_defense_armed)


func set_defense_pulse(pulse_ids: Array) -> void:
	_pulse_ids = pulse_ids.duplicate()
	_refresh_defense_pulse()


func _refresh_defense_pulse() -> void:
	for idx in _slots.size():
		var power: Variant = _cached_inventory[idx] if idx < _cached_inventory.size() else null
		var should_pulse: bool = power is GamePower and _pulse_ids.has((power as GamePower).id)
		_slots[idx].set_defense_pulse(should_pulse)


func flash_grant(power_id: String) -> void:
	for idx in _cached_inventory.size():
		var p: Variant = _cached_inventory[idx]
		if p is GamePower and (p as GamePower).id == power_id and idx < _slots.size():
			_slots[idx].flash_grant()
			return


func apply_responsive(layout_w: float) -> void:
	var panel_w: float = clamp(layout_w * 0.68, 280.0, 340.0)
	custom_minimum_size = Vector2(panel_w, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func refresh_for_effect(is_frozen: bool, is_blinded: bool) -> void:
	_is_frozen = is_frozen
	_is_blinded = is_blinded
	for idx in _slots.size():
		var power: Variant = _cached_inventory[idx] if idx < _cached_inventory.size() else null
		_slots[idx].set_power(power, _is_frozen)
	_refresh_armed()
	_refresh_defense_pulse()


func get_power_id_at(index: int) -> String:
	if index < 0 or index >= _cached_inventory.size():
		return ""
	var p: Variant = _cached_inventory[index]
	if p is GamePower:
		return (p as GamePower).id
	return ""


func _on_slot_pressed(index: int) -> void:
	slot_pressed.emit(index)


func _on_slot_drag_launch(index: int) -> void:
	slot_drag_launch.emit(index)


func _on_slot_drag_discard(index: int) -> void:
	slot_drag_discard.emit(index)
