@tool
extends HBoxContainer

@onready var texture_rect: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

@export var damage_value:= 100:
	set(value):
		damage_value = value
		if label:
			label.text = str(value)
		
@export var faction := "human"
@export var hero_name:= "ShieldMan":
	set(value):
		hero_name = value
		var sprite_frames = load("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres") as SpriteFrames

		if sprite_frames.has_animation("idle"):  # 替换为您的实际动画名称
			var texture = sprite_frames.get_frame("idle", 0)  # 获取 "default" 动画的第 0 帧
			texture_rect.texture = texture  # 将获取的帧赋值给 TextureRec
		

# Called when the node enters the scene tree for the first time.
func _ready():
	var sprite_frames = load("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres") as SpriteFrames

	if sprite_frames.has_animation("idle"):  # 替换为您的实际动画名称
		var texture = sprite_frames.get_frame_texture("idle", 0)  # 获取 "default" 动画的第 0 帧
		texture_rect.texture = texture  # 将获取的帧赋值给 TextureRec


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress_bar.max_value = 1000
	progress_bar.value = damage_value
	label.text = str(damage_value)
