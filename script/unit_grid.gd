class_name UnitGrid
extends Node2D

var units: Dictionary

signal unit_grid_changed

@export var size: Vector2i

func _ready() -> void:
	for y in size.y:
		for x in size.x:
			units[Vector2i(x,y)] = null
	
func add_unit(tile: Vector2i, unit: Hero) -> bool:
	if not is_tile_occupied(tile):
		units[tile] =  unit
		unit_grid_changed.emit()
		return true
	else:
		return false
	
func is_tile_occupied(tile: Vector2i) -> bool:
	return units[tile] != null
	
func is_grid_full() -> bool:
	return units.key.all(is_tile_occupied)
	
func get_first_empty_tile() -> Vector2i:
	for tile in units.keys():
		if units[tile] == null:
			return tile
	return Vector2i(-1, -1)

func get_all_units() -> Array[Hero]:
	var unit_arry: Array[Hero] = []
	for hro in units.values():
		if hro != null:
			unit_arry.append(hro)
	return unit_arry
