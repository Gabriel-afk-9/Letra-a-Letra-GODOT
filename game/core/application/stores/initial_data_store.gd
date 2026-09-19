extends RefCounted
class_name InitialDataStore

# Cache em memória dos dados pré-carregados pela Loading Screen.
# Instância única detida pelo ServiceRegistry (ver service_registry.gd).
var _user: User = null
var _offers: Array = []
var _inventory: Array = []
var _friends: Array = []
var _pending: Array = []
var _sent: Array = []
var _friends_page: int = 0
var _friends_total_pages: int = 1
var _friends_total_elements: int = 0

var _profile_loaded: bool = false
var _shop_loaded: bool = false
var _inventory_loaded: bool = false
var _friends_loaded: bool = false


func set_user(user: User) -> void:
	_user = user
	_profile_loaded = true


func set_offers(offers: Array) -> void:
	_offers = offers
	_shop_loaded = true


func set_inventory(items: Array) -> void:
	_inventory = items
	_inventory_loaded = true


func set_friends(friends: Array, page: int, total_pages: int, total_elements: int) -> void:
	_friends = friends
	_friends_page = page
	_friends_total_pages = total_pages
	_friends_total_elements = total_elements


func set_pending(requests: Array) -> void:
	_pending = requests


func set_sent(requests: Array) -> void:
	_sent = requests


func mark_friends_loaded() -> void:
	_friends_loaded = true


func get_user() -> User:
	return _user


func get_offers() -> Array:
	return _offers


func get_inventory() -> Array:
	return _inventory


func get_friends() -> Array:
	return _friends


func get_pending() -> Array:
	return _pending


func get_sent() -> Array:
	return _sent


func get_friends_page() -> int:
	return _friends_page


func get_friends_total_pages() -> int:
	return _friends_total_pages


func get_friends_total_elements() -> int:
	return _friends_total_elements


func has_user() -> bool:
	return _user != null


func is_profile_loaded() -> bool:
	return _profile_loaded


func is_shop_loaded() -> bool:
	return _shop_loaded


func is_inventory_loaded() -> bool:
	return _inventory_loaded


func is_friends_loaded() -> bool:
	return _friends_loaded


func is_ready() -> bool:
	return _profile_loaded and _shop_loaded and _inventory_loaded and _friends_loaded


func clear() -> void:
	_user = null
	_offers = []
	_inventory = []
	_friends = []
	_pending = []
	_sent = []
	_friends_page = 0
	_friends_total_pages = 1
	_friends_total_elements = 0
	_profile_loaded = false
	_shop_loaded = false
	_inventory_loaded = false
	_friends_loaded = false
