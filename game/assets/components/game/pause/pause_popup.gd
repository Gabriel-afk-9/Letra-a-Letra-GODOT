extends Control
class_name PausePopup

signal leave_confirmed
signal closed

@onready var _dim: ColorRect = $DimBackground
@onready var _default_actions: VBoxContainer = $Center/Card/Margin/RootVBox/Content/DefaultActions
@onready var _confirm_actions: VBoxContainer = $Center/Card/Margin/RootVBox/Content/ConfirmActions
@onready var _leave_button: Button = $Center/Card/Margin/RootVBox/Content/DefaultActions/LeaveButton
@onready var _close_button: Button = $Center/Card/Margin/RootVBox/TitlePillWrap/CloseButton
@onready var _cancel_button: Button = $Center/Card/Margin/RootVBox/Content/ConfirmActions/Row/CancelButton
@onready var _confirm_button: Button = $Center/Card/Margin/RootVBox/Content/ConfirmActions/Row/ConfirmLeaveButton

func _ready() -> void:
	visible = false
	_confirm_actions.visible = false
	_default_actions.visible = true

func open() -> void:
	_default_actions.visible = true
	_confirm_actions.visible = false
	visible = true

func close() -> void:
	visible = false
	_default_actions.visible = true
	_confirm_actions.visible = false
	closed.emit()

func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.pressed and me.button_index == MOUSE_BUTTON_LEFT:
			close()
	elif event is InputEventScreenTouch:
		var te := event as InputEventScreenTouch
		if te.pressed:
			close()

func _on_close_pressed() -> void:
	close()

func _on_leave_pressed() -> void:
	_default_actions.visible = false
	_confirm_actions.visible = true

func _on_cancel_pressed() -> void:
	_default_actions.visible = true
	_confirm_actions.visible = false

func _on_confirm_leave_pressed() -> void:
	leave_confirmed.emit()
