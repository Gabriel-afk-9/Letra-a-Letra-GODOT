extends GutTest

func test_home_has_no_exit_button_node() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/home/presentation/views/home_screen.tscn")
	assert_false(tscn.contains("ExitButton"), "Home should not contain ExitButton")
	assert_false(tscn.contains("exit_button.tscn"), "Home should not reference exit_button.tscn")

func test_home_gd_has_no_exit_handler() -> void:
	var gd := FileAccess.get_file_as_string("res://features/home/presentation/views/home_screen.gd")
	assert_false(gd.contains("exit_btn"), "home_screen.gd should not reference exit_btn")
	assert_false(gd.contains("_on_exit_button_pressed"), "handler should be removed")
	assert_false(gd.contains("exit_game"), "exit_game call should not be in home_screen.gd")
