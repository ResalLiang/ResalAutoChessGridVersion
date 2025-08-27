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

# Called when the node enters the scene tree for the first time
func _ready():
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
	
	#var source_texture = sprite_frames.get_frame_texture("idle", 0)
	#if not source_texture:
		#push_error("Failed to get frame texture from 'idle' animation")
		#return
	
	# Extract and apply the texture region
	#var extracted_texture = extract_8x8_region_optimized(source_texture, 16, 16)
	#if extracted_texture:
		#texture_rect.texture = extracted_texture
		
	var source_texture = AtlasTexture.new()
	source_texture.set_atlas(sprite_frames.get_frame_texture("idle", 0))
	source_texture.region = Rect2(12, 18, 8, 8)
	texture_rect.texture = source_texture

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

func extract_8x8_region_optimized(source_texture: Texture2D, origin_x: int, origin_y: int) -> Texture2D:
	# Validate input texture
	if not source_texture:
		push_error("Source texture is null")
		return null
	
	# Get source image
	var source_image = source_texture.get_image()
	if not source_image:
		push_error("Failed to get image from texture")
		return null
	
	# Get source dimensions
	var source_width = source_image.get_width()
	var source_height = source_image.get_height()
	
	# Validate coordinates are within bounds
	if origin_x < 0 or origin_y < 0 or origin_x + 8 > source_width or origin_y + 8 > source_height:
		push_error("8x8 region exceeds texture bounds. Source: %dx%d, Region: %d,%d" % [source_width, source_height, origin_x, origin_y])
		return null
	
	# Create new 8x8 image
	var extracted_image = Image.create_empty(8, 8, false, source_image.get_format())
	
	# Use blit_rect for efficient pixel copying
	extracted_image.blit_rect(source_image, Rect2i(origin_x, origin_y, 8, 8), Vector2i(0, 0))
	
	# Create and return new ImageTexture
	var extracted_texture = ImageTexture.new()
	extracted_texture.create_from_image(extracted_image)
	
	return extracted_texture
