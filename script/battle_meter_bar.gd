class_name BattleMeterBar
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
		
@export var hero_team := 1:
	set(value):
		hero_team = value
		_update_hero_texture()

# Called when the node enters the scene tree for the first time
func _ready():
		
	texture_rect.set_custom_minimum_size(Vector2(8, 8))
	progress_bar.set_custom_minimum_size(Vector2(96, 8))
	label.set_custom_minimum_size(Vector2(24, 8))
	
	texture_rect.size_flags_horizontal = 0
	progress_bar.size_flags_horizontal = 3
	label.size_flags_horizontal = 8

	_update_hero_texture()
	_update_damage_display()

# Update hero texture from sprite frames
func _update_hero_texture():
	if not texture_rect:
		return
		
	var sprite_path = "res://asset/animation/" + sprite_faction + "/" + sprite_faction + sprite_name + ".tres"
	
	# Check if resource exists before loading
	if not ResourceLoader.exists(sprite_path):
		push_error("Sprite frames resource not found: " + sprite_path)
		return
		
	var sprite_frames = load(sprite_path) as SpriteFrames
	if not sprite_frames:
		push_error("Failed to load sprite frames from: " + sprite_path)
		return
	
	# Check if idle animation exists first
	if not sprite_frames.has_animation("idle"):
		push_error("Animation 'idle' not found in sprite frames: " + sprite_path)
		return
	
	# Get texture from idle animation instead of die animation
	var frame_count = sprite_frames.get_frame_count("idle")
	if frame_count == 0:
		push_error("No frames found in 'idle' animation")
		return
			
	var source_texture = AtlasTexture.new()
	source_texture.set_atlas(sprite_frames.get_frame_texture("idle", 0))
	source_texture.region = Rect2(12, 18, 8, 8)
	texture_rect.texture = source_texture
	var fill_style = StyleBoxFlat.new()
	if hero_team == 1:
		fill_style.bg_color = Color.GREEN  # Set fill color
	else:
		fill_style.bg_color = Color.RED  # Set fill color
	fill_style.border_width_bottom = 1
	fill_style.border_width_top = 1
	fill_style.border_width_left = 1
	fill_style.border_width_right = 1
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Apply the style to progress bar
	progress_bar.add_theme_stylebox_override("fill", fill_style)


# Update damage value display on progress bar and label
func _update_damage_display():
	if progress_bar:
		progress_bar.max_value = highest_damage_value
		progress_bar.value = damage_value
	
	if label:
		label.text = str(damage_value)

func init(faction: String, hero_name: String, team: int, max_value: int, value: int):
	sprite_faction = faction
	sprite_name = hero_name
	hero_team = team
	highest_damage_value = max_value
	damage_value = value
	_update_hero_texture()
	_update_damage_display()
