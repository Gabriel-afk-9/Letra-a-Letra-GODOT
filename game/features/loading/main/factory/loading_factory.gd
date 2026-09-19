extends RefCounted
class_name LoadingFactory

static func create() -> LoadingViewModel:
	var services := ServiceRegistry

	var usecase := LoadInitialDataUseCase.new(
		services.user_repository(),
		RemoteShopRepository.new(services.http_client()),
		RemoteInventoryRepository.new(services.http_client()),
		RemoteFriendRepository.new(services.http_client()),
		SessionStore,
		services.initial_data_store()
	)

	return LoadingViewModel.new(
		usecase,
		services.navigation_service(),
		SessionStore,
		services.initial_data_store()
	)
