extends RefCounted

class_name GamePowerMapper


static func to_domain(data: Dictionary) -> GamePower:
	var raw_id = data.get("id")
	var raw_type = data.get("name")
	var raw_rarity = data.get("rarity")

	var parsed_id := ""
	if raw_id != null:
		parsed_id = str(raw_id)

	var parsed_type := ""
	if raw_type != null:
		parsed_type = str(raw_type)

	var parsed_rarity := ""
	if raw_rarity != null:
		parsed_rarity = str(raw_rarity)

	# Payload sem raridade (estado atual do backend) — resolve pelo tipo.
	if parsed_rarity.is_empty():
		parsed_rarity = GamePowerCatalog.get_rarity(parsed_type)

	return GamePower.new(parsed_id, parsed_type, parsed_rarity)
