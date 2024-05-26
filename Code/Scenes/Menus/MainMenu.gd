extends Control

@export var newH2pPosition: Vector2 = Vector2(25,40)
@export var orgH2pPosition: Vector2 = Vector2(25,-700)

signal switchPlay
signal switchOptions
signal switchTutorial
signal playSFX(index)
signal boardSFX(index)

var can: bool = false
var moved: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	$Buttons/Play.grab_focus()
	can = true

func _process(_delta):
	if not moved:
		$How2Play.position = orgH2pPosition
		moved = true

#______________________________
#BUTTON NAVIGATIONS
#______________________________
func _on_play_pressed() -> void:
	playSFX.emit(1)
	switchPlay.emit()

func _on_options_pressed() -> void:
	playSFX.emit(1)
	switchOptions.emit()

func _on_scores_pressed() -> void:
	playSFX.emit(1)
	$"Score Display".show()

func _on_how_2_play_pressed() -> void:
	var h2pTween = self.create_tween()
	playSFX.emit(1)
	get_viewport().gui_get_focus_owner().release_focus()
	h2pTween.tween_property($How2Play,"position",newH2pPosition,.1)
	await h2pTween.finished
	switchTutorial.emit()

#______________________________
#SCORE AND BASIC CONTROLS
#______________________________
func _on_score_display_refocus() -> void:
	$Buttons/Scores.grab_focus()
	playSFX.emit(2)

func _on_focus_entered() -> void:
	if can:
		playSFX.emit(0)

#______________________________
#HOW TO PLAY SIGNALS
#______________________________
func _on_how_2_play_make_sfx(index):
	playSFX.emit(index)

func _on_how_2_play_exit():
	var h2pTween = self.create_tween()
	playSFX.emit(2)
	h2pTween.tween_property($How2Play,"position",orgH2pPosition,.1)
	await h2pTween.finished
	$Buttons/How2Play.grab_focus()

func _on_how_2_play_board_sfx(index):
	boardSFX.emit(index)
