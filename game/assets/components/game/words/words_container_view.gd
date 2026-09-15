extends PanelContainer
class_name WordsContainerView


const WORD_PILL_SCENE := preload("res://assets/components/game/words/word_pill.tscn")

var _flow: HFlowContainer

var _last_signature: String = ""


func _ready() -> void:
	_flow = get_node_or_null("WordsContainer") as HFlowContainer
	if _flow != null:
		_flow.alignment = FlowContainer.ALIGNMENT_CENTER
		_flow.add_theme_constant_override("h_separation", 12)
		_flow.add_theme_constant_override("v_separation", 10)


func update_words(items: Array) -> void:
	if _flow == null:
		_flow = get_node_or_null("WordsContainer") as HFlowContainer
		if _flow == null:
			return
	var sig := _signature(items)
	if sig == _last_signature:
		return
	_last_signature = sig
	_rebuild(items)


func force_refresh_signature() -> void:
	_last_signature = ""


func get_flow() -> HFlowContainer:
	if _flow == null:
		_flow = get_node_or_null("WordsContainer") as HFlowContainer
	return _flow


func _signature(items: Array) -> String:
	var parts: Array = []
	for entry in items:
		if entry is Dictionary:
			var d: Dictionary = entry
			parts.append("%s|%s|%s" % [str(d.get("text", "")), str(d.get("found", false)), str(d.get("found_by", ""))])
		else:
			parts.append(str(entry))
	return "|".join(parts)


func _rebuild(items: Array) -> void:
	for child in _flow.get_children():
		child.queue_free()
	for entry in items:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var text: String = str(d.get("text", ""))
		if text.is_empty():
			continue
		var owner: String = str(d.get("owner", ""))
		var pill: WordPill = WORD_PILL_SCENE.instantiate()
		_flow.add_child(pill)
		pill.setup(text, owner)
