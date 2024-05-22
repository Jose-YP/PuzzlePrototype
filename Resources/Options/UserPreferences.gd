extends Resource
class_name UserPreferences

#AUDIO OPTIONS
@export_range(0,100,.05) var masterAudioLeve: float = 100.0
@export_range(0,100,.05) var musicAudioLeve: float = 100.0
@export_range(0,100,.05) var sfxAudioLeve: float = 100.0

#INPUT MAP
@export_enum("KEYBOARD","GAMEPAD") var input_type: int = 0
@export var keyboard_action_events: Dictionary = {}
@export var joy_action_events: Dictionary ={}

#PREFERED COLORS
@export_color_no_alpha var earthColor: Color = Color(0.631, 0.125, 0.125)
@export_color_no_alpha var seaColor: Color = Color(0.137, 0.6, 0.91)
@export_color_no_alpha var airColor: Color = Color(1,1,1)
@export_color_no_alpha var lightColor: Color = Color(0.898, 0.91, 0.137)
@export_color_no_alpha var darkColor: Color = Color(0.478, 0.071, 0.365)
@export_color_no_alpha var breakerColor: Color = Color(0.514, 0.969, 0.557)

#FUNCTIONS
func save(NG = false) -> void:
	ResourceSaver.save(self, "res://Resources/Options/UserPrefs.tres")
	if NG:
		NGCloudSave.save_game()

static func load_or_create() -> UserPreferences:
	var res: UserPreferences = load("res://Resources/Options/UserPrefs.tres") as UserPreferences
	if !res:
		res = UserPreferences.new()
	return res

#Ugly functions but they work 
func set_colors(newColors):
	earthColor = newColors[0]
	seaColor = newColors[1]
	airColor = newColors[2]
	lightColor = newColors[3]
	darkColor = newColors[4]
	breakerColor = newColors[5]

func get_regular_colors() -> Array[Color]:
	var arr: Array[Color] = [earthColor, seaColor, airColor,
	 lightColor, darkColor]
	return arr

func reset_colors():
	earthColor = Color(0.631, 0.125, 0.125)
	seaColor = Color(0.137, 0.6, 0.91)
	airColor = Color(1,1,1)
	lightColor = Color(0.898, 0.91, 0.137)
	darkColor = Color(0.478, 0.071, 0.365)
	breakerColor = Color(0.514, 0.969, 0.557)
