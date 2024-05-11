extends Control

signal switchPlay
signal switchOptions

func _ready() -> void:
	$Buttons/Play.grab_focus()

func _on_play_pressed() -> void:
	switchPlay.emit()

func _on_options_pressed() -> void:
	switchOptions.emit()

func _on_scores_pressed() -> void:
	$"Score Display".show()

func _on_how_2_play_pressed() -> void:
	pass # Replace with function body.

func _on_score_display_refocus() -> void:
	$Buttons/Scores.grab_focus()
