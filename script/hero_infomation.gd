class_name HeroInformation
extends HBoxContainer

@onready var hero_name: Label = $VBoxContainer/hero_name
@onready var hero_faction: Label = $VBoxContainer/hero_faction
@onready var max_hp: Label = $VBoxContainer/max_hp
@onready var armor: Label = $VBoxContainer/armor
@onready var speed: Label = $VBoxContainer/speed
@onready var damage: Label = $VBoxContainer/damage
@onready var attack_range: Label = $VBoxContainer/attack_range
@onready var attack_speed: Label = $VBoxContainer/attack_speed
@onready var spell: Label = $VBoxContainer/spell
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var animation_faction := "human"
var animation_hero_name := "ShieldMan"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_hero(hero: Hero) -> void:
	hero.drag_handler.drag_started.connect(_on_hero_drag_started.bind(hero))
	hero.drag_handler.drag_canceled.connect(_on_hero_drag_canceled.bind(hero))
	hero.drag_handler.drag_dropped.connect(_on_hero_dropped.bind(hero))
	
		
func _on_hero_drag_started(starting_position: Vector2, status: String, hero: Hero) -> void:
	visible = true
	hero_name.text = "Hero Name = " + hero.hero_name
	hero_faction.text = "Faction = " + hero.faction
	max_hp.text = "Max HP = " + str(hero.max_hp)
	armor.text = "Armor = " + str(hero.armor)
	speed.text = "Speed = " + str(hero.spd)
	damage.text = "Damage = " + str(hero.damage)
	attack_range.text = "Attack Range = " + str(hero.attack_range)
	attack_speed.text = "Attack Speed = " + str(hero.attack_spd)
	spell.text = "Spell = " + hero.skill_name
	animation_faction = hero.faction
	animation_hero_name = hero.hero_name
	_load_animations()
		
func _on_hero_drag_canceled(starting_position: Vector2, status: String, hero: Hero) -> void:
	visible = false
	
func _on_hero_dropped(starting_position: Vector2, status: String, hero: Hero) -> void:
	visible = false

func _load_animations():
	var path = "res://asset/animation/%s/%s%s.tres" % [animation_faction, animation_faction, animation_hero_name]
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
