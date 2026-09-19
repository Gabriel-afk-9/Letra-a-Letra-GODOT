extends RefCounted
class_name ShopOffer

# Oferta da loja (GET /shop/offers, schema Offer em docs/api.json).
var offer_id: String
var title: String
var coin_type: String
var price: float
var rewards: Array
var repeatable: bool
var active: bool
var has_expiration: bool
var expires_at: String
var created_at: String


func _init(
	p_offer_id: String = "",
	p_title: String = "",
	p_coin_type: String = "",
	p_price: float = 0.0,
	p_rewards: Array = [],
	p_repeatable: bool = false,
	p_active: bool = true,
	p_has_expiration: bool = false,
	p_expires_at: String = "",
	p_created_at: String = ""
) -> void:
	offer_id = p_offer_id
	title = p_title
	coin_type = p_coin_type
	price = p_price
	rewards = p_rewards
	repeatable = p_repeatable
	active = p_active
	has_expiration = p_has_expiration
	expires_at = p_expires_at
	created_at = p_created_at


static func from_dictionary(data: Dictionary) -> ShopOffer:
	if data.is_empty():
		return null
	var rewards_variant = data.get("rewards", [])
	var rewards: Array = rewards_variant if rewards_variant is Array else []
	return ShopOffer.new(
		str(data.get("offerId", "")),
		str(data.get("title", "")),
		str(data.get("coinType", "")),
		float(data.get("price", 0.0)),
		rewards,
		bool(data.get("repeatable", false)),
		bool(data.get("active", true)),
		bool(data.get("hasExpiration", false)),
		str(data.get("expiresAt", "")),
		str(data.get("createdAt", ""))
	)
