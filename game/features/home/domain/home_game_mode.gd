extends RefCounted
class_name HomeGameMode

# Modos de jogo selecionáveis na Home. Para adicionar um modo novo, basta
# acrescentar um valor ao enum e aos dicionários abaixo — o seletor da tela
# é montado a partir de HomeGameMode.all().

enum Mode {
	NORMAL,
	RANKED,
	BOT,
}

const LABELS := {
	Mode.NORMAL: "CASUAL",
	Mode.RANKED: "RANK",
	Mode.BOT: "BOT",
}


static func all() -> Array:
	return [Mode.NORMAL, Mode.RANKED, Mode.BOT]


static func label(mode: int) -> String:
	return str(LABELS.get(mode, "CASUAL"))
