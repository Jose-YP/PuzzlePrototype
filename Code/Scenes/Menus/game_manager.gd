extends CanvasLayer

@export var Newgrounds: bool = true
@export var MusicOn: bool = true

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %Zap, %LevelUp, %ETC, %AllFall]
@onready var BreakSFX: Array[Node] = $BoardSFX/BreakSFX.get_children()
@onready var MenuSFX: Array[Node] = $BoardMusic.get_children()
@onready var ETCMusic: Array[AudioStreamPlayer] = [$ETCMusic/MainMenu,$ETCMusic/EndRun]
@onready var BoardMusic: Array[Node] = $BoardMusic.get_children()
@onready var currentScene = $MainMenu
@onready var editableMusicBus = AudioServer.get_bus_index("ManageMusic")

#Scenes for loading
const boardScene: String = "res://Scenes/Board&Beads/Board.tscn"
const optionsScene: String = "res://Scenes/MainMenu/options_menu.tscn"
#Non Loading Scenes
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const loadingScreen = preload("res://Scenes/Constants/ETC/load_screen.tscn")

var unpausing: bool = false
var currentSong: AudioStreamPlayer
var loopVal: float = 0.0
var loopedSong: bool = false

func _ready() -> void:
	BoardSFX[0].play()
	BoardSFX[0].stop()
	BoardSFX[1].play()
	BoardSFX[1].stop()
	ready_playing(ETCMusic[0])
	FinalGlobal.finalReady(Newgrounds)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("Pause") and not unpausing:
		play_menu_sfx(3)
		var currently = get_tree().paused
		get_tree().paused = not currently
		$PauseScreen.visible = not currently
		$PauseScreen.play_sfx()
	elif Input.is_action_just_pressed("Pause"):
		unpausing = false
	
	if loopVal > currentSong.get_playback_position():
		print("YOU LOOPED")
		loopedSong = true
		
		
	loopVal = currentSong.get_playback_position()

#-----------------------------------------
#SCENE SWITCHING
#-----------------------------------------
#For non-loading scenes
func changeScene(scene) -> void:
	Globals.save.save(Newgrounds)
	Globals.userPrefs.save(Newgrounds)
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
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)
	$PauseScreen.entered_board(true)
	

func option_scene_loaded(scene) -> void:
	changeScene(scene)
	currentScene.connect("main",back_to_menu)
	currentScene.connect("makeNoise",_on_option_make_noise)

func back_to_menu() -> void:
	changeScene(mainMenuScene)
	currentScene.connect("switchOptions", _on_main_menu_switch_options)
	currentScene.connect("switchPlay", _on_main_menu_switch_play)
	currentScene.connect("boardSFX", _on_board_play_sfx)
	currentScene.connect("playSFX", play_menu_sfx)

func play_menu_sfx(index) -> void:
	MenuSFX[index].play()

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------
func _on_main_menu_switch_options() -> void:
	loadScene(optionsScene)

func _on_main_menu_switch_play() -> void:
	MenuSFX[1].play()
	loadScene(boardScene)

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index) -> void:
	BoardSFX[index].play()

func _on_board_play_break_sfx(index) -> void:
	BreakSFX[index].play()

func on_board_retry(onBoard = true) -> void:
	if onBoard:
		loadScene(boardScene)

#-----------------------------------------
#OPTION MENU SIGNALS
#-----------------------------------------
func _on_option_make_noise() -> void:
	%ETC.play()

#-----------------------------------------
#OTHER
#-----------------------------------------
func _on_pause_screen_play_sfx() -> void:
	unpausing = true
	MenuSFX[3].play()

func ready_playing(song) -> void:
	var fadeIn = create_tween().set_ease(Tween.EASE_IN)
	fadeIn.tween_method(fade_music, 0.0, 1.0, 10)
	currentSong = song
	song.play()

func play_music(song) -> void:
	if MusicOn:
		var MusicBus = AudioServer.get_bus_index("ManageMusic")
		var fadeOut = create_tween().set_ease(Tween.EASE_IN)
		fadeOut.tween_method(MusicBus.set_bus_volume_db, linear_to_db(1.0), linear_to_db(0.0), .5)
		currentSong.stop()
		song.play()
		currentSong = song
		fadeOut.tween_method(MusicBus.set_bus_volume_db, linear_to_db(0.0), linear_to_db(1.0), .5)

func fade_music(value) -> void:
	AudioServer.set_bus_volume_db(editableMusicBus, linear_to_db(value))
