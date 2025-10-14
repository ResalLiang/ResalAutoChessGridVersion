# =====================================================
# Minesweeper Game for Godot 2D Pixel Game
# 
# Code Structure:
# 1. Constants and Variables
# 2. _ready() - Initialization
# 3. _input(event) - Input Handling
# 4. Game Initialization Methods
# 5. Game Logic Methods
# 6. UI and Rendering Methods
# 7. Utility Methods
# =====================================================

extends Node2D

# =====================================================
# 1. CONSTANTS AND VARIABLES
# =====================================================

# Game difficulty settings (rows, cols, mines)
const DIFFICULTY_SETTINGS = {
	"beginner": {"rows": 9, "cols": 9, "mines": 10},
	"intermediate": {"rows": 16, "cols": 16, "mines": 40},
	"expert": {"rows": 16, "cols": 30, "mines": 99}
}

# Cell states
const CELL_UNOPENED = 0
const CELL_OPENED = 1
const CELL_FLAGGED = 2
const CELL_QUESTION = 3

# Cell types
const CELL_EMPTY = 0
const CELL_MINE = 1
const CELL_NUMBER_1 = 2
const CELL_NUMBER_2 = 3
const CELL_NUMBER_3 = 4
const CELL_NUMBER_4 = 5
const CELL_NUMBER_5 = 6
const CELL_NUMBER_6 = 7
const CELL_NUMBER_7 = 8
const CELL_NUMBER_8 = 9

# Configuration variables
var cell_size = 16  # Can be changed to adjust game size
var current_difficulty = "beginner"
var game_over = false
var first_click = true

# Game data structures
var board_data = {}  # Dictionary storing cell content (mine, number, empty)
var board_state = {}  # Dictionary storing cell state (unopened, opened, flagged)
var board_size = Vector2(0, 0)
var mines_count = 0
var flags_placed = 0

# TileMap references
@onready var background_layer: TileMap = $BackgroundLayer
@onready var content_layer: TileMap = $ContentLayer
@onready var state_layer: TileMap = $StateLayer

# UI references
@onready var ui_container: Control = $UIContainer
@onready var difficulty_buttons: HBoxContainer = $UIContainer/DifficultyButtons
@onready var mines_label: Label = $UIContainer/MinesLabel
@onready var game_status_label: Label = $UIContainer/GameStatusLabel

# =====================================================
# 2. INITIALIZATION
# =====================================================

func _ready():
	# Initialize the game with beginner difficulty
	initialize_game("beginner")
	
	# Connect difficulty buttons
	for button in difficulty_buttons.get_children():
		if button is Button:
			button.pressed.connect(_on_difficulty_button_pressed.bind(button.name.to_lower()))

# =====================================================
# 3. INPUT HANDLING
# =====================================================

func _input(event):
	if game_over:
		return
	
	# Handle mouse input on the game board
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell_pos = background_layer.local_to_map(background_layer.to_local(mouse_pos))
		
		# Check if click is within board bounds
		if is_position_valid(cell_pos):
			handle_cell_click(cell_pos, event)

# Handle cell clicks based on mouse button
func handle_cell_click(cell_pos: Vector2i, event: InputEventMouseButton):
	var current_state = board_state[cell_pos]
	
	# Left click - open cell
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if current_state == CELL_UNOPENED:
			open_cell(cell_pos)
	
	# Right click - toggle flag/question mark
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if current_state == CELL_UNOPENED:
			# Place flag
			board_state[cell_pos] = CELL_FLAGGED
			flags_placed += 1
			update_cell_display(cell_pos)
		elif current_state == CELL_FLAGGED:
			# Change to question mark
			board_state[cell_pos] = CELL_QUESTION
			flags_placed -= 1
			update_cell_display(cell_pos)
		elif current_state == CELL_QUESTION:
			# Back to unopened
			board_state[cell_pos] = CELL_UNOPENED
			update_cell_display(cell_pos)
	
	# Middle click or both buttons - chord action (open surrounding cells)
	elif (event.button_index == MOUSE_BUTTON_MIDDLE or 
		  (event.button_index == MOUSE_BUTTON_LEFT and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or
		  (event.button_index == MOUSE_BUTTON_RIGHT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))):
		if current_state == CELL_OPENED and get_cell_content(cell_pos) >= CELL_NUMBER_1:
			chord_action(cell_pos)
	
	update_ui()

# =====================================================
# 4. GAME INITIALIZATION METHODS
# =====================================================

# Initialize game with specified difficulty
func initialize_game(difficulty: String):
	current_difficulty = difficulty
	var settings = DIFFICULTY_SETTINGS[difficulty]
	board_size = Vector2(settings.cols, settings.rows)
	mines_count = settings.mines
	flags_placed = 0
	game_over = false
	first_click = true
	
	# Clear and initialize board data structures
	board_data.clear()
	board_state.clear()
	initialize_empty_board()
	
	# Setup TileMaps and UI
	setup_tilemaps()
	update_ui()
	
	game_status_label.text = "Game Started - " + difficulty.capitalize()

# Create empty board structure
func initialize_empty_board():
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			board_data[pos] = CELL_EMPTY
			board_state[pos] = CELL_UNOPENED

# Setup TileMap layers with proper cell size
func setup_tilemaps():
	# Clear all layers
	background_layer.clear()
	content_layer.clear()
	state_layer.clear()
	
	# Set cell size for all layers
	background_layer.tile_set.tile_size = Vector2i(cell_size, cell_size)
	content_layer.tile_set.tile_size = Vector2i(cell_size, cell_size)
	state_layer.tile_set.tile_size = Vector2i(cell_size, cell_size)
	
	# Create background grid
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			background_layer.set_cell(0, pos, 0, Vector2i(0, 0))  # Background tile
			state_layer.set_cell(0, pos, 0, Vector2i(0, 0))  # Unopened state tile

# =====================================================
# 5. GAME LOGIC METHODS
# =====================================================

# Place mines after first click to ensure first click is safe
func place_mines(first_click_pos: Vector2i):
	var mines_placed = 0
	var rng = RandomNumberGenerator.new()
	
	while mines_placed < mines_count:
		var x = rng.randi_range(0, board_size.x - 1)
		var y = rng.randi_range(0, board_size.y - 1)
		var pos = Vector2i(x, y)
		
		# Don't place mine on first click position or adjacent cells
		if pos != first_click_pos and not is_adjacent_to_position(pos, first_click_pos) and board_data[pos] != CELL_MINE:
			board_data[pos] = CELL_MINE
			mines_placed += 1
	
	# Calculate numbers for all non-mine cells
	calculate_cell_numbers()

# Check if position is adjacent to given position
func is_adjacent_to_position(pos: Vector2i, target_pos: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(pos.x + dx, pos.y + dy)
			if check_pos == target_pos:
				return true
	return false

# Calculate numbers for all cells based on adjacent mines
func calculate_cell_numbers():
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			if board_data[pos] != CELL_MINE:
				var mine_count = count_adjacent_mines(pos)
				if mine_count > 0:
					board_data[pos] = CELL_NUMBER_1 + (mine_count - 1)

# Count adjacent mines for a given cell
func count_adjacent_mines(pos: Vector2i) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(pos.x + dx, pos.y + dy)
			if is_position_valid(check_pos) and board_data[check_pos] == CELL_MINE:
				count += 1
	return count

# Open a cell and handle consequences
func open_cell(pos: Vector2i):
	# Place mines after first click
	if first_click:
		place_mines(pos)
		first_click = false
	
	var content = get_cell_content(pos)
	
	# Hit a mine - game over
	if content == CELL_MINE:
		board_state[pos] = CELL_OPENED
		game_over = true
		reveal_all_mines()
		game_status_label.text = "Game Over! You hit a mine!"
		update_cell_display(pos)
		return
	
	# Open empty cell with flood fill
	if content == CELL_EMPTY:
		flood_fill_open(pos)
	else:
		# Open numbered cell
		board_state[pos] = CELL_OPENED
		update_cell_display(pos)
	
	# Check for win condition
	check_win_condition()

# Recursive flood fill for opening empty areas
func flood_fill_open(pos: Vector2i):
	if not is_position_valid(pos) or board_state[pos] == CELL_OPENED:
		return
	
	board_state[pos] = CELL_OPENED
	update_cell_display(pos)
	
	# Only continue flood fill for empty cells
	if get_cell_content(pos) == CELL_EMPTY:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var new_pos = Vector2i(pos.x + dx, pos.y + dy)
				flood_fill_open(new_pos)

# Chord action - open surrounding cells when number equals adjacent flags
func chord_action(pos: Vector2i):
	var adjacent_flags = count_adjacent_flags(pos)
	var cell_number = get_cell_content(pos) - CELL_NUMBER_1 + 1
	
	if adjacent_flags == cell_number:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var check_pos = Vector2i(pos.x + dx, pos.y + dy)
				if is_position_valid(check_pos) and board_state[check_pos] == CELL_UNOPENED:
					open_cell(check_pos)

# Count adjacent flags for chord action
func count_adjacent_flags(pos: Vector2i) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var check_pos = Vector2i(pos.x + dx, pos.y + dy)
			if is_position_valid(check_pos) and board_state[check_pos] == CELL_FLAGGED:
				count += 1
	return count

# Check if player has won the game
func check_win_condition():
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			# If there's an unopened non-mine cell, game continues
			if board_data[pos] != CELL_MINE and board_state[pos] != CELL_OPENED:
				return
	
	# All non-mine cells are opened - player wins!
	game_over = true
	game_status_label.text = "Congratulations! You Win!"
	flag_all_mines()

# =====================================================
# 6. UI AND RENDERING METHODS
# =====================================================

# Update cell visual representation based on state and content
func update_cell_display(pos: Vector2i):
	var state = board_state[pos]
	
	# Clear previous content and state
	content_layer.set_cell(0, pos, -1)
	state_layer.set_cell(0, pos, -1)
	
	if state == CELL_OPENED:
		# Show cell content (number, mine, or empty)
		var content = get_cell_content(pos)
		if content == CELL_MINE:
			content_layer.set_cell(0, pos, 0, Vector2i(9, 0))  # Mine tile
		elif content >= CELL_NUMBER_1:
			var number = content - CELL_NUMBER_1
			content_layer.set_cell(0, pos, 0, Vector2i(number, 0))  # Number tile
		# Empty cells show nothing (already cleared)
	else:
		# Show cell state (unopened, flag, question mark)
		if state == CELL_FLAGGED:
			state_layer.set_cell(0, pos, 0, Vector2i(1, 0))  # Flag tile
		elif state == CELL_QUESTION:
			state_layer.set_cell(0, pos, 0, Vector2i(2, 0))  # Question mark tile
		else: # CELL_UNOPENED
			state_layer.set_cell(0, pos, 0, Vector2i(0, 0))  # Unopened tile

# Update UI elements
func update_ui():
	mines_label.text = "Mines: %d/%d" % [flags_placed, mines_count]

# Reveal all mines when game is lost
func reveal_all_mines():
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			if board_data[pos] == CELL_MINE and board_state[pos] != CELL_FLAGGED:
				board_state[pos] = CELL_OPENED
				update_cell_display(pos)

# Flag all mines when game is won
func flag_all_mines():
	for y in range(board_size.y):
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			if board_data[pos] == CELL_MINE and board_state[pos] != CELL_FLAGGED:
				board_state[pos] = CELL_FLAGGED
				update_cell_display(pos)
	flags_placed = mines_count
	update_ui()

# =====================================================
# 7. UTILITY METHODS
# =====================================================

# Check if position is within board bounds
func is_position_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < board_size.x and pos.y >= 0 and pos.y < board_size.y

# Get cell content with bounds checking
func get_cell_content(pos: Vector2i):
	if is_position_valid(pos):
		return board_data[pos]
	return CELL_EMPTY

# =====================================================
# UI SIGNAL HANDLERS
# =====================================================

func _on_difficulty_button_pressed(difficulty: String):
	initialize_game(difficulty)
