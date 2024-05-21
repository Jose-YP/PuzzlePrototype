extends Control

signal switchPlay
signal switchOptions
signal playSFX(index)
signal boardSFX(index)

var can: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	$Buttons/Play.grab_focus()
	can = true

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
	playSFX.emit(1)
	get_viewport().gui_get_focus_owner().release_focus()
	$How2Play.show()

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
	playSFX.emit(2)
	$How2Play.hide()
	$Buttons/How2Play.grab_focus()

func _on_how_2_play_board_sfx(index):
	boardSFX.emit(index)
