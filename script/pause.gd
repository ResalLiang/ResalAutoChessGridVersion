extends Node

func _ready():
	# 让这个节点在暂停时仍然处理
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	# 显示暂停菜单
	# get_node("PauseMenu").show()

func resume_game():
	get_tree().paused = false
	# 隐藏所有菜单
	# get_node("PauseMenu").hide()
	# get_node("SettingsMenu").hide()
