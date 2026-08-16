extends RefCounted
class_name PendingNavigationPayload


var _payload: Variant = null


# Guarda um objeto para a próxima troca de tela. Semântica de "set":
# substitui o que estava guardado, se houver.

func set_payload(payload: Variant) -> void:
	_payload = payload


# Devolve o objeto e IMEDIATAMENTE limpa o campo — semântica de "take", não
# de "get": evita que um dado velho vaze para uma visita futura não
# relacionada à mesma tela.

func take_payload() -> Variant:
	var payload: Variant = _payload
	_payload = null
	return payload
