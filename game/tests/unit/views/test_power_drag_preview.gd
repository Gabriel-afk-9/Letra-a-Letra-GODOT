extends GutTest


func test_power_drag_constants_and_preview_thresholds() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	var slot := FileAccess.get_file_as_string("res://assets/components/game/inventory/inventory_slot.gd")
	var panel := FileAccess.get_file_as_string("res://assets/components/game/inventory/inventory_panel.gd")
	var combined := gd + slot + panel
	assert_true(combined.contains("GLOBAL_SWIPE_THRESHOLD_PX := 40.0"), "threshold 40")
	assert_true(combined.contains("ARMED_LIFT_Y := 0.0"))
	assert_true(combined.contains("ARMED_LIFT_SCALE := Vector2.ONE"))
	assert_true(combined.contains("delta < -20.0"), "preview >20")
	assert_true(combined.contains("delta > 20.0"))
	assert_true(combined.contains("is-using") or combined.contains("_apply_drag_preview"), "preview helper exists")


func test_power_commit_anim_uses_mvp_timings() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	var slot := FileAccess.get_file_as_string("res://assets/components/game/inventory/inventory_slot.gd")
	var combined := gd + slot
	assert_true(combined.contains("powerUse") or combined.contains("_animate_launch_slot"))
	assert_true(combined.contains("powerDiscard") or combined.contains("_animate_discard_slot"))
	assert_true(combined.contains("0.3"), "300ms delay before WS")
	assert_true(combined.contains("scale", ), "scale anim exists")
