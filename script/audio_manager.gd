# AudioManager.gd
# --- SINGLETON SCRIPT ---
# This script should be attached to the root node of a scene that is configured as an Autoload.
# It manages all BGM and SFX, creating a player pool at runtime for efficient playback.
extends Node

# --- Member Variables ---

# Dictionaries to store the preloaded audio resources.
@export var bgm_resources: Dictionary = {
	"main_menu": preload("res://audio/music/main_theme.ogg"),
	"battle": preload("res://audio/music/battle_theme.ogg")
}

@export var sfx_resources: Dictionary = {
	"alliance": {
		"knight": {
			"attack": preload("res://audio/sfx/sword_swing.wav"),
			"death": preload("res://audio/sfx/human_death.wav")
		},
		"mage": {
			"attack": preload("res://audio/sfx/fireball.wav")
		}
	},
	"horde": {
		"grunt": {
			"attack": preload("res://audio/sfx/axe_swing.wav"),
			"death": preload("res://audio/sfx/orc_death.wav")
		}
	}
}

# The key for the default BGM.
@export var default_bgm_key: String = "main_menu"

# The number of SFX players to create in the pool.
@export var sfx_pool_size: int = 10

# Node references.
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_player_pool_container: Node = $SFXPlayerPool

# This array will be populated in the _ready() function.
var sfx_player_pool: Array[AudioStreamPlayer] = []

# --- Godot Lifecycle Methods ---

func _ready():
	# Dynamically create and add SFX players to the pool.
	for i in range(sfx_pool_size):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_" + str(i + 1)
		sfx_player_pool_container.add_child(sfx_player)
		sfx_player_pool.append(sfx_player)
	print("AudioManager (Singleton) is ready. Created ", sfx_pool_size, " SFX players.")

# --- Public Methods ---

func play_music(music_key: String):
	var music_stream: AudioStream
	if bgm_resources.has(music_key):
		music_stream = bgm_resources[music_key]
	else:
		push_warning("BGM key not found: '" + music_key + "'. Playing default BGM.")
		if bgm_resources.has(default_bgm_key):
			music_stream = bgm_resources[default_bgm_key]
		else:
			push_error("Default BGM key not found: '" + default_bgm_key + "'. BGM cannot be played.")
			return

	if bgm_player.stream == music_stream and bgm_player.is_playing():
		return

	bgm_player.stop()
	bgm_player.stream = music_stream
	bgm_player.play()
	print("Playing BGM with key: ", music_key)

func play_sfx(faction: String, chess_name: String, action: String):
	var keys = [faction, chess_name, action]
	
	if not check_key_valid(sfx_resources, keys):
		push_warning("SFX resource not found for: " + str(keys))
		return
	
	var sfx_stream: AudioStream = sfx_resources[faction][chess_name][action]
	
	for player in sfx_player_pool:
		if not player.is_playing():
			player.stream = sfx_stream
			player.play()
			print("Playing SFX for: ", str(keys), " on player ", player.name)
			return
	
	push_warning("No available SFX players in the pool. Could not play: " + str(keys))

# --- Helper Methods ---

func check_key_valid(dict: Dictionary, keys: Array) -> bool:
	var current_level = dict
	for i in range(keys.size()):
		var key = keys[i]
		if not current_level.has(key):
			return false
		current_level = current_level[key]
		if i < keys.size() - 1 and not typeof(current_level) == TYPE_DICTIONARY:
			return false
	return true
