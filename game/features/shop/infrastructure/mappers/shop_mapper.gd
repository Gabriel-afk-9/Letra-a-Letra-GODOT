extends RefCounted
class_name ShopMapper


static func offers_from_body(body: Dictionary) -> Array:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return []
	var data: Dictionary = data_variant
	var offers_variant = data.get("offers", [])
	if not offers_variant is Array:
		return []
	var offers: Array = []
	for item_variant in offers_variant:
		if not item_variant is Dictionary:
			continue
		var offer := ShopOffer.from_dictionary(item_variant)
		if offer != null and not offer.offer_id.is_empty():
			offers.append(offer)
	return offers
