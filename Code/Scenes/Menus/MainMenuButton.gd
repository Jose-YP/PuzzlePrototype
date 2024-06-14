extends TextureButton

@onready var animations: AnimationPlayer = $AnimationPlayer

var pressing: bool = false

signal finish

func _ready():
	texture_normal = texture_normal.duplicate()

func _on_pressed():
	#position = Vector2(194,258.5)
	animations.play("MainMenuButtons/Pressed")
	texture_normal = texture_normal.duplicate()

func _on_focus_entered():
	animations.play("MainMenuButtons/Hover")
	texture_normal = texture_normal.duplicate()

func _on_focus_exited():
	if pressing:
		await finish
	else:
		animations.stop()
	
	animations.play("MainMenuButtons/Off")
	texture_normal = texture_normal.duplicate()

func finish_signal():
	finish.emit()
	pressing = false

func _on_animation_player_current_animation_changed(animName):
	print(animName)
