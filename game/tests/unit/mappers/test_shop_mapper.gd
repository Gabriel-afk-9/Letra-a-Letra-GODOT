extends GutTest


func test_offers_from_body_parses_active_offers() -> void:
	var body := {
		"success": true,
		"data": {
			"offers": [
				{
					"offerId": "o-1",
					"title": "Pacote Inicial",
					"coinType": "SOFT",
					"price": 99.0,
					"rewards": [{"offerRewardId": "r-1"}],
					"repeatable": false,
					"active": true,
					"hasExpiration": false,
					"expiresAt": "",
					"createdAt": "2026-01-01T00:00:00Z",
				},
				{
					"offerId": "o-2",
					"title": "Gemas x10",
					"coinType": "HARD",
					"price": 10.0,
					"rewards": [],
					"repeatable": true,
					"active": true,
					"hasExpiration": true,
					"expiresAt": "2026-12-31T00:00:00Z",
					"createdAt": "2026-01-02T00:00:00Z",
				},
			]
		}
	}

	var offers := ShopMapper.offers_from_body(body)

	assert_eq(offers.size(), 2)
	assert_eq(offers[0].offer_id, "o-1")
	assert_eq(offers[0].title, "Pacote Inicial")
	assert_eq(offers[0].coin_type, "SOFT")
	assert_eq(offers[1].repeatable, true)
	assert_eq(offers[1].expires_at, "2026-12-31T00:00:00Z")


func test_offers_from_body_skips_invalid_entries() -> void:
	var body := {
		"data": {
			"offers": [
				{"title": "Sem id"},
				"nao-um-dicionario",
				{"offerId": "o-9", "title": "Válida"},
			]
		}
	}

	var offers := ShopMapper.offers_from_body(body)

	assert_eq(offers.size(), 1)
	assert_eq(offers[0].offer_id, "o-9")


func test_offers_from_body_empty_without_data() -> void:
	assert_eq(ShopMapper.offers_from_body({}), [])
	assert_eq(ShopMapper.offers_from_body({"data": {}}), [])
	assert_eq(ShopMapper.offers_from_body({"data": {"offers": {}}}), [])
