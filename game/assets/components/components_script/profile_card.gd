extends PanelContainer
class_name ProfileCard

@onready var nick_label: Label = $MarginContainer/ProfileHBox/NickLabel
@onready var avatar_btn: Button = $MarginContainer/ProfileHBox/AvatarBtn

signal avatar_pressed

func _ready() -> void:
	avatar_btn.pressed.connect(func(): avatar_pressed.emit())

func setup(nickname: String) -> void:
	nick_label.text = nickname

func set_loading() -> void:
	nick_label.text = "Carregando..."
