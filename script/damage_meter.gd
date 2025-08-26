@tool
extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	# 加载 SpriteFrames 资源
	var sprite_frames = load("res://asset/animation/human/humanShieldMan.tres") as SpriteFrames

	# 检查动画是否存在，以及获取其中的帧
	if sprite_frames.has_animation("idle"):  # 替换为您的实际动画名称
		var texture = sprite_frames.get_frame("default", 0)  # 获取 "default" 动画的第 0 帧
		$TextureRect.texture = texture  # 将获取的帧赋值给 TextureRect


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
