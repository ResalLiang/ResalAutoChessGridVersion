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
@onready var path_active_button: TextureButton = $ui/path_active_button
@onready var faction_path_label: Label = $ui/NinePatchRect/VBoxContainer/faction_path_label
@onready var faction_bonus_description: Label = $ui/NinePatchRect/VBoxContainer/faction_bonus_description

@onready var consume_remian_lose_round: TextureButton = $ui/active_button_container/consume_remian_lose_round
@onready var consume_max_lose_round: TextureButton = $ui/active_button_container/consume_max_lose_round
@onready var consume_won_round: TextureButton = $ui/active_button_container/consume_won_round
@onready var just_active: TextureButton = $ui/active_button_container/just_active
@onready var just_active_label: Label = $ui/active_button_container/just_active/Label

@onready var lose_round_container: HBoxContainer = $ui/won_lose_round_container/lose_round_container
@onready var remain_lose_rounds_template: TextureRect = $ui/won_lose_round_container/lose_round_container/remain_lose_rounds_template
@onready var lose_rounds_template: TextureRect = $ui/won_lose_round_container/lose_round_container/lose_rounds_template
@onready var won_round_container: HBoxContainer = $ui/won_lose_round_container/won_round_container
@onready var won_rounds_template: TextureRect = $ui/won_lose_round_container/won_round_container/won_rounds_template
@onready var remain_won_rounds_template: TextureRect = $ui/won_lose_round_container/won_round_container/remain_won_rounds_template

var current_page := 0
var faction_array : Array
var game_faction_path_upgrade

var current_path_number := 0
var current_level_number := 0

signal button_actived
signal path_actived(faction: String, path:String, level: int)

func _ready() -> void:
	
	game_faction_path_upgrade = get_parent().faction_path_upgrade
	
	if button_actived.connect(handle_button_actived) != OK:
		print("button_actived connect fail!")
	
	faction_array = game_faction_path_upgrade.keys()
	var total_page = faction_array.size()
	
	for node in bonus_button_container.get_children():
		if not node is TextureButton:
			continue
		if node.pressed.connect(on_path_bonus_pressed.bind(node)) != OK:
			print("node.pressed connect fail!")
	
	
	handle_button_actived()
		
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
			handle_button_actived()
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
			handle_button_actived()
	)
	
	consume_remian_lose_round.pressed.connect(
		func():
			DataManagerSingleton.lose_rounds += 1
			button_actived.emit()
			if current_level_number == 0 or current_path_number == 0:
				return
			game_faction_path_upgrade[faction_array[current_page]]["path" + str(current_path_number)] = current_level_number
			path_actived.emit(faction_array[current_page], "path" + str(current_path_number), current_level_number)
			refresh_page()
	)
	consume_max_lose_round.pressed.connect(
		func():
			DataManagerSingleton.max_lose_rounds_modifier -= 1
			if DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier < DataManagerSingleton.lose_rounds:
				DataManagerSingleton.lose_rounds -= 1
			button_actived.emit()
			if current_level_number == 0 or current_path_number == 0:
				return
			game_faction_path_upgrade[faction_array[current_page]]["path" + str(current_path_number)] = current_level_number
			path_actived.emit(faction_array[current_page], "path" + str(current_path_number), current_level_number)
			refresh_page()		
	)
	consume_won_round.pressed.connect(
		func():
			DataManagerSingleton.won_rounds -= 1
			button_actived.emit()
			if current_level_number == 0 or current_path_number == 0:
				return
			game_faction_path_upgrade[faction_array[current_page]]["path" + str(current_path_number)] = current_level_number
			path_actived.emit(faction_array[current_page], "path" + str(current_path_number), current_level_number)
			refresh_page()
	)
	just_active.pressed.connect(
		func():
			get_parent().remain_upgrade_count -= 1
			button_actived.emit()
			if current_level_number == 0 or current_path_number == 0:
				return
			game_faction_path_upgrade[faction_array[current_page]]["path" + str(current_path_number)] = current_level_number
			path_actived.emit(faction_array[current_page], "path" + str(current_path_number), current_level_number)
			refresh_page()
	)
	
	current_page_label.text = str(current_page + 1)
	handle_button_actived()
	refresh_page()
	
func refresh_page():		
	
	for path_index in game_faction_path_upgrade[faction_array[current_page]].keys():
		var current_path_level =  game_faction_path_upgrade[faction_array[current_page]][path_index]
		
		var disable_third_path:= false
		match path_index:
			"path1":
				disable_third_path = game_faction_path_upgrade[faction_array[current_page]]["path2"] > 0 and game_faction_path_upgrade[faction_array[current_page]]["path3"] > 0
			"path2":
				disable_third_path = game_faction_path_upgrade[faction_array[current_page]]["path1"] > 0 and game_faction_path_upgrade[faction_array[current_page]]["path3"] > 0
			"path3":
				disable_third_path = game_faction_path_upgrade[faction_array[current_page]]["path1"] > 0 and game_faction_path_upgrade[faction_array[current_page]]["path2"] > 0
			_:
				pass

		if disable_third_path and faction_array[current_page] != "demon":
			set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), false)
			set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), false)
			set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), false)
			get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = true
			get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = true
			get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true		
			continue	

		match current_path_level:
			0:
				if path_index != "path4":
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), false)
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), false)
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), false)
					get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
					get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = true
					get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true
				else:
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), false)
					get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
					
			1:
				if path_index != "path4":
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), false)
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), false)
					get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
					get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = false
					get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = true
				else:
					set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
					get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
					
			2:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), false)
				get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = false
			3:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), true)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), true)
				get_node("ui/bonus_button_container/"+ path_index + "_button1").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button2").disabled = false
				get_node("ui/bonus_button_container/"+ path_index + "_button3").disabled = false		
			_:
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button1"), false)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button2"), false)
				set_button_texture(get_node("ui/bonus_button_container/"+ path_index + "_button3"), false)
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
		"elf Path 1 Level 1" :
			faction_bonus_description.text = "Damage reduced by 50% (minimum 1 damage), gain +1 additional attack"
		"elf Path 1 Level 2" :
			faction_bonus_description.text = "Damage reduced by 60% (minimum 2 damage), gain +2 additional attacks"
		"elf Path 1 Level 3" :
			faction_bonus_description.text = "Damage reduced by 70% (minimum 3 damage), gain +3 additional attacks"
		"elf Path 2 Level 1" :
			faction_bonus_description.text = "Critical strike chance increased by 10%"
		"elf Path 2 Level 2" :
			faction_bonus_description.text = "Critical strike chance increased by 10%, critical damage multiplier increased by 100%"
		"elf Path 2 Level 3" :
			faction_bonus_description.text = "Critical strike chance increased by 20%, critical damage multiplier increased by 250%"
		"elf Path 3 Level 1" :
			faction_bonus_description.text = "Dodge chance increased by 10%"
		"elf Path 3 Level 2" :
			faction_bonus_description.text = "Dodge chance increased by 20%, 50% chance to counterattack when dodging"
		"elf Path 3 Level 3" :
			faction_bonus_description.text = "Dodge chance increased by 30%, 50% chance to counterattack when being attacked"
		"elf Path 4 Level 1" :
			faction_bonus_description.text = "Place holder"
		"human Path 1 Level 1" :
			faction_bonus_description.text = "Maximum population capacity increased by 1"
		"human Path 1 Level 2" :
			faction_bonus_description.text = "Maximum population capacity increased by 2"
		"human Path 1 Level 3" :
			faction_bonus_description.text = "Maximum population capacity increased by 3"
		"human Path 2 Level 1" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 2)"
		"human Path 2 Level 2" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 4)"
		"human Path 2 Level 3" :
			faction_bonus_description.text = "For every 2 additional Human chess pieces purchased, refresh 1 Villager chess piece (maximum shop tier 6)"
		"human Path 3 Level 1": 
			faction_bonus_description.text = "Common rarity chess pieces can choose to become their upgraded version when merging"
		"human Path 3 Level 2": 
			faction_bonus_description.text = "Uncommon rarity chess pieces can choose to become their upgraded version when merging"
		"human Path 3 Level 3": 
			faction_bonus_description.text = "Rare rarity chess pieces can choose to become their upgraded version when merging"
		"human Path 4 Level 1": 
			faction_bonus_description.text = "Fill the shop with villager"
		"dwarf Path 1 Level 1" :
			faction_bonus_description.text = "Armor increased by 2 points, increased by 4 points when adjacent to allied Dwarf"
		"dwarf Path 1 Level 2" :
			faction_bonus_description.text = "Armor increased by 4 points, increased by 6 points when adjacent to allied Dwarf, gain 5 points of damage reflection"
		"dwarf Path 1 Level 3" :
			faction_bonus_description.text = "Armor increased by 6 points, increased by 8 points when adjacent to allied Dwarf, gain 10 points of damage reflection"
		"dwarf Path 2 Level 1" :
			faction_bonus_description.text = "Add base speed to damage when not moving"
		"dwarf Path 2 Level 2" :
			faction_bonus_description.text = "Add base speed to damage when not moving"
		"dwarf Path 2 Level 3" :
			faction_bonus_description.text = "Add base speed to damage when not moving"
		"dwarf Path 3 Level 1" :
			faction_bonus_description.text = "Movement speed increased by 1 point during first turn"
		"dwarf Path 3 Level 2" :
			faction_bonus_description.text = "Movement speed increased by 2 points during first turn"
		"dwarf Path 3 Level 3" :
			faction_bonus_description.text = "Movement speed increased by 3 points during first turn"
		"dwarf Path 4 Level 1" :
			faction_bonus_description.text = "Place holder"
		"forestProtector Path 1 Level 1" :
			faction_bonus_description.text = "The number required to merge level 1 forestProtector pieces is reduced from 3 to 2"
		"forestProtector Path 1 Level 2" :
			faction_bonus_description.text = "The number required to merge all forestProtector pieces is reduced from 3 to 2"
		"forestProtector Path 1 Level 3" :
			faction_bonus_description.text = "The number required to merge all pieces is reduced from 3 to 2"
		"forestProtector Path 2 Level 1" :
			faction_bonus_description.text = "forestProtector pieces gain maximum health and health regeneration bonus"
		"forestProtector Path 2 Level 2" :
			faction_bonus_description.text = "forestProtector pieces gain maximum health and health regeneration bonus, and after killing a piece, they gain a small permanent stat increase"
		"forestProtector Path 2 Level 3" :
			faction_bonus_description.text = "forestProtector pieces gain maximum health and health regeneration bonus, and after killing a piece, they gain a permanent stat increase"
		"forestProtector Path 3 Level 1" :
			faction_bonus_description.text = "forestProtector gains a small damage reduction and damage increase against the piece faction that killed it in the previous round"
		"forestProtector Path 3 Level 2" :
			faction_bonus_description.text = "forestProtector gains damage reduction and damage increase against the piece faction that killed it in the previous round"
		"forestProtector Path 3 Level 3" :
			faction_bonus_description.text = "forestProtector gains a large damage reduction and damage increase against the piece faction that killed it in the previous round"
		"forestProtector Path 4 Level 1" :
			faction_bonus_description.text = "Placeholder"
		"undead Path 1 Level 1" :
			faction_bonus_description.text = "Enemies gain small armor and speed debuff"
		"undead Path 1 Level 2" :
			faction_bonus_description.text = "Enemies gain armor and speed debuff"
		"undead Path 1 Level 3" :
			faction_bonus_description.text = "Enemies gain large armor and speed debuff"
		"undead Path 2 Level 1" :
			faction_bonus_description.text = "Necromancer and deathlord can summon skeleton from corpse base on its role"
		"undead Path 2 Level 2" :
			faction_bonus_description.text = "Necromancer and deathlord can summon skeleton from corpse base on its role, unlock SkeletonArcher and SkeletonWarrior"
		"undead Path 2 Level 3" :
			faction_bonus_description.text = "Necromancer and deathlord can summon skeleton from corpse base on its role, unlock SkeletonHorseman and SkeletonMage"
		"undead Path 3 Level 1" :
			faction_bonus_description.text = "Necromancer and deathlord can summon zombie from corpse base on its stats"
		"undead Path 3 Level 2" :
			faction_bonus_description.text = "Necromancer and deathlord can summon zombie from corpse base on its stats, unlock ZombieDog, ZombieRunner and ZombieWarrior"
		"undead Path 3 Level 3" :
			faction_bonus_description.text = "Necromancer and deathlord can summon zombie from corpse base on its stats, unlock ZombieCrusher and ZombieButcher"
		"undead Path 4 Level 1" :
			faction_bonus_description.text = "Placeholder"
		"holy Path 1 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 1 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 1 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 2 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 2 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 2 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 3 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 3 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 3 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"holy Path 4 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 1 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 1 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 1 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 2 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 2 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 2 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 3 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 3 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 3 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"orc Path 4 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"ootf Path 1 Level 1" :
			faction_bonus_description.text = "Friendly faction gain a small amout of mp from each chess with burn effect"
		"ootf Path 1 Level 2" :
			faction_bonus_description.text = "Friendly faction gain some mp from each chess with burn effect"
		"ootf Path 1 Level 3" :
			faction_bonus_description.text = "Friendly faction gain a large amout of mp from each chess with burn effect"
		"ootf Path 2 Level 1" :
			faction_bonus_description.text = "Friendly faction with burn effect gain damage and speed buff"
		"ootf Path 2 Level 2" :
			faction_bonus_description.text = "Friendly faction with burn effect gain damage and speed buff"
		"ootf Path 2 Level 3" :
			faction_bonus_description.text = "Friendly faction with burn effect gain damage and speed buff"
		"ootf Path 3 Level 1" :
			faction_bonus_description.text = "Summon a weak fire elemental creature when killing enemies"
		"ootf Path 3 Level 2" :
			faction_bonus_description.text = "Summon a fire elemental creature when killing enemies"
		"ootf Path 3 Level 3" :
			faction_bonus_description.text = "Summon a strong fire elemental creature when killing enemies"
		"ootf Path 4 Level 1" :
			faction_bonus_description.text = "Randomly burn a chess at the start of turn"
		"lizardMan Path 1 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 1 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 1 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 2 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 2 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 2 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 3 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 3 Level 2" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 3 Level 3" :
			faction_bonus_description.text = "PlaceHolder"
		"lizardMan Path 4 Level 1" :
			faction_bonus_description.text = "PlaceHolder"
		_:
			faction_bonus_description.text = "place holder"
			
	match faction_array[current_page] + " Path " + str(current_path_number):
		"elf Path 1" :
			faction_path_label.text = "Path1 Critical Mastery"
		"elf Path 2" :
			faction_path_label.text = "Path2 Evasion Mastery"
		"elf Path 3" :
			faction_path_label.text = "Path3 Multi-Strike Mastery"
		"elf Path 4" :
			faction_path_label.text = "Path4 Placeholder"
		"human Path 1" :
			faction_path_label.text = "Path1 Population Expansion"
		"human Path 2" :
			faction_path_label.text = "Path2 Village Recruitment"
		"human Path 3" :
			faction_path_label.text = "Path3 Evolutionary Merge"
		"human Path 4" :
			faction_path_label.text = "Path4 Villager Gathering"
		"dwarf Path 1" :
			faction_path_label.text = "Path1 Iron Defense"
		"dwarf Path 2" :
			faction_path_label.text = "Path2 Army Principle"
		"dwarf Path 3" :
			faction_path_label.text = "Path3 Battle Momentum"
		"dwarf Path 4" :
			faction_path_label.text = "Path4 Placeholder"
		"forestProtector Path 1" :
			faction_path_label.text = "Path1 Streamlined Fusion"
		"forestProtector Path 2" :
			faction_path_label.text = "Path2 Sylvan Resilience"
		"forestProtector Path 3" :
			faction_path_label.text = "Path3 Echoing Vengeance"
		"forestProtector Path 4" :
			faction_path_label.text = "Path4 Placeholder"
		"undead Path 1" :
			faction_path_label.text = "Path1 Weaken"
		"undead Path 2" :
			faction_path_label.text = "Path2 Control Skeleton"
		"undead Path 3" :
			faction_path_label.text = "Path3 Control Zombie"
		"undead Path 4" :
			faction_path_label.text = "Path4 Placeholder"
		"holy Path 1" :
			faction_path_label.text = "PlaceHolder"
		"holy Path 2" :
			faction_path_label.text = "PlaceHolder"
		"holy Path 3" :
			faction_path_label.text = "PlaceHolder"
		"holy Path 4" :
			faction_path_label.text = "PlaceHolder"
		"orc Path 1" :
			faction_path_label.text = "Chess nearby gain a lesser buff when ally orc cast battle cry in small area"
		"orc Path 2" :
			faction_path_label.text = "Chess nearby gain a lesser buff when ally orc cast battle cry nearby"
		"orc Path 3" :
			faction_path_label.text = "Chess nearby gain a lesser buff when ally orc cast battle cry in large area"
		"orc Path 4" :
			faction_path_label.text = "PlaceHolder"
		"ootf Path 1" :
			faction_path_label.text = "PlaceHolder"
		"ootf Path 2" :
			faction_path_label.text = "PlaceHolder"
		"ootf Path 3" :
			faction_path_label.text = "PlaceHolder"
		"ootf Path 4" :
			faction_path_label.text = "PlaceHolder"
		"lizardMan Path 1" :
			faction_path_label.text = "PlaceHolder"
		"lizardMan Path 2" :
			faction_path_label.text = "PlaceHolder"
		"lizardMan Path 3" :
			faction_path_label.text = "PlaceHolder"
		"lizardMan Path 4" :
			faction_path_label.text = "PlaceHolder"
		"demon Path 1" :
			faction_path_label.text = "PlaceHolder"
		"demon Path 2" :
			faction_path_label.text = "PlaceHolder"
		"demon Path 3" :
			faction_path_label.text = "PlaceHolder"
		"demon Path 4" :
			faction_path_label.text = "Path4 Deal with the devil"
		_:
			faction_path_label.text = "place holder"	
		
	refresh_page()
	handle_button_actived()
		
func set_button_texture(button: TextureButton, is_active: bool) -> void:
	
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

func handle_button_actived():
	for node in lose_round_container.get_children() + won_round_container.get_children():
		if not node.name.contains("template"):
			node.queue_free()
	
	for i in range(DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier - DataManagerSingleton.lose_rounds):
		var new_remain_lose_rounds_icon = remain_lose_rounds_template.duplicate(true)
		new_remain_lose_rounds_icon.visible = true
		lose_round_container.add_child(new_remain_lose_rounds_icon)

	for i in range(DataManagerSingleton.lose_rounds):
		var new_lose_rounds_icon = lose_rounds_template.duplicate(true)
		new_lose_rounds_icon.visible = true
		lose_round_container.add_child(new_lose_rounds_icon)

	for i in range(DataManagerSingleton.won_rounds):
		var new_won_rounds_icon = won_rounds_template.duplicate(true)
		new_won_rounds_icon.visible = true
		won_round_container.add_child(new_won_rounds_icon)
		
	for i in range(DataManagerSingleton.max_won_rounds + DataManagerSingleton.max_won_rounds_modifier - DataManagerSingleton.won_rounds):
		var new_remain_won_rounds_icon = remain_won_rounds_template.duplicate(true)
		new_remain_won_rounds_icon.visible = true
		won_round_container.add_child(new_remain_won_rounds_icon)
			
	just_active_label.text = "Active(" + str(get_parent().remain_upgrade_count) + ")"
	
	if current_level_number == 0 or current_path_number == 0:
		consume_remian_lose_round.disabled = true
		consume_max_lose_round.disabled = true
		consume_won_round.disabled = true
		just_active.disabled = true
		return
	elif current_path_number == 4 and current_level_number != 1:
		consume_remian_lose_round.disabled = true
		consume_max_lose_round.disabled = true
		consume_won_round.disabled = true
		just_active.disabled = true
		return
	elif not current_level_number - game_faction_path_upgrade[faction_array[current_page]]["path" + str(current_path_number)] == 1:
		consume_remian_lose_round.disabled = true
		consume_max_lose_round.disabled = true
		consume_won_round.disabled = true
		just_active.disabled = true
		return
		
	if DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier - DataManagerSingleton.lose_rounds > 1:
		consume_remian_lose_round.disabled = false
	else:
		consume_remian_lose_round.disabled = true
		
	if DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier > 1 and DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier - DataManagerSingleton.lose_rounds > 0:
		consume_max_lose_round.disabled = false
	else:
		consume_max_lose_round.disabled = true
		
	if DataManagerSingleton.won_rounds > 0:
		consume_won_round.disabled = false
	else:
		consume_won_round.disabled = true
		
	if get_parent().remain_upgrade_count > 0:
		just_active.disabled = false
	else:
		just_active.disabled = true

	
