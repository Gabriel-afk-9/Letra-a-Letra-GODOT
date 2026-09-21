extends GutTest
class_name BaseGameTest

# Base escalável para ViewModels de Game — elimina 9 before_each idênticos.
# Uso: extends BaseGameTest e chame make_game_vm() no before_each.

func make_game_vm(my_id: String = "me", opp_id: String = "opp") -> Dictionary:
	var repo := FakeGameRepository.new()
	var provider := FakeCurrentUserProvider.new()
	provider.set_user(my_id, "Eu")
	var usecase := GameUseCase.new(repo, provider)
	usecase._opponent_id = opp_id
	var vm := GameViewModel.new(usecase, null)
	vm._on_turn_changed(my_id, "", true)
	return {"repo": repo, "provider": provider, "usecase": usecase, "vm": vm}

func make_room_vm(nav: NavigationService = null) -> Dictionary:
	var repo := FakeRoomRepository.new()
	var usecase := RoomsUseCase.new(repo)
	var payload := PendingNavigationPayload.new()
	if nav == null:
		nav = NavigationService.new()
	var vm := RoomsViewModel.new(usecase, nav, payload)
	return {"repo": repo, "usecase": usecase, "payload": payload, "nav": nav, "vm": vm}
