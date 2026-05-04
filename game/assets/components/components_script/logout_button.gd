extends Button

func _ready() -> void:
	self.pressed.connect(_on_logout_pressed)

func _on_logout_pressed() -> void:
	
	self.disabled = true 
	
	AuthManager.clear_session()
	
	print("Sessão encerrada. Voltando para o Login...")
	
	get_tree().change_scene_to_file("res://scenes/login/login_screen.tscn")
