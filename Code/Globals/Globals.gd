extends Node

@onready var save = Save

#const save = load("res://Resources/SaveData/SaveFile.tres")
const bead = preload("res://Scenes/Board&Beads/SingleBead.tscn")
const bead_types: Array[String] = ["Earth","Sea","Air","Light","Dark"]
const bead_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
const directions: Array[String] = ["Left","Right","Up","Down"]
const otherConnectionNum: Array = [1,0,3,2]

var relation_flags: Array[int] = []
var glow_num: int = 3
var highestID: String
var lowestID: String

func _ready():
	print("Globals Ready")
	save = Save.load_or_create()
	
	print(save.HiScores)
	print("HIGHEST: ", find_extreme_score())
	print("LOWEST: ", find_extreme_score(true))

func find_extreme_score(lowest = false) -> Dictionary:
	var maxHold: Dictionary = {"abc" : [0,""]}
	var maxID: String = "abc"
	for ID in save.HiScores:
		if lowest:
			if (save.HiScores[ID][0] <= maxHold[maxID][0]
			or maxID == "abc"):
				maxHold.clear()
				maxHold[ID] = save.HiScores[ID]
				maxID = ID
		else:
			if save.HiScores[ID][0] >= maxHold[maxID][0]:
				maxHold.clear()
				maxHold[ID] = save.HiScores[ID]
				maxID = ID
	
	if lowest: lowestID = maxID
	else: highestID = maxID
	return maxHold

func get_extreme(lowest = false):
	if lowest:
		return save.HiScores[lowestID]
	else:
		return save.HiScores[highestID]

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
