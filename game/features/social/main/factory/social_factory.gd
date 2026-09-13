extends RefCounted
class_name SocialFactory

static func create() -> SocialViewModel:
	var services := ServiceRegistry

	var friend_repository := RemoteFriendRepository.new(services.http_client())

	var usecase := FriendsUseCase.new(
		friend_repository,
		services.user_repository(),
		SessionStore
	)

	return SocialViewModel.new(usecase)
