extends GutTest


func test_roundtrip_dictionary() -> void:
	var original := {"a": 1, "b": [2, 3], "c": {"d": "hello"}}
	var encoded := JsonSerializer.encode(original)
	var decoded := JsonSerializer.decode(encoded)

	assert_eq(decoded["a"], 1.0) # JSON numbers decode as float
	assert_eq(decoded["c"]["d"], "hello")


func test_decode_empty_returns_empty() -> void:
	assert_eq(JsonSerializer.decode(""), {})
	assert_eq(JsonSerializer.decode("{}"), {})


func test_decode_invalid_returns_empty() -> void:
	assert_eq(JsonSerializer.decode("not json"), {})
	assert_eq(JsonSerializer.decode("[1,2,3]"), {}) # array root → {} per impl


func test_encode_empty() -> void:
	assert_eq(JsonSerializer.encode({}), "{}")
