# AudioManager.gd
# --- SINGLETON SCRIPT ---
# This script should be attached to the root node of a scene that is configured as an Autoload.
# It manages all BGM and SFX, creating a player pool at runtime for efficient playback.
extends Node

# --- Member Variables ---

# Dictionaries to store the preloaded audio resources.
@export var bgm_resources: Dictionary = {
	"menu": preload("res://asset/audio/RPG-Music-Pack/02-Home_Town.wav"),
	"battle": preload("res://asset/audio/RPG-Music-Pack/06-Battle.wav")
}

@export var sfx_resources: Dictionary = {
	"human": {
		"mage": {
			"melee_attack_started": preload("res://asset/audio/90_RPG_Battle_SFX/19_Slash_01.wav"),
			"ranged_attack_started": preload("res://asset/audio/90_RPG_Battle_SFX/41_bow_draw_01.wav"),
			"spell_casted": preload("res://asset/audio/50_RPG_Battle_Magic_SFX/04_Fire_explosion_04_medium.wav"),
			"damage_taken": preload("res://asset/audio/90_RPG_Battle_SFX/09_Impact_01.wav"),
			"critical_damage_taken": preload("res://asset/audio/90_RPG_Battle_SFX/09_Impact_01.wav"),
			"attack_evased": preload("res://asset/audio/90_RPG_Battle_SFX/35_Miss_Evade_02.wav"),
			"projectile_lauched": preload("res://asset/audio/90_RPG_Battle_SFX/47_Bow_hit_01.wav"),
			"is_died": preload("res://asset/audio/90_RPG_Battle_SFX/69_Enemy_death_01.wav")
		}
	},
	"default": {
		"melee_attack_started": preload("res://asset/audio/90_RPG_Battle_SFX/19_Slash_01.wav"),
		"ranged_attack_started": preload("res://asset/audio/90_RPG_Battle_SFX/41_bow_draw_01.wav"),
		"spell_casted": preload("res://asset/audio/50_RPG_Battle_Magic_SFX/04_Fire_explosion_04_medium.wav"),
		"damage_taken": preload("res://asset/audio/90_RPG_Battle_SFX/09_Impact_01.wav"),
		"critical_damage_taken": preload("res://asset/audio/90_RPG_Battle_SFX/09_Impact_01.wav"),
		"attack_evased": preload("res://asset/audio/90_RPG_Battle_SFX/35_Miss_Evade_02.wav"),
		"projectile_lauched": preload("res://asset/audio/90_RPG_Battle_SFX/47_Bow_hit_01.wav"),
		"is_died": preload("res://asset/audio/90_RPG_Battle_SFX/69_Enemy_death_01.wav")
	}
}

# The key for the default BGM.
@export var default_bgm_key: String = "main_menu"

# The number of SFX players to create in the pool.
@export var sfx_pool_size: int = 10

# Node references.
var bgm_player

# This array will be populated in the _ready() function.
var sfx_player_pool: Array[AudioStreamPlayer] = []

# --- Godot Lifecycle Methods ---

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Dynamically create and add SFX players to the pool.
	bgm_player = AudioStreamPlayer.new()
	bgm_player.set_volume_db(-20)
	add_child(bgm_player)
	bgm_player.set_bus("BGM")

	for i in range(sfx_pool_size):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.set_volume_db(0)
		sfx_player.name = "SFXPlayer_" + str(i + 1)
		sfx_player.set_bus("SFX")
		add_child(sfx_player)
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

#summoned_character.spell_casted.connect(AudioManagerSingleton.play_sfx.bind("spell_casted"))
#summoned_character.ranged_attack_started.connect(AudioManagerSingleton.play_sfx.bind("ranged_attack_started"))
#summoned_character.melee_attack_started.connect(AudioManagerSingleton.play_sfx.bind("melee_attack_started"))
#summoned_character.projectile_lauched.connect(AudioManagerSingleton.play_sfx.bind("projectile_lauched"))
#summoned_character.damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("damage_taken"))
#summoned_character.critical_damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("critical_damage_taken"))
#summoned_character.heal_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("heal_taken"))
#summoned_character.attack_evased.connect(AudioManagerSingleton.play_sfx.unbind(1).bind("attack_evased"))
#summoned_character.is_died.connect(AudioManagerSingleton.play_sfx.bind("is_died"))
	
func play_sfx(obstacle: Obstacle, action: String):
	var keys = [obstacle.faction, obstacle.chess_name, action]
	
	var sfx_stream: AudioStream
	
	if not DataManagerSingleton.check_key_valid(sfx_resources, keys):
		sfx_stream = sfx_resources["default"][action]
	else:
		sfx_stream = sfx_resources[obstacle.faction][obstacle.chess_name][action]
	
	for player in sfx_player_pool:
		if not player.is_playing():
			player.stream = sfx_stream
			player.play()
			print("Playing SFX for: ", str(keys), " on player ", player.name)
			return
	
	push_warning("No available SFX players in the pool. Could not play: " + str(keys))
