extends Node

@onready var rules: Rules = load("res://Resources/Rules/Basic Rules.res")
@onready var save = Save.load_or_create()
@onready var display = sort_scores()

enum TempModes {
	DANGER,
	BREAKER,
	DEFAULT
}

const bead = preload("res://Scenes/Board&Beads/SingleBead.tscn")
const bead_types: Array[String] = ["Earth","Sea","Air","Light","Dark"]
const directions: Array[String] = ["Left","Right","Up","Down"]
const otherConnectionNum: Array = [1,0,3,2]
const beadSpeeds = [.05,.1,.125,.075,.2]

var relation_flags: Array[int] = []
var droughtArray: Array[int] = [0,0,0,0,0]
var floodArray: Array[int] = [0,0,0,0,0]
var bead_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
var breaker_color: Color = Color(0.514, 0.969, 0.557)
var link_colors = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
var buses = [AudioServer.get_bus_index("Master"),
 AudioServer.get_bus_index("Music"),
 AudioServer.get_bus_index("SFX")]
var glow_num: int = 3
var level: int = 1
var highestID: String
var lowestID: String
var NewgroundsToggle: bool = true

func _ready() -> void:
	if save.reset:
		save.reset_value()
	
	set_other_inputs(false)
	set_controls()
	set_colors()
	
	var rel = rules.bead_relationships
	Globals.glow_num = rel.glow_num
	Globals.relation_flags = [rel.earthRelations, rel.seaRelations, rel.airRelations,
	rel.lightRelations, rel.darkRelations]

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

func get_controls() -> void:
	for action in Globals.save.keyboard_action_events:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, Globals.save.keyboard_action_events[action])
		InputMap.action_add_event(action, Globals.save.joy_action_events[action])

func set_controls() -> void:
	for action in Globals.save.keyboard_action_events:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, Globals.save.keyboard_action_events[action])
		InputMap.action_add_event(action, Globals.save.joy_action_events[action])

func show_controls(textureNode) -> void:
	match Globals.save.input_type:
		0:
			textureNode.texture.force_type = ControllerIconTexture.ForceType.KEYBOARD_MOUSE
		1:
			textureNode.texture.force_type = ControllerIconTexture.ForceType.CONTROLLER

func set_colors() -> void:
	bead_colors = Globals.save.get_regular_colors()
	breaker_color = Globals.save.breakerColor
	
	for i in range(bead_colors.size()):
		var current = bead_colors[i]
		link_colors[i] = Color.from_hsv(clamp(current.h, 0, 1), clamp(current.s - .1, 0, 1), .98)

func all_black() -> bool:
	var all = true
	
	for i in range(bead_colors.size()):
		print(bead_types[i], ": ",bead_colors[i])
		
		if bead_colors[i] != Color.BLACK:
			all = false
			break
	
	return all

func set_volume() -> void:
	var levels = [Globals.save.masterAudioLeve, Globals.save.musicAudioLeve, Globals.save.sfxAudioLeve]
	
	for i in range(buses.size()):  #0.01 so it doesn't get too loud
		AudioServer.set_bus_volume_db(buses[i], linear_to_db(levels[i] * 0.01))

func NG_load(save_file):
	Globals.save.HiScores = save_file["scores"]
	Globals.save.username = save_file["username"]
	
	Globals.save.input_type = save_file["control_type"]
	Globals.save.keyboard_action_events = save_file["controls_key"]
	Globals.save.joy_action_events = save_file["controls_joy"]
	
	Globals.save.earthColor = save_file["earth_color"]
	Globals.save.seaColor = save_file["sea_color"]
	Globals.save.airColor = save_file["air_color"]
	Globals.save.lightColor = save_file["light_color"]
	Globals.save.darkColor = save_file["dark_color"]
	Globals.save.breakerColor = save_file["breaker_color"]
	
	Globals.save.masterAudioLeve = save_file["master"]
	Globals.save.musicAudioLeve = save_file["music"]
	Globals.save.sfxAudioLeve = save_file["sfx"]

#______________________________
#INPUT MANAGEMENT
#______________________________
func set_other_inputs(should: bool) -> void:
	InputMap.action_erase_events("ui_focus_next")
	InputMap.action_erase_events("ui_focus_prev")
	if should:
		for event in InputMap.action_get_events("ui_accept"):
			InputMap.action_add_event("ui_focus_next", event)
		for event in InputMap.action_get_events("ui_cancel"):
			InputMap.action_add_event("ui_focus_prev", event)

func pressed_accept() -> bool:
	var countEither: bool = true
	var cancelEvents = InputMap.action_get_events("ui_cancel")
	var inputAccept = Input.is_action_just_pressed("ui_accept")
	
	#Check if CCW event also hits an event in ui_cancel
	for event in InputMap.action_get_events("CCW"):
		if cancelEvents.find(event) != -1:
			countEither = false
	
	#If it does, only check for ui_accept
	if countEither:
		return inputAccept or Input.is_action_just_pressed("CCW")
	else:
		#Check if counterclockwise is has an input in accept
		var countOther: bool = false
		for event in InputMap.action_get_events("Clockwise"):
			if cancelEvents.find(event) != -1:
				countOther = true
		
		if countOther:
			return inputAccept or Input.is_action_just_pressed("Clockwise")
		else:
			return inputAccept

func pressed_cancel() -> bool:
	var countEither: bool = true
	var acceptEvents = InputMap.action_get_events("ui_accept")
	var inputCancel = Input.is_action_just_pressed("ui_cancel")
	
	#Check if CCW event also hits an event in ui_cancel
	for event in InputMap.action_get_events("Clockwise"):
		if acceptEvents.find(event) != -1:
			countEither = false
	
	#If it does, only check for ui_accept
	if countEither:
		return inputCancel or Input.is_action_just_pressed("Clockwise")
	else:
		#Check if counterclockwise is has an input in accept
		var countOther: bool = false
		for event in InputMap.action_get_events("CCW"):
			if acceptEvents.find(event) != -1:
				countOther = true
		
		if countOther:
			return inputCancel or Input.is_action_just_pressed("CCW")
		else:
			return inputCancel

#______________________________
#CONVERSION
#______________________________
func find_placement(regScore) -> int:
	var placement: int = 7
	#If regular score is higher than any of the current Hi scores 
	for i in range(display.size()):
		if regScore > display[i][0]:
			placement -= 1
	
	return placement

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
