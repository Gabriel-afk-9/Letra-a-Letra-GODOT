extends PanelContainer

@onready var nick_label: Label = $MarginContainer/ProfileHBox/NickLabel
@onready var avatar_btn: Button = $MarginContainer/ProfileHBox/AvatarBtn

signal avatar_pressed

func _ready() -> void:
	# Conecta o clique da foto para avisar a tela principal
	avatar_btn.pressed.connect(func(): avatar_pressed.emit())

# Função para a tela principal injetar os dados
func setup(nickname: String) -> void:
	nick_label.text = nickname

# Mostra um estado de espera enquanto a API responde
func set_loading() -> void:
	nick_label.text = "Carregando..."
