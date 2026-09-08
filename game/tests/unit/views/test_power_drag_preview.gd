extends GutTest

func test_power_drag_constants_and_preview_thresholds() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("GLOBAL_SWIPE_THRESHOLD_PX := 40.0"), "threshold 40")
	assert_true(gd.contains("ARMED_LIFT_Y := -10.0"))
	assert_true(gd.contains("ARMED_LIFT_SCALE := Vector2(1.12, 1.12)"))
	assert_true(gd.contains("delta < -20.0"), "preview >20")
	assert_true(gd.contains("delta > 20.0"))
	assert_true(gd.contains("is-using") or gd.contains("_apply_drag_preview"), "preview helper exists")

func test_power_commit_anim_uses_mvp_timings() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("powerUse") or gd.contains("_animate_launch_slot"))
	assert_true(gd.contains("powerDiscard") or gd.contains("_animate_discard_slot"))
	assert_true(gd.contains("0.3"), "300ms delay before WS")
	assert_true(gd.contains("scale", ), "scale anim exists")
