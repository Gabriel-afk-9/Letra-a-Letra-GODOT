extends RefCounted
class_name InventoryItemFactory

static func avatar(item_id: String, equipped: bool = false, asset_path: String = "AVATAR/ceo.webp") -> InventoryItem:
	return InventoryItem.from_dictionary({
		"itemId": item_id,
		"name": "Avatar",
		"kind": "EQUIPPABLE",
		"category": "AVATAR",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": equipped,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": asset_path,
	})

static func banner(item_id: String) -> InventoryItem:
	return InventoryItem.from_dictionary({
		"itemId": item_id,
		"name": "Banner",
		"kind": "EQUIPPABLE",
		"category": "BANNER",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": false,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": "BANNER/green.webp",
	})

static func consumable(item_id: String, quantity: int = 2) -> InventoryItem:
	return InventoryItem.from_dictionary({
		"itemId": item_id,
		"name": "Gelo",
		"kind": "CONSUMABLE",
		"category": "EMOTE",
		"context": "MATCH",
		"quantity": quantity,
		"equipped": false,
		"acquiredAt": "2026-01-02T00:00:00Z",
		"expiresAt": "",
		"assetPath": "",
	})

static func board(item_id: String) -> InventoryItem:
	return InventoryItem.from_dictionary({
		"itemId": item_id,
		"name": "Tabuleiro",
		"kind": "EQUIPPABLE",
		"category": "BOARD",
		"context": "MATCH",
		"quantity": 1,
		"equipped": false,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": "BOARD/t1.webp",
	})
