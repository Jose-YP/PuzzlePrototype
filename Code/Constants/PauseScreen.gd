extends CanvasLayer

signal playSFX

func _input( event: InputEvent):
	if event.is_action_pressed("Pause"):
		var currently = get_tree().paused
		get_tree().paused = not currently
		visible = not currently
		playSFX.emit()
