extends ParallaxBackground

@export var scrolling_speed: Vector2 = Vector2(100.0, 50.0)
@export var first_color: Color = Color.WHITE
@export var second_color: Color = Color.WHITE

@onready var mirroring: Vector2 = $FirstLayer.motion_mirroring

func _ready():
	$FirstLayer.modulate = first_color
	$SecondLayer.modulate = Color(second_color, .15)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scroll_offset += (scrolling_speed * Vector2(delta, delta))
	
	#I wanna prevent the number from getting to big but
	
	#if (int(scroll_offset.x) % int(mirroring.x) == 0
	#and (int(scroll_offset.y) % int(mirroring.y)) == 0):
		#scroll_offset = Vector2.ZERO
