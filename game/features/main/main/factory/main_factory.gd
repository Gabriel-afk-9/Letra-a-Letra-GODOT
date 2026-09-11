extends RefCounted
class_name MainFactory

static func create() -> MainViewModel:
	var services := ServiceRegistry

	return MainViewModel.new(
		services.navigation_service()
	)
