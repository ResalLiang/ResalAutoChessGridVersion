class_name ChessMover
extends Node


@onready var shop_handler: ShopHandler = %shop_handler


@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop

@export var play_areas: Array[PlayArea]


signal chess_moved(obstacle: Obstacle, play_area: PlayArea, tile: Vector2i)
signal chess_raised(chess_position: Vector2, obstacle: Obstacle)
signal chess_dropped(obstacle: Obstacle)

func _ready() -> void:
	pass
	
func setup_before_turn_start():
	# var chesses := get_tree().get_nodes_in_group("chess_group")
	# for obstacle: Obstacle in chesses:
	# 	setup_chess(obstacle)
	for area_index in play_areas:
		for chess_index in area_index.unit_grid.get_all_units():
			if is_instance_valid(chess_index) and chess_index is Chess and chess_index.status != chess_index.STATUS.DIE:
				setup_chess(chess_index)
		
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
	obstacle.global_position = play_areas[i].global_position + obstacle.get_parent().to_local(play_areas[i].get_global_from_tile(tile))
	chess_moved.emit(obstacle, play_areas[i], tile)


func _move_chess(obstacle: Obstacle, play_area: PlayArea, tile: Vector2i) -> void:
	
	'''add chess to play_area.unit_grid, add child'''
	'''_move_chess(obstacle: Obstacle, play_area: PlayArea, tile: Vector2i)'''

	play_area.unit_grid.add_unit(tile, obstacle)
	# obstacle.global_position = play_area.get_global_from_tile(tile)
	obstacle.reparent(play_area.unit_grid)
	if _get_play_area_for_position(obstacle.global_position) == 0:
		obstacle.current_play_area = obstacle.play_areas.playarea_arena
	elif _get_play_area_for_position(obstacle.global_position) == 1:
		obstacle.current_play_area = obstacle.play_areas.playarea_bench
	elif _get_play_area_for_position(obstacle.global_position) == 2:
		obstacle.current_play_area = obstacle.play_areas.playarea_shop
	obstacle.global_position = play_area.global_position + play_area.to_local(play_area.get_global_from_tile(tile))
	chess_moved.emit(obstacle, play_area, tile)


func tween_move_chess(obstacle: Obstacle, play_area: PlayArea, chess_position: Vector2i) -> void:
	var i := _get_play_area_for_position(obstacle.global_position)
	if play_areas[i].unit_grid.units.values().has(obstacle):
		var obstacle_tile = play_areas[i].get_tile_from_global(obstacle.global_position)
		play_areas[i].unit_grid.remove_unit(obstacle_tile)
	var new_global_position =  play_areas[i].global_position + Vector2(chess_position)
	var move_tween
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(obstacle, "global_position", new_global_position, 0.25)
	await move_tween.finished

	if _get_play_area_for_position(obstacle.global_position) == 0:
		obstacle.current_play_area = obstacle.play_areas.playarea_arena
	elif _get_play_area_for_position(obstacle.global_position) == 1:
		obstacle.current_play_area = obstacle.play_areas.playarea_bench
	elif _get_play_area_for_position(obstacle.global_position) == 2:
		obstacle.current_play_area = obstacle.play_areas.playarea_shop

	var new_tile = play_areas[i].get_tile_from_global(obstacle.global_position)

	play_area.unit_grid.add_unit(new_tile, obstacle)
	chess_moved.emit(obstacle, play_area, new_tile)
	obstacle.reparent(play_area.unit_grid)
	
	await get_tree().process_frame
	
	return

		
func _on_chess_drag_started(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	
	if get_parent().is_game_turn_start:
		return
		
	_set_highlighters(true)
	
	var i := _get_play_area_for_position(obstacle.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(obstacle.global_position)
		play_areas[i].unit_grid.remove_unit(tile)
		chess_raised.emit(starting_position, obstacle)	
			
	arena.get_node("arena_bound").visible = false
	bench.get_node("bench_bound").visible = false
	shop.get_node("shop_bound").visible = false
	
	match i:
		0:
			arena.get_node("arena_bound").visible = true
			bench.get_node("bench_bound").visible = true	
			shop.get_node("shop_bound").visible = false		
		1:
			arena.get_node("arena_bound").visible = true
			bench.get_node("bench_bound").visible = true	
			shop.get_node("shop_bound").visible = false		
		2:
			if obstacle.faction == "villager":
				bench.get_node("bench_bound").visible = true	
				shop.get_node("shop_bound").visible = false	
			else:
				arena.get_node("arena_bound").visible = true
				bench.get_node("bench_bound").visible = true	
				shop.get_node("shop_bound").visible = false		
				
		
		
func _on_chess_drag_canceled(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	chess_dropped.emit(obstacle)
	
	arena.get_node("arena_bounds").visible = false
	bench.get_node("bench_bounds").visible = false
	shop.get_node("shop_bounds").visible = false
	
	if get_parent().is_game_turn_start:
		_set_highlighters(false)
		_reset_chess_to_starting_position(starting_position, obstacle)
		
		return
		
	
	_set_highlighters(false)
	_reset_chess_to_starting_position(starting_position, obstacle)
	
	
func _on_chess_dropped(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:

	chess_dropped.emit(obstacle)
	
	
	arena.get_node("arena_bound").visible = false
	bench.get_node("bench_bound").visible = false
	shop.get_node("shop_bound").visible = false

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
	
	if drop_area_index == 0 and not new_area.is_tile_in_placeable_bounds(new_tile):
		_reset_chess_to_starting_position(starting_position, obstacle)	
		return	

	if (old_area_index == 2 and drop_area_index == 0 and not get_parent().is_game_turn_start) or (old_area_index == 2 and drop_area_index == 1): # buy chesss

		if shop_handler.can_pay_chess(obstacle) and not new_area.unit_grid.is_tile_occupied(new_tile) and get_parent().current_population < get_parent().max_population:
			# has enough money and population for buying
			shop_handler.buy_chess(obstacle)
			_move_chess(obstacle, new_area, new_tile)
			if not get_parent().is_game_turn_start:
				await get_parent().check_chess_merge()
			return

		elif shop_handler.can_pay_chess(obstacle) and not new_area.unit_grid.is_tile_occupied(new_tile) and (old_area_index == 2 and drop_area_index == 1):
			# 
			shop_handler.buy_chess(obstacle)
			_move_chess(obstacle, new_area, new_tile)
			return
			
		elif not shop_handler.can_pay_chess(obstacle): # cannot pay
			_reset_chess_to_starting_position(starting_position, obstacle)
			get_parent().control_shaker(get_parent().remain_coins_label)
			return

		elif get_parent().current_population >= get_parent().max_population: # not enough population
			_move_chess(obstacle, new_area, new_tile)
			var merge_result = await get_parent().check_chess_merge()
			if merge_result and get_parent().current_population <= get_parent().max_population:
				shop_handler.buy_chess(merge_result)
				return
			else:
				_reset_chess_to_starting_position(starting_position, obstacle)
				get_parent().control_shaker(get_parent().population_label)
				return

		else:
			_reset_chess_to_starting_position(starting_position, obstacle)
			return
			

	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_obstacle: Obstacle = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit(new_tile)
		_move_chess(old_obstacle, old_area, old_tile)
		
	_move_chess(obstacle, new_area, new_tile)		
	
