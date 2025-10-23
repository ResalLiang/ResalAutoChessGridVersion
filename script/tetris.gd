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

const RARITY_ARRY = ["Common", "Uncommon", "Rare", "Epic", "Legenadry"]

const effect_icon_scene = preload("res://scene/effect_icon.tscn")

# Game state
var board = []  # Board array, "" = empty, string = piece type
var current_piece_type = ""
var current_piece_position = Vector2i(0, 0)
var current_piece_rotation = 0
var next_piece_type = ""
var score = 0
var game_over = false
var drop_timer = 0.0
var drop_interval = 1.0
var rarity_index := 0:
	set(value):
		rarity_index = value
		update_rarity_label()
		line_up_chess()

var game_started:= false

# Node references
@onready var board_tilemap: TileMapLayer = $Board/TileMapLayer
@onready var piece_tilemap: TileMapLayer = $PieceContainer/TileMapLayer
@onready var next_piece_tilemap: TileMapLayer = $NextPieceContainer/TileMapLayer
@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/RestartButton
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel
@onready var left_button: TextureButton = $controller/speed_controller/LeftButton
@onready var right_button: TextureButton = $controller/speed_controller/RightButton
@onready var left_button2: TextureButton = $controller/rarity_filter/LeftButton
@onready var right_button2: TextureButton = $controller/rarity_filter/RightButton
@onready var label: Label = $controller/speed_controller/Label
@onready var label2: Label = $controller/rarity_filter/Label
@onready var game_start_button: TextureButton = $game_start_button
@onready var waiting_chess: Node2D = $waiting_chess
@onready var button: Button = $Button

signal to_menu_scene

var enemy_death_array
var animation_count:= 0

func _ready():
	var chess_array_width := 8
	var chess_array_height := 10
	var chess_size = Vector2i(20, 20)


	for y in range(chess_array_height):
		for x in range(chess_array_width):
			if y % 2 == 0:
				line_up_position.append(Vector2i(chess_array_width - 1 - x, y))
			else:
				line_up_position.append(Vector2i(x, y))
	line_up_position.make_read_only()
	
	reset_game()
	
	if restart_button.pressed.connect(_on_restart_button_pressed) != OK:
		print("restart_button connect fail!")
	update_drop_interval_label()
	left_button.pressed.connect(
		func():
			drop_interval -= 0.1
			drop_interval = max(0.1, drop_interval)
			update_drop_interval_label()
		
	)
	right_button.pressed.connect(
		func():
			drop_interval += 0.1
			drop_interval = min(2, drop_interval)
			update_drop_interval_label()
		
	)
	
	left_button2.pressed.connect(
		func():
			rarity_index -= 1
			rarity_index = max(0, rarity_index)
			update_rarity_label()
		
	)
	right_button2.pressed.connect(
		func():
			rarity_index += 1
			rarity_index = min(4, rarity_index)
			update_rarity_label()
		
	)
	game_start_button.pressed.connect(
		func():
			reset_game()
			game_started = true
			start_new_game()
			
	)
	button.pressed.connect(
		func():
			to_menu_scene.emit()
	)

	enemy_death_array = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["enemy_death_array"]

	line_up_chess()
	
func reset_game():

	# Reset game state
	score = 0
	game_over = false
	game_over_panel.visible = false
	current_piece_rotation = 0
	
	current_piece_type = ""
	
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
	
	# Update UI
	score_label.text = "Score: " + str(score)

func start_new_game():
	
	# Generate initial pieces
	next_piece_type = get_random_piece_type()
	spawn_new_piece()
	

func get_random_piece_type():
	#waiting_chess_checkin()
	var pieces = SHAPES.keys()
	return pieces[randi() % pieces.size()]

func spawn_new_piece():
	var check_in_chess = await waiting_chess_checkin()
	current_piece_type = next_piece_type
	current_piece_position = Vector2i(BOARD_WIDTH / 2 - 2, 0)
	current_piece_rotation = 0
	next_piece_type = get_random_piece_type()
	
	# Check if game is over
	if check_collision(current_piece_position, get_current_shape()):
		game_over = true
		final_score_label.text = "Game Over\nfinal score : " + str(score)
		game_over_panel.visible = true
		game_started = false
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
	
	# Safety check for empty piece type
	if current_piece_type == "" or current_piece_type == null:
		return
	
	# Draw current piece
	var current_shape = get_current_shape()
	var color = get_color_for_piece(current_piece_type)  # Use safe method
	var tile_coords = COLORS_TILE.get(color, Vector2i(0, 0))  # Use get method to avoid errors
	
	for cell in current_shape:
		var pos = current_piece_position + cell
		if pos.y >= 0:  # Only draw if within visible area
			piece_tilemap.set_cell(pos, 0, tile_coords)

func draw_next_piece():
	# Clear next piece preview tilemap
	next_piece_tilemap.clear()
	
	# Safety check for empty piece type
	if next_piece_type == "" or next_piece_type == null:
		return
	
	# Draw next piece preview
	var color = get_color_for_piece(next_piece_type)  # Use safe method
	var tile_coords = COLORS_TILE.get(color, Vector2i(0, 0))  # Use get method to avoid errors
	
	for cell in SHAPES[next_piece_type]:
		var preview_pos = cell + Vector2i(0, 0)  # Adjust position for preview
		next_piece_tilemap.set_cell(preview_pos, 0, tile_coords)

# Safe color retrieval method
func get_color_for_piece(piece_type: String) -> Color:
	# Return default color if piece type is empty or null
	if piece_type == "" or piece_type == null:
		return Color.WHITE
	
	# Use get method to safely access dictionary
	return COLORS.get(piece_type, Color.WHITE)

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
	if game_over or not game_started:
		return
	
	# Automatic dropping
	drop_timer += delta
	if drop_timer >= drop_interval:
		drop_timer = 0.0
		if not move_piece(Vector2i(0, 1)):
			lock_piece()

func _input(event):
	if not game_started:
		return
		
	if event.is_action_pressed("ui_left"):
		move_piece(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_piece(Vector2i(1, 0))
	elif event.is_action_pressed("ui_down"):
		move_piece(Vector2i(0, 1))
	elif event.is_action_pressed("ui_up"):
		rotate_piece()
	elif event.is_action_pressed("tetrix_drop"):  # Space key
		drop_piece()
	elif event.is_action_pressed("ui_cancel"):  # ESC key
		if game_over:
			start_new_game()
	elif event.is_action_pressed("refresh"):
		waiting_chess_checkin()

func _on_restart_button_pressed():
	reset_game()
	game_started = false

func update_drop_interval_label():
	label.text = str(drop_interval)

func update_rarity_label():
	label2.text = RARITY_ARRY[rarity_index]

func line_up_chess():

	for node in waiting_chess.get_children():
		if node is AnimatedSprite2D:
			node.queue_free()

	line_up_sprite = []


	enemy_death_array = enemy_death_array.filter(
		func(node):
			var node_faction = node[0]
			var node_chess_name = node[1]
			if not (DataManagerSingleton.get_chess_data().keys().has(node_faction) and DataManagerSingleton.get_chess_data()[node_faction].keys().has(node_chess_name)):
				return false

			# const RARITY_ARRY = ["Common", "Uncommon", "Rare", "Epic", "Legenadry"]
			if RARITY_ARRY.slice(0, rarity_index).has(DataManagerSingleton.get_chess_data()[node_faction][node_chess_name]["rarity"]):
				return true
			return false
	)
	if enemy_death_array.size() == 0:
		return
	 
	animation_count = 0

	var current_x := 0
	var current_y := 0
	var step_x := 1

	while animation_count < line_up_position.size():
		var chess_faction = enemy_death_array.pop_front()
		var chess_name = enemy_death_array.pop_front()
		if DataManagerSingleton.get_chess_data().keys().has(chess_faction) and DataManagerSingleton.get_chess_data()[chess_faction].keys().has(chess_name):
			var chess_animation = AnimatedSprite2D.new()
			waiting_chess.add_child(chess_animation) 

			chess_animation.set_meta("faction", chess_faction)
			chess_animation.set_meta("chess_name", chess_name)
			
			var current_chess_tile = line_up_position[animation_count]

			if current_chess_tile.y >= chess_array_height:
				return

			if current_chess_tile.y % 2 != 0:
				chess_animation.flip_h = true
			else:
				chess_animation.flip_h = false

			chess_animation.position = current_chess_tile * chess_size
			chess_animation.z_index = 30
			_load_animations(chess_animation, chess_faction, chess_name)
			line_up_sprite.append(chess_animation)

		animation_count += 1
		
func _load_animations(aniamtion: AnimatedSprite2D, faction: String, chess_name: String):
	var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, chess_name]
	if ResourceLoader.exists(path):
		var frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
		aniamtion.sprite_frames = frames

		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = load("res://asset/shader/LightweightPixelPerfectOutline.gdshader")
		aniamtion.material = shader_mat
		aniamtion.animation_finished.connect(
			func():
				var rand_wait_time = randf_range(1.5, 3.5)
				await get_tree().create_timer(rand_wait_time).timeout
				if is_instance_valid(aniamtion) and not aniamtion.is_queued_for_deletion() and aniamtion.sprite_frames.has_animation("idle"):
					aniamtion.play("idle")
		)
		aniamtion.play("jump")
	else:
		push_error("Animation resource not found: " + path)

func waiting_chess_checkin() -> Array:
	var chess_array_width := 8
	var chess_array_height := 10
	var chess_size = Vector2(20, 20)
	var new_position
	var check_in_chess_faction: String = ""
	var check_in_chess_name: String = ""

	if line_up_sprite.size() == 0:
		return ["", ""]

	var sprite_node = line_up_sprite[0]
	var sprite_position = line_up_position[0] as Vector2

	if sprite_node.position != sprite_position * chess_size:
		var quick_align_tween = create_tween()
		quick_align_tween.tween_property(sprite_node, "position", sprite_position, 0.02)
		await quick_align_tween.finished
	var move_tween = create_tween()
	new_position = sprite_node.position + Vector2(40, 0)
	move_tween.set_trans(Tween.TRANS_LINEAR)
	move_tween.tween_property(sprite_node, "position", new_position, 0.1)
	check_in_chess_faction = sprite_node.get_meta("faction", "human")
	check_in_chess_name = sprite_node.get_meta("chess_name", "ShieldMan")
	await move_tween.finished
	line_up_sprite.pop_front()
	sprite_node.queue_free()
	await get_tree().process_frame
	
	for i in range(line_up_sprite.size()):
		sprite_node = line_up_sprite[i]
		sprite_position = line_up_position[i]
		if (not is_instance_valid(sprite_node)) or (not sprite_node is AnimatedSprite2D):
			continue
		sprite_node.stop()
		
		sprite_node.play("move")

		move_tween = create_tween()
		new_position = sprite_position as Vector2 * chess_size
		move_tween.set_trans(Tween.TRANS_LINEAR)
		move_tween.tween_property(sprite_node, "position", new_position, 0.02)
		#await move_tween.finished
				
		if sprite_position.y % 2 != 0:
			sprite_node.flip_h = true
		else:
			sprite_node.flip_h = false				
		
		sprite_node.play("idle")

		if i == line_up_sprite.size() - 1:
			await move_tween.finished
		
	var chess_faction = enemy_death_array.pop_front()
	var chess_name = enemy_death_array.pop_front()
	
	if DataManagerSingleton.get_chess_data().keys().has(chess_faction) and DataManagerSingleton.get_chess_data()[chess_faction].keys().has(chess_name):

		var chess_animation = AnimatedSprite2D.new()
		waiting_chess.add_child(chess_animation) 		

		#var chess_array_width := 8
		#var chess_array_height := 10

		chess_animation.flip_h = true				
		chess_animation.position = Vector2(chess_array_width - 1, chess_array_height - 1) * chess_size
		chess_animation.z_index = 30
		_load_animations(chess_animation, chess_faction, chess_name)
		line_up_sprite.append(chess_animation)

	return [check_in_chess_faction, check_in_chess_name]
