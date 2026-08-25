class_name GamePowerCatalog


const POWER_TYPE_FREEZE := "FREEZE"
const POWER_TYPE_UNFREEZE := "UNFREEZE"
const POWER_TYPE_BLIND := "BLIND"
const POWER_TYPE_LANTERN := "LANTERN"
const POWER_TYPE_IMMUNITY := "IMMUNITY"
const POWER_TYPE_DETECT_TRAPS := "DETECT_TRAPS"
const POWER_TYPE_BLOCK := "BLOCK"
const POWER_TYPE_UNBLOCK := "UNBLOCK"
const POWER_TYPE_SPY := "SPY"
const POWER_TYPE_TRAP := "TRAP"


const SCOPE_GLOBAL := "GLOBAL"
const SCOPE_CELL := "CELL"


# Raridades espelham o enum PowerRarity do backend. O valor por tipo vem de
# PowerType.java (metadado fixo do tipo, não da instância).
const RARITY_COMMON := "COMMON"
const RARITY_RARE := "RARE"
const RARITY_EPIC := "EPIC"
const RARITY_LEGENDARY := "LEGENDARY"


const POWER_TABLE: Dictionary = {
	POWER_TYPE_FREEZE: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": true,
		"can_use_while_frozen": false,
		"rarity": RARITY_RARE
	},
	POWER_TYPE_UNFREEZE: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": false,
		"can_use_while_frozen": true,
		"rarity": RARITY_RARE
	},
	POWER_TYPE_BLIND: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": true,
		"can_use_while_frozen": false,
		"rarity": RARITY_EPIC
	},
	POWER_TYPE_LANTERN: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": false,
		"can_use_while_frozen": false,
		"rarity": RARITY_EPIC
	},
	POWER_TYPE_IMMUNITY: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": false,
		"can_use_while_frozen": true,
		"rarity": RARITY_LEGENDARY
	},
	POWER_TYPE_DETECT_TRAPS: {
		"scope": SCOPE_GLOBAL,
		"is_offensive": false,
		"can_use_while_frozen": false,
		"rarity": RARITY_COMMON
	},
	POWER_TYPE_BLOCK: {
		"scope": SCOPE_CELL,
		"is_offensive": true,
		"can_use_while_frozen": false,
		"rarity": RARITY_COMMON
	},
	POWER_TYPE_UNBLOCK: {
		"scope": SCOPE_CELL,
		"is_offensive": false,
		"can_use_while_frozen": false,
		"rarity": RARITY_COMMON
	},
	POWER_TYPE_SPY: {
		"scope": SCOPE_CELL,
		"is_offensive": false,
		"can_use_while_frozen": false,
		"rarity": RARITY_RARE
	},
	POWER_TYPE_TRAP: {
		"scope": SCOPE_CELL,
		"is_offensive": true,
		"can_use_while_frozen": false,
		"rarity": RARITY_COMMON
	}
}


static func get_scope(power_type: String) -> String:
	var entry = POWER_TABLE.get(power_type)

	if entry is Dictionary:
		return str(entry.get("scope", SCOPE_GLOBAL))

	return SCOPE_GLOBAL


static func is_offensive(power_type: String) -> bool:
	var entry = POWER_TABLE.get(power_type)

	if entry is Dictionary:
		return bool(entry.get("is_offensive", false))

	return false


static func can_use_while_frozen(power_type: String) -> bool:
	var entry = POWER_TABLE.get(power_type)

	if entry is Dictionary:
		return bool(entry.get("can_use_while_frozen", false))

	return false


static func get_rarity(power_type: String) -> String:
	var entry = POWER_TABLE.get(power_type)

	if entry is Dictionary:
		return str(entry.get("rarity", ""))

	return ""
