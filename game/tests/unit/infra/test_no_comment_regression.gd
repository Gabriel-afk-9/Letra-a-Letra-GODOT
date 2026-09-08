extends GutTest

func test_no_hash_comments_remain_in_project() -> void:
	var files := [
		"res://features/game/presentation/views/game_screen.gd",
		"res://features/game/presentation/viewmodels/game_viewmodel.gd",
		"res://features/game/infrastructure/repositories/remote_game_repository.gd",
		"res://features/game/application/usecases/game_usecase.gd",
		"res://core/infrastructure/network/websocket/websocket_client.gd",
	]
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		var lines := text.split("\n")
		for line in lines:
			var stripped: String = line.strip_edges()
			if stripped.begins_with("#"):
				assert_true(false, "Found stray # comment in %s: %s" % [path, line])
				return
	assert_true(true)

func test_tscn_has_no_comments_and_docs_intact() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.tscn")
	assert_false(tscn.contains("#"), "tscn should not contain # comments")
	var ok := FileAccess.file_exists("res://tests/helpers/fake_game_repository.gd")
	assert_true(ok)
