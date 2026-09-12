extends Control
class_name ShellScreen

@onready var page_container: Control = $PageContainer
@onready var navbar: Navbar = $Navbar

var _manager: NavigationManager

func _ready() -> void:
	ShellFactory.bind(self)

func setup(manager: NavigationManager) -> void:
	_manager = manager
	navbar.page_selected.connect(_on_page_selected)
	_manager.page_changed.connect(_on_page_changed)
	_manager.select(Navbar.PAGE_PLAY)

func _on_page_selected(page_id: StringName) -> void:
	_manager.select(page_id)

func _on_page_changed(page_id: StringName) -> void:
	navbar.set_selected(page_id)
