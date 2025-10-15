extends Node2D

# Constants
const GRID_SIZE := Vector2(16, 16)
const GAME_WIDTH := 20
const GAME_HEIGHT := 15
const MOVE_SPEED := 0.2  # seconds per tile

# Game variables
var score := 0
var high_score := 0
var is_game_active := false
var current_direction := Vector2.RIGHT
var next_direction := Vector2.RIGHT
var snake_body: Array[Vector2] = []
var snake_sprites: Array[AnimatedSprite2D] = []
var chess_position := Vector2.ZERO
var chess_sprite: AnimatedSprite2D
var enemy_death_array: Array
var current_chess_index := 0  # Track which chess to use next


@onready var game_board: Node2D = $GameBoard
@onready var background: TileMapLayer = $GameBoard/Background
@onready var game_elements: Node2D = $GameBoard/GameElements
@onready var ui_container: Control = $UIContainer
@onready var score_label: Label = $UIContainer/ScoreLabel
@onready var high_score_label: Label = $UIContainer/HighScoreLabel
@onready var start_button: Button = $UIContainer/StartButton
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_timer: Timer = $GameTimer
@onready var waiting_chess: Node2D = $waiting_chess

var animation_count:= 0

signal to_menu_scene

func _ready() -> void:
	"""Initialize game state and load high score"""
	enemy_death_array = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["enemy_death_array"].duplicate(true)

	high_score = _load_high_score()
	_update_ui()
	game_over_panel.hide()
	_initialize_game_board()


func _initialize_game_board() -> void:
	"""Set up the game board background"""
	# Clear existing tiles
	#background.clear()
	
	# Fill the game area with background tiles
	#for x in range(GAME_WIDTH):
		#for y in range(GAME_HEIGHT):
			#background.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	pass

func start_game() -> void:
	"""Start a new game with initial snake and chess"""
	# Reset game state
	score = 0
	is_game_active = true
	current_direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	current_chess_index = 0  # Reset chess index
	
	# Clear existing game elements
	for child in game_elements.get_children():
		child.queue_free()
	snake_body.clear()
	snake_sprites.clear()
	
	# Initialize snake in the center with two segments
	var start_pos := Vector2(GAME_WIDTH / 2, GAME_HEIGHT / 2)
	snake_body = [start_pos, start_pos - Vector2.RIGHT]
	
	# Create snake segments using first two pairs from enemy_death_array
	if enemy_death_array.size() >= 4:
		for i in range(2):
			var segment_pos := snake_body[i]
			var faction: String = enemy_death_array[i * 2]
			var chess_name: String = enemy_death_array[i * 2 + 1]
			_create_snake_segment(segment_pos, faction, chess_name)
			current_chess_index += 2  # Move to next chess pair
	
	# Generate first chess
	_generate_chess()
	
	# Start game timer
	game_timer.wait_time = MOVE_SPEED
	game_timer.start()
	
	_update_ui()
	start_button.hide()


func _create_snake_segment(position: Vector2, faction: String, chess_name: String) -> void:
	"""Create a visual snake segment at the given position with specific animation"""
	var animated_sprite := AnimatedSprite2D.new()
	
	# Get sprite frame from enemy_death_array
	var sprite_frame: SpriteFrames = _get_sprite_frame(faction, chess_name)
	animated_sprite.sprite_frames = sprite_frame
	
	animated_sprite.position = position * GRID_SIZE
	animated_sprite.play("default")
	
	# Set initial flip based on direction
	if snake_sprites.is_empty():  # Head
		animated_sprite.flip_h = (current_direction == Vector2.LEFT)
	
	game_elements.add_child(animated_sprite)
	snake_sprites.append(animated_sprite)


func _generate_chess() -> void:
	"""Generate new chess at random position not occupied by snake"""
	# Check if board is full
	if snake_body.size() >= GAME_WIDTH * GAME_HEIGHT:
		_end_game(true)  # Win condition - board filled
		return
	
	# Find all valid positions not occupied by snake
	var valid_positions: Array[Vector2] = []
	for x in range(GAME_WIDTH):
		for y in range(GAME_HEIGHT):
			var pos = Vector2(x, y)
			if not snake_body.has(pos):
				valid_positions.append(pos)
	
	# If no valid positions, end game
	if valid_positions.is_empty():
		_end_game(true)
		return
	
	# Select random position
	chess_position = valid_positions.pick_random()
	
	# Remove existing chess if any
	if chess_sprite and is_instance_valid(chess_sprite):
		chess_sprite.queue_free()
	
	# Create chess visual
	chess_sprite = AnimatedSprite2D.new()
	
	# Get next chess pair from enemy_death_array
	if enemy_death_array.size() >= current_chess_index + 2:
		var faction: String = enemy_death_array[current_chess_index]
		var chess_name: String = enemy_death_array[current_chess_index + 1]
		var sprite_frame: SpriteFrames = _get_sprite_frame(faction, chess_name)
		chess_sprite.sprite_frames = sprite_frame
	
	chess_sprite.position = chess_position * GRID_SIZE + Vector2(8, 0)
	chess_sprite.play("default")
	chess_sprite.name = "Chess"
	chess_sprite.play("jump")
	game_elements.add_child(chess_sprite)


func _input(event: InputEvent) -> void:
	"""Handle input for changing snake direction"""
	if not is_game_active:
		return
	
	if event.is_action_pressed("ui_right") and current_direction != Vector2.LEFT:
		next_direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_left") and current_direction != Vector2.RIGHT:
		next_direction = Vector2.LEFT
	elif event.is_action_pressed("ui_down") and current_direction != Vector2.UP:
		next_direction = Vector2.DOWN
	elif event.is_action_pressed("ui_up") and current_direction != Vector2.DOWN:
		next_direction = Vector2.UP


func _on_game_timer_timeout() -> void:
	"""Move snake one tile in current direction on timer timeout"""
	if not is_game_active:
		return
	
	current_direction = next_direction
	
	# Calculate new head position
	var new_head_pos: Vector2 = snake_body[0] + current_direction
	
	# Wrap around screen edges
	#new_head_pos.x = wrapf(new_head_pos.x, 0, GAME_WIDTH)
	#new_head_pos.y = wrapf(new_head_pos.y, 0, GAME_HEIGHT)
	
	# Check for collisions
	if _check_collision(new_head_pos):
		_end_game(false)
		return
	
	# Check if eating chess
	var is_eating_chess := (new_head_pos == chess_position)
	
	# Move snake
	snake_body.push_front(new_head_pos)
	if not is_eating_chess:
		snake_body.pop_back()
	else:
		score += 1
		
		# Add new segment to snake using next chess animation
		var tail_pos: Vector2 = snake_body[snake_body.size() - 1]
		
		# Use next chess pair from enemy_death_array
		if enemy_death_array.size() >= current_chess_index + 2:
			var faction: String = enemy_death_array[current_chess_index]
			var chess_name: String = enemy_death_array[current_chess_index + 1]
			_create_snake_segment(tail_pos, faction, chess_name)
			current_chess_index += 2  # Move to next chess pair
		
		# Generate new chess
		_generate_chess()
		_update_ui()
	
	_update_snake()


func _check_collision(position: Vector2) -> bool:
	"""Check if position collides with snake body (excluding head for movement)"""
	# Check collision with body (skip head since it's moving to new position)
	for i in range(1, snake_body.size()):
		if snake_body[i] == position:
			return true
		else:
			if position.x < 0:
				return true
			elif position.x >= GAME_WIDTH:
				return true
			elif position.y < 0:
				return true
			elif position.y >= GAME_HEIGHT:
				return true
	return false


func _end_game(is_win: bool) -> void:
	"""End game and check for high score"""
	is_game_active = false
	game_timer.stop()
	
	if score > high_score:
		high_score = score
		_save_high_score()
	
	# Show game over panel
	game_over_panel.show()
	start_button.show()
	DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["enemy_death_array"] = enemy_death_array


func _update_snake() -> void:
	"""Update all snake segments positions and animations with smooth movement"""
	# Update positions of all snake segments
	for i in range(snake_body.size()):
		if i < snake_sprites.size():
			snake_sprites[i].play("move")
			var target_position: Vector2 = snake_body[i] * GRID_SIZE + Vector2(8, 0)
			
			# Create tween for smooth movement
			var tween := create_tween()
			tween.tween_property(snake_sprites[i], "position", target_position, MOVE_SPEED)
			
			# Update flip_h for head based on direction
			if i == 0:  # Head
				snake_sprites[i].flip_h = (current_direction == Vector2.LEFT)
			else:
				snake_sprites[i].flip_h = snake_body[i].x - snake_body[i - 1].x > 0


func _update_ui() -> void:
	"""Update score and high score display"""
	score_label.text = "Score: " + str(score)
	high_score_label.text = "High Score: " + str(high_score)


func _save_high_score() -> void:
	"""Save high score to persistent storage"""
	var save_file := FileAccess.open("user://high_score.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(high_score)
		save_file.close()


func _load_high_score() -> int:
	"""Load high score from persistent storage"""
	var loaded_high_score := 0
	
	var save_file := FileAccess.open("user://high_score.save", FileAccess.READ)
	if save_file:
		loaded_high_score = save_file.get_var()
		save_file.close()
	
	return loaded_high_score


func _on_start_button_pressed() -> void:
	"""Start game when start button is pressed"""
	game_over_panel.hide()
	start_game()


func set_move_speed(new_speed: float) -> void:
	"""Change snake movement speed"""
	game_timer.wait_time = new_speed
	if is_game_active:
		game_timer.start()


func _get_sprite_frame(faction: String, chess_name: String) -> SpriteFrames:
	"""Get sprite frame based on faction and chess name"""
	var frames
	var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, chess_name]
	if ResourceLoader.exists(path):
		frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			if anim_name == "move" or anim_name == "jump" or anim_name == "fly":
				frames.set_animation_loop(anim_name, true)
			else:
				frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
	else:
		push_error("Animation resource not found: " + path)
		
	return frames


func _on_back_button_pressed() -> void:
	to_menu_scene.emit()


func _on_restart_button_pressed() -> void:
	_initialize_game_board() 
	start_game()
	game_over_panel.visible = false
