@tool
class_name Damage_Meter_Bar
extends HBoxContainer

@onready var texture_rect: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

# HBoxContainer (Main Container)
# ├── Property Management
# │   ├── damage_value (with setter for auto UI update)
# │   ├── sprite_faction (with setter for auto texture update)
# │   └── sprite_name (with setter for auto texture update)
# ├── Initialization Flow
# │   └── _ready() → Update texture and UI display
# └── Update Methods
#     ├── _update_hero_texture() (unified texture update logic)
#     └── _update_damage_display() (unified UI update logic)

# Damage value property with real-time UI update
@export var damage_value := 10:
	set(value):
		damage_value = value
		_update_damage_display()

@export var highest_damage_value := 100:
	set(value):
		highest_damage_value = value
		_update_damage_display()
		
# Faction property
@export var sprite_faction := "human":
	set(value):
		sprite_faction = value
		_update_hero_texture()

# Hero name property with real-time texture update
@export var sprite_name := "ShieldMan":
	set(value):
		sprite_name = value
		_update_hero_texture()

# Called when the node enters the scene tree for the first time
func _ready():
	_update_hero_texture()
	_update_damage_display()

# Update hero texture from sprite frames
func _update_hero_texture():
	if not texture_rect:
		return
		
	var sprite_path = "res://asset/animation/" + sprite_faction + "/" + sprite_faction + sprite_name + ".tres"
	var sprite_frames = load(sprite_path) as SpriteFrames
	
	if sprite_frames and sprite_frames.has_animation("idle"):
		var texture = sprite_frames.get_frame_texture("idle", 0)
		texture_rect.texture = texture

# Update damage value display on progress bar and label
func _update_damage_display():
	if progress_bar:
		progress_bar.max_value = highest_damage_value
		progress_bar.value = damage_value
	
	if label:
		label.text = str(damage_value)

func init(faction: String, hero_name: String, max_value: int, value: int):
	sprite_faction = faction
	sprite_name = hero_name
	highest_damage_value = max_value
	damage_value = value
	_update_hero_texture()
	_update_damage_display()
