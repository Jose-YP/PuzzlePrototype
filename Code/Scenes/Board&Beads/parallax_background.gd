extends ParallaxBackground

@export var scrolling_speed: Vector2 = Vector2(-100.0, -50.0)
@export var first_color: Color = Color.WHITE
@export var second_color: Color = Color.WHITE

@onready var mirroring: Vector2 = $FirstLayer.motion_mirroring

var DomainColors: Array[Color] = [Globals.bead_colors[0],Globals.bead_colors[1],Globals.bead_colors[2]]
var EnergyColors: Array[Color] = [Globals.bead_colors[3],Globals.bead_colors[4]]
var colorGroups: Array[Array] = [DomainColors, EnergyColors]
var tweening

func _ready():
	$FirstLayer.modulate = Color(first_color, .90)
	$SecondLayer.modulate = Color(second_color, .35)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not  tweening:
		scroll_offset += (scrolling_speed * Vector2(delta, delta))
	
		#I wanna prevent the number from getting to big but
		if (int(scroll_offset.x) % int(mirroring.x) == 0
		or (int(scroll_offset.y) % int(mirroring.y)) == 0):
			var reverseTween = create_tween().set_ease(Tween.EASE_IN)
			reverseTween.tween_property(self, "scroll_offset", Vector2.ZERO, scroll_offset.x/50)
			tweening = true
			await reverseTween.finished
			tweening = false
		
