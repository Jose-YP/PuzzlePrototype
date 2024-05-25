extends Node

@onready var rules: Rules = load("res://Resources/Rules/Basic Rules.tres")
@onready var save = Save.load_or_create()
@onready var userPrefs = UserPreferences.load_or_create()
@onready var display = sort_scores()

const bead = preload("res://Scenes/Board&Beads/SingleBead.tscn")
const bead_types: Array[String] = ["Earth","Sea","Air","Light","Dark"]
const directions: Array[String] = ["Left","Right","Up","Down"]
const otherConnectionNum: Array = [1,0,3,2]

var relation_flags: Array[int] = []
var bead_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
var breaker_color: Color = Color(0.514, 0.969, 0.557)
var droughtArray: Array[int] = [0,0,0,0,0]
var glow_num: int = 3
var level: int = 1
var highestID: String
var lowestID: String
var NewgroundsToggle: bool = true

func _ready() -> void:
	set_other_inputs()
	set_controls()
	set_colors()

#______________________________
#SAVE MANAGEMENT
#______________________________
func find_extreme_score(lowest = false, Dict = save.HiScores) -> String:
	var maxHold: Dictionary = {"abc" : [0,""]}
	var maxID: String = "abc"
	for ID in Dict:
		if lowest:
			if (Dict[ID][0] <= maxHold[maxID][0]
			or maxID == "abc"):
				maxHold.clear()
				maxHold[ID] = Dict[ID]
				maxID = ID
		else:
			if Dict[ID][0] >= maxHold[maxID][0]:
				maxHold.clear()
				maxHold[ID] = Dict[ID]
				maxID = ID
	
	if Dict == save.HiScores:
		if lowest: lowestID = maxID
		else: highestID = maxID
	return maxID

func get_extreme(lowest = false) -> Array:
	if lowest:
		return save.HiScores[lowestID]
	else:
		return save.HiScores[highestID]

func sort_scores() -> Array:
	var sorted: Array = []
	var Dict = save.HiScores.duplicate(true)
	for i in range(save.HiScores.size()):
		var ID = find_extreme_score(false, Dict)
		sorted.append(Dict[ID])
		Dict.erase(ID)
	
	return sorted

func set_controls() -> void:
	for action in Globals.userPrefs.keyboard_action_events:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, Globals.userPrefs.keyboard_action_events[action])
	
	for action in Globals.userPrefs.joy_action_events:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, Globals.userPrefs.keyboard_action_events[action])

func set_colors() -> void:
	bead_colors = Globals.userPrefs.get_regular_colors()
	breaker_color = Globals.userPrefs.breakerColor

#______________________________
#INPUT MANAGEMENT
#______________________________
func set_other_inputs() -> void:
	InputMap.action_erase_events("ui_focus_next")
	InputMap.action_erase_events("ui_focus_prev")
	for event in InputMap.action_get_events("ui_accept"):
		InputMap.action_add_event("ui_focus_next", event)
	for event in InputMap.action_get_events("ui_cancel"):
		InputMap.action_add_event("ui_focus_prev", event)

#______________________________
#CONVERSION
#______________________________
func string_to_flag(type) -> int:
	match type:
		"Earth":
			return 1
		"Sea":
			return 2
		"Air":
			return 4
		"Light":
			return 8
		"Dark":
			return 16
	return 0
