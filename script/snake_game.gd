# =====================================================
# Snake Game for Godot 2D Pixel Game
# 
# Node Structure:
# SnakeGame (Node2D)
#   ├── GameBoard (Node2D) - Main game container
#   │   ├── Background (ColorRect) - Game background
#   │   └── GameElements (Node2D) - Container for snake and food
#   ├── UIContainer (Control) - UI elements
#   │   ├── ScoreLabel (Label) - Display current score
#   │   ├── HighScoreLabel (Label) - Display high score
#   │   ├── GameOverPanel (Panel) - Game over screen
#   │   └── StartButton (Button) - Start game button
#   └── GameTimer (Timer) - Controls snake movement speed
# =====================================================

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
var move_speed = 0.15  # Time between moves in seconds (can be adjusted)

# Node references
@onready var game_board = $GameBoard
@onready var background = $GameBoard/Background
@onready var game_elements = $GameBoard/GameElements
@onready var ui_container = $UIContainer
@onready var score_label = $UIContainer/ScoreLabel
@onready var high_score_label = $UIContainer/HighScoreLabel
@onready var game_over_panel = $UIContainer/GameOverPanel
@onready var start_button = $UIContainer/StartButton
@onready var game_timer = $GameTimer

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
	
	# Initialize snake - start with 3 segments in the middle
	snake_body.clear()
	var start_x = GRID_WIDTH / 2
	var start_y = GRID_HEIGHT / 2
	
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
	var valid_positions = []
	
	# Find all empty positions
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var pos = Vector2(x, y)
			if not snake_body.has(pos):
				valid_positions.append(pos)
	
	# Randomly select a position for food
	if valid_positions.size() > 0:
		var random_index = randi() % valid_positions.size()
		food_position = valid_positions[random_index]
	else:
		# No valid positions (snake fills entire board) - game won!
		_end_game(true)

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
	for i in range(snake_body.size() - 1):
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
	draw_rect(rect, color)
	
	# Add a small border for pixel art style
	var border_rect = Rect2(
		offset + cell_position * GRID_SIZE,
		Vector2(GRID_SIZE - 1, GRID_SIZE - 1)
	)
	draw_rect(border_rect, Color.BLACK, false)

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
