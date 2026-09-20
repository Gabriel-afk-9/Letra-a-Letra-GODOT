extends GutTest

var _switch: ToggleSwitch


func before_each() -> void:
	_switch = ToggleSwitch.new()
	_switch.size = Vector2(76, 36)
	add_child_autofree(_switch)
	await get_tree().process_frame


func test_switch_starts_off() -> void:
	assert_false(_switch.is_on(), "deve iniciar desligado")
	assert_eq(_switch.state_text(), "OFF")


func test_switch_set_value_emits_once() -> void:
	var received: Array = []
	_switch.toggled.connect(func(value: bool) -> void: received.append(value))

	_switch.set_value(true)

	assert_true(_switch.is_on())
	assert_eq(_switch.state_text(), "ON")
	assert_eq(received, [true])


func test_switch_set_same_value_does_not_emit() -> void:
	var received: Array = []
	_switch.toggled.connect(func(value: bool) -> void: received.append(value))
	_switch.set_value(true, true)

	_switch.set_value(true)

	assert_true(received.is_empty(), "valor repetido não deve emitir")


func test_switch_click_toggles() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	click.position = Vector2(38, 18)

	_switch._gui_input(click)
	assert_true(_switch.is_on(), "clique deve ligar")
	_switch._gui_input(click)
	assert_false(_switch.is_on(), "clique deve desligar")


func test_switch_disabled_ignores_click() -> void:
	var received: Array = []
	_switch.toggled.connect(func(value: bool) -> void: received.append(value))
	_switch.set_disabled(true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false

	_switch._gui_input(click)

	assert_false(_switch.is_on(), "desabilitado não deve alternar")
	assert_true(received.is_empty())
	assert_true(_switch.modulate.a < 1.0, "desabilitado deve ter feedback visual")


func test_switch_reenable_restores_interaction() -> void:
	_switch.set_disabled(true)
	_switch.set_disabled(false)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false

	_switch._gui_input(click)

	assert_true(_switch.is_on(), "reabilitado deve alternar")


func test_switch_keyboard_accept_toggles() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.pressed = true

	_switch._gui_input(key)

	assert_true(_switch.is_on(), "teclado deve alternar")
