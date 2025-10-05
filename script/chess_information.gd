class_name ChessInformation
extends VBoxContainer

const effect_icon_scene = preload("res://scene/effect_icon.tscn")

@onready var chess_stats: VBoxContainer = $chess_stats

@onready var chess_name: Label = $chess_stats/chess_name
@onready var chess_faction: Label = $chess_stats/chess_faction
@onready var max_hp: Label = $chess_stats/max_hp
@onready var armor: Label = $chess_stats/armor
@onready var speed: Label = $chess_stats/speed
@onready var damage: Label = $chess_stats/damage
@onready var attack_range: Label = $chess_stats/attack_range
@onready var attack_speed: Label = $chess_stats/attack_speed
@onready var spell: Label = $chess_stats/spell

@onready var animated_sprite_2d: AnimatedSprite2D = $icons/AnimatedSprite2D

@onready var icon_container: HBoxContainer = $icon_container

@onready var kill_count_container: HBoxContainer = $icons/kill_count_container
@onready var kill_icon: TextureRect = $icons/kill_count_container/kill_icon
@onready var kill_icon_template: TextureRect = $icons/kill_icon_template

var animation_faction := "human"
var animation_chess_name := "SwordMan"

var record_chess: Obstacle
var showed_chess: Obstacle

var game_root_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	game_root_scene = get_parent()
	visible = false
	#chess_name.text = "Chess Name = " + showed_chess.chess_name
	#chess_faction.text = "Faction = " + showed_chess.faction
	
	max_hp.set_meta("tips", "Health points. Unit dies when reaching 0.")
	armor.set_meta("tips", "Reduces damage taken by this amount.")
	speed.set_meta("tips", "Movement range per turn (tiles).")
	damage.set_meta("tips", "Damage dealt per attack(melee/ranged).")
	attack_range.set_meta("tips", "Attack distance (tiles).")
	attack_speed.set_meta("tips", "Attacks per turn.")
	spell.set_meta("tips", "Special ability (requires full MP).")
	
	
	for node in chess_stats.get_children():
		if not node is Label:
			continue
			
		# Connect mouse entered signal
		node.mouse_entered.connect(
			func():
				game_root_scene.tips_label.global_position = get_global_mouse_position() + Vector2(-140, -8)
				game_root_scene.tips_label.text = node.get_meta("tips", "")
				if game_root_scene.tips_label.text != "":
					game_root_scene.tips_label.visible = true
				else:
					game_root_scene.tips_label.visible = false
		)
		
		# Connect mouse exited signal
		node.mouse_exited.connect(
			func():
				game_root_scene.tips_label.visible = false
		)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if DataManagerSingleton.check_obstacle_valid(showed_chess):
		refresh_chess_information()

func setup_chess(obstacle: Obstacle) -> void:
	obstacle.drag_handler.drag_started.connect(show_chess_information.bind(obstacle))
	obstacle.drag_handler.is_clicked.connect(show_chess_information.bind(obstacle))
	obstacle.drag_handler.drag_canceled.connect(_on_chess_drag_canceled.bind(obstacle))
	obstacle.drag_handler.drag_dropped.connect(_on_chess_dropped.bind(obstacle))
	
		
func show_chess_information(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:

	showed_chess = obstacle
	
	refresh_chess_information()

		
	animation_faction = showed_chess.faction
	animation_chess_name = showed_chess.chess_name
	_load_animations()

func refresh_chess_information():	
	if showed_chess == null:
		visible = false
		return
	
	for node in icon_container.get_children():
		node.queue_free()

	visible = true
	chess_name.text = "Chess Name = " + showed_chess.chess_name
	chess_faction.text = "Faction = " + showed_chess.faction
	if showed_chess.is_active:
		max_hp.text = "HP = " + str(round(showed_chess.hp)) + " / " + str(round(showed_chess.max_hp))
		armor.text = "Armor = " + str(round(showed_chess.armor))
		speed.text = "Speed = " + ("0" if showed_chess.get("speed") == null else str(round(showed_chess.speed)))
		damage.text = "Damage = " + ("0/0" if showed_chess.get("melee_damage") == null else str(round(showed_chess.melee_damage)) + " / " + str(round(showed_chess.ranged_damage)))
		attack_range.text = "Attack Range = " + ("0" if showed_chess.get("attack_range") == null else str(round(showed_chess.attack_range)))
		attack_speed.text = "Attack Speed = " + ("0" if showed_chess.get("attack_speed") == null else str(round(showed_chess.attack_speed)))
	else:
		max_hp.text = "HP = " + str(round(showed_chess.hp)) + " / " + str(round(showed_chess.base_max_hp))
		armor.text = "Armor = " + str(round(showed_chess.base_armor))
		speed.text = "Speed = " + ("0" if showed_chess.get("base_speed") == null else str(round(showed_chess.base_speed)))
		damage.text = "Damage = " + ("0/0" if showed_chess.get("base_melee_damage") == null else str(round(showed_chess.base_melee_damage)) + " / " + str(round(showed_chess.base_ranged_damage)))
		attack_range.text = "Attack Range = " + ("0" if showed_chess.get("base_attack_range") == null else str(round(showed_chess.base_attack_range)))
		attack_speed.text = "Attack Speed = " + ("0" if showed_chess.get("base_attack_speed") == null else str(round(showed_chess.base_attack_speed)))
	
	if showed_chess.base_max_mp == 0 and showed_chess is Chess and showed_chess.passive_ability != "":
		spell.text = "Passive ability : " + showed_chess.passive_ability
	elif showed_chess is Chess and showed_chess.base_max_mp > 0:
		spell.text = "Spell : " + showed_chess.skill_name
		spell.visible = true
	else:
		spell.visible = false
	
	var kill_count = showed_chess.total_kill_count
	if kill_count == kill_count_container.get_children().size():
		pass
	else:
		for node in kill_count_container.get_children():
			node.queue_free()
		
		if showed_chess is Chess:			
			
			if kill_count <= 0:
				kill_count_container.visible = false
			else:
				kill_count_container.visible = true
				for i in range(min(5,kill_count)):
					var new_kill_icon = kill_icon_template.duplicate()
					new_kill_icon.visible = true
					new_kill_icon.reparent(kill_count_container)
							
		else:
			kill_count_container.visible = false

	if showed_chess.effect_handler:
		var chess_effect_list = showed_chess.effect_handler.effect_list.duplicate()
		if chess_effect_list.size() == 0 or is_instance_valid(chess_effect_list):
			return

		for effect_index in chess_effect_list:
			
			var effect_icon = effect_icon_scene.instantiate()
			effect_icon.effect_name = effect_index.effect_name
			effect_icon.tooltip_text = effect_index.effect_name + " by " + effect_index.effect_applier + " :\n" + effect_index.effect_description
			icon_container.add_child(effect_icon)
			
			# Connect mouse entered signal
			effect_icon.mouse_entered.connect(
				func():
					if not effect_icon.get_global_rect().has_point(get_global_mouse_position()):
						return
					game_root_scene.tips_label.global_position = get_global_mouse_position() + Vector2(-140, -24)
					game_root_scene.tips_label.text = effect_index.effect_name + " by " + effect_index.effect_applier + " :\n" + effect_index.effect_description
					#game_root_scene.tips_label.text = "123"
					if game_root_scene.tips_label.text != "":
						game_root_scene.tips_label.visible = true
					else:
						game_root_scene.tips_label.visible = false
			)
			
			# Connect mouse exited signal
			effect_icon.mouse_exited.connect(
				func():
					if not effect_icon.get_global_rect().has_point(get_global_mouse_position()):
						game_root_scene.tips_label.visible = false
			)
				
func _on_chess_drag_canceled(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	visible = false
	
func _on_chess_dropped(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	visible = false

func _load_animations():
	var path = "res://asset/animation/%s/%s%s.tres" % [animation_faction, animation_faction, animation_chess_name]
	if ResourceLoader.exists(path):
		var frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
		animated_sprite_2d.sprite_frames = frames
		animated_sprite_2d.play("idle")
	else:
		push_error("Animation resource not found: " + path)


func _on_animated_sprite_2d_animation_finished() -> void:
	var rand_anim_index = randi_range(0, animated_sprite_2d.sprite_frames.get_animation_names().size() - 1)
	var rand_anim_name = animated_sprite_2d.sprite_frames.get_animation_names()[rand_anim_index]
	animated_sprite_2d.play(rand_anim_name)
