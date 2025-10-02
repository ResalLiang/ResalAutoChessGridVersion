# GameManager.gd
# Node Structure:
# Main (Node2D)
# ├── Board (Node2D) - Game board display
# ├── PieceContainer (Node2D) - Current piece container
# ├── NextPieceContainer (Node2D) - Next piece preview
# ├── ScoreLabel (Label) - Score display
# └── GameOverPanel (Panel) - Game over panel

extends Node2D

# Game configuration
const BOARD_WIDTH = 8
const BOARD_HEIGHT = 16
const CELL_SIZE = 16

# Tetromino shape definitions
const SHAPES = {
	"I": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"O": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0)],
	"L": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 0)],
	"J": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 0)],
	"S": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"Z": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
}

# Color definitions
const COLORS = {
	"I": Color.CYAN,
	"O": Color.YELLOW,
	"T": Color.PURPLE,
	"L": Color.ORANGE,
	"J": Color.BLUE,
	"S": Color.GREEN,
	"Z": Color.RED
}

# Game state
var board = []  # Board array, "" = empty, string = piece type
var current_piece_type = ""
var current_piece_position = Vector2i(0, 0)
var current_piece_rotation = 0  # Track current rotation state
var next_piece_type = ""
var score = 0
var game_over = false
var drop_timer = 0.0
const DROP_INTERVAL = 1.0  # Drop one cell per second

# Node references
@onready var board_node:Node2D = $Board
@onready var piece_container:Node2D = $PieceContainer
@onready var next_piece_container:Node2D = $NextPieceContainer
@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel:Panel = $GameOverPanel
@onready var restart_button:Button = $GameOverPanel/RestartButton
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel

signal to_menu_scene

func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)
	# Initialize game board
	initialize_board()
	# Start new game
	start_new_game()

func initialize_board():
	# Create empty game board
	board = []
	for y in range(BOARD_HEIGHT):
		var row = []
		for x in range(BOARD_WIDTH):
			row.append("")  # Use empty string for empty cells
		board.append(row)

func start_new_game():
	# Reset game state
	score = 0
	game_over = false
	game_over_panel.visible = false
	current_piece_rotation = 0
	
	# Clear game board
	initialize_board()
	
	# Generate initial pieces
	next_piece_type = get_random_piece_type()
	spawn_new_piece()
	
	# Update UI
	update_score_display()
	draw_board()

func get_random_piece_type():
	var pieces = SHAPES.keys()
	return pieces[randi() % pieces.size()]

func spawn_new_piece():
	# Set current piece
	current_piece_type = next_piece_type
	current_piece_position = Vector2i(BOARD_WIDTH / 2 - 2, 0)
	current_piece_rotation = 0
	
	# Generate next piece
	next_piece_type = get_random_piece_type()
	
	# Check if game is over
	if check_collision(current_piece_position, get_current_shape()):
		game_over = true
		game_over_panel.visible = true
		return
	
	# Draw current piece and next piece preview
	draw_current_piece()
	draw_next_piece()

func get_current_shape():
	# Get the current shape based on rotation
	if current_piece_type == "O":  # O piece doesn't rotate
		return SHAPES[current_piece_type]
	
	var shape = SHAPES[current_piece_type].duplicate()  # Create a copy to rotate
	
	# Apply rotation
	for i in range(current_piece_rotation):
		shape = rotate_shape_90(shape)
	
	return shape

func rotate_shape_90(shape):
	# Rotate shape 90 degrees clockwise
	var rotated = []
	for cell in shape:
		# Simple rotation around (1,1) as center
		var rotated_cell = Vector2i(-cell.y + 1, cell.x + 1)
		rotated.append(rotated_cell)
	return rotated

func draw_board():
	# Clear board display
	for child in board_node.get_children():
		child.queue_free()
	
	# Draw blocks on game board
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] != "":  # Check for non-empty string
				draw_cell(board_node, Vector2i(x, y), COLORS[board[y][x]])

func draw_current_piece():
	# Clear current piece display
	for child in piece_container.get_children():
		child.queue_free()
	
	# Draw current piece
	var current_shape = get_current_shape()
	for cell in current_shape:
		var pos = current_piece_position + cell
		# Only draw if the cell is within the visible board
		if pos.y >= 0:
			draw_cell(piece_container, pos, COLORS[current_piece_type])

func draw_next_piece():
	# Clear next piece preview
	for child in next_piece_container.get_children():
		child.queue_free()
	
	# Draw next piece preview
	for cell in SHAPES[next_piece_type]:
		draw_cell(next_piece_container, cell + Vector2i(2, 2), COLORS[next_piece_type])

func draw_cell(container, position, color):
	var rect = ColorRect.new()
	rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	rect.position = Vector2(position.x * CELL_SIZE, position.y * CELL_SIZE)
	rect.color = color
	# Add a small border to make cells more visible
	var style_box = StyleBoxFlat.new()
	style_box.border_width_bottom = 1
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_color = Color.BLACK
	rect.set("theme_override_styles/panel", style_box)
	container.add_child(rect)

func check_collision(position, shape):
	# Check if piece collides with boundaries or other blocks
	for cell in shape:
		var pos = position + cell
		
		# Check boundaries
		if pos.x < 0 or pos.x >= BOARD_WIDTH or pos.y >= BOARD_HEIGHT:
			return true
		
		# Check bottom and other blocks
		# Make sure we're checking within the board bounds
		if pos.y >= 0 and pos.y < BOARD_HEIGHT and pos.x >= 0 and pos.x < BOARD_WIDTH:
			if board[pos.y][pos.x] != "":  # Check for non-empty string
				return true
	
	return false

func move_piece(direction):
	if game_over:
		return false
	
	var new_position = current_piece_position + direction
	
	if not check_collision(new_position, get_current_shape()):
		current_piece_position = new_position
		draw_current_piece()
		return true
	
	return false

func rotate_piece():
	if game_over or current_piece_type == "O":  # O piece doesn't rotate
		return
	
	# Try to rotate
	var new_rotation = (current_piece_rotation + 1) % 4
	var test_shape = SHAPES[current_piece_type].duplicate()
	for i in range(new_rotation):
		test_shape = rotate_shape_90(test_shape)
	
	# Check collision after rotation
	if not check_collision(current_piece_position, test_shape):
		current_piece_rotation = new_rotation
		draw_current_piece()

func drop_piece():
	if game_over:
		return
	
	# Move piece to bottom
	while move_piece(Vector2i(0, 1)):
		pass
	
	# Lock piece to board
	lock_piece()

func lock_piece():
	# Lock current piece to game board
	var current_shape = get_current_shape()
	for cell in current_shape:
		var pos = current_piece_position + cell
		if pos.y >= 0 and pos.y < BOARD_HEIGHT and pos.x >= 0 and pos.x < BOARD_WIDTH:
			board[pos.y][pos.x] = current_piece_type
	
	# Check and clear completed lines
	clear_completed_lines()
	
	# Update the board display
	draw_board()
	
	# Spawn new piece
	spawn_new_piece()

func clear_completed_lines():
	var lines_cleared = 0
	var lines_to_clear = []
	
	# Find completed lines
	for y in range(BOARD_HEIGHT):
		var row_full = true
		for x in range(BOARD_WIDTH):
			if board[y][x] == "":  # Check for empty string
				row_full = false
				break
		
		if row_full:
			lines_to_clear.append(y)
			lines_cleared += 1
	
	# Remove completed lines from bottom to top
	lines_to_clear.sort()
	for i in range(lines_to_clear.size() - 1, -1, -1):
		var y = lines_to_clear[i]
		board.remove_at(y)
	
	# Add new empty rows at top
	for i in range(lines_cleared):
		var new_row = []
		for x in range(BOARD_WIDTH):
			new_row.append("")  # Use empty string for empty cells
		board.insert(0, new_row)
	
	# Update score
	if lines_cleared > 0:
		score += lines_cleared * 100
		update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(score)

func _process(delta):
	if game_over:
		return
	
	# Automatic dropping
	drop_timer += delta
	if drop_timer >= DROP_INTERVAL:
		drop_timer = 0.0
		if not move_piece(Vector2i(0, 1)):
			lock_piece()

func _input(event):
	if event.is_action_pressed("ui_left"):
		move_piece(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_piece(Vector2i(1, 0))
	elif event.is_action_pressed("ui_down"):
		move_piece(Vector2i(0, 1))
	elif event.is_action_pressed("ui_up"):
		rotate_piece()
	elif event.is_action_pressed("ui_accept"):  # Space key
		drop_piece()
	elif event.is_action_pressed("ui_cancel"):  # ESC key
		if game_over:
			start_new_game()

func update_score(score):
	score_label.text = "Score: " + str(score)

func show_game_over():
	final_score_label.text = "Game Over\nfinal score : " + str(score)
	game_over_panel.visible = true

func _on_restart_button_pressed():
	game_over_panel.visible = false
	
	# Initialize game board
	initialize_board()
	# Start new game
	start_new_game()


func _on_button_pressed() -> void:
	to_menu_scene.emit()
