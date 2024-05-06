extends Node

const bead = preload("res://Scenes/Board&Beads/SingleBead.tscn")
const bead_types: Array[String] = ["Earth","Liquid","Air","Light","Dark"]
const bead_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
const directions: Array[String] = ["Left","Right","Up","Down"]
const otherConnectionNum: Array = [1,0,3,2]

var relation_flags: Array[int] = []
var glow_num: int = 3

func string_to_flag(type) -> int:
	match type:
		"Earth":
			return 1
		"Liquid":
			return 2
		"Air":
			return 4
		"Light":
			return 8
		"Dark":
			return 16
	
	return 0
