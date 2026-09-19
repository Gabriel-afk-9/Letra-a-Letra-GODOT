extends GutTest

var _words: WordsContainerView
var _effect: EffectOverlay
var _blind: BlindVignette
var _player: PlayerInfoBar

func before_each() -> void:
	var w_scene: PackedScene = load("res://assets/components/game/words/words_container_view.tscn")
	_words = w_scene.instantiate()
	add_child(_words)
	await get_tree().process_frame
	var e_scene: PackedScene = load("res://assets/components/game/overlays/effect_overlay.tscn")
	_effect = e_scene.instantiate()
	add_child(_effect)
	await get_tree().process_frame
	var b_scene: PackedScene = load("res://assets/components/game/overlays/blind_vignette.tscn")
	_blind = b_scene.instantiate()
	add_child(_blind)
	await get_tree().process_frame
	var p_scene: PackedScene = load("res://assets/components/game/player/player_info_bar.tscn")
	_player = p_scene.instantiate()
	add_child(_player)
	await get_tree().process_frame

func after_each() -> void:
	_words.queue_free()
	_effect.queue_free()
	_blind.queue_free()
	_player.queue_free()

func test_effect_overlay_constants_and_show_hide() -> void:
	assert_eq(EffectOverlay.EFFECT_OVERLAY_FADE, 0.3, "fade 0.3")
	var gd = FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("EFFECT_FREEZE_COLOR") and gd.contains("0.2, 0.5, 1.0, 0.25"), "FREEZE color 0.2 0.5 1 0.25")
	assert_true(gd.contains("EFFECT_IMMUNITY_COLOR") and gd.contains("1.0, 0.55, 0.1, 0.35"), "IMMUNITY 1 0.55 0.1 0.35")
	assert_true(gd.contains("EFFECT_LANTERN_FLASH") and gd.contains("1, 1, 1, 0.6"), "LANTERN FLASH 1 1 1 0.6")
	assert_true(gd.contains("UNFREEZE_HOT_HOLD") and gd.contains("2.0"), "UNFREEZE hold 2.0")
	assert_true(gd.contains("flash(EFFECT_LANTERN_FLASH, 0.5)"), "flash lantern 0.5 deve existir")
	assert_true(gd.contains("flash(EFFECT_UNFREEZE_HOT, UNFREEZE_HOT_HOLD)"), "flash unfreeze 2.0 deve existir")
	assert_eq(_effect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "effect IGNORE")
	assert_eq(_effect.modulate.a, 0.0, "effect inicia invisível")
	_effect.show_with_color(Color(0.2, 0.5, 1.0, 0.25))
	await get_tree().process_frame
	assert_true(_effect.visible, "show deve tornar visível")
	_effect.hide_overlay()
	await get_tree().process_frame

func test_blind_vignette_and_game_over_overlay() -> void:
	assert_eq(_blind.mouse_filter, Control.MOUSE_FILTER_IGNORE, "blind IGNORE")
	var tscn = FileAccess.get_file_as_string("res://assets/components/game/overlays/blind_vignette.tscn")
	assert_true(tscn.contains("mouse_filter = 2") or tscn.contains("MOUSE_FILTER_IGNORE"), "blind vignette deve ser IGNORE")
	var go_gd = FileAccess.get_file_as_string("res://assets/components/game/overlays/game_over_overlay.gd")
	assert_true(go_gd.contains("show_result"), "GameOver deve ter show_result")
	assert_true(go_gd.contains("0.2, 1, 0.2") or go_gd.contains("0.2, 1.0, 0.2"), "win verde deve existir")
	var go_tscn = FileAccess.get_file_as_string("res://assets/components/game/overlays/game_over_overlay.tscn")
	assert_true(go_tscn.contains("custom_minimum_size = Vector2(320"), "GameOver Panel 320")
	assert_true(go_tscn.contains("corner_radius_top_left = 12"), "corner 12")

func test_words_container_update_and_signature() -> void:
	assert_eq(_words.custom_minimum_size.y, 72.0, "words wrapper 72")
	assert_true(_words.clip_contents, "words deve clip")
	var flow: HFlowContainer = _words.get_flow()
	assert_eq(flow.get_theme_constant("h_separation"), 12, "h_separation 12")
	assert_eq(flow.get_theme_constant("v_separation"), 10, "v_separation 10")
	_words.update_words([{"text": "CASA", "owner": "me", "found": false, "found_by": ""}, {"text": "MAR", "owner": "opponent", "found": true, "found_by": "opp"}])
	await get_tree().process_frame
	assert_eq(flow.get_child_count(), 2, "deve criar 2 WordPills")
	_words.update_words([{"text": "CASA", "owner": "me", "found": false, "found_by": ""}, {"text": "MAR", "owner": "opponent", "found": true, "found_by": "opp"}])
	await get_tree().process_frame
	assert_eq(flow.get_child_count(), 2, "mesma signature não deve recriar")
	_words.force_refresh_signature()
	_words.update_words([{"text": "NOVO", "owner": "me", "found": false, "found_by": ""}])
	await get_tree().process_frame
	assert_eq(flow.get_child_count(), 1, "force_refresh deve recriar com 1")

func test_player_info_bar_turn_and_cards() -> void:
	var tscn = FileAccess.get_file_as_string("res://assets/components/game/player/player_info_bar.tscn")
	assert_true(tscn.contains("MyCardWrapper") and tscn.contains("Vector2(220, 70)"), "MyCard 220x70")
	assert_true(tscn.contains("OpponentCardWrapper") and tscn.contains("Vector2(220, 70)"), "OpponentCard 220x70")
	_player.setup_players("Eu", "Adv")
	await get_tree().process_frame
	_player.set_turn(true)
	await get_tree().process_frame
	_player.set_turn_seconds(30.0)
	await get_tree().process_frame
	var turn_label: Label = _player.get_node_or_null("TurnLabel") as Label
	if turn_label != null:
		assert_true(turn_label.text.length() > 0, "TurnLabel deve mostrar texto")
	assert_not_null(_player.get_node_or_null("CardsCenter/MyCardWrapper"), "MyCardWrapper deve existir")
	assert_not_null(_player.get_node_or_null("CardsCenter/OpponentCardWrapper"), "OpponentCardWrapper deve existir")

