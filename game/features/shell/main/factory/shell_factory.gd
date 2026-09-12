extends RefCounted
class_name ShellFactory

static func bind(view: ShellScreen) -> void:
	var manager := NavigationManager.new(view.page_container)
	manager.register_page(Navbar.PAGE_SHOP, AppRoutes.SHOP)
	manager.register_page(Navbar.PAGE_INVENTORY, AppRoutes.INVENTORY)
	manager.register_page(Navbar.PAGE_PLAY, AppRoutes.HOME)
	manager.register_page(Navbar.PAGE_SOCIAL, AppRoutes.SOCIAL)
	manager.register_page(Navbar.PAGE_ROOMS, AppRoutes.ROOMS)
	view.setup(manager)
