extends ParallaxBackground

@export var debug_speed: float = 2
@export var dark_mode: bool = true
@export var scrolling_speed: Vector2 = Vector2(-100.0, -50.0)

@export_category("Colors")
@export_subgroup("Background")
@export var dark_BG: Color = Color(0.169, 0.051, 0.122)
@export var light_BG: Color = Color.WHITE
@export_subgroup("Patterns")
@export var dark_first: Color = Color(0.325, 0.612, 0.588)
@export var dark_second: Color = Color(0.49, 0.8, 0.773)
@export var light_first: Color = Color(0.325, 0.612, 0.588)
@export var light_second: Color = Color(0.49, 0.8, 0.773)
@export var danger_color: Color = Color.RED

@onready var mirroring: Vector2 = $FirstLayer.motion_mirroring
@onready var modeColors: Array = [[dark_BG, dark_first, dark_second], [light_BG, light_first, light_second]]
@onready var DomainColors: Array[Color] = [Globals.bead_colors[0],Globals.bead_colors[1],Globals.bead_colors[2]]
@onready var EnergyColors: Array[Color] = [Globals.bead_colors[3],Globals.bead_colors[4]]
@onready var colorGroups: Array[Array] = [DomainColors, EnergyColors]

const second_alpha: float = .35

var in_danger: bool = false
var using: Array
var currentMode: Globals.TempModes = Globals.TempModes.DEFAULT
var tweening

#-----------------------------------------
#INITALIZATION AND PROCESSING
#-----------------------------------------
func _ready() -> void:
	using = modeColors[1]
	if dark_mode:
		using = modeColors[0]
	
	$ColorRect.color = using[0]
	$FirstLayer.modulate = Color(using[1])
	$SecondLayer.modulate = Color(using[2], second_alpha)

func _process(delta) -> void:
	scroll_offset += (scrolling_speed * debug_speed * Vector2(delta, delta))

#-----------------------------------------
#COLOR CHANGE
#-----------------------------------------
func switch_mode() -> void:
	if not tweening:
		if dark_mode:
			dark_mode = false
			using = modeColors[1]
		else:
			dark_mode = true
			using = modeColors[0]
		
		color_change(using[0], using[1], using[2])

func color_change(BGColor = using[0], first = using[1], second = using[2]) -> void:
	tweening = true
	match currentMode:
		Globals.TempModes.DANGER:
			first = danger_color
			second =  danger_color
		Globals.TempModes.BREAKER:
			first = Globals.breaker_color
			second =  Globals.breaker_color
	
	var colorTween = self.create_tween().set_parallel()
	
	colorTween.tween_property($ColorRect, "color", BGColor, .5)
	colorTween.tween_property($FirstLayer, "modulate", first, .5)
	colorTween.tween_property($SecondLayer, "modulate", Color(second, second_alpha), .5)
	
	await colorTween.finished
	tweening = false
