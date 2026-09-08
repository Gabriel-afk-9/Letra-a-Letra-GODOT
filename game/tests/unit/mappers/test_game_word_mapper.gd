extends GutTest


func test_word_found_true() -> void:
	var word := GameWordMapper.to_domain({"word": "GODOT", "found": true, "foundById": "p1"})

	assert_eq(word.word, "GODOT")
	assert_true(word.found)
	assert_eq(word.found_by_player_id, "p1")


func test_word_not_found_defaults() -> void:
	var word := GameWordMapper.to_domain({"word": "LETRA"})

	assert_eq(word.word, "LETRA")
	assert_false(word.found)
	assert_eq(word.found_by_player_id, "")


func test_word_null_fields() -> void:
	var word := GameWordMapper.to_domain({"word": null, "found": null, "foundById": null})

	assert_eq(word.word, "")
	assert_false(word.found)
	assert_eq(word.found_by_player_id, "")
