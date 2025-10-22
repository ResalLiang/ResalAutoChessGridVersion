extends Node2D
class_name gallery

const alternative_choice_scene = preload("res://scene/alternative_choice.tscn")

@onready var chess_data_container : VBoxContainer = $chess_data_container

@onready var chess_container: ScrollContainer = $chess_container
@onready var chess_vbox_container: VBoxContainer = $chess_container/chess_vbox_container

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

@onready var back_button: Button = $back_button
@onready var reset_button: Button = $reset_button

@onready var next_page_animated_sprite_2d: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var backward_page: TextureButton = $Node2D/backward_page
@onready var forward_page: TextureButton = $Node2D/forward_page
@onready var current_page_label: Label = $Node2D/current_page_label


signal to_menu_scene
signal to_tetris_scene
signal to_snake_scene
signal to_minesweep_scene

var current_page := 0

func _ready() -> void:
	var chess_data_count := 0
	for faction_index in DataManagerSingleton.get_chess_data().keys():
		for chess_index in DataManagerSingleton.get_chess_data()[faction_index].keys():
			chess_data_count += 1
			
	var total_page = ceil(chess_data_count * 1.0 / 16)
	
	
	backward_page.pressed.connect(
		func():
			if current_page == 0:
				return
			else:
				current_page -= 1
				current_page = max(0, min(total_page - 1, current_page))
			backward_page.visible = false
			forward_page.visible = false
			chess_data_container.visible = false
			chess_container.visible = false
			animated_sprite_2d.visible = false
			current_page_label.visible = false
			next_page_animated_sprite_2d.play("backward")
			await next_page_animated_sprite_2d.animation_finished
			refresh_gallery()
			backward_page.visible = true
			backward_page.position = Vector2(19, 7)
			forward_page.visible = true
			forward_page.position = Vector2(395, 1)
			#chess_data_container.visible = true
			chess_container.visible = true	
			#animated_sprite_2d.visible = true	
			current_page_label.visible = true
			current_page_label.position = Vector2(402, 242)
			current_page_label.text = str(current_page + 1)
	)	
	
	forward_page.pressed.connect(
		func():
			if current_page == total_page - 1:
				return
			else:
				current_page += 1
				current_page = max(0, min(total_page - 1, current_page))
			backward_page.visible = false
			forward_page.visible = false
			chess_data_container.visible = false
			chess_container.visible = false
			animated_sprite_2d.visible = false
			current_page_label.visible = false
			next_page_animated_sprite_2d.play("forward")
			await next_page_animated_sprite_2d.animation_finished
			refresh_gallery()
			backward_page.visible = true
			backward_page.position = Vector2(27, 1)
			forward_page.visible = true
			forward_page.position = Vector2(403, 7)
			#chess_data_container.visible = true
			chess_container.visible = true	
			#animated_sprite_2d.visible = true	
			current_page_label.visible = true
			current_page_label.position = Vector2(410, 248)
			current_page_label.text = str(current_page + 1)
	)
	
	current_page_label.text = str(current_page + 1)
	refresh_gallery()
	
func refresh_gallery():

	# Clean up existing nodes
	for node in chess_container.get_children():
		if node != chess_vbox_container:  # Keep the VBoxContainer
			node.queue_free()
	
	# Clean up VBoxContainer's children
	for node in chess_vbox_container.get_children():
		node.queue_free()
	
	await get_tree().process_frame  # Wait for cleanup to complete
	
	# Setup containers
	chess_container.size = Vector2(180, 180)  # Set appropriate size
	chess_container.clip_contents = true
	chess_vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chess_vbox_container.size_flags_vertical = Control.SIZE_EXPAND_FILL


	chess_container.mouse_filter = Control.MOUSE_FILTER_PASS
	chess_vbox_container.mouse_filter = Control.MOUSE_FILTER_PASS

	# Get player data
	var current_player_data = {}
	var current_player_chess_data = {}
	
	if DataManagerSingleton.player_datas.has(DataManagerSingleton.current_player):
		current_player_data = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]
		if current_player_data.has("chess_stat"):
			current_player_chess_data = current_player_data["chess_stat"]
	
	var chess_displayed_x = 0
	var chess_displayed_xmax = 4
	var chess_hbox_container = null
	
	var current_chess_index := 0
	
	# Create buttons for each chess piece
	for faction_index in DataManagerSingleton.get_chess_data().keys():
		for chess_index in DataManagerSingleton.get_chess_data()[faction_index].keys():
			
			if current_chess_index >= 16 * (current_page + 1) or current_chess_index < 16 * current_page:
				current_chess_index += 1
				continue
			if chess_displayed_x == 0:
				chess_hbox_container = HBoxContainer.new()
				chess_hbox_container.mouse_filter = Control.MOUSE_FILTER_PASS
				chess_hbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				chess_hbox_container.custom_minimum_size = Vector2(40, 40)  # Give enough height
				chess_hbox_container.alignment = BoxContainer.ALIGNMENT_BEGIN

			var chess_button = create_chess_button(faction_index, chess_index, current_player_chess_data)
			if chess_button:
				chess_hbox_container.add_child(chess_button)
			
			chess_displayed_x += 1
			if chess_displayed_x >= chess_displayed_xmax:
				chess_displayed_x = 0
				chess_vbox_container.add_child(chess_hbox_container)
				chess_hbox_container = null
				
			current_chess_index += 1
			
	# Add the last row if it has buttons
	if chess_hbox_container and chess_hbox_container.get_child_count() > 0:
		chess_vbox_container.add_child(chess_hbox_container)

func create_chess_button(faction_index: String, chess_index: String, current_player_chess_data: Dictionary) -> TextureButton:
	var chess_button = TextureButton.new()
	var source_texture = AtlasTexture.new()
	
	# Determine sprite path
	var sprite_path = "res://asset/animation/human/humanSwordMan.tres"  # Default fallback
	
	if not DataManagerSingleton.check_key_valid(DataManagerSingleton.player_datas,[DataManagerSingleton.current_player, "chess_stat", faction_index, chess_index, "buy_count"]):
		sprite_path = "res://asset/animation/human/humanSwordMan.tres"
		chess_button.disabled = true
	elif DataManagerSingleton.check_key_valid(current_player_chess_data, [faction_index, chess_index, "buy_count"]) and current_player_chess_data[faction_index][chess_index]["buy_count"] > 0:
		var test_path = "res://asset/animation/%s/%s%s.tres" % [faction_index, faction_index, chess_index]
		if ResourceLoader.exists(test_path):
			sprite_path = test_path
	else:
		sprite_path = "res://asset/animation/human/humanSwordMan.tres"
		chess_button.disabled = true
	
	# Load texture with error handling
	if ResourceLoader.exists(sprite_path):
		var sprite_frames = load(sprite_path) as SpriteFrames
		if sprite_frames and sprite_frames.has_animation("idle") and sprite_frames.get_frame_count("idle") > 0:
			var frame_texture = sprite_frames.get_frame_texture("idle", 0)
			if frame_texture:
				source_texture.atlas = frame_texture
				source_texture.region = Rect2(6, 12, 20, 20)
				# Setup button properties
				chess_button.texture_normal = source_texture
				chess_button.texture_hover = source_texture
				chess_button.texture_pressed = source_texture
				chess_button.custom_minimum_size = Vector2(40, 40)
				#chess_button.expand_mode = TextureButton.EXPAND_FIT_WIDTH_PROPORTIONAL
				#chess_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				
				# Set metadata and connect signal
				chess_button.set_meta("faction", faction_index)
				chess_button.set_meta("chess_name", chess_index)
				chess_button.z_index = 25
				if chess_button.pressed.connect(_on_chess_button_pressed.bind(chess_button)) != OK:
					print("chess_button.pressed connect fail!")
				chess_button.set_stretch_mode(0)
				chess_button.visible = true
				chess_button.mouse_filter = Control.MOUSE_FILTER_PASS
				
				return chess_button
			else:
				print("Warning: Could not get frame texture - ", sprite_path)
		else:
			print("Warning: Invalid SpriteFrames or no idle animation - ", sprite_path)
	else:
		print("Warning: Resource does not exist - ", sprite_path)
	
	return null

func _on_chess_button_pressed(button: TextureButton):
	chess_data_container.visible = true
	animated_sprite_2d.visible = true
	var faction_index = button.get_meta("faction")
	var chess_index = button.get_meta("chess_name")

	# Check if chess data exists for current player
	if not DataManagerSingleton.check_key_valid(DataManagerSingleton.player_datas,[DataManagerSingleton.current_player, "chess_stat", faction_index, chess_index]):
		chess_data_container.visible = false
		animated_sprite_2d.visible = false
		return

	var current_chess_data = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["chess_stat"][faction_index][chess_index]

	# Check if player owns this chess piece
	if not current_chess_data.has("buy_count") or current_chess_data["buy_count"] == 0:
		chess_data_container.visible = false
		animated_sprite_2d.visible = false
		return
	else:
		# Load and setup animation
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

		# Show UI elements
		chess_data_container.visible = true
		animated_sprite_2d.visible = true

		# Update statistics labels
		update_stat_label(buy_count, current_chess_data, "buy_count")
		update_stat_label(sell_count, current_chess_data, "sell_count")
		update_stat_label(refresh_count, current_chess_data, "refresh_count")
		update_stat_label(max_damage, current_chess_data, "max_damage")
		update_stat_label(max_damage_taken, current_chess_data, "max_damage_taken")
		update_stat_label(max_heal, current_chess_data, "max_heal")
		update_stat_label(max_heal_taken, current_chess_data, "max_heal_taken")
		update_stat_label(critical_attack_count, current_chess_data, "critical_attack_count")
		update_stat_label(evase_attack_count, current_chess_data, "evase_attack_count")
		update_stat_label(cast_spell_count, current_chess_data, "cast_spell_count")

func update_stat_label(label: Label, chess_data: Dictionary, stat_key: String):
	"""Helper function to update stat labels"""
	if chess_data.has(stat_key):
		label.text = stat_key + " : " + str(chess_data[stat_key])
	else:
		label.text = stat_key + " : /"

func _on_animated_sprite_2d_animation_finished() -> void:
	# Play a random animation when current animation finishes
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.get_animation_names().size() > 0:
		var rand_anim_index = randi_range(0, animated_sprite_2d.sprite_frames.get_animation_names().size() - 1)
		var rand_anim_name = animated_sprite_2d.sprite_frames.get_animation_names()[rand_anim_index]
		animated_sprite_2d.play(rand_anim_name)

func _on_back_button_pressed() -> void:
	to_menu_scene.emit()

func _on_reset_button_pressed() -> void:

	var alternative_choice = alternative_choice_scene.instantiate()
	alternative_choice.get_node("Label").text = "Reset data?"
	alternative_choice.get_node("button_container/Button1").text = "Yes"
	alternative_choice.get_node("button_container/Button2").text = "No"
	add_child(alternative_choice)
	await alternative_choice.choice_made
	alternative_choice.visible = false
	if alternative_choice.get_meta("choice") == 1:
		DataManagerSingleton.clean_player_data(DataManagerSingleton.current_player)
		refresh_gallery()
	elif alternative_choice.get_meta("choice") == 2:
		pass
	alternative_choice.queue_free()		
	


func _on_tetris_button_pressed() -> void:
	to_tetris_scene.emit()


func _on_snake_game_button_pressed() -> void:
	to_snake_scene.emit()


func _on_minesweep_game_button_pressed() -> void:
	to_minesweep_scene.emit()
