extends Node2D
class_name skill_tree

const alternative_choice_scene = preload("res://scene/alternative_choice.tscn")

@onready var back_button: Button = $back_button

@onready var next_page_animated_sprite_2d: AnimatedSprite2D = $next_page_animated_sprite_2d

@onready var backward_page: TextureButton = $ui/backward_page
@onready var forward_page: TextureButton = $ui/forward_page
@onready var current_page_label: Label = $ui/current_page_label

@onready var ui: Node2D = $ui
@onready var bonus_button_container: Node2D = $ui/bonus_button_container

@onready var faction_label: Label = $ui/faction_label
@onready var faction_path_label: Label = $ui/NinePatchRect/faction_path_label
@onready var faction_bonus_description: Label = $ui/NinePatchRect/faction_bonus_description
@onready var path_active_button: TextureButton = $ui/path_active_button

signal to_menu_scene

var current_page := 0
var faction_array := ["Elf", "Human", "Dwarf"]
var game_faction_path_update

var current_path_number := 0
var current_level_number := 0

var faction_path_update_template = {
	"Elf": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	},
	"Human": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	},
	"Dwarf": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	}	
}

func _ready() -> void:
	
	#game_faction_path_update = get_parent().faction_path_update
	game_faction_path_update = faction_path_update_template.duplicate(true)
	
	var total_page = faction_array.size()
	
	for node in bonus_button_container.get_children():
		if not node is TextureButton:
			continue
		node.pressed.connect(on_path_bonus_pressed.bind(node))
		
	backward_page.pressed.connect(
		func():
			if current_page == 0:
				return
			else:
				current_page -= 1
				current_page = max(0, min(total_page - 1, current_page))
				
			ui.visible = false
			next_page_animated_sprite_2d.play("backward")
			await next_page_animated_sprite_2d.animation_finished
			ui.visible = true
			backward_page.position = Vector2(19, 7)
			forward_page.position = Vector2(395, 1)
			current_page_label.position = Vector2(402, 242)
			current_path_number = 0
			current_level_number = 0
			refresh_page()
	)	
	
	forward_page.pressed.connect(
		func():
			if current_page == total_page - 1:
				return
			else:
				current_page += 1
				current_page = max(0, min(total_page - 1, current_page))
			ui.visible = false
			next_page_animated_sprite_2d.play("forward")
			await next_page_animated_sprite_2d.animation_finished
			ui.visible = true
			backward_page.position = Vector2(27, 1)
			forward_page.position = Vector2(403, 7)
			current_page_label.position = Vector2(410, 248)
			current_path_number = 0
			current_level_number = 0
			refresh_page()
	)
	
	path_active_button.pressed.connect(
		func():
			if current_level_number == 0 or current_path_number == 0:
				return
			game_faction_path_update[faction_array[current_page]]["path" + str(current_path_number)] = current_level_number
			refresh_page()
	)
	
	current_page_label.text = str(current_page + 1)
	refresh_page()
	
func refresh_page():			
	if current_level_number == 0 or current_path_number == 0:
		path_active_button.disabled = true
	elif current_path_number == 4:
		path_active_button.disabled = true
	elif current_level_number - game_faction_path_update[faction_array[current_page]]["path" + str(current_path_number)] == 1:
		path_active_button.disabled = false
	else:
		path_active_button.disabled = true
		
	
	for path_index in game_faction_path_update[faction_array[current_page]].keys():
		var current_path_level =  game_faction_path_update[faction_array[current_page]][path_index]
		
		match current_path_level:
			0:
				get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = true
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true
			1:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
				get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true
			2:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), true)
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = false
			3:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), true)
			_:
				get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = true
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true
		
		
	faction_label.text = faction_array[current_page]
	current_page_label.text = str(current_page + 1)

func _on_back_button_pressed() -> void:
	queue_free()

func on_path_bonus_pressed(node: TextureButton):
	current_path_number = int(node.name.split("")[4])
	current_level_number = int(node.name.right(1))
	
	match faction_array[current_page] + " Path " + str(current_path_number) + " Level " + str(current_level_number):
		"Elf Path 1 Level 1" :
			faction_bonus_description.text = "Critical strike chance increased by 10%"
		"Elf Path 1 Level 2" :
			faction_bonus_description.text = "Critical strike chance increased by 10%, critical damage multiplier increased by 100%"
		"Elf Path 1 Level 3" :
			faction_bonus_description.text = "Critical strike chance increased by 20%, critical damage multiplier increased by 250%"
		"Elf Path 2 Level 1" :
			faction_bonus_description.text = "Dodge chance increased by 10%"
		"Elf Path 2 Level 2" :
			faction_bonus_description.text = "Dodge chance increased by 20%, 50% chance to counterattack when dodging"
		"Elf Path 2 Level 3" :
			faction_bonus_description.text = "Dodge chance increased by 30%, 50% chance to counterattack when being attacked"
		"Elf Path 3 Level 1" :
			faction_bonus_description.text = "Damage reduced by 50% (minimum 1 damage), gain +1 additional attack"
		"Elf Path 3 Level 2" :
			faction_bonus_description.text = "Damage reduced by 60% (minimum 2 damage), gain +2 additional attacks"
		"Elf Path 3 Level 3" :
			faction_bonus_description.text = "Damage reduced by 70% (minimum 3 damage), gain +3 additional attacks"
		"Human Path 1 Level 1" :
			faction_bonus_description.text = "Maximum population capacity increased by 1"
		"Human Path 1 Level 2" :
			faction_bonus_description.text = "Maximum population capacity increased by 2"
		"Human Path 1 Level 3" :
			faction_bonus_description.text = "Maximum population capacity increased by 3"
		"Human Path 2 Level 1" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 2)"
		"Human Path 2 Level 2" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 4)"
		"Human Path 2 Level 3" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 6)"
		"Human Path 3 Level 1": 
			faction_bonus_description.text = "Common rarity chess pieces can choose to become their upgraded version when merging"
		"Human Path 3 Level 2": 
			faction_bonus_description.text = "Uncommon rarity chess pieces can choose to become their upgraded version when merging"
		"Human Path 3 Level 3": 
			faction_bonus_description.text = "Rare rarity chess pieces can choose to become their upgraded version when merging"
		"Dwarf Path 1 Level 1" :
			faction_bonus_description.text = "Armor increased by 2 points, increased by 4 points when adjacent to allied Dwarf"
		"Dwarf Path 1 Level 2" :
			faction_bonus_description.text = "Armor increased by 4 points, increased by 6 points when adjacent to allied Dwarf, gain 5 points of damage reflection"
		"Dwarf Path 1 Level 3" :
			faction_bonus_description.text = "Armor increased by 6 points, increased by 8 points when adjacent to allied Dwarf, gain 10 points of damage reflection"
		"Dwarf Path 2 Level 1" :
			faction_bonus_description.text = "Damage increased by 3 points"
		"Dwarf Path 2 Level 2" :
			faction_bonus_description.text = "Damage increased by 4 points; when HP falls below one-third maximum: lose all armor, gain melee damage bonus equal to 50% of lost armor value and 50% damage lifesteal (lasts one turn)"
		"Dwarf Path 2 Level 3" :
			faction_bonus_description.text = "Damage increased by 5 points; when HP falls below one-third maximum: lose all armor, gain melee damage bonus equal to 100% of lost armor value and 100% damage lifesteal (lasts one turn)"
		"Dwarf Path 3 Level 1" :
			faction_bonus_description.text = "Movement speed increased by 1 point during first turn"
		"Dwarf Path 3 Level 2" :
			faction_bonus_description.text = "Movement speed increased by 2 points during first turn"
		"Dwarf Path 3 Level 3" :
			faction_bonus_description.text = "Movement speed increased by 3 points during first turn"
		_:
			faction_bonus_description.text = ""
			
	match faction_array[current_page] + " Path " + str(current_path_number):
		"Elf Path 1" :
			faction_path_label.text = "Critical Mastery"
		"Elf Path 2" :
			faction_path_label.text = "Evasion Mastery"
		"Elf Path 3" :
			faction_path_label.text = "Multi-Strike Mastery"
		"Human Path 1" :
			faction_path_label.text = "Population Expansion"
		"Human Path 2" :
			faction_path_label.text = "Village Recruitment"
		"Human Path 3" :
			faction_path_label.text = "Evolutionary Merge"
		"Dwarf Path 1" :
			faction_path_label.text = "Iron Defense"
		"Dwarf Path 2" :
			faction_path_label.text = "Berserker Rage"
		"Dwarf Path 3" :
			faction_path_label.text = "Battle Momentum"
		_:
			faction_path_label.text = ""	
		
	refresh_page()
		
func set_button_texture(button: TextureButton, is_active: bool) -> void:
	pass
	if not button.texture_normal is AtlasTexture:
		return
	var new_texture = button.texture_normal.duplicate(true)
	match is_active:
		true:
			new_texture.region.position.x = 32
		false:
			new_texture.region.position.x = 0
		_:
			new_texture.region.position.x = 0
	button.texture_normal = new_texture
