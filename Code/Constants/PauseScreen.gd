extends CanvasLayer

@onready var retryDissplay: HBoxContainer = $VBoxContainer/RETRY

signal retry
signal playSFX

func _input( event: InputEvent):
	if event.is_action_just_pressed("Pause"):
		var currently = get_tree().paused
		get_tree().paused = not currently
		visible = not currently
		playSFX.emit()
	
	if event.is_action_just_pressed("Break"):
		retry.emit()
