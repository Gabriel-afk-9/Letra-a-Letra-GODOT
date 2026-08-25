extends RefCounted

class_name GamePlayerStateMapper


static func to_domain(data: Dictionary) -> GamePlayerState:
	var raw_id = data.get("id")

	var parsed_id := ""
	if raw_id != null:
		parsed_id = str(raw_id)

	var parsed_inventory: Array[GamePower] = []

	var raw_inventory = data.get("inventory")

	if raw_inventory is Array:
		var inventory: Array = raw_inventory

		for index in GamePlayerState.INVENTORY_SIZE:
			if index >= inventory.size():
				parsed_inventory.append(null)
				continue

			var raw_power = inventory[index]

			if raw_power is Dictionary:
				parsed_inventory.append(GamePowerMapper.to_domain(raw_power))
			else:
				parsed_inventory.append(null)
	else:
		for index in GamePlayerState.INVENTORY_SIZE:
			parsed_inventory.append(null)

	return GamePlayerState.new(parsed_id, parsed_inventory)
