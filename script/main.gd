extends Node2D
class_name Main

@onready var main_container: Control = $main_container
@onready var transition_layer: ColorRect = $transition_layer

# 当前活跃的场景
var current_scene: Node2D = null
var added_scene: Node2D = null
var tween

func _ready():
	# 初始化显示主菜单
	AudioManagerSingleton.play_music("menu")
	show_main_menu()

# 显示主菜单
func show_main_menu():
	AudioManagerSingleton.play_music("menu")
	await _transition_to_scene("res://scene/menu.tscn", main_container, true)
	current_scene.to_game_scene.connect(show_game)
	current_scene.to_gallery_scene.connect(show_gallery)
	current_scene.to_upgrade_scene.connect(show_player_upgrade)
	
# 显示游戏场景
func show_game():
	AudioManagerSingleton.play_music("battle")
	await _transition_to_scene("res://scene/game.tscn", main_container, true)
	current_scene.to_menu_scene.connect(show_main_menu)
	current_scene.add_round_finish_scene.connect(show_round_finish)
	current_scene.to_game_finish_scene.connect(show_game_finish)

# 显示设置菜单
func show_settings():
	AudioManagerSingleton.play_music("menu")
	await _transition_to_scene("res://scene/setting.tscn", main_container, true)
	
# 显示设置菜单
func show_round_finish(result: String):
	add_scene("res://scene/round_finish.tscn", main_container, false)
	if result == "WON":
		added_scene.label.text = "You Won This Round!"
	elif result == "LOSE":
		added_scene.label.text = "You Lose This Round..."
	elif result == "DRAW":
		added_scene.label.text = "Just Draw This Round..."

func show_player_upgrade():
	AudioManagerSingleton.play_music("menu")
	await _transition_to_scene("res://scene/player_upgrade.tscn", main_container, true)
	current_scene.to_menu_scene.connect(show_main_menu)
	
# 显示设置菜单
func show_game_finish():
	await _transition_to_scene("res://scene/game_finish.tscn", main_container, false)
	current_scene.load_animation()
	current_scene.to_menu_scene.connect(show_main_menu)
	current_scene.to_game_scene.connect(show_game)

func show_gallery():
	AudioManagerSingleton.play_music("menu")
	await _transition_to_scene("res://scene/gallery.tscn", main_container, true)
	current_scene.to_menu_scene.connect(show_main_menu)
	current_scene.to_mini_game_scene.connect(show_mini_game)
	
func show_mini_game():
	AudioManagerSingleton.play_music("menu")
	await _transition_to_scene("res://scene/tetris.tscn", main_container, true)
	current_scene.to_menu_scene.connect(show_main_menu)
	

# 场景切换核心方法 - 这是自定义方法
func _transition_to_scene(scene_path: String, container: Control, if_transition: bool):
	transition_layer.set_mouse_filter(0)
	# 显示过渡效果
	if if_transition:
		VirtualCursorSingleton.set_cursor_type("loading")
		transition_layer.show()
		tween = create_tween()
		tween.tween_property(transition_layer, "color", Color(0, 0, 0, 1), 0.15)
		await tween.finished
	
	# 清理当前场景
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# 加载新场景
	var new_scene = load(scene_path).instantiate()
	if not new_scene:
		print("Failed to load scene at path: ", scene_path)
		return
	current_scene = new_scene
	container.add_child(current_scene)
	
	# 隐藏其他容器，显示目标容器
	main_container.hide()
	container.show()
	
	# 淡出过渡效果
	if if_transition:
		tween = create_tween()
		tween.tween_property(transition_layer, "color", Color(0, 0, 0, 0), 0.2)
		await tween.finished
		VirtualCursorSingleton.set_cursor_type("default")
		transition_layer.hide()
		
	transition_layer.set_mouse_filter(1)


		
func add_scene(scene_path: String, container: Control, if_transition: bool):
		# 显示过渡效果
	if if_transition:
		transition_layer.show()
		tween = create_tween()
		tween.tween_property(transition_layer, "color", Color(0, 0, 0, 1), 0.2)
		await tween.finished
		
	# 加载新场景
	var new_scene = load(scene_path).instantiate()
	if not new_scene:
		print("Failed to load scene at path: ", scene_path)
		return
	added_scene = new_scene
	container.add_child(new_scene)
	
	# 隐藏其他容器，显示目标容器
	main_container.hide()
	container.show()	
	# 淡出过渡效果
	if if_transition:
		tween = create_tween()
		tween.tween_property(transition_layer, "color", Color(0, 0, 0, 0), 0.2)
		await tween.finished
		transition_layer.hide()
