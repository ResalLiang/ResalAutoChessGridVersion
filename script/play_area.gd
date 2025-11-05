class_name PlayArea
extends TileMapLayer

@export var unit_grid: UnitGrid
@export var tile_highlighter: TileHighlighter

var bounds: Rect2i
var placeable_bounds : Rect2i

func _ready() -> void:
	bounds = Rect2i(Vector2i.ZERO, unit_grid.size)
	placeable_bounds = Rect2i(Vector2i.ZERO, unit_grid.size)
	if not DataManagerSingleton.player_data["debug_mode"] and DataManagerSingleton.current_player != "debug":
		placeable_bounds.size.x = placeable_bounds.size.x / 2
	
func get_tile_from_global(global: Vector2) -> Vector2i:
	return local_to_map(to_local(global))
	
func get_global_from_tile(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))
	
func get_hovered_tile() -> Vector2i:
	return local_to_map(get_local_mouse_position())
	
func is_tile_in_bounds(tile: Vector2i) -> bool:
	return bounds.has_point(tile)
	
func is_tile_in_placeable_bounds(tile: Vector2i) -> bool:
	return placeable_bounds.has_point(tile)
