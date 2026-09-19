extends GutTest


func test_mask_keeps_rounded_discard() -> void:
	var source := FileAccess.get_file_as_string("res://assets/styles/rounded_image_mask.gdshader")
	assert_true(source.contains("discard"), "máscara descarta cantos")
	assert_true(source.contains("sd_round_box"), "SDF de retângulo arredondado")


func test_mask_restores_original_brightness() -> void:
	var source := FileAccess.get_file_as_string("res://assets/styles/rounded_image_mask.gdshader")
	assert_true(source.contains("linear_to_srgb"), "recodifica a saída para sRGB")
	assert_true(source.contains("1.0 / 2.4"), "usa a curva sRGB inversa exata")
