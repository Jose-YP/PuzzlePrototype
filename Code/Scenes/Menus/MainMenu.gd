extends Control

signal switchPlay
signal switchOptions
signal playSFX(index)

var can: bool = false

func _ready() -> void:
	$Buttons/Play.grab_focus()
	can = true

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

func _on_score_display_refocus() -> void:
	$Buttons/Scores.grab_focus()
	playSFX.emit(2)

func _on_focus_entered() -> void:
	if can:
		playSFX.emit(0)
