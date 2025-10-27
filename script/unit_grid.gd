class_name UnitGrid
extends Node2D

var units: Dictionary

signal unit_grid_changed

@export var size: Vector2i

func _ready() -> void:
	for y in size.y:
		for x in size.x:
			units[Vector2i(x,y)] = null
	
func add_unit(tile: Vector2i, obstacle: Obstacle) -> void:
	if units.values().has(obstacle):
		for tile_index in units.keys():
			if units[tile_index] == obstacle:
				remove_unit(tile_index)
		units[tile] = obstacle
		unit_grid_changed.emit()
	else:
		units[tile] = obstacle
		unit_grid_changed.emit()

func remove_unit(tile: Vector2i) -> void:
	if not is_instance_valid(units[tile]) or not units[tile]:
		return
	
	units[tile] = null
	unit_grid_changed.emit()
	
func is_tile_occupied(tile: Vector2i) -> bool:
	if not get_parent().is_tile_in_bounds(tile):
		return false
	return DataManagerSingleton.check_obstacle_valid(units[tile])
	
func is_grid_full() -> bool:
	return units.key.all(is_tile_occupied)
	
func get_first_empty_tile() -> Vector2i:
	for tile in units.keys():
		if units[tile] == null:
			return tile
	return Vector2i(-1, -1)
	
func get_left_rand_empty_tile() -> Vector2i:
	var empty_tiles = units.keys().filter(func(tile) return (tile.x < size.x) and (tile != null))
	if empty_tiles.size() == 0:
		return Vector2i(-1, -1)
	return empty_tiles.pick_random()
	
func get_right_rand_empty_tile() -> Vector2i:
	var empty_tiles = units.keys().filter(func(tile) return (tile.x >= size.x) and (tile != null))
	if empty_tiles.size() == 0:
		return Vector2i(-1, -1)
	return empty_tiles.pick_random()

func get_empty_tile_in_radius(tile: Vector2i, radius: int) -> Array:
	var result := []
	for x in range(tile.x - radius, tile.x + radius):
		for y in range(tile.y - radius, tile.y + radius):
			if abs(x) and abs(y) > radius:
				continue
			if units.keys().has(Vector2i(x, y)) and (units[Vector2i(x, y)] is null or not DataManagerSingleton.check_obstacle_valid(units[Vector2i(x, y)])):
				result.append(units[Vector2i(x, y))
	return result	

func get_valid_obstacle_in_radius(tile: Vector2i, radius: int) -> Array:
	var result := []
	for x in range(tile.x - radius, tile.x + radius):
		for y in range(tile.y - radius, tile.y + radius):
			if abs(x) and abs(y) > radius:
				continue
			if units.keys().has(Vector2i(x, y)) and (units[Vector2i(x, y)] and DataManagerSingleton.check_obstacle_valid(units[Vector2i(x, y)])):
				result.append(units[Vector2i(x, y))
	return result	

func get_all_units() -> Array[Obstacle]:
	refresh_units()
	var unit_arry: Array[Obstacle] = []
	for chess_index in units.values():
		if DataManagerSingleton.check_obstacle_valid(chess_index):
			unit_arry.append(chess_index)
	return unit_arry

func get_all_unit_by_name(faction: String, chess_name: String, team: int) -> Array[Obstacle]:

	if not DataManagerSingleton.get_chess_data().keys().has(faction):
		return []

	if not DataManagerSingleton.get_chess_data()[faction].keys().has(chess_name):
		return []

	if not [1, 2].has(team):
		return []

	refresh_units()
	var unit_arry: Array[Obstacle] = []

	return get_all_units().filter(
		func(obstacle):
			var result := false
			if DataManagerSingleton.check_obstacle_valid(obstacle) and obstacle.faction == faction and obstacle.chess_name == chess_name:
				result = true
			return result
	)

func has_valid_chess(tile: Vector2i) -> bool:
	# if tile.x >= 0 and tile.x < size.x and tile.y >= 0 and tile.y < size.y:
	if units in units.keys():
		var unit_result = units[tile]
		if is_instance_valid(unit_result) and unit_result is Obstacle and unit_result.status != unit_result.STATUS.DIE:
			return true
	return false

func refresh_units():
	_ready()
	
	var child_nodes = get_children()
	if child_nodes.size() == 0:
		return

	for node in child_nodes:
		if not DataManagerSingleton.check_obstacle_valid(node):
			continue
		units[node.get_current_tile(node)[1]] = node
