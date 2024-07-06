extends Resource
class_name Save

#SAVE FILE BASICS
@export_category("Score")
@export var HiScores: Dictionary = {"999999":[1,"YP!"],
"000000":[40,"YP!"],
"111111":[30,"YP!"],
"222222":[20,"YP!"],
"333333":[10,"YP!"],
"444444":[50,"YP!"]}
@export var username: String = "LVY"

#AUDIO OPTIONS
@export_category("Audio")
@export_range(0,100,.05) var masterAudioLeve: float = 100.0
@export_range(0,100,.05) var musicAudioLeve: float = 100.0
@export_range(0,100,.05) var sfxAudioLeve: float = 100.0

#INPUT MAP
@export_category("Controls")
@export_enum("KEYBOARD","GAMEPAD") var input_type: int = 0
@export var keyboard_action_events: Dictionary = {}
@export var joy_action_events: Dictionary ={}
@export var reset: bool = true

#PREFERED COLORS
@export_category("Colors")
@export_color_no_alpha var earthColor: Color = Color(0.886, 0.224, 0.212)
@export_color_no_alpha var seaColor: Color = Color(0.137, 0.6, 0.91)
@export_color_no_alpha var airColor: Color = Color(1,1,1)
@export_color_no_alpha var lightColor: Color = Color(0.898, 0.91, 0.137)
@export_color_no_alpha var darkColor: Color = Color(0.843, 0.251, 0.663)
@export_color_no_alpha var breakerColor: Color = Color(0.514, 0.969, 0.557)

#______________________________
#SAVE & LOAD
#______________________________
func save(NG = false) -> void:
	if NG:
		NGSaveSetup.sync_files()
		NGCloudSave.save_game()
	else:
		ResourceSaver.save(self, "res://Resources/SaveData/SaveFile.tres")

static func load_or_create() -> Save:
	var res: Save = load("res://Resources/SaveData/SaveFile.tres") as Save
	if !res:
		res = Save.new()
	return res

func save_score(score,name):
	var id: String = ""
	for i in range(6):
		id = str(id,randi_range(0,9))
	HiScores[id] = [score,name]

#______________________________
#OTHER SETS
#______________________________
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

#______________________________
#RESETTING
#______________________________
func reset_value():
	if reset:
		reset_scores()
		
		username = "LVY"
		
		masterAudioLeve = 100.0
		musicAudioLeve = 100.0
		sfxAudioLeve = 100.0
		
		input_type = 0
		set_default_controls()
		reset_colors()
		
		reset = false
		save(Globals.NewgroundsToggle)
		if Globals.NewgroundsToggle:
			save(false)

func reset_scores():
	HiScores = {"999999":[1,"NAN"],
			"000000":[5,"NAN"],
			"111111":[4,"NAN"],
			"222222":[3,"NAN"],
			"333333":[2,"NAN"],
			"444444":[1,"NAN"]}

func set_default_controls():
	InputMap.load_from_project_settings()
	const actions = ["Break","Flip","ui_accept","ui_cancel","ui_down","ui_left","ui_right","ui_up"]
	for action in actions:
		var events = InputMap.action_get_events(action)
		keyboard_action_events[action] = events[0]
		joy_action_events[action] = events[1]

func reset_colors():
	earthColor = Color(0.886, 0.224, 0.212)
	seaColor = Color(0.137, 0.6, 0.91)
	airColor = Color(1,1,1)
	lightColor = Color(0.898, 0.91, 0.137)
	darkColor = Color(0.843, 0.251, 0.663)
	breakerColor = Color(0.514, 0.969, 0.557)
