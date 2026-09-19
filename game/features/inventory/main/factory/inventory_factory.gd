extends RefCounted
class_name InventoryFactory

# Monta o ViewModel do inventário com as dependências compartilhadas.
# O serviço de assets é um Node com ciclo de vida da tela: a view o
# adiciona como filho através de view_model.asset_service().
static func create() -> InventoryViewModel:
	var services := ServiceRegistry

	var repository := RemoteInventoryRepository.new(services.http_client())
	var usecase := InventoryUseCase.new(repository)
	var assets := EquippableAssetService.new()

	return InventoryViewModel.new(usecase, assets, services.initial_data_store())
