extends CanvasLayer

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %ETC]
@onready var MenuSFX: Array[AudioStreamPlayer] = [%MenuMove, %MenuConfirm,
 %MenuDeselect, %Pause]
@onready var music: AudioStreamPlayer = $Music/Music
@onready var currentScene = $MainMenu

const boardScene = preload("res://Scenes/Board&Beads/Board.tscn")
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const optionsScene = preload("res://Scenes/MainMenu/options_menu.tscn")

#-----------------------------------------
#SCENE SWITCHING
#-----------------------------------------
func changeScene(scene) -> void:
	Globals.save.save()
	Globals.userPrefs.save()
	currentScene.queue_free()
	
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	currentScene = newScene

func back_to_menu():
	changeScene(mainMenuScene)

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------
func _on_main_menu_switch_options():
	changeScene(optionsScene)
	currentScene.connect("main",back_to_menu)
	currentScene.connect("makeNoise",_on_option_make_noise)
	currentScene.connect("testMusic",_on_option_test_music)

func _on_main_menu_switch_play():
	changeScene(boardScene)
	currentScene.connect("playSFX",_on_board_play_sfx)
	currentScene.Fail.connect("main",back_to_menu)
	currentScene.Fail.connect("retry",on_board_retry)

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index):
	BoardSFX[index].play()

func on_board_retry():
	pass

#-----------------------------------------
#OPTION MENU SIGNALS
#-----------------------------------------
func _on_option_make_noise():
	%ETC.play()

func _on_option_test_music():
	music.play()
