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

# Tile coordinates for each color in the tileset
const COLORS_TILE = {
	Color.CYAN: Vector2i(3, 19),
	Color.YELLOW: Vector2i(4, 19),
	Color.PURPLE: Vector2i(5, 19),
	Color.ORANGE: Vector2i(4, 21),
	Color.BLUE: Vector2i(5, 21),
	Color.GREEN: Vector2i(4, 22),
	Color.RED: Vector2i(5, 22)
}

# Game state
var board = []  # Board array, "" = empty, string = piece type
var current_piece_type = ""
var current_piece_position = Vector2i(0, 0)
var current_piece_rotation = 0
var next_piece_type = ""
var score = 0
var game_over = false
var drop_timer = 0.0
const DROP_INTERVAL = 1.0

# Node references
@onready var board_tilemap: TileMapLayer = $Board/TileMapLayer
@onready var piece_tilemap: TileMapLayer = $PieceContainer/TileMapLayer
@onready var next_piece_tilemap: TileMapLayer = $NextPieceContainer/TileMapLayer
@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/RestartButton
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel

signal to_menu_scene

func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)
	start_new_game()

func start_new_game():
	# Reset game state
	score = 0
	game_over = false
	game_over_panel.visible = false
	current_piece_rotation = 0
	
	# Create empty game board
	board = []
	for y in range(BOARD_HEIGHT):
		var row = []
		for x in range(BOARD_WIDTH):
			row.append("")
		board.append(row)
	
	# Clear all tilemaps
	board_tilemap.clear()
	piece_tilemap.clear()
	next_piece_tilemap.clear()
	
	# Generate initial pieces
	next_piece_type = get_random_piece_type()
	spawn_new_piece()
	
	# Update UI
	score_label.text = "Score: " + str(score)

func get_random_piece_type():
	var pieces = SHAPES.keys()
	return pieces[randi() % pieces.size()]

func spawn_new_piece():
	current_piece_type = next_piece_type
	current_piece_position = Vector2i(BOARD_WIDTH / 2 - 2, 0)
	current_piece_rotation = 0
	next_piece_type = get_random_piece_type()
	
	# Check if game is over
	if check_collision(current_piece_position, get_current_shape()):
		game_over = true
		final_score_label.text = "Game Over\nfinal score : " + str(score)
		game_over_panel.visible = true
		return
	
	# Draw current piece and next piece preview
	draw_current_piece()
	draw_next_piece()

func get_current_shape():
	if current_piece_type == "O":  # O piece doesn't rotate
		return SHAPES[current_piece_type]
	
	var shape = SHAPES[current_piece_type].duplicate()
	for i in range(current_piece_rotation):
		shape = rotate_shape_90(shape)
	return shape

func rotate_shape_90(shape):
	var rotated = []
	for cell in shape:
		rotated.append(Vector2i(-cell.y + 1, cell.x + 1))
	return rotated

func draw_board():
	# Clear and redraw board tilemap
	board_tilemap.clear()
	
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] != "":
				var color = COLORS[board[y][x]]
				var tile_coords = COLORS_TILE[color]
				board_tilemap.set_cell(Vector2i(x, y), 0, tile_coords)

func draw_current_piece():
	# Clear current piece tilemap
	piece_tilemap.clear()
	
	# Draw current piece
	var current_shape = get_current_shape()
	var color = COLORS[current_piece_type]
	var tile_coords = COLORS_TILE[color]
	
	for cell in current_shape:
		var pos = current_piece_position + cell
		if pos.y >= 0:  # Only draw if within visible area
			piece_tilemap.set_cell(pos, 0, tile_coords)

func draw_next_piece():
	# Clear next piece preview tilemap
	next_piece_tilemap.clear()
	
	# Draw next piece preview
	var color = COLORS[next_piece_type]
	var tile_coords = COLORS_TILE[color]
	
	for cell in SHAPES[next_piece_type]:
		var preview_pos = cell + Vector2i(2, 2)  # Adjust position for preview
		next_piece_tilemap.set_cell(preview_pos, 0, tile_coords)

func check_collision(position, shape):
	for cell in shape:
		var pos = position + cell
		
		# Check boundaries
		if pos.x < 0 or pos.x >= BOARD_WIDTH or pos.y >= BOARD_HEIGHT:
			return true
		
		# Check other blocks
		if pos.y >= 0 and pos.y < BOARD_HEIGHT and pos.x >= 0 and pos.x < BOARD_WIDTH:
			if board[pos.y][pos.x] != "":
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
	if game_over or current_piece_type == "O":
		return
	
	var new_rotation = (current_piece_rotation + 1) % 4
	var test_shape = SHAPES[current_piece_type].duplicate()
	for i in range(new_rotation):
		test_shape = rotate_shape_90(test_shape)
	
	if not check_collision(current_piece_position, test_shape):
		current_piece_rotation = new_rotation
		draw_current_piece()

func drop_piece():
	if game_over:
		return
	
	while move_piece(Vector2i(0, 1)):
		pass
	lock_piece()

func lock_piece():
	# Lock current piece to game board
	for cell in get_current_shape():
		var pos = current_piece_position + cell
		if pos.y >= 0 and pos.y < BOARD_HEIGHT and pos.x >= 0 and pos.x < BOARD_WIDTH:
			board[pos.y][pos.x] = current_piece_type
	
	# Check and clear completed lines
	var lines_cleared = 0
	var lines_to_clear = []
	
	for y in range(BOARD_HEIGHT):
		var row_full = true
		for x in range(BOARD_WIDTH):
			if board[y][x] == "":
				row_full = false
				break
		
		if row_full:
			lines_to_clear.append(y)
			lines_cleared += 1
	
	# Remove completed lines and add new empty rows
	lines_to_clear.sort()
	for i in range(lines_to_clear.size() - 1, -1, -1):
		board.remove_at(lines_to_clear[i])
	
	for i in range(lines_cleared):
		var new_row = []
		for x in range(BOARD_WIDTH):
			new_row.append("")
		board.insert(0, new_row)
	
	# Update score
	if lines_cleared > 0:
		score += lines_cleared * 100
		score_label.text = "Score: " + str(score)
	
	# Update board and spawn new piece
	draw_board()
	spawn_new_piece()

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

func _on_restart_button_pressed():
	game_over_panel.visible = false
	start_new_game()

func _on_button_pressed() -> void:
	to_menu_scene.emit()
