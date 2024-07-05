extends ParallaxBackground

@export var debug_speed: float = 2
@export var dark_mode: bool = true
@export var scrolling_speed: Vector2 = Vector2(-100.0, -50.0)

@export_category("Colors")
@export_subgroup("Background")
@export var dark_BG: Color = Color(0.169, 0.051, 0.122)
@export var light_BG: Color = Color()
@export_subgroup("Patterns")
@export var dark_first: Color = Color(0.325, 0.612, 0.588)
@export var dark_second: Color = Color(0.49, 0.8, 0.773)
@export var light_first: Color = Color(0.325, 0.612, 0.588)
@export var light_second: Color = Color(0.49, 0.8, 0.773)

@onready var mirroring: Vector2 = $FirstLayer.motion_mirroring

var DomainColors: Array[Color] = [Globals.bead_colors[0],Globals.bead_colors[1],Globals.bead_colors[2]]
var EnergyColors: Array[Color] = [Globals.bead_colors[3],Globals.bead_colors[4]]
var colorGroups: Array[Array] = [DomainColors, EnergyColors]
var modeColors: Array = [[dark_BG, dark_first, dark_second], [light_BG, light_first, light_second]]
var using: Array
var tweening

func _ready() -> void:
	using = modeColors[1]
	if dark_mode:
		using = modeColors[0]
	
	$ColorRect.color = using[0]
	$FirstLayer.modulate = Color(using[1])
	$SecondLayer.modulate = Color(using[2], .35)

func _process(delta) -> void:
	if not  tweening:
		scroll_offset += (scrolling_speed * debug_speed * Vector2(delta, delta))

func switch_mode() -> void:
	if dark_mode:
		dark_mode = false
		using = modeColors[1]
	else:
		dark_mode = true
		using = modeColors[0]
	
	color_change(using[0], using[1], using[2])

func color_change(BGColor, first, second) -> void:
	var colorTween = self.create_tween().set_parallel()
	
	colorTween.tween_property($ColorRect, "color", BGColor, .5)
	colorTween.tween_property($FirstLayer, "color", first, .5)
	colorTween.tween_property($SecondLayer, "color", Color(second, .35), .5)
