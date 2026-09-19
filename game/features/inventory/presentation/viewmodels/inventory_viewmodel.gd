extends BaseViewModel
class_name InventoryViewModel

# Expõe o inventário real do jogador (GET /user/items) para a tela.
# Semeia a pintura instantânea com o InitialDataStore quando disponível
# e sempre atualiza com a API ao abrir a tela.
signal inventory_changed
signal asset_changed(item_id: String)
signal download_changed(item_id: String)

const TAB_ORDER: Array = ["AVATAR", "BANNER", "FRAME", "EMOTE", "BOARD", "CELL"]
const TAB_CONSUMABLE := "CONSUMABLE"
const TAB_OTHERS := "OUTROS"

var _usecase: InventoryUseCase
var _assets: EquippableAssetService
var _data_store: InitialDataStore
var _items: Array = []
var _seeded_from_store: bool = false


func _init(
	usecase: InventoryUseCase,
	assets: EquippableAssetService,
	data_store: InitialDataStore = null
) -> void:
	_usecase = usecase
	_assets = assets
	_data_store = data_store
	if _assets != null:
		_assets.asset_ready.connect(_on_asset_ready)
		_assets.download_failed.connect(_on_download_failed)


func asset_service() -> EquippableAssetService:
	return _assets


func load_initial() -> void:
	if not _seeded_from_store and _data_store != null and _data_store.is_inventory_loaded():
		_seeded_from_store = true
		_items = _data_store.get_inventory()
		inventory_changed.emit()
	await refresh()


func refresh() -> void:
	if is_loading():
		return
	_set_loading(true)
	_clear_error()
	var result: Dictionary = await _usecase.fetch_my_inventory()
	_set_loading(false)
	if result.has("error"):
		_set_error(str(result["error"]))
		inventory_changed.emit()
		return
	_items = result.get("items", [])
	inventory_changed.emit()


func items() -> Array:
	return _items


func has_items() -> bool:
	return not _items.is_empty()


func load_failed() -> bool:
	return has_error() and _items.is_empty()


# Todas as seções são sempre exibidas, mesmo vazias: uma aba por
# categoria equipável conhecida, seguida de categorias extras presentes
# nos dados (ordem alfabética) e da aba de consumíveis por último.
func categories() -> Array:
	var found: Array = []
	for item_variant in _items:
		var item := item_variant as InventoryItem
		if item == null:
			continue
		if EquippableAssetPaths.is_equippable(item):
			var category := EquippableAssetPaths.tab_of(item)
			if not found.has(category):
				found.append(category)
	var ordered: Array = []
	for preferred in TAB_ORDER:
		ordered.append(preferred)
	var extra: Array = []
	for category_variant in found:
		var category := str(category_variant)
		if not TAB_ORDER.has(category) and not extra.has(category):
			extra.append(category)
	extra.sort()
	ordered.append_array(extra)
	ordered.append(TAB_CONSUMABLE)
	return ordered


func items_for(tab: String) -> Array:
	var result: Array = []
	for item_variant in _items:
		var item := item_variant as InventoryItem
		if item == null:
			continue
		if tab == TAB_CONSUMABLE:
			if not EquippableAssetPaths.is_equippable(item):
				result.append(item)
		elif EquippableAssetPaths.is_equippable(item) and EquippableAssetPaths.tab_of(item) == tab:
			result.append(item)
	return result


func is_consumable_tab(tab: String) -> bool:
	return tab == TAB_CONSUMABLE


func texture_for(item: InventoryItem) -> Texture2D:
	if _assets == null:
		return null
	return _assets.texture_for(item)


func needs_download(item: InventoryItem) -> bool:
	if _assets == null:
		return false
	return _assets.needs_download(item)


func is_downloading(item: InventoryItem) -> bool:
	if _assets == null:
		return false
	return _assets.is_downloading(item)


func download_asset(item: InventoryItem) -> void:
	if item == null or _assets == null:
		return
	if is_downloading(item):
		return
	if not needs_download(item):
		return
	download_changed.emit(item.item_id)
	await _assets.download(item)


func _on_asset_ready(item_id: String) -> void:
	asset_changed.emit(item_id)


func _on_download_failed(item_id: String, error_message: String) -> void:
	download_changed.emit(item_id)
	_set_error(error_message)
