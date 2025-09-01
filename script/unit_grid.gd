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
	units[tile] = obstacle
	unit_grid_changed.emit()

func remove_unit(tile: Vector2i) -> void:
	var unit := units[tile] as Node
	
	if not unit:
		return
	
	units[tile] = null
	unit_grid_changed.emit()
	
func is_tile_occupied(tile: Vector2i) -> bool:
	return units[tile] != null
	
func is_grid_full() -> bool:
	return units.key.all(is_tile_occupied)
	
func get_first_empty_tile() -> Vector2i:
	for tile in units.keys():
		if units[tile] == null:
			return tile
	return Vector2i(-1, -1)

func get_all_units() -> Array[Obstacle]:
	var unit_arry: Array[Obstacle] = []
	for hro in units.values():
		if hro != null:
			unit_arry.append(hro)
	return unit_arry

func has_valid_chess(tile: Vector2i) -> bool:
	# if tile.x >= 0 and tile.x < size.x and tile.y >= 0 and tile.y < size.y:
	if units in units.keys():
		var unit_result = units[tile]
		if is_instance_valid(unit_result) and unit_result is Obstacle and unit_result.status != unit_result.STATUS.DIE:
			return true
	return false
