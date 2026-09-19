extends GutTest


func test_items_from_body_parses_user_items() -> void:
	var body := {
		"success": true,
		"data": {
			"items": [
				{
					"itemId": "i-1",
					"name": "Avatar Coruja",
					"kind": "EQUIPPABLE",
					"category": "AVATAR",
					"context": "PROFILE",
					"quantity": 1,
					"equipped": true,
					"acquiredAt": "2026-01-01T00:00:00Z",
					"expiresAt": "",
					"assetPath": "res://assets/cosmetics/avatar/owl.png",
				},
				{
					"itemId": "i-2",
					"name": "Congelar",
					"kind": "CONSUMABLE",
					"category": "EMOTE",
					"context": "MATCH",
					"quantity": 3,
					"equipped": false,
					"acquiredAt": "2026-01-02T00:00:00Z",
					"expiresAt": "",
					"assetPath": "",
				},
			]
		}
	}

	var items := InventoryMapper.items_from_body(body)

	assert_eq(items.size(), 2)
	assert_eq(items[0].item_id, "i-1")
	assert_eq(items[0].category, "AVATAR")
	assert_eq(items[0].equipped, true)
	assert_eq(items[1].kind, "CONSUMABLE")
	assert_eq(items[1].quantity, 3)


func test_items_from_body_skips_invalid_entries() -> void:
	var body := {
		"data": {
			"items": [
				{"name": "Sem id"},
				42,
				{"itemId": "i-9", "name": "Válido"},
			]
		}
	}

	var items := InventoryMapper.items_from_body(body)

	assert_eq(items.size(), 1)
	assert_eq(items[0].item_id, "i-9")


func test_items_from_body_empty_without_data() -> void:
	assert_eq(InventoryMapper.items_from_body({}), [])
	assert_eq(InventoryMapper.items_from_body({"data": {}}), [])
	assert_eq(InventoryMapper.items_from_body({"data": {"items": {}}}), [])
