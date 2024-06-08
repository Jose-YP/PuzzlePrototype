extends TextureButton

@export var richText: String = "TEST"

@onready var animations: AnimationPlayer = $AnimationPlayer

func _ready():
	pass

func _on_pressed():
	animations.play("Pressed", -1.0, 2.0)
