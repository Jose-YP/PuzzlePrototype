extends TextureButton

@onready var animations: AnimationPlayer = $AnimationPlayer

signal finish

func _ready():
	texture_normal = texture_normal.duplicate()

func _process(delta):
	print(animations.get_assigned_animation())

func _on_pressed():
	animations.play("MainMenuButtons/Pressed")
	texture_normal = texture_normal.duplicate()

func _on_focus_entered():
	animations.play("MainMenuButtons/Hover")
	texture_normal = texture_normal.duplicate()

func _on_focus_exited():
	animations.stop()
	animations.play("MainMenuButtons/Off")
	animations.play("RESET")
	texture_normal = texture_normal.duplicate()
	print("RESERT", self, texture_normal)

func finish_signal():
	finish.emit()
