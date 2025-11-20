# AudioManager.gd
# --- SINGLETON SCRIPT ---
# This script should be attached to the root node of a scene that is configured as an Autoload.
# It manages all BGM and SFX, creating a player pool at runtime for efficient playback.
extends Node

# --- Member Variables ---

# Dictionaries to store the preloaded audio resources.
@export var bgm_resources: Dictionary = {
	"menu": preload("res://asset/audio/Heroes of Might and Magic III/01 THE PRIDE OF ERATHIA.wav"),
	"battle": preload("res://asset/audio/Heroes of Might and Magic III/03 FOR BLOOD & HONOR.wav"),
	"round_win": preload("res://asset/audio/Heroes of Might and Magic III/Mp3/Win Battle.mp3"),
	"round_lose": preload("res://asset/audio/Heroes of Might and Magic III/Mp3/LoseCombat.mp3"),
	"game_win": preload("res://asset/audio/Heroes of Might and Magic III/Mp3/Win Scenario.mp3"),
	"game_lose": preload("res://asset/audio/Heroes of Might and Magic III/Mp3/Lose Campain.mp3"),
	"0": preload("res://asset/audio/Heroes of Might and Magic III/01 A SONG FOR CATHERINE.wav"),
	"1": preload("res://asset/audio/Heroes of Might and Magic III/01 CAPTURING THE LANDS.wav"),
	"2": preload("res://asset/audio/Heroes of Might and Magic III/01 ESCAPE FROM NIGHON.wav"),
	"3": preload("res://asset/audio/Heroes of Might and Magic III/01 THE PRIDE OF ERATHIA.wav"),
	"4": preload("res://asset/audio/Heroes of Might and Magic III/02 FIGHTING FOR THE KING.wav"),
	"5": preload("res://asset/audio/Heroes of Might and Magic III/02 NO REST FOR THE LICH KING.wav"),
	"6": preload("res://asset/audio/Heroes of Might and Magic III/02 SEARCHING THE HIGHLANDS.wav"),
	"7": preload("res://asset/audio/Heroes of Might and Magic III/02 THE DRUID & THE RANGER.wav"),
	"8": preload("res://asset/audio/Heroes of Might and Magic III/03 CROSSING AT THE STRONGHOLD.wav"),
	"9": preload("res://asset/audio/Heroes of Might and Magic III/03 FOR BLOOD & HONOR.wav"),
	"10": preload("res://asset/audio/Heroes of Might and Magic III/03 ROLAND'S REPRISE.wav"),
	"11": preload("res://asset/audio/Heroes of Might and Magic III/03 THE HERETIC'S PLAN.wav"),
	"12": preload("res://asset/audio/Heroes of Might and Magic III/04 A COLD CRUSADE.wav"),
	"13": preload("res://asset/audio/Heroes of Might and Magic III/04 SECRET OF THE GRAIL ARTIFACT.wav"),
	"14": preload("res://asset/audio/Heroes of Might and Magic III/04 THE BATTLE OF ANTAGARICH.wav"),
	"15": preload("res://asset/audio/Heroes of Might and Magic III/04 THE KINGDOM OF TATALIA.wav"),
	"16": preload("res://asset/audio/Heroes of Might and Magic III/05 A CONTEMPLATION OF STRATEGY.wav"),
	"17": preload("res://asset/audio/Heroes of Might and Magic III/05 BEAUTY IN THE DARKEST OF THINGS.wav"),
	"18": preload("res://asset/audio/Heroes of Might and Magic III/05 QUEST TO FREE KING ROLAND.wav"),
	"19": preload("res://asset/audio/Heroes of Might and Magic III/05 THE WIZARD & THE ALCHEMIST.wav"),
	"20": preload("res://asset/audio/Heroes of Might and Magic III/06 A PASSAGE TO BRACADA.wav"),
	"21": preload("res://asset/audio/Heroes of Might and Magic III/06 A QUICK STROLL THROUGH THE KINGDOM.wav"),
	"22": preload("res://asset/audio/Heroes of Might and Magic III/06 PASSAGE TO THE INFERNO.wav"),
	"23": preload("res://asset/audio/Heroes of Might and Magic III/06 THE NECROPOLIS.wav"),
	"24": preload("res://asset/audio/Heroes of Might and Magic III/07 AVLEE'S PROMENADE.wav"),
	"25": preload("res://asset/audio/Heroes of Might and Magic III/07 LIZARD MARSHES.wav"),
	"26": preload("res://asset/audio/Heroes of Might and Magic III/07 SNEAKING THROUGH ERATHIA.wav"),
	"27": preload("res://asset/audio/Heroes of Might and Magic III/07 THE REIGN OF THE ORCS.wav"),
	"28": preload("res://asset/audio/Heroes of Might and Magic III/08 A HERO'S VICTORY.wav"),
	"29": preload("res://asset/audio/Heroes of Might and Magic III/08 THE ALTAR OF MAGIC.wav"),
	"30": preload("res://asset/audio/Heroes of Might and Magic III/08 THE DEMONIAC'S ODYSSEY.wav"),
	"31": preload("res://asset/audio/Heroes of Might and Magic III/08 THE SEARCH FOR GREATER LANDS.wav"),
	"32": preload("res://asset/audio/Heroes of Might and Magic III/09 CONTESTED LANDS.wav"),
	"33": preload("res://asset/audio/Heroes of Might and Magic III/09 THE OCEANS OF ERATHIA.wav"),
	"34": preload("res://asset/audio/Heroes of Might and Magic III/09 WELCOME TO STEADWICK.wav"),
	"35": preload("res://asset/audio/Heroes of Might and Magic III/10 KING ROLAND'S RETURN.wav"),
	"36": preload("res://asset/audio/Heroes of Might and Magic III/10 WANDERING THROUGH THE DESERT.wav"),
	"37": preload("res://asset/audio/Heroes of Might and Magic III/11 PLANNING GRYPHONHEART'S DEMISE.wav"),
	"38": preload("res://asset/audio/Heroes of Might and Magic III/12 THE NECROMANCERS OF DEYJA.wav"),
	"39": preload("res://asset/audio/Heroes of Might and Magic III/13 THE PILGRIMAGE TO KREWOLD.wav"),
	"40": preload("res://asset/audio/Heroes of Might and Magic III/14 NO REST FOR CRUSADERS.wav")
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
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] or DataManagerSingleton.current_player == "debug":
		print("AudioManager (Singleton) is ready. Created ", sfx_pool_size, " SFX players.")

# --- Public Methods ---

func play_music(music_key: String):
	var music_stream: AudioStream
	if music_key == "random":
		var bgm_index: int = randi_range(0, 40)
		music_key = str(bgm_index)
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

	if ["round_win", "round_lose", "game_win", "game_lose"].has(music_key):
		bgm_player.play()
	else:
		bgm_player.play(2.0)
		
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] or DataManagerSingleton.current_player == "debug":
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
	
func play_sfx(chess: Chess, action: String):
	var keys = [chess.faction, chess.chess_name, action]
	
	var sfx_stream: AudioStream
	
	if not DataManagerSingleton.check_key_valid(sfx_resources, keys):
		sfx_stream = sfx_resources["default"][action]
	else:
		sfx_stream = sfx_resources[chess.faction][chess.chess_name][action]
	
	for player in sfx_player_pool:
		if not player.is_playing():
			player.stream = sfx_stream
			player.play()
			if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] or DataManagerSingleton.current_player == "debug":
				print("Playing SFX for: ", str(keys), " on player ", player.name)
			return
	
	push_warning("No available SFX players in the pool. Could not play: " + str(keys))
