class_name ChessMover
extends Node


@onready var shop_handler: ShopHandler = %shop_handler


@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop
@onready var grave: PlayArea = %grave

@export var play_areas: Array[PlayArea]

var phantom_chess_group : Array = []

signal chess_moved(chess: Chess, play_area: PlayArea, tile: Vector2i)
signal chess_raised(chess_position: Vector2, chess: Chess)
signal chess_dropped(chess: Chess)
signal villager_released(villager_name: String, release_position: Vector2)

func _ready() -> void:
	pass
	
# func setup_before_turn_start():
# 	# var chesses := get_tree().get_nodes_in_group("chess_group")
# 	# for chess: Chess in chesses:
# 	# 	setup_chess(chess)
# 	for area_index in play_areas:
# 		for chess_index in area_index.unit_grid.get_all_units():
# 			if is_instance_valid(chess_index) and chess_index is Chess and chess_index.status != chess_index.STATUS.DIE:
# 				setup_chess(chess_index)
		
func setup_chess(chess: Chess) -> void:
	if chess.drag_handler.drag_started.connect(_on_chess_drag_started.bind(chess)) != OK:
		print("chess.drag_handler.drag_started connect fail!" + str(chess.drag_handler.drag_started.connect(_on_chess_drag_started.bind(chess))))
	if chess.drag_handler.drag_canceled.connect(_on_chess_drag_canceled.bind(chess)) != OK:
		print("chess.drag_handler.drag_canceled connect fail!")
	if chess.drag_handler.drag_dropped.connect(_on_chess_dropped.bind(chess)) != OK:
		print("chess.drag_handler.drag_dropped connect fail!")
	
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
	
func _reset_chess_to_starting_position(starting_position: Vector2, chess: Chess) -> void:
	var i := _get_play_area_for_position(starting_position)
	var tile := play_areas[i].get_tile_from_global(starting_position)
	
	#chess.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, chess)
	# chess.global_position = play_areas[i].get_global_from_tile(tile)
	chess.reparent(play_areas[i].unit_grid)
	chess.global_position = play_areas[i].global_position + chess.get_parent().to_local(play_areas[i].get_global_from_tile(tile))
	chess_moved.emit(chess, play_areas[i], tile)


func _move_chess(chess: Chess, play_area: PlayArea, tile: Vector2i) -> void:
	
	'''add chess to play_area.unit_grid, add child'''
	'''_move_chess(chess: Chess, play_area: PlayArea, tile: Vector2i)'''

	play_area.unit_grid.add_unit(tile, chess)
	# chess.global_position = play_area.get_global_from_tile(tile)
	chess.reparent(play_area.unit_grid)
	if _get_play_area_for_position(chess.global_position) == 0:
		chess.current_play_area = chess.play_areas.playarea_arena
	elif _get_play_area_for_position(chess.global_position) == 1:
		chess.current_play_area = chess.play_areas.playarea_bench
	elif _get_play_area_for_position(chess.global_position) == 2:
		chess.current_play_area = chess.play_areas.playarea_shop
	elif _get_play_area_for_position(chess.global_position) == 3:
		chess.current_play_area = chess.play_areas.playarea_grave
	chess.global_position = play_area.global_position + play_area.to_local(play_area.get_global_from_tile(tile))
	chess_moved.emit(chess, play_area, tile)
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] or DataManagerSingleton.current_player == "debug":
		print("=".repeat(20))
		print("moving" + chess.chess_name + " to " + str(tile) + ", global_position = " + str(chess.global_position))
		print("current area : " + chess.get_current_tile(chess)[0].name + ", current_tile : " + str(chess.get_current_tile(chess)[1]))


func tween_move_chess(chess: Chess, play_area: PlayArea, chess_position: Vector2i) -> void:
	var i := _get_play_area_for_position(chess.global_position)
	if play_areas[i].unit_grid.units.values().has(chess):
		var chess_tile = play_areas[i].get_tile_from_global(chess.global_position)
		play_areas[i].unit_grid.remove_unit(chess_tile)
	var new_global_position =  play_areas[i].global_position + Vector2(chess_position)
	var move_tween
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_LINEAR)
	move_tween.tween_property(chess, "global_position", new_global_position, 0.25)
	await move_tween.finished

	if _get_play_area_for_position(chess.global_position) == 0:
		chess.current_play_area = chess.play_areas.playarea_arena
	elif _get_play_area_for_position(chess.global_position) == 1:
		chess.current_play_area = chess.play_areas.playarea_bench
	elif _get_play_area_for_position(chess.global_position) == 2:
		chess.current_play_area = chess.play_areas.playarea_shop
	elif _get_play_area_for_position(chess.global_position) == 3:
		chess.current_play_area = chess.play_areas.playarea_grave

	var new_tile = play_areas[i].get_tile_from_global(chess.global_position)

	play_area.unit_grid.add_unit(new_tile, chess)
	chess_moved.emit(chess, play_area, new_tile)
	chess.reparent(play_area.unit_grid)
	
	await get_tree().process_frame
	
	return

		
func _on_chess_drag_started(starting_position: Vector2, status: String, chess: Chess) -> void:
	
	if get_parent().is_game_turn_start:
		return
		
	_set_highlighters(true)
	
	var i := _get_play_area_for_position(chess.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(chess.global_position)
		play_areas[i].unit_grid.remove_unit(tile)
		chess_raised.emit(starting_position, chess)	
			
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
			if chess.faction == "villager":
				bench.get_node("bench_bound").visible = true	
				shop.get_node("shop_bound").visible = false	
			else:
				arena.get_node("arena_bound").visible = true
				bench.get_node("bench_bound").visible = true	
				shop.get_node("shop_bound").visible = false		
				
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] or DataManagerSingleton.current_player == "debug":
		print("=".repeat(20))
		print("start moving " + chess.chess_name + ", global_position = " + str(chess.global_position))
		print("current area : " + chess.get_current_tile(chess)[0].name + ", current_tile : " + str(chess.get_current_tile(chess)[1]))
	
		
func _on_chess_drag_canceled(starting_position: Vector2, status: String, chess: Chess) -> void:
	chess_dropped.emit(chess)
	
	arena.get_node("arena_bound").visible = false
	bench.get_node("bench_bound").visible = false
	shop.get_node("shop_bound").visible = false
	
	if get_parent().is_game_turn_start:
		_set_highlighters(false)
		_reset_chess_to_starting_position(starting_position, chess)
		
		return
		
	
	_set_highlighters(false)
	_reset_chess_to_starting_position(starting_position, chess)
	
	
func _on_chess_dropped(starting_position: Vector2, status: String, chess: Chess) -> void:

	chess_dropped.emit(chess)
	
	
	arena.get_node("arena_bound").visible = false
	bench.get_node("bench_bound").visible = false
	shop.get_node("shop_bound").visible = false

	if get_parent().is_game_turn_start:
		_set_highlighters(false)
		_reset_chess_to_starting_position(starting_position, chess)
		return
	
	_set_highlighters(false)
	var old_area_index := _get_play_area_for_position(starting_position)
	var drop_area_index := _get_play_area_for_position(chess.get_global_mouse_position())
	# area_index :
	# 	-1: forbidden area
	# 	0:	arena area
	# 	1:	bench area
	# 	2:	shop area
		
	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(starting_position)
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_hovered_tile()
	
	if drop_area_index == -1 and chess.faction == "villager":
		var chess_phantom = chess.get_temp_copy() #as Chess
		shop_handler.buy_chess(chess_phantom)
		villager_released.emit(chess.chess_name, chess.get_global_mouse_position())
		phantom_chess_group.append(chess_phantom)
		await get_tree().process_frame
		chess.queue_free()

	match [old_area_index, drop_area_index]:
		[0, 0]:
			# move from arena to arena
			if not new_area.is_tile_in_placeable_bounds(new_tile):
				_reset_chess_to_starting_position(starting_position, chess)	
				return	
			
			if new_area.unit_grid.is_tile_occupied(new_tile):
				var old_chess: Chess = new_area.unit_grid.units[new_tile]
				new_area.unit_grid.remove_unit(new_tile)
				_move_chess(old_chess, old_area, old_tile)
		[1, 1]:
			# move from bench to bench
			if new_area.unit_grid.is_tile_occupied(new_tile):
				var old_chess: Chess = new_area.unit_grid.units[new_tile]
				new_area.unit_grid.remove_unit(new_tile)
				_move_chess(old_chess, old_area, old_tile)
		[2, 2]:
			# move from shop to shop
			if new_area.unit_grid.is_tile_occupied(new_tile):
				var old_chess: Chess = new_area.unit_grid.units[new_tile]
				new_area.unit_grid.remove_unit(new_tile)
				_move_chess(old_chess, old_area, old_tile)
		[0, 1]:
			# from arena to bench
			if new_area.unit_grid.is_tile_occupied(new_tile):
				var old_chess: Chess = new_area.unit_grid.units[new_tile]
				new_area.unit_grid.remove_unit(new_tile)
				_move_chess(old_chess, old_area, old_tile)
		[0, 2]:
			# from arena to shop
			shop_handler.sell_chess(chess)
			return
		[1, 0]:
			# from bench to arena
			if not new_area.is_tile_in_placeable_bounds(new_tile):
				_reset_chess_to_starting_position(starting_position, chess)	
				return	
			
			if new_area.unit_grid.is_tile_occupied(new_tile):
				var old_chess: Chess = new_area.unit_grid.units[new_tile]
				new_area.unit_grid.remove_unit(new_tile)
				_move_chess(old_chess, old_area, old_tile)
		[1, 2]:
			# from bench to shop
			shop_handler.sell_chess(chess)
			return
		[2, 0]:
			# from shop to arena
			if not new_area.is_tile_in_placeable_bounds(new_tile):
				_reset_chess_to_starting_position(starting_position, chess)	
				return	
			
			# cannot buy to a occupied position
			if new_area.unit_grid.is_tile_occupied(new_tile):
				_reset_chess_to_starting_position(starting_position, chess)
				return
			
			# cannot buy a villager to arena
			if chess is Chess and chess.role == "villager":
				_reset_chess_to_starting_position(starting_position, chess)
				return
			
			# population check
			if get_parent().current_population >= get_parent().max_population:
				var same_chess_count := 0
				for chess_index in (arena.unit_grid.get_all_units() + bench.unit_grid.get_all_units()):
					if chess_index.faction == chess.faction and chess_index.chess_name == chess.chess_name and chess_index.team == chess.team and chess_index.chess_level == chess.chess_level:
						same_chess_count += 1
				if same_chess_count >= 2:
					var chess_phantom = chess.get_temp_copy() #as Chess
					_move_chess(chess, new_area, new_tile)
					shop_handler.buy_chess(chess_phantom)
					phantom_chess_group.append(chess_phantom)
					await get_tree().process_frame
					#chess_phantom.queue_free()
					return
				else:
					_reset_chess_to_starting_position(starting_position, chess)
					get_parent().control_shaker(get_parent().population_label)
					return
					
			if not shop_handler.can_pay_chess(chess): 
				# cannot pay
				_reset_chess_to_starting_position(starting_position, chess)
				get_parent().control_shaker(get_parent().remain_coins_label)
				return
			
			shop_handler.buy_chess(chess)
			_move_chess(chess, new_area, new_tile)
			return			
				
		[2, 1]:
			# from shop to bench
			
			# cannot buy to a occupied position
			if new_area.unit_grid.is_tile_occupied(new_tile):
				_reset_chess_to_starting_position(starting_position, chess)
				return
					
			if not shop_handler.can_pay_chess(chess): 
				# cannot pay
				_reset_chess_to_starting_position(starting_position, chess)
				get_parent().control_shaker(get_parent().remain_coins_label)
				return
					
			# population check
			var chess_phantom = chess.get_temp_copy() #as Chess
			_move_chess(chess, new_area, new_tile)
			shop_handler.buy_chess(chess_phantom)
			phantom_chess_group.append(chess_phantom)
			await get_tree().process_frame
			#chess_phantom.queue_free()
			return	

		_:
			#other ilegal movement
			_reset_chess_to_starting_position(starting_position, chess)
			return
	
	_move_chess(chess, new_area, new_tile)
		
	
