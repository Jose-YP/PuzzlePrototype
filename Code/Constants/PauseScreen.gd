extends CanvasLayer

@onready var retryDissplay: HBoxContainer = $VBoxContainer/RETRY
@onready var quitDisplay: HBoxContainer = $VBoxContainer/QUIT

signal retry(allowed)
signal quit(allowed)
signal playSFX
signal unpauseSong

var onBoard: bool = false

func _input( event: InputEvent):
	if event.is_action_pressed("Pause"):
		unpause()
	
	if event.is_action_pressed("Flip"):
		quit.emit(onBoard)
		unpause()
	
	if event.is_action_pressed("Break"):
		retry.emit(onBoard)
		unpause()

func unpause() -> void:
	var currently = get_tree().paused
	get_tree().paused = not currently
	visible = not currently
	playSFX.emit()
	unpauseSong.emit()

func entered_board(value) -> void:
	if value:
		$VBoxContainer/RETRY.show()
		$VBoxContainer/QUIT.show()
	else:
		$VBoxContainer/RETRY.hide()
		$VBoxContainer/QUIT.hide()
	onBoard = value

func play_sfx():
	%Pause.play()
