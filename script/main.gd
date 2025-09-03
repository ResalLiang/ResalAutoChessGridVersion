extends Node2D
class_name Main

@onready var main_container: Control = $main_container
@onready var transition_layer: ColorRect = $transition_layer

# 当前活跃的场景
var current_scene: Node2D = null

func _ready():
	# 初始化显示主菜单
	main_container.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	show_main_menu()

# 显示主菜单
func show_main_menu():
	_transition_to_scene("res://scene/menu.tscn", main_container)

# 显示游戏场景
func show_game():
	_transition_to_scene("res://scene/game.tscn", main_container)

# 显示设置菜单
func show_settings():
	_transition_to_scene("res://scene/setting.tscn", main_container)

# 场景切换核心方法 - 这是自定义方法
func _transition_to_scene(scene_path: String, container: Control):
	# 显示过渡效果
	transition_layer.show()
	var tween = create_tween()
	tween.tween_property(transition_layer, "color", Color(0, 0, 0, 1), 0.5)
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
	container.add_child(new_scene)
	current_scene = new_scene
	
	# 隐藏其他容器，显示目标容器
	menu_container.hide()
	game_container.hide()
	container.show()
	
	# 淡出过渡效果
	tween = create_tween()
	tween.tween_property(transition_layer, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	transition_layer.hide()
