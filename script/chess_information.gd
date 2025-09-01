class_name ChessInformation
extends HBoxContainer

@onready var chess_name: Label = $VBoxContainer/chess_name
@onready var chess_faction: Label = $VBoxContainer/chess_faction
@onready var max_hp: Label = $VBoxContainer/max_hp
@onready var armor: Label = $VBoxContainer/armor
@onready var speed: Label = $VBoxContainer/speed
@onready var damage: Label = $VBoxContainer/damage
@onready var attack_range: Label = $VBoxContainer/attack_range
@onready var attack_speed: Label = $VBoxContainer/attack_speed
@onready var spell: Label = $VBoxContainer/spell
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var animation_faction := "human"
var animation_chess_name := "ShieldMan"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_chess(obstacle: Obstacle) -> void:
	obstacle.drag_handler.drag_started.connect(show_chess_information.bind(obstacle))
	obstacle.drag_handler.is_clicked.connect(show_chess_information.bind(obstacle))
	obstacle.drag_handler.drag_canceled.connect(_on_chess_drag_canceled.bind(obstacle))
	obstacle.drag_handler.drag_dropped.connect(_on_chess_dropped.bind(obstacle))
	
		
func show_chess_information(starting_position: Vector2, status: String, obstacle: Obstacle) -> void:
	visible = true
	chess_name.text = "Chess Name = " + obstacle.chess_name
	chess_faction.text = "Faction = " + obstacle.faction
	max_hp.text = "Max HP = " + str(obstacle.max_hp)
	armor.text = "Armor = " + str(obstacle.armor)
	speed.text = "Speed = " + str(obstacle.spd)
	damage.text = "Damage = " + str(obstacle.damage)
	attack_range.text = "Attack Range = " + str(obstacle.attack_range)
	attack_speed.text = "Attack Speed = " + str(obstacle.attack_spd)
	spell.text = "Spell = " + obstacle.skill_name
	animation_faction = obstacle.faction
	animation_chess_name = obstacle.chess_name
	_load_animations()
		
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
