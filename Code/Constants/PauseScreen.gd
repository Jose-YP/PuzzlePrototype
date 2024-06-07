extends CanvasLayer

@onready var retryDissplay: HBoxContainer = $VBoxContainer/RETRY

signal retry
signal playSFX
signal unpauseSong

var onBoard: bool = false

func _input( event: InputEvent):
	if event.is_action_pressed("Pause"):
		var currently = get_tree().paused
		get_tree().paused = not currently
		visible = not currently
		playSFX.emit()
		unpauseSong.emit()
	
	if event.is_action_pressed("Break"):
		retry.emit(onBoard)

func entered_board(value) -> void:
	if value:
		$VBoxContainer/RETRY.show()
	else:
		$VBoxContainer/RETRY.hide()
	onBoard = value

func play_sfx():
	%Pause.play()
