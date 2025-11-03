extends Node2D
class_name Main

@onready var main_container: Control = $main_container
@onready var transition_layer: ColorRect = $transition_layer

# 当前活跃的场景
var current_scene: Node2D = null
var added_scene: Node2D = null
var current_bgm: String
var tween

func _ready():
	# 初始化显示主菜单
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	AudioManagerSingleton.bgm_player.finished.connect(
		func():
			AudioManagerSingleton.play_music(current_bgm)			
	)
	show_main_menu()

# 显示主菜单
func show_main_menu():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/menu.tscn", main_container, true)
	if current_scene.to_game_scene.connect(show_game) != OK:
		print("current_scene.to_game_scene connect fail!")
	if current_scene.to_gallery_scene.connect(show_gallery) != OK:
		print("current_scene.to_gallery_scene connect fail!")
	if current_scene.to_upgrade_scene.connect(show_player_upgrade) != OK:
		print("current_scene.to_upgrade_scene connect fail!")
	
# 显示游戏场景
func show_game():
	current_bgm = "battle"
	AudioManagerSingleton.play_music("random")
	await _transition_to_scene("res://scene/game.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	if current_scene.add_round_finish_scene.connect(show_round_finish) != OK:
		print("current_scene.add_round_finish_scene connect fail!")
	if current_scene.to_game_finish_scene.connect(show_game_finish) != OK:
		print("current_scene.to_game_finish_scene connect fail!")

# 显示设置菜单
func show_settings():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/setting.tscn", main_container, true)
	
# 显示设置菜单
func show_round_finish(result: String):
	add_scene("res://scene/round_finish.tscn", main_container, false)
	added_scene.tree_exiting.connect(func(): AudioManagerSingleton.play_music("random"))
	if result == "WON":
		added_scene.label.text = "You Won This Round!"
		AudioManagerSingleton.play_music("round_win")
	elif result == "LOSE":
		added_scene.label.text = "You Lose This Round..."
		AudioManagerSingleton.play_music("round_lose")
	elif result == "DRAW":
		added_scene.label.text = "Just Draw This Round..."
		AudioManagerSingleton.play_music("round_lose")

func show_player_upgrade():
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/player_upgrade.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	
# 显示设置菜单
func show_game_finish():
	if DataManagerSingleton.in_game_data["total_won_game"] > 0:
		AudioManagerSingleton.play_music("game_won")
	else:
		AudioManagerSingleton.play_music("game_lose")
	await _transition_to_scene("res://scene/game_finish.tscn", main_container, false)
	current_scene.load_animation()
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	if current_scene.to_game_scene.connect(show_game) != OK:
		print("current_scene.to_game_scene connect fail!")

func show_gallery():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/gallery.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	if current_scene.to_tetris_scene.connect(show_tetris_game) != OK:
		print("current_scene.to_tetris_scene connect fail!")
	if current_scene.to_snake_scene.connect(show_snake_game) != OK:
		print("current_scene.to_snake_scene connect fail!")
	if current_scene.to_minesweep_scene.connect(show_minesweep_game) != OK:
		print("current_scene.to_minesweep_scene connect fail!")
	
func show_tetris_game():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/tetris.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	
func show_snake_game():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/snake.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	
func show_minesweep_game():
	current_bgm = "menu"
	AudioManagerSingleton.play_music(current_bgm)
	await _transition_to_scene("res://scene/minesweep.tscn", main_container, true)
	if current_scene.to_menu_scene.connect(show_main_menu) != OK:
		print("current_scene.to_menu_scene connect fail!")
	

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
