extends Control
class_name FactionBonusBar

@onready var label: Label = $Label
@onready var texture_rect: TextureRect = $TextureRect
@onready var frame_texture_rect: TextureRect = $TextureRect/TextureRect

var bar_color: Color:
	set(value):
		bar_color = value
		texture_rect.texture = texture_rect.texture.duplicate()
		match bar_color:
			Color.GREEN:
				texture_rect.texture.region.position.y = 54
			Color.RED:
				texture_rect.texture.region.position.y = 6
			Color.BLUE:
				texture_rect.texture.region.position.y = 38
			Color.YELLOW:
				texture_rect.texture.region.position.y = 22
			_:
				texture_rect.texture.region.position.y = 54
				
var bar_value: int:
	set(value):
		bar_value = value
		texture_rect.texture = texture_rect.texture.duplicate()
		if [1, 2, 3, 4, 5, 6].has(bar_value):
			texture_rect.visible = true
			texture_rect.texture.region.position.x = 627 + (6 - bar_value) * 48
		else:
			texture_rect.visible = false
			frame_texture_rect.visible = true
			
var frame_color: String:
	set(value):
		frame_color = value
		frame_texture_rect.texture = frame_texture_rect.texture.duplicate()
		match frame_color:
			"Silver":
				frame_texture_rect.texture.region.position.y = 3
			"Iron":
				frame_texture_rect.texture.region.position.y = 19
			"Copper":
				frame_texture_rect.texture.region.position.y = 35
					
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
