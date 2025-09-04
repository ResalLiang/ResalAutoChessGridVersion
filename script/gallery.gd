extends Node2D
class_name gallery

@onready var chess_container: VBoxContainer = $chess_container
@onready var chess_data_container : VBoxContainer = $chess_data_container

@onready var buy_count: Label = $chess_data_container/buy_count
@onready var sell_count: Label = $chess_data_container/sell_count
@onready var refresh_count: Label = $chess_data_container/refresh_count
@onready var max_damage: Label = $chess_data_container/max_damage
@onready var max_damage_taken: Label = $chess_data_container/max_damage_taken
@onready var max_heal: Label = $chess_data_container/max_heal
@onready var max_heal_taken: Label = $chess_data_container/max_heal_taken
@onready var critical_attack_count: Label = $chess_data_container/critical_attack_count
@onready var evase_attack_count: Label = $chess_data_container/evase_attack_count
@onready var cast_spell_count: Label = $chess_data_container/cast_spell_count

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:

	for node in chess_container.get_child():
		node.queue_free()

	chess_data_container.visible = false
	animated_sprite_2d.visible = false

	chess_container.mouse_filter = Control.MOUSE_FILTER_PASS

	var current_player_data = DataManagerSingleton[DataManagerSingleton.current_player]
	var current_player_chess_data = current_player_data["chess_stat"]

	var chess_displayed_x = 0
	var chess_displayed_xmax = 8
	var chess_displayed_y = 0

	for faction_index in current_player_chess_data.keys():
		for chess_index in current_player_chess_data[faction_index].keys():
			if chess_displayed_x == 0 or not current_h_container:
				var h_chess_container = HBoxContainer.new()
				h_chess_container.mouse_filter = Control.MOUSE_FILTER_PASS
				h_chess_container.custom_minimum_size = Vector2(256, 32)
				chess_container.add_child(h_chess_container)
				current_h_container = h_chess_container

			var chess_button = TextureButton.new()
			var source_texture = AtlasTexture.new()
			var sprite_path
			if current_player_chess_data[faction_index][chess_index]["buy_count"] > 0:
				sprite_path = "res://asset/animation/" + sprite_faction + "/" + faction_index + chess_index + ".tres"
			eles:
				sprite_path = "res://asset/animation/" + "human" + "/" + "human" + "ShieldMan" + ".tres"
			# Check if resource exists before loading
			if not ResourceLoader.exists(sprite_path):
				sprite_path = "res://asset/animation/" + "human" + "/" + "human" + "ShieldMan" + ".tres"
				continue
			var sprite_frames = load(sprite_path) as SpriteFrames
			source_texture.set_atlas(sprite_frames.get_frame_texture("idle", 0))
			source_texture.region = Rect2(6, 12, 20, 20)

			chess_button.size = Vector2(32, 32)
			chess_button.texture_normal = source_texture
			chess_button.texture_hover = source_texture
			chess_button.texture_pressed = source_texture
			chess_button.set_meta("faction", faction_index)
			chess_button.set_meta("chess_name",chess_index)
			chess_button.pressed.connect(_on_chess_button_pressed.bind(chess_button))


			current_h_container.add_child(chess_button)
			chess_displayed_x += 1
			if chess_displayed_x >= chess_displayed_xmax:
				chess_displayed_x = 0
				chess_displayed_y += 1

func _on_chess_button_pressed(button: TextureButton):

	
	faction_index = button.get_meta("faction")
	chess_index = button.get_meta("chess_name")

	var current_chess_data = DataManagerSingleton[DataManagerSingleton.current_player]["chess_stat"][faction_index][chess_index]
	if current_chess_data["buy_count"] == 0:
		chess_data_container.visible = false
		animated_sprite_2d.visible = false
		return

	else:

		var path = "res://asset/animation/%s/%s%s.tres" % [faction_index, faction_index, chess_index]
		if ResourceLoader.exists(path):
			var frames = ResourceLoader.load(path)
			for anim_name in frames.get_animation_names():
				frames.set_animation_loop(anim_name, false)
				frames.set_animation_speed(anim_name, 8.0)
			animated_sprite_2d.sprite_frames = frames
			animated_sprite_2d.play("idle")
		else:
			push_error("Animation resource not found: " + path)

		chess_data_container.visible = true
		animated_sprite_2d.visible = true

		if current_chess_data.has_key(buy_count):
			buy_count.text = current_chess_data[buy_count]
		else:
			buy_count.text = "/"

		if current_chess_data.has_key(sell_count):
			sell_count.text = current_chess_data[sell_count]
		else:
			sell_count.text = "/"

		if current_chess_data.has_key(refresh_count):
			refresh_count.text = current_chess_data[refresh_count]
		else:
			refresh_count.text = "/"

		if current_chess_data.has_key(max_damage):
			max_damage.text = current_chess_data[max_damage]
		else:
			max_damage.text = "/"

		if current_chess_data.has_key(max_damage_taken):
			max_damage_taken.text = current_chess_data[max_damage_taken]
		else:
			max_damage_taken.text = "/"

		if current_chess_data.has_key(max_heal):
			max_heal.text = current_chess_data[max_heal]
		else:
			max_heal.text = "/"

		if current_chess_data.has_key(max_heal_taken):
			max_heal_taken.text = current_chess_data[max_heal_taken]
		else:
			max_heal_taken.text = "/"

		if current_chess_data.has_key(critical_attack_count):
			critical_attack_count.text = current_chess_data[critical_attack_count]
		else:
			critical_attack_count.text = "/"

		if current_chess_data.has_key(evase_attack_count):
			evase_attack_count.text = current_chess_data[evase_attack_count]
		else:
			evase_attack_count.text = "/"
			
		if current_chess_data.has_key(cast_spell_count):
			cast_spell_count.text = current_chess_data[cast_spell_count]
		else:
			cast_spell_count.text = "/"

func _on_animated_sprite_2d_animation_finished() -> void:
	var rand_anim_index = randi_range(0, animated_sprite_2d.sprite_frames.get_animation_names().size() - 1)
	var rand_anim_name = animated_sprite_2d.sprite_frames.get_animation_names()[rand_anim_index]
	animated_sprite_2d.play(rand_anim_name)


# @onready var buy_count: Label = $chess_data_container/buy_count
# @onready var sell_count: Label = $chess_data_container/sell_count
# @onready var refresh_count: Label = $chess_data_container/refresh_count
# @onready var max_damage: Label = $chess_data_container/max_damage
# @onready var max_damage_taken: Label = $chess_data_container/max_damage_taken
# @onready var max_heal: Label = $chess_data_container/max_heal
# @onready var max_heal_taken: Label = $chess_data_container/max_heal_taken
# @onready var critical_attack_count: Label = $chess_data_container/critical_attack_count
# @onready var evase_attack_count: Label = $chess_data_container/evase_attack_count
# @onready var cast_spell_count: Label = $chess_data_container/cast_spell_count		

# var chess_stat_sample = {
# 	"buy_count": 0,
# 	"sell_count": 0,
# 	"refresh_count" : 0,
# 	"max_damage": 0,
# 	"max_damage_taken": 0,
# 	"critical_attack_count": 0,
# 	"evase_attack_count" : 0,
# 	"cast_spell_count" : 0
# }
