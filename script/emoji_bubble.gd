extends Node2D

@export var bubble_index: int = 1:
	set(value):
		if value > 9 or value < 1:
			return
		bubble_index = value
		update_bubble_texture()

@export var emoji_index: int = 1:
	set(value):
		if value > 127 or value < 1:
			return
		emoji_index = value
		update_emoji_texture()

@onready var bubble_texture: TextureRect = $bubble_texture
@onready var emoji_texture: TextureRect = $emoji_texture

func _ready() -> void:
	bubble_index = randi_range(1, 9)
	emoji_index = randi_range(1, 127)
	update_bubble_texture()
	update_emoji_texture()
	await get_tree().create_timer(2.0).timeout
	queue_free()
	

func update_bubble_texture() -> void:
	var bubble_path = "res://asset/sprite/emoji_comic_pack_Joyquest_2.0/bubbles/bubble_white_%d.png" % bubble_index
	var bubble: Texture2D = load(bubble_path)
	if bubble and bubble_texture:
		bubble_texture.texture = bubble
	else:
		push_error("Failed to load bubble texture: " + bubble_path)

func update_emoji_texture() -> void:
	var emoji_path = "res://asset/sprite/emoji_comic_pack_Joyquest_2.0/outline_emojis/em_outline_%d.png" % emoji_index
	var emoji: Texture2D = load(emoji_path)
	if emoji and emoji_texture:
		emoji_texture.texture = emoji
	else:
		push_error("Failed to load emoji texture: " + emoji_path)
