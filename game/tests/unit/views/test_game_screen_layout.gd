extends GutTest

func test_words_wrapper_is_72_fixed_and_shrink_center() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	var words_tscn := FileAccess.get_file_as_string("res://assets/components/game/words/words_container_view.tscn")
	assert_true(gd.contains("custom_minimum_size = Vector2(0, 72)") or words_tscn.contains("custom_minimum_size = Vector2(0, 72)"), "wrapper should be 72 fixed")
	assert_true(gd.contains("CLIP") or gd.contains("clip_contents") or words_tscn.contains("clip_contents"), "wrapper should clip")
	assert_true(words_tscn.contains("size_flags_horizontal = 3") or words_tscn.contains("SIZE_EXPAND_FILL"), "words flow should expand fill inside wrapper")
	assert_false(gd.contains("v_center"), "words wrapper should not use v_center CenterContainer that breaks horizontal")

func test_card_220_and_dots_inside() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.tscn")
	var bar := FileAccess.get_file_as_string("res://assets/components/game/player/player_info_bar.tscn")
	var combined := tscn + bar
	assert_true(combined.contains("MyCardWrapper") and combined.contains("custom_minimum_size = Vector2(220, 70)"))
	assert_true(combined.contains("OpponentCardWrapper") and combined.contains("Vector2(220, 70)"))
	assert_true(combined.contains("MyPowerDots") and combined.contains("offset_right = 210.0"))
	assert_true(combined.contains("offset_top = 50.0") and combined.contains("offset_bottom = 66.0"))

func test_inventory_transparent_when_has_power() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	var slot := FileAccess.get_file_as_string("res://assets/components/game/inventory/inventory_slot.gd")
	var panel := FileAccess.get_file_as_string("res://assets/components/game/inventory/inventory_panel.tscn")
	var combined := gd + slot + panel
	assert_false(combined.contains("0.95, 0.52, 0.09"), "inventory should not be orange fill when has power")
	assert_true(combined.contains("bg_color = Color(0, 0, 0, 0)"), "transparent bg expected")
