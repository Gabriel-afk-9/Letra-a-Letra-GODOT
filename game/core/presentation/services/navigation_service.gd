extends RefCounted

class_name NavigationService


const LOGIN := "res://features/login/presentation/views/login_screen.tscn"
const HOME := "res://features/home/presentation/views/home_screen.tscn"
const MATCHMAKING := "res://features/matchmaking/presentation/views/matchmaking_screen.tscn"


func go_to(scene: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.change_scene_to_file(scene)


func go_to_login() -> void:
	go_to(LOGIN)


func go_to_home() -> void:
	go_to(HOME)


func go_to_matchmaking() -> void:
	go_to(MATCHMAKING)


func back() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
