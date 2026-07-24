extends RefCounted
class_name NavigationService

func go_to(scene: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.call_deferred("change_scene_to_file", scene)

func quit_game() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.quit()
