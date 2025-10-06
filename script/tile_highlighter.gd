class_name TileHighlighter
extends Node

@export var enable:bool = false:
	set = _set_enable
@export var play_area: PlayArea
@export var highlight_layer: TileMapLayer
@export var tile: Vector2i

@onready var source_id := highlight_layer.tile_set.get_source_id(2)

func _process(delta: float) -> void:
	if not enable:
		return
		
	var select_tile := play_area.get_hovered_tile()
	
	if not play_area.is_tile_in_bounds(select_tile):
		highlight_layer.clear()
		return
		
	_update_tile(select_tile)
	
func _set_enable(new_value: bool) -> void:
	enable = new_value
	
	if not enable and play_area:
		highlight_layer.clear()
		
func _update_tile(select_tile: Vector2i) -> void:
	highlight_layer.clear()
	if get_parent().name == "arena" and not play_area.is_tile_in_placeable_bounds(select_tile):
		source_id = highlight_layer.tile_set.get_source_id(3)
		tile = Vector2(2, 0)
	else:
		source_id = highlight_layer.tile_set.get_source_id(2)
		tile = Vector2(0, 1)
	highlight_layer.set_cell(select_tile, source_id, tile)
