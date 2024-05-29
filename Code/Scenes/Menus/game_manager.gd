extends CanvasLayer

@export var Newgrounds: bool = true

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %Zap, %LevelUp, %ETC, %AllFall]
@onready var BreakSFX: Array[AudioStreamPlayer] = [%Roar, %Roar2, %Roar3]
@onready var MenuSFX: Array[AudioStreamPlayer] = [%MenuMove, %MenuConfirm,
 %MenuDeselect, %Pause]
@onready var music: AudioStreamPlayer = $Music/Music
@onready var currentScene = $MainMenu

#Scenes for loading
const boardScene: String = "res://Scenes/Board&Beads/Board.tscn"
const optionsScene: String = "res://Scenes/MainMenu/options_menu.tscn"
#Non Loading Scenes
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const loadingScreen = preload("res://Scenes/Constants/ETC/load_screen.tscn")

var unpausing: bool = false

func _ready():
	FinalGlobal.finalReady(Newgrounds)

func _process(_delta):
	if Input.is_action_just_pressed("Pause") and not unpausing:
		play_menu_sfx(3)
		var currently = get_tree().paused
		get_tree().paused = not currently
		$PauseScreen.visible = not currently
	elif Input.is_action_just_pressed("Pause"):
		unpausing = false

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
	$PauseScreen.retryDissplay.hide()

#For loading scenes
func loadScene(scene) -> void:
	changeScene(loadingScreen)
	currentScene.next_scene = scene
	match scene:
		boardScene:
			currentScene.connect("finished", board_scene_loaded)
		optionsScene:
			currentScene.connect("finished", option_scene_loaded)

func board_scene_loaded(scene):
	changeScene(scene)
	currentScene.connect("playSFX",_on_board_play_sfx)
	currentScene.connect("playBreak", _on_board_play_break_sfx)
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)
	$PauseScreen.retryDissplay.show()

func option_scene_loaded(scene):
	changeScene(scene)
	currentScene.connect("main",back_to_menu)
	currentScene.connect("makeNoise",_on_option_make_noise)
	currentScene.connect("testMusic",_on_option_test_music)

func back_to_menu():
	changeScene(mainMenuScene)
	currentScene.connect("switchOptions", _on_main_menu_switch_options)
	currentScene.connect("switchPlay", _on_main_menu_switch_play)
	currentScene.connect("boardSFX", _on_board_play_sfx)
	currentScene.connect("playSFX", play_menu_sfx)

func play_menu_sfx(index):
	MenuSFX[index].play()

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------
func _on_main_menu_switch_options():
	loadScene(optionsScene)

func _on_main_menu_switch_play():
	MenuSFX[1].play()
	loadScene(boardScene)

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index):
	BoardSFX[index].play()

func _on_board_play_break_sfx(index):
	BreakSFX[index].play()

func on_board_retry():
	if currentScene == boardScene:
		loadScene(boardScene)

#-----------------------------------------
#OPTION MENU SIGNALS
#-----------------------------------------
func _on_option_make_noise():
	%ETC.play()

func _on_option_test_music():
	music.play()

#-----------------------------------------
#OTHER
#-----------------------------------------
func _on_pause_screen_play_sfx():
	unpausing = true
	MenuSFX[3].play()
