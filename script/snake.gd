extends Node2D

# =====================================================
# 1. CONSTANTS AND VARIABLES
# =====================================================

# Game configuration
const GRID_SIZE = 20  # Size of each grid cell in pixels
const GRID_WIDTH = 20  # Number of horizontal cells
const GRID_HEIGHT = 15  # Number of vertical cells

# Directions
const DIRECTION_RIGHT = Vector2(1, 0)
const DIRECTION_LEFT = Vector2(-1, 0)
const DIRECTION_UP = Vector2(0, -1)
const DIRECTION_DOWN = Vector2(0, 1)

# Game states
var game_running = false
var current_direction = DIRECTION_RIGHT
var next_direction = DIRECTION_RIGHT

# Game data
var snake_body = []  # Array of Vector2 positions
var food_position = Vector2.ZERO
var score = 0
var high_score = 0

# Configuration
var move_speed = 0.15  # Time between moves in seconds

var enemy_death_array:= []
var animation_count:= 0
var waiting_chess

# Node references
@onready var game_board: Node2D = $GameBoard
@onready var background: ColorRect = $GameBoard/Background
@onready var game_elements: Node2D = $GameBoard/GameElements
@onready var ui_container: Control = $UIContainer
@onready var score_label: Label = $UIContainer/ScoreLabel
@onready var high_score_label: Label = $UIContainer/HighScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var start_button: Button = $UIContainer/StartButton
@onready var game_timer: Timer = $GameTimer

# =====================================================
# 2. INITIALIZATION
# =====================================================

func _ready():
	# Set up game board size
	_setup_game_board()
	
	# Load high score from file
	_load_high_score()
	
	# Connect UI signals
	start_button.pressed.connect(_on_start_button_pressed)
	
	# Initialize UI
	_update_ui()
	game_over_panel.visible = false

# Set up game board dimensions
func _setup_game_board():
	var board_width = GRID_WIDTH * GRID_SIZE
	var board_height = GRID_HEIGHT * GRID_SIZE
	
	# Set background size
	background.size = Vector2(board_width, board_height)
	
	# Center the game board in the view
	var viewport_size = get_viewport_rect().size
	game_board.position = (viewport_size - Vector2(board_width, board_height)) / 2

# =====================================================
# 3. GAME INITIALIZATION
# =====================================================

# Start a new game
func start_game():
	# Reset game state
	game_running = true
	score = 0
	current_direction = DIRECTION_RIGHT
	next_direction = DIRECTION_RIGHT
	
	# Clear snake body
	snake_body.clear()
	
	# Initialize snake - start with 3 segments in a safe position
	var start_x = int(GRID_WIDTH / 2)
	var start_y = int(GRID_HEIGHT / 2)
	
	# Ensure the snake starts in a valid position
	start_x = clamp(start_x, 3, GRID_WIDTH - 1)
	start_y = clamp(start_y, 1, GRID_HEIGHT - 2)
	
	snake_body.append(Vector2(start_x, start_y))
	snake_body.append(Vector2(start_x - 1, start_y))
	snake_body.append(Vector2(start_x - 2, start_y))
	
	# Generate first food
	_generate_food()
	
	# Start game timer
	game_timer.wait_time = move_speed
	game_timer.start()
	
	# Update UI
	_update_ui()
	game_over_panel.visible = false
	start_button.visible = false
	
	# Force initial redraw
	queue_redraw()

# Generate food at random position not occupied by snake
func _generate_food():
	var max_attempts = 100
	var attempts = 0
	
	while attempts < max_attempts:
		var x = randi() % GRID_WIDTH
		var y = randi() % GRID_HEIGHT
		var pos = Vector2(x, y)
		
		# Check if position is occupied by snake
		var position_occupied = false
		for segment in snake_body:
			if segment == pos:
				position_occupied = true
				break
		
		if not position_occupied:
			food_position = pos
			return
		
		attempts += 1
	
	# Fallback position if no valid position found
	food_position = Vector2(0, 0)

# =====================================================
# 4. INPUT HANDLING
# =====================================================

func _input(event):
	if not game_running:
		return
	
	# Handle keyboard input for direction changes
	if event.is_action_pressed("ui_right") and current_direction != DIRECTION_LEFT:
		next_direction = DIRECTION_RIGHT
	elif event.is_action_pressed("ui_left") and current_direction != DIRECTION_RIGHT:
		next_direction = DIRECTION_LEFT
	elif event.is_action_pressed("ui_up") and current_direction != DIRECTION_DOWN:
		next_direction = DIRECTION_UP
	elif event.is_action_pressed("ui_down") and current_direction != DIRECTION_UP:
		next_direction = DIRECTION_DOWN

# =====================================================
# 5. GAME LOGIC
# =====================================================

# Main game update - called by timer
func _on_game_timer_timeout():
	if not game_running:
		return
	
	# Update current direction
	current_direction = next_direction
	
	# Calculate new head position
	var new_head = snake_body[0] + current_direction
	
	# Check for collisions
	if _check_collision(new_head):
		_end_game(false)
		return
	
	# Move snake
	snake_body.push_front(new_head)
	
	# Check if snake ate food
	if new_head == food_position:
		# Increase score
		score += 10
		
		# Generate new food
		_generate_food()
		
		# Update UI
		_update_ui()
		
		# Snake grows by not removing tail
	else:
		# Remove tail if no food was eaten
		snake_body.pop_back()
	
	# Redraw game
	queue_redraw()

# Check for collisions with walls or self
func _check_collision(position: Vector2) -> bool:
	# Check wall collision
	if position.x < 0 or position.x >= GRID_WIDTH or position.y < 0 or position.y >= GRID_HEIGHT:
		return true
	
	# Check self collision (skip the tail since it will move)
	for i in range(snake_body.size()):
		if position == snake_body[i]:
			return true
	
	return false

# End the game
func _end_game(is_win: bool):
	game_running = false
	game_timer.stop()
	
	# Update high score if needed
	if score > high_score:
		high_score = score
		_save_high_score()
	
	# Show game over panel
	game_over_panel.visible = true
	start_button.visible = true
	
	# Update UI
	_update_ui()

# =====================================================
# 6. RENDERING
# =====================================================

# Draw game elements
func _draw():
	# We need to draw relative to the game_elements node
	var draw_position = game_elements.position
	
	# Draw snake
	for i in range(snake_body.size()):
		var segment = snake_body[i]
		var color = Color.GREEN if i == 0 else Color.DARK_GREEN  # Head is brighter
		_draw_cell(segment, color, draw_position)
	
	# Draw food
	_draw_cell(food_position, Color.RED, draw_position)

# Draw a single grid cell
func _draw_cell(cell_position: Vector2, color: Color, offset: Vector2):
	var rect = Rect2(
		offset + cell_position * GRID_SIZE,
		Vector2(GRID_SIZE, GRID_SIZE)
	)
	game_elements.draw_rect(rect, color)
	
	# Add a small border for pixel art style
	var border_rect = Rect2(
		offset + cell_position * GRID_SIZE,
		Vector2(GRID_SIZE - 1, GRID_SIZE - 1)
	)
	game_elements.draw_rect(border_rect, Color.BLACK, false)

# =====================================================
# 7. UI MANAGEMENT
# =====================================================

# Update all UI elements
func _update_ui():
	score_label.text = "Score: %d" % score
	high_score_label.text = "High Score: %d" % high_score

# Save high score to file
func _save_high_score():
	var file = FileAccess.open("user://snake_highscore.dat", FileAccess.WRITE)
	if file:
		file.store_32(high_score)

# Load high score from file
func _load_high_score():
	if FileAccess.file_exists("user://snake_highscore.dat"):
		var file = FileAccess.open("user://snake_highscore.dat", FileAccess.READ)
		if file:
			high_score = file.get_32()

# =====================================================
# 8. UI SIGNAL HANDLERS
# =====================================================

func _on_start_button_pressed():
	start_game()

# =====================================================
# 9. CONFIGURATION METHODS
# =====================================================

# Change snake movement speed (can be called from outside)
func set_move_speed(new_speed: float):
	move_speed = new_speed
	if game_running:
		game_timer.wait_time = move_speed
		game_timer.start()


func line_up_chess():
	enemy_death_array = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["enemy_death_array"].duplicate()
	if enemy_death_array.size() == 0:
		return
	 
	animation_count = 0
	var chess_array_width := 8
	var chess_array_height := 10
	var chess_size = Vector2i(20, 20)
	
	while animation_count < chess_array_width * chess_array_height:
		var chess_faction = enemy_death_array.pop_front()
		var chess_name = enemy_death_array.pop_front()
		if DataManagerSingleton.get_chess_data().keys().has(chess_faction) and DataManagerSingleton.get_chess_data()[chess_faction].keys().has(chess_name):
			var chess_animation = AnimatedSprite2D.new()
			waiting_chess.add_child(chess_animation) 

			chess_animation.set_meta("faction", chess_faction)
			chess_animation.set_meta("chess_name", chess_name)
			
			var current_chess_tile

			if floor(animation_count / chess_array_width) % 2 != 0:
				current_chess_tile = Vector2i(animation_count % chess_array_width, floor(animation_count / chess_array_width))
			else:
				current_chess_tile = Vector2i(chess_array_width - 1 - (animation_count % chess_array_width), floor(animation_count / chess_array_width))
			if current_chess_tile.y >= chess_array_height:
				return
			if current_chess_tile.y % 2 != 0:
				chess_animation.flip_h = true
			else:
				chess_animation.flip_h = false				
			chess_animation.position = Vector2(current_chess_tile.x * chess_size.x, current_chess_tile.y * chess_size.y)
			chess_animation.z_index = 30
			_load_animations(chess_animation, chess_faction, chess_name)
			chess_animation.animation_finished.connect(
				func():
					#var rand_anim_index = randi_range(0, chess_animation.sprite_frames.get_animation_names().size() - 1)
					#var rand_anim_name = chess_animation.sprite_frames.get_animation_names()[rand_anim_index]
					#chess_animation.play(rand_anim_name)
					var rand_wait_time = randf_range(1.5, 3.5)
					await get_tree().create_timer(rand_wait_time).timeout
					if is_instance_valid(chess_animation) and not chess_animation.is_queued_for_deletion():
						chess_animation.play("idle")
			)

		else:
			pass
		animation_count += 1
		
func _load_animations(aniamtion: AnimatedSprite2D, faction: String, chess_name: String):
	var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, chess_name]
	if ResourceLoader.exists(path):
		var frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
		aniamtion.sprite_frames = frames
		aniamtion.play("idle")
	else:
		push_error("Animation resource not found: " + path)

func waiting_chess_checkin() -> Array:
	var chess_array_width := 8
	var chess_array_height := 10
	var chess_size = Vector2i(20, 20)
	var new_position
	var check_in_chess_faction: String = ""
	var check_in_chess_name: String = ""
	
	
	for node in waiting_chess.get_children():
		if (not is_instance_valid(node)) or (not node is AnimatedSprite2D):
			continue
		node.stop()
	
		if node.position == Vector2(7 * 20, 0):
			var move_tween1
			if move_tween1:
				move_tween1.kill()
			new_position = node.position + Vector2(40, 0)
			move_tween1 = create_tween()
			move_tween1.set_trans(Tween.TRANS_LINEAR)
			move_tween1.tween_property(node, "position", new_position, 0.1)
			check_in_chess_faction = node.get_meta("faction", "")
			check_in_chess_name = node.get_meta("chess_name", "")
			await move_tween1.finished
			node.queue_free()
			await get_tree().process_frame
			continue

		var move_tween				
		node.play("move")
		var chess_current_tile = Vector2i(floor(node.position.x / chess_size.x), floor(node.position.y / chess_size.y))
		if chess_current_tile.x == 7 and chess_current_tile.y % 2 != 0:
			new_position = node.position + Vector2(-20, 0)
		elif chess_current_tile.x == 7 and chess_current_tile.y % 2 == 0:
			new_position = node.position + Vector2(0, -20)
		elif chess_current_tile.x == 0 and chess_current_tile.y % 2 != 0:
			new_position = node.position + Vector2(0, -20)
		elif chess_current_tile.x == 0 and chess_current_tile.y % 2 == 0:
			new_position = node.position + Vector2(20, 0)
		elif chess_current_tile.y % 2 != 0:
			new_position = node.position + Vector2(-20, 0)
		elif chess_current_tile.y % 2 == 0:
			new_position = node.position + Vector2(20, 0)
		
		if move_tween:
			move_tween.kill()
		move_tween = create_tween()
		move_tween.set_trans(Tween.TRANS_LINEAR)
		move_tween.tween_property(node, "position", new_position, 0.02)
		#await move_tween.finished
				
		chess_current_tile = Vector2i(floor(new_position.x / chess_size.x), floor(new_position.y / chess_size.y))
		if chess_current_tile.y % 2 != 0:
			node.flip_h = true
		else:
			node.flip_h = false				
		
		node.play("idle")
		
	var chess_animation = AnimatedSprite2D.new()
	waiting_chess.add_child(chess_animation) 
	
	if enemy_death_array.size() <= 0:
		return [check_in_chess_faction, check_in_chess_name]
		
	var chess_faction = enemy_death_array.pop_front()
	var chess_name = enemy_death_array.pop_front()
	
	if not (DataManagerSingleton.get_chess_data().keys().has(chess_faction) and DataManagerSingleton.get_chess_data()[chess_faction].keys().has(chess_name)):
		return [check_in_chess_faction, check_in_chess_name]
		
	chess_animation.flip_h = true				
	chess_animation.position = Vector2((chess_array_width - 1) * chess_size.x, (chess_array_height - 1) * chess_size.y)
	chess_animation.z_index = 30
	_load_animations(chess_animation, chess_faction, chess_name)
	chess_animation.animation_finished.connect(
		func():
			#var rand_anim_index = randi_range(0, chess_animation.sprite_frames.get_animation_names().size() - 1)
			#var rand_anim_name = chess_animation.sprite_frames.get_animation_names()[rand_anim_index]
			#chess_animation.play(rand_anim_name)
			var rand_wait_time = randf_range(1.5, 3.5)
			await get_tree().create_timer(rand_wait_time).timeout
			if is_instance_valid(chess_animation) and not chess_animation.is_queued_for_deletion():
				chess_animation.play("idle")
	)

	return [check_in_chess_faction, check_in_chess_name]
