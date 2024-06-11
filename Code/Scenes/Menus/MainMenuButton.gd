extends TextureButton

@export var richText: String = "TEST"

@onready var animations: AnimationPlayer = $AnimationPlayer

signal finish

func _ready():
	$".".grab_focus()

func _on_pressed():
	print("B")
	animations.play("Pressed")
	await finish
	print("C")
	animations.play("Pressed",true)

func _on_focus_entered():
	print("a")
	animations.play("Hover", -1.0, 1.0)

func _on_focus_exited():
	animations.play("RESET", -1.0, 2.0)

func finish_signal():
	finish.emit()
