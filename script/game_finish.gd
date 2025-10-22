extends Node2D
class_name GameFinish

@onready var container: VBoxContainer = $container
@onready var animated_sprite_2d: AnimatedSprite2D = $Node2D/TextureRect19/AnimatedSprite2D
@onready var restart_button: Button = $restart_button
@onready var back_button: Button = $back_button
@onready var label: Label = $Label

const score_label_scene = preload("res://scene/score_label.tscn")

signal to_menu_scene
signal to_game_scene

var final_score := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DataManagerSingleton.won_rounds == DataManagerSingleton.max_won_rounds:
		label.text = "You Won the Game!"
	else:
		label.text = "You Lose the Game..."
	calculate_final_score()
	DataManagerSingleton.record_game(final_score, DataManagerSingleton.current_chess_array)
	DataManagerSingleton.save_game_json()
	
	if restart_button.pressed.connect(_on_restart_button_pressed) != OK:
		print("restart_button.pressed connect fail!")
	if back_button.pressed.connect(_on_back_button_pressed) != OK:
		print("back_button.pressed connect fail!")
	
	#debug_button_state(restart_button)
	#debug_button_state(back_button)
	#
	#setup_debug_signals(restart_button)
	#setup_debug_signals(back_button)
	
	
	await get_tree().process_frame
	await staggered_fly_in()

func _on_restart_button_pressed() -> void:
	#print("🎉 按钮点击成功！")
	to_game_scene.emit()

func _on_back_button_pressed() -> void:
	#print("🎉 按钮点击成功！")
	to_menu_scene.emit()

func calculate_final_score():
	final_score = 0
	var current_player_ingame_data = DataManagerSingleton.in_game_data
	var score_label
	var score_bonus
	var score_reason
	for item in current_player_ingame_data.keys():
		if not item is String:
			continue
			
		match item:
			"enemy_death_count":
				score_bonus = 100
				score_reason = "Killing Enemies"
			"ally_death_count":
				score_bonus = 100
				score_reason = "Allies Killed"
			"total_won_round":
				score_bonus = 100
				score_reason = "Winning Rounds"
			"total_lose_round":
				score_bonus = 50
				score_reason = "Losing Rounds"
			"total_won_game":
				score_bonus = 2000
				score_reason = "Winning the Game"
			"total_lose_game":
				score_bonus = 1000
				score_reason = "Losing the Game"
			"total_coin_spend":
				score_bonus = 10
				score_reason = "Coins Spend"
			"total_refresh_count" :
				score_bonus = 100
				score_reason = "Refresh"
			_:
				score_bonus = -1
				score_reason = "Default"
				
		if (current_player_ingame_data[item] is int or current_player_ingame_data[item] is float) and score_bonus != -1:
			var item_score = score_bonus * current_player_ingame_data[item]

			score_label = score_label_scene.instantiate()
			score_label.text = score_reason + " : " + str(score_bonus) + " * " + str(current_player_ingame_data[item]) + " = " + str(item_score)

			score_label.visible = true
			container.add_child(score_label)
			final_score += item_score
		
	score_label = score_label_scene.instantiate()
	score_label.text = "--------------------------"
	container.add_child(score_label)
	
	score_label = score_label_scene.instantiate()
	score_label.text = "Total Score" + " : " + str(final_score)
	container.add_child(score_label)

func staggered_fly_in():
	var labels = []
	var original_parents = []
	var original_positions = []
	
	# 收集容器中的所有Label并记录原始信息
	for child in container.get_children():
		if child is Label:
			labels.append(child)
			original_parents.append(child.get_parent())
			# 获取在容器中的最终位置
			await get_tree().process_frame  # 等待布局更新
			original_positions.append(child.global_position)
	
	# 临时将Label移到主场景，这样就能自由控制位置
	for i in range(labels.size()):
		var label = labels[i]
		var original_pos = original_positions[i]
		
		# 移到主场景
		label.reparent(self)
		
		# 设置初始位置（屏幕右侧）
		label.global_position = Vector2(get_viewport().get_visible_rect().size.x + 200, original_pos.y)
		label.modulate.a = 0.0
	
	# 依次播放动画
	for i in range(labels.size()):
		var label = labels[i]
		var delay = i * 0.1
		var final_pos = original_positions[i]
		
		await get_tree().create_timer(delay).timeout
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		tween.tween_property(label, "global_position", final_pos, 0.4)
		tween.tween_property(label, "modulate:a", 1.0, 0.4)
		
		# 动画完成后，将Label放回Container
		await tween.finished
		remove_child(label)
		container.add_child(label)
		label.modulate.a = 1.0  # 确保完全可见

func load_animation():
	var mvp_chess = DataManagerSingleton.mvp_chess
	if mvp_chess is String:
		animated_sprite_2d.visible = false
	else:
		animated_sprite_2d.visible = true
		var showed_chess_faction = mvp_chess[0][0]
		var showed_chess_name = mvp_chess[0][1]
		var path = "res://asset/animation/%s/%s%s.tres" % [showed_chess_faction, showed_chess_faction, showed_chess_name]
		if ResourceLoader.exists(path):
			var frames = ResourceLoader.load(path)
			for anim_name in frames.get_animation_names():
				frames.set_animation_loop(anim_name, false)
				frames.set_animation_speed(anim_name, 8.0)
			animated_sprite_2d.sprite_frames = frames
			animated_sprite_2d.play("idle")
		else:
			push_error("Animation resource not found: " + path)
			

func _on_animated_sprite_2d_animation_finished() -> void:
	var rand_anim_index = randi_range(0, animated_sprite_2d.sprite_frames.get_animation_names().size() - 1)
	var rand_anim_name = animated_sprite_2d.sprite_frames.get_animation_names()[rand_anim_index]
	animated_sprite_2d.play(rand_anim_name)


func debug_button_state(debug_button: Button):
	print("=== 按钮调试信息 ===")
	print("节点路径: ", debug_button.get_path())
	print("禁用: ", debug_button.disabled)
	print("可见: ", debug_button.visible)
	print("在场景树: ", debug_button.is_inside_tree())
	print("鼠标过滤: ", debug_button.mouse_filter)
	print("尺寸: ", debug_button.size)
	
	# 检查信号连接
	if debug_button.is_connected("pressed", _on_Button_pressed):
		print("✅ pressed信号已连接")
	else:
		print("❌ pressed信号未连接")
	print("==================")

func setup_debug_signals(debug_button: Button):
	# 连接所有有用的调试信号
	if not debug_button.is_connected("pressed", _on_Debug_pressed):
		if debug_button.connect("pressed", _on_Debug_pressed) != OK:
			print("debug_button connect fail!")
	
	if not debug_button.is_connected("button_down", _on_Debug_button_down):
		if debug_button.connect("button_down", _on_Debug_button_down) != OK:
			print("debug_button connect fail!")
	
	if not debug_button.is_connected("mouse_entered", _on_Debug_mouse_entered):
		if debug_button.connect("mouse_entered", _on_Debug_mouse_entered) != OK:
			print("debug_button connect fail!")

func _on_Debug_pressed():
	print("🎉 按钮点击成功！")

func _on_Debug_button_down():
	print("⬇️ 按钮按下")

func _on_Debug_mouse_entered():
	print("🐭 鼠标悬停在按钮上")

# 这是你实际要执行的方法
func _on_Button_pressed():
	print("🎯 主业务逻辑执行")
	# 你的实际代码在这里
