extends Node2D
class_name GameFinish

@onready var container: VBoxContainer = $container

const score_label_scene = preload("res://scene/score_label.tscn")

signal to_menu_scene
signal to_game_scene

var final_score := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	calculate_final_score()
	await get_tree().process_frame
	staggered_fly_in()
	DataManagerSingleton.record_game(final_score, DataManagerSingleton.current_chess_array)
	DataManagerSingleton.save_game_json()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_restart_button_pressed() -> void:
	to_game_scene.emit()

func _on_back_button_pressed() -> void:
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
				
		if item is String and (current_player_ingame_data[item] is int or current_player_ingame_data[item] is float) and score_bonus != -1:
			var item_score = score_bonus * current_player_ingame_data[item]

			score_label = score_label_scene.instantiate()
			score_label.text = score_reason + " : " + str(score_bonus) + " * " + str(current_player_ingame_data[item]) + " = " + str(item_score)

			# score_label = Label.new()

			# # Create a new theme
			# var new_theme = Theme.new()
			
			# # Load font resource
			# var font = load("res://fonts/your_font.ttf") as FontFile
			
			# # Set font and size in theme using correct methods
			# new_theme.set_font("font", "Label", font)
			# new_theme.set_font_size("font_size", "Label", 8)
			
			# # Apply theme to label
			# score_label.theme = new_theme

			# score_label.text = score_reason + " : " + str(score_bonus) + " * " + str(current_player_ingame_data[item]) + " = " + str(item_score)
			score_label.visible = false
			container.add_child(score_label)
			final_score += item_score
		
	score_label = Label.new()
	score_label.text = "Total Score" + " : " + str(final_score)
	container.add_child(score_label)


func staggered_fly_in():
	var labels = []
	
	# 收集容器中的所有Label
	for child in container.get_children():
		if child is Label:
			labels.append(child)
	
	# 设置所有Label的初始位置
	for label in labels:
		label.visible = true
		label.position.x = get_viewport().get_visible_rect().size.x + 200
		label.modulate.a = 0.0
	
	# 依次播放动画
	for i in range(labels.size()):
		var label = labels[i]
		var delay = i * 0.2  # 每个延迟0.2秒
		
		await get_tree().create_timer(delay).timeout
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		# 获取最终位置（由容器布局决定）
		var final_pos = Vector2.ZERO  # 相对于容器的位置
		
		tween.tween_property(label, "position.x", final_pos.x, 0.6)
		tween.tween_property(label, "modulate.a", 1.0, 0.4)
