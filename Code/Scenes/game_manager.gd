extends CanvasLayer

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %Twinkle, %ETC]
@onready var MenuSFX: Array[AudioStreamPlayer] = [%MenuMove, %MenuConfirm,
 %MenuDeselect, %Pause]
@onready var music: AudioStreamPlayer = $Music/Music
@onready var currentScene = $"Main Menu"

const boardScene = preload("res://Scenes/Board&Beads/Board.tscn")
const mainMenuScene = preload("res://Scenes/MainMenu/MainMenu.tscn")
const optionsScene = preload("res://Scenes/MainMenu/options_menu.tscn")



#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	print("READY")
	print(Globals.sort_scores())

#-----------------------------------------
#SCENE SWITCHING
#-----------------------------------------
func changeScene(scene) -> void:
	Globals.currentSave.save()
	currentScene.queue_free()
	
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	currentScene = newScene

#-----------------------------------------
#MAIN MENU SIGNALS
#-----------------------------------------

#-----------------------------------------
#BOARD SIGNALS
#-----------------------------------------
func _on_board_play_sfx(index):
	BoardSFX[index].play()

#-----------------------------------------
#OPTION MENU SIGNALS
#-----------------------------------------
func _on_option_make_noise():
	%ETC.play()


func _on_main_menu_switch_options():
	pass # Replace with function body.


func _on_main_menu_switch_play():
	pass # Replace with function body.
