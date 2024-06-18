extends TabContainer

@export var small: bool = false
@export var smallSize: Vector2 = Vector2(20,20)
@export var regSize: Vector2 = Vector2(40,40)

func _ready():
	resize()
	edit_color(current_tab)

func resize():
	if small:
		custom_minimum_size = smallSize
	else:
		custom_minimum_size = regSize

func edit_color(index):
	match index:
		0:
			modulate = Globals.save.earthColor
		1:
			modulate = Globals.save.seaColor
		2:
			modulate = Globals.save.airColor
		3:
			modulate = Globals.save.lightColor
		4:
			modulate = Globals.save.darkColor
		6:
			modulate = Globals.save.breakerColor
		5:
			modulate = Color.TRANSPARENT
