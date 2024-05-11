extends Control

signal switchPlay
signal switchOptions

func _on_play_pressed():
	switchPlay.emit()

func _on_options_pressed():
	switchOptions.emit()

func _on_scores_pressed():
	$"Score Display".show()

func _on_how_2_play_pressed():
	pass # Replace with function body.

func _on_score_display_refocus():
	$Buttons/Scores.grab_focus()
