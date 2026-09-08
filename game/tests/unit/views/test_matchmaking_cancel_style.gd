extends GutTest

func test_found_shows_disabled_instead_of_hidden() -> void:
	var text := FileAccess.get_file_as_string("res://features/matchmaking/presentation/views/matchmaking_screen.gd")
	assert_true(text.contains("MatchmakingState.FOUND"))
	var found_idx := text.find("FOUND:")
	var snippet := text.substr(found_idx, 300)
	assert_true(snippet.contains("cancel_button.show()"), "FOUND should show")
	assert_true(snippet.contains("cancel_button.disabled = true"), "FOUND should be disabled")
	assert_false(snippet.contains("hide()"), "FOUND should not hide")

func test_connecting_shows_disabled() -> void:
	var text := FileAccess.get_file_as_string("res://features/matchmaking/presentation/views/matchmaking_screen.gd")
	var idx := text.find("CONNECTING:")
	var snippet := text.substr(idx, 300)
	assert_true(snippet.contains("cancel_button.show()"))
	assert_true(snippet.contains("cancel_button.disabled = true"))

func test_cancel_uses_disabled_style() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/matchmaking/presentation/views/matchmaking_screen.tscn")
	assert_true(tscn.contains("disabled_button.tres"), "CancelButton should reference disabled_button.tres")
	assert_true(tscn.contains("theme_override_styles/disabled"))
