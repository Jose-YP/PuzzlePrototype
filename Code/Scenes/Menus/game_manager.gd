extends CanvasLayer

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %Zap, %LevelUp, %ETC]
@onready var MenuSFX: Array[AudioStreamPlayer] = [%MenuMove, %MenuConfirm,
 %MenuDeselect, %Pause]
@onready var music: AudioStreamPlayer = $Music/Music
@onready var currentScene = $MainMenu

#Scenes for loading
const boardScene: String ="res://Scenes/Board&Beads/Board.tscn"
#Non Loading Scenes
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const optionsScene = preload("res://Scenes/MainMenu/options_menu.tscn")
const loadingScreen = preload("res://Scenes/Constants/ETC/load_screen.tscn")

var unpausing: bool = false

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
	Globals.save.save()
	Globals.userPrefs.save()
	currentScene.queue_free()
	
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	$".".move_child(currentScene,1)
	currentScene = newScene

#For loading scenes
func loadScene(scene) -> void:
	changeScene(loadingScreen)
	currentScene.next_scene = scene
	currentScene.connect("finished", board_scene_loaded)

func board_scene_loaded(scene):
	changeScene(scene)
	currentScene.connect("playSFX",_on_board_play_sfx)
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)

func back_to_menu():
	changeScene(mainMenuScene)
	currentScene.connect("switchOptions", _on_main_menu_switch_options)
	currentScene.connect("switchPlay", _on_main_menu_switch_play)
	currentScene.connect("boardSFX", _on_board_play_sfx)

func play_menu_sfx(index):
	MenuSFX[index].play()

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------
func _on_main_menu_switch_options():
	changeScene(optionsScene)
	currentScene.connect("main",back_to_menu)
	currentScene.connect("makeNoise",_on_option_make_noise)
	currentScene.connect("testMusic",_on_option_test_music)

func _on_main_menu_switch_play():
	loadScene(boardScene)

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index):
	BoardSFX[index].play()

func on_board_retry():
	currentScene.reload_current_scene()
	currentScene.connect("playSFX",_on_board_play_sfx)
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)

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
