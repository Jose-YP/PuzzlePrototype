extends TabContainer

@export var small: bool = false
@export var smallSize: Vector2 = Vector2(20,20)
@export var regSize: Vector2 = Vector2(40,40)

func _ready():
	if small:
		custom_minimum_size = smallSize
	else:
		custom_minimum_size = regSize
