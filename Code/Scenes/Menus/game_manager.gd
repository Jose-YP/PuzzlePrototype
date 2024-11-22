extends CanvasLayer

@export var Newgrounds: bool = true
@export var MusicOn: bool = true
@export var resetScores: bool = false
@export_range(0,.5,.01)  var pitchShift: float = .3

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %Zap, %LevelUp, %ETC, %AllFall, %Win]
@onready var BreakSFX: Array[Node] = $BoardSFX/BreakSFX.get_children()
@onready var MenuSFX: Array[Node] = $MenuSFX.get_children()
@onready var BoardMusic: Array[Node] = $BoardMusic.get_children()
@onready var ETCMusic: Array[AudioStreamPlayer] = [$ETCMusic/MainMenu,$ETCMusic/EndRun]
@onready var currentScene: Node = $MainMenu
@onready var editableMusicBus = AudioServer.get_bus_index("ManageMusic")

#Scenes for loading
const boardScene: String = "res://Scenes/Board&Beads/Board.tscn"
const optionsScene: String = "res://Scenes/MainMenu/options_menu.tscn"
#Non Loading Scenes
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const loadingScreen = preload("res://Scenes/Constants/load_screen.tscn")

var currentSong: AudioStreamPlayer
var loopVal: float = 0.0
var reset_controls: bool = false
var unpausing: bool = false
var loopedSong: bool = false
var usingBoardSongs: bool = false
var readied: bool = false

#-----------------------------------------
#INITALIZATION AND PROCESSING
#-----------------------------------------
func _ready() -> void:
	await get_tree().create_timer(1).timeout
	
	print("HUH")
	FinalGlobal.finalReady(Newgrounds)
	
	#if resetScores:
		#Globals.save.reset_scores() 
	
	#if Globals.all_black():
		#Globals.save.reset_colors()
		#NGSaveSetup.sync_files()
	
	await get_tree().create_timer(1).timeout
	ready_playing(ETCMusic[0])
	var loadedTween = get_tree().create_tween()
	loadedTween.tween_property($ColorRect, "modulate", Color.TRANSPARENT, 1.0)
	$MainMenu.emit_signal("readied")
	readied = true

func _process(_delta) -> void:
	if readied:
		if Input.is_action_just_pressed("Pause") and not unpausing:
			currentSong.stream_paused = true
			play_menu_sfx(3)
			var currently = get_tree().paused
			get_tree().paused = not currently
			$PauseScreen.visible = not currently
			$PauseScreen.play_sfx()
			
		elif Input.is_action_just_pressed("Pause"):
			unpausing = false
	
	if MusicOn and currentSong != null and usingBoardSongs:
		if loopVal > currentSong.get_playback_position():
			if loopedSong:
				#If on first song, it'll get to the last song, otherwise go backwards
				play_music(BoardMusic[BoardMusic.find(currentSong) - 1])
			else:
				loopedSong = true
		
		loopVal = currentSong.get_playback_position()

#-----------------------------------------
#SCENE SWITCHING
#-----------------------------------------
#For non-loading scenes
func changeScene(scene) -> void:
	BG_react(Globals.TempModes.DEFAULT)
	Globals.save.save(Newgrounds)
	currentScene.queue_free()
	
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	$".".move_child(newScene,1)
	currentScene = newScene
	$PauseScreen.entered_board(false)

#For loading scenes
func loadScene(scene) -> void:
	changeScene(loadingScreen)
	currentScene.next_scene = scene
	match scene:
		boardScene:
			currentScene.connect("finished", board_scene_loaded)
		optionsScene:
			currentScene.connect("finished", option_scene_loaded)

func board_scene_loaded(scene) -> void:
	changeScene(scene)
	currentScene.connect("playSFX",_on_board_play_sfx)
	currentScene.connect("playBreak", _on_board_play_break_sfx)
	currentScene.connect("brokenBeadSFX",bead_break_SFX)
	currentScene.connect("dying", fail_SFX)
	currentScene.connect("died", fail_song)
	currentScene.connect("switchMode", switch_mode)
	currentScene.connect("modeReact", BG_react)
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)
	currentScene.HiScoreScene.connect("menuSFX", play_menu_sfx)
	$PauseScreen.entered_board(true)
	BoardMusic.shuffle()
	play_music(BoardMusic[0])

func option_scene_loaded(scene) -> void:
	changeScene(scene)
	currentScene.connect("main",back_to_menu)
	currentScene.connect("makeNoise",_on_option_make_noise)
	currentScene.connect("switchBG", switch_mode)

func back_to_menu() -> void:
	play_menu_sfx(2)
	changeScene(mainMenuScene)
	currentScene.connect("switchOptions", _on_main_menu_switch_options)
	currentScene.connect("switchPlay", _on_main_menu_switch_play)
	currentScene.connect("playSFX", play_menu_sfx)
	if currentSong != ETCMusic[0]:
		play_music(ETCMusic[0])

func play_menu_sfx(index) -> void:
	MenuSFX[index].play()

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------
func _on_main_menu_switch_options() -> void:
	loadScene(optionsScene)

func _on_main_menu_switch_play() -> void:
	loadScene(boardScene)

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index) -> void:
	BoardSFX[index].play()

func _on_board_play_break_sfx(index) -> void:
	BreakSFX[index].play()

func on_board_retry(allowed = true) -> void:
	play_menu_sfx(1)
	if allowed:
		loadScene(boardScene)

func _on_pause_screen_quit(allowed = true) -> void:
	if allowed:
		back_to_menu()

#func play_beggining_load() -> void:
	#%LevelUp.pitch_scale = .65
	#%LevelUp.play()
	#
	#await %LevelUp.finished
	#%LevelUp.pitch_scale = 1

func bead_break_SFX() -> void:
	var pitch = AudioServer.get_bus_effect(6, 0)
	pitch.pitch_scale = randf_range(1 - pitchShift, 1 + pitchShift)
	%Break.play()

func fail_SFX() -> void:
	var pitchTween = create_tween().set_ease(Tween.EASE_OUT)
	
	%RunOver.play()
	pitchTween.tween_method(tweening_pitch, 1.55, .7, .07) 
	
	await %RunOver.finished

func fail_song() -> void:
	play_music(ETCMusic[1])

#-----------------------------------------
#OPTION MENU SIGNALS
#-----------------------------------------
func _on_option_make_noise() -> void:
	%ETC.play()

#-----------------------------------------
#MUSIC
#-----------------------------------------
func ready_playing(song) -> void:
	if MusicOn:
		var fadeIn = create_tween().set_ease(Tween.EASE_IN)
		fadeIn.tween_method(fade_music, 0.0, 1.0, 10)
		currentSong = song
		song.play()

func play_music(song) -> void:
	if MusicOn:
		var fadeOut = create_tween().set_ease(Tween.EASE_IN)
		fadeOut.tween_method(fade_music, 1.0, 0.0, 1)
		await fadeOut.finished
		
		currentSong.stop()
		loopVal = 0.0
		song.play()
		loopedSong = false
		print(song)
		currentSong = song
		usingBoardSongs = true if BoardMusic.find(currentSong) != -1 else false
		
		fadeOut = create_tween().set_ease(Tween.EASE_IN)
		fadeOut.tween_method(fade_music, 0.0, 1.0, 5)

func _on_pause_screen_unpause_song() -> void:
	currentSong.stream_paused = false

func fade_music(value) -> void:
	AudioServer.set_bus_volume_db(editableMusicBus, linear_to_db(value))

#-----------------------------------------
#OTHER
#-----------------------------------------
func _on_pause_screen_play_sfx() -> void:
	unpausing = true
	MenuSFX[3].play()

func tweening_pitch(ammount, busLocation: int = 7, effectLocation: int = 1) -> void:
	var pitch = AudioServer.get_bus_effect(busLocation, effectLocation)
	pitch.pitch_scale = ammount

func switch_mode() -> void:
	$ParallaxBackground.switch_mode()

func BG_react(mode: Globals.TempModes) -> void:
	match mode:
		Globals.TempModes.DANGER:
			$ParallaxBackground.currentMode = Globals.TempModes.DANGER
		Globals.TempModes.BREAKER:
			$ParallaxBackground.currentMode = Globals.TempModes.BREAKER
		Globals.TempModes.DEFAULT:
			$ParallaxBackground.currentMode = Globals.TempModes.DEFAULT
	
	$ParallaxBackground.color_change()
