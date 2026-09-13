extends RefCounted
class_name Friendship

const STATUS_ACCEPT := "ACCEPT"
const STATUS_DECLINED := "DECLINED"
const STATUS_PENDING := "PENDING"

const DIRECTION_SENT := "SENT"
const DIRECTION_RECEIVED := "RECEIVED"

var user_id_1: String
var user_id_2: String
var friend_id: String
var direction: String
var status: String
var request_date: String
var nickname: String
var equipped: Array


func _init(
	p_user_id_1: String = "",
	p_user_id_2: String = "",
	p_status: String = STATUS_PENDING,
	p_request_date: String = "",
	p_friend_id: String = "",
	p_direction: String = "",
	p_nickname: String = "",
	p_equipped: Array = []
) -> void:
	user_id_1 = p_user_id_1
	user_id_2 = p_user_id_2
	status = p_status
	request_date = p_request_date
	friend_id = p_friend_id
	direction = p_direction
	nickname = p_nickname
	equipped = p_equipped


func display_name(fallback_prefix: String, fallback_id: String) -> String:
	if not nickname.strip_edges().is_empty():
		return nickname
	var short := Friendship.short_id(fallback_id)
	if fallback_prefix.strip_edges().is_empty():
		return short
	return "%s %s" % [fallback_prefix, short]


func equipped_art(cosmetic_type: String) -> Texture2D:
	return CosmeticArt.equipped_art(equipped, cosmetic_type)


func sender_id() -> String:
	return user_id_1


func other_id(my_id: String) -> String:
	if not friend_id.is_empty():
		return friend_id
	if user_id_1 == my_id:
		return user_id_2
	return user_id_1


func is_sent() -> bool:
	return direction == DIRECTION_SENT


func date_short() -> String:
	if request_date.length() >= 10:
		return request_date.left(10)
	return request_date


static func short_id(user_id: String) -> String:
	if user_id.length() > 8:
		return user_id.left(8)
	return user_id
