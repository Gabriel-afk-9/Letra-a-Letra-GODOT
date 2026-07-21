extends RefCounted
class_name LoginUseCase


var _repository: RemoteLoginRepository
var _session_store


func _init(
	repository: RemoteLoginRepository,
	session_store
) -> void:

	_repository = repository
	_session_store = session_store


func execute(
	request: LoginRequest
) -> LoginResult:

	var result: LoginResult = await _repository.login(request)

	if result.success:

		_session_store.start_session(
			result.user,
			result.access_token
		)

	return result
