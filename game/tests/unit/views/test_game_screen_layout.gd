extends GutTest

func test_words_wrapper_is_72_fixed_and_shrink_center() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("custom_minimum_size = Vector2(0, 72)"), "wrapper should be 72 fixed")
	assert_true(gd.contains("CLIP") or gd.contains("clip_contents"), "wrapper should clip")
	assert_true(gd.contains("words_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL"))
	assert_true(gd.contains("words_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER"))
	assert_false(gd.contains("v_center"), "words wrapper should not use v_center CenterContainer that breaks horizontal")

func test_card_220_and_dots_inside() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.tscn")
	assert_true(tscn.contains("MyCardWrapper") and tscn.contains("custom_minimum_size = Vector2(220, 70)"))
	assert_true(tscn.contains("OpponentCardWrapper") and tscn.contains("Vector2(220, 70)"))
	assert_true(tscn.contains("MyPowerDots") and tscn.contains("offset_right = 210.0"))
	assert_true(tscn.contains("offset_top = 50.0") and tscn.contains("offset_bottom = 66.0"))

func test_inventory_transparent_when_has_power() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	# has-power should be transparente, not laranja #F58417 #0.95,0.52,0.09
	assert_false(gd.contains("0.95, 0.52, 0.09"), "inventory should not be orange fill when has power")
	assert_true(gd.contains("bg_color = Color(0, 0, 0, 0)"), "transparent bg expected")
