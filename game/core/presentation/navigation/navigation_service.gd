extends RefCounted
class_name NavigationService

func go_to(scene: String) -> void:
	# Toda navegação com destino à Shell passa antes pela Loading,
	# que pré-carrega os dados iniciais (loja, inventário, perfil,
	# amigos) antes de liberar a renderização da Shell.
	if scene == AppRoutes.SHELL:
		_change_scene(AppRoutes.LOADING)
		return
	_change_scene(scene)

func go_to_shell() -> void:
	# Acesso direto à Shell, sem passar pela Loading. Uso exclusivo
	# da LoadingViewModel após concluir o pré-carregamento.
	_change_scene(AppRoutes.SHELL)

func quit_game() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.quit()

func _change_scene(scene: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.call_deferred("change_scene_to_file", scene)
