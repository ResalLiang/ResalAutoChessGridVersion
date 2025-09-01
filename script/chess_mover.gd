class_name ChessMover
extends Node

@export var play_areas: Array[PlayArea]
@onready var shop_handler: ShopHandler = %shop_handler
signal chess_moved(obstacle: Obstacle, play_area: PlayArea, tile: Vector2i)

func _ready() -> void:
	pass
	
func setup_before_turn_start():
	var chesses := get_tree().get_nodes_in_group("chess_group")
	for obstacle: Obstacle in chesses:
		setup_chess(obstacle)
		
func setup_chess(obstacle: Obstacle) -> void:
	obstacle.drag_handler.drag_started.connect(_on_chess_drag_started.bind(obstacle))
	obstacle.drag_handler.drag_canceled.connect(_on_chess_drag_canceled.bind(obstacle))
	obstacle.drag_handler.drag_dropped.connect(_on_chess_dropped.bind(obstacle))
	
func _set_highlighters(enabled: bool) -> void:
	for play_area: PlayArea in play_areas:
		play_area.tile_highlighter.enable = enabled
		
func _get_play_area_for_position(global: Vector2) -> int:
	var dropped_area_index := -1
	
	for i in play_areas.size():
		var tile := play_areas[i].get_tile_from_global(global)
		if play_areas[i].is_tile_in_bounds(tile):
			dropped_area_index = i
	
	return dropped_area_index
	
func _reset_chess_to_starting_position(starting_position: Vector2, obstacle: Obstacle) -> void:
	var i := _get_play_area_for_position(starting_position)
	var tile := play_areas[i].get_tile_from_global(starting_position)
	
	#obstacle.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, obstacle)
	# obstacle.global_position = play_areas[i].get_global_from_tile(tile)
	obstacle.reparent(play_areas[i].unit_grid)
	obstacle._position = obstacle.get_parent().to_local(play_areas[i].get_global_from_tile(tile))


func _move_chess(obstacle: Obstacle, play_area: PlayArea, tile: Vector2i) -> void:
	play_area.unit_grid.add_unit(tile, obstacle)
	# obstacle.global_position = play_area.get_global_from_tile(tile)
	obstacle.reparent(play_area.unit_grid)
	obstacle._position = play_area.to_local(play_area.get_global_from_tile(tile))
	if _get_play_area_for_position(obstacle.global_position) == 0:
		obstacle.current_play_area = obstacle.play_areas.playarea_arena
	elif _get_play_area_for_position(obstacle.global_position) == 1:
		obstacle.current_play_area = obstacle.play_areas.playarea_bench
	elif _get_play_area_for_position(obstacle.global_position) == 2:
		obstacle.current_play_area = obstacle.play_areas.playarea_shop
	chess_moved.emit(obstacle, play_area, tile)

		
func _on_chess_drag_started(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	
	if get_parent().is_game_turn_start:
		return
		
	_set_highlighters(true)
	
	var i := _get_play_area_for_position(obstacle.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(obstacle.global_position)
		play_areas[i].unit_grid.remove_unit(tile)
		
		
func _on_chess_drag_canceled(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	
	if get_parent().is_game_turn_start:
		_set_highlighters(false)
		_reset_chess_to_starting_position(starting_position, obstacle)
		return
		
	
	_set_highlighters(false)
	_reset_chess_to_starting_position(starting_position, obstacle)
	
	
func _on_chess_dropped(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	
	if get_parent().is_game_turn_start:
		_set_highlighters(false)
		_reset_chess_to_starting_position(starting_position, obstacle)
		return
	
	_set_highlighters(false)
	var old_area_index := _get_play_area_for_position(starting_position)
	var drop_area_index := _get_play_area_for_position(obstacle.get_global_mouse_position())
	# area_index :
	# 	-1: forbidden area
	# 	0:	arena area
	# 	1:	bench area
	# 	2:	shop area

	if drop_area_index == -1:
		_reset_chess_to_starting_position(starting_position, obstacle)
		return
	elif (old_area_index == 0 or old_area_index == 1) and drop_area_index == 2: # move obstacle back to shop means sell
		shop_handler.sell_chess(obstacle)
		return

		
	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(starting_position)
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_hovered_tile()

	if (old_area_index == 2 and drop_area_index == 0 and not get_parent().is_game_turn_start) or (old_area_index == 2 and drop_area_index == 1): # buy chesss

		if shop_handler.can_pay_chess(obstacle) and not new_area.unit_grid.is_tile_occupied(new_tile) and get_parent().current_population < get_parent().max_population:
			shop_handler.buy_chess(obstacle)
			_move_chess(obstacle, new_area, new_tile)
			return
		else:
			_reset_chess_to_starting_position(starting_position, obstacle)
			return

	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_obstacle: Obstacle = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit(new_tile)
		_move_chess(old_obstacle, old_area, old_tile)
		
	_move_chess(obstacle, new_area, new_tile)		
	
