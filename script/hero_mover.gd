class_name HeroMover
extends Node

@export var play_areas: Array[PlayArea]
@onready var shop_handler: ShopHandler = %shop_handler


func _ready() -> void:
	pass
	
func setup_before_turn_start():
	var heroes := get_tree().get_nodes_in_group("hero_group")
	for hero: Hero in heroes:
		setup_hero(hero)
		
func setup_hero(hero: Hero) -> void:
	hero.drag_handler.drag_started.connect(_on_hero_drag_started.bind(hero))
	hero.drag_handler.drag_canceled.connect(_on_hero_drag_canceled.bind(hero))
	hero.drag_handler.drag_dropped.connect(_on_hero_dropped.bind(hero))
	
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
	
func _reset_hero_to_starting_position(starting_position: Vector2, hero: Hero) -> void:
	var i := _get_play_area_for_position(starting_position)
	var tile := play_areas[i].get_tile_from_global(starting_position)
	
	#hero.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, hero)
	# hero.global_position = play_areas[i].get_global_from_tile(tile)
	hero.reparent(play_areas[i].unit_grid)
	hero._position = hero.get_parent().to_local(play_areas[i].get_global_from_tile(tile))


func _move_hero(hero: Hero, play_area: PlayArea, tile: Vector2i) -> void:
	play_area.unit_grid.add_unit(tile, hero)
	# hero.global_position = play_area.get_global_from_tile(tile)
	hero.reparent(play_area.unit_grid)
	hero._position = play_area.to_local(play_area.get_global_from_tile(tile))
	if _get_play_area_for_position(hero.global_position) == 0:
		hero.current_play_area = hero.play_areas.playarea_arena
	elif _get_play_area_for_position(hero.global_position) == 1:
		hero.current_play_area = hero.play_areas.playarea_bench
	elif _get_play_area_for_position(hero.global_position) == 2:
		hero.current_play_area = hero.play_areas.playarea_shop

		
func _on_hero_drag_started(starting_position: Vector2, status: String, hero: Hero) -> void:
	_set_highlighters(true)
	
	var i := _get_play_area_for_position(hero.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(hero.global_position)
		play_areas[i].unit_grid.remove_unit(tile)
		
		
func _on_hero_drag_canceled(starting_position: Vector2, status: String, hero: Hero) -> void:
	_set_highlighters(false)
	_reset_hero_to_starting_position(starting_position, hero)
	
	
func _on_hero_dropped(starting_position: Vector2, status: String, hero: Hero) -> void:
	
	_set_highlighters(false)
	var old_area_index := _get_play_area_for_position(starting_position)
	var drop_area_index := _get_play_area_for_position(hero.get_global_mouse_position())
	# area_index :
	# 	-1: forbidden area
	# 	0:	arena area
	# 	1:	bench area
	# 	2:	shop area

	if drop_area_index == -1:
		_reset_hero_to_starting_position(starting_position, hero)
		return
	elif (old_area_index == 0 or old_area_index == 1) and drop_area_index == 2: # move hero back to shop means sell
		shop_handler.sell_hero(hero)
		return

		
	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(starting_position)
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_hovered_tile()

	if (old_area_index == 2 and drop_area_index == 0 and not get_parent().is_game_turn_start) or (old_area_index == 2 and drop_area_index == 1): # buy heros
		if shop_handler.can_pay_hero(hero) and not new_area.unit_grid.is_tile_occupied(new_tile):
			shop_handler.buy_hero(hero)
			_move_hero(hero, new_area, new_tile)
			return
		else:
			_reset_hero_to_starting_position(starting_position, hero)
			return

	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_hero: Hero = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit(new_tile)
		_move_hero(old_hero, old_area, old_tile)
		
	_move_hero(hero, new_area, new_tile)		
	
