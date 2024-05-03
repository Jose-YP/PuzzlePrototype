extends Node

const piece = preload("res://Scenes/SinglePiece.tscn")
const piece_types: Array[String] = ["Earth","Liquid","Air","Light","Dark"]
const piece_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
const glow_colors: Array[Color] = [Color(1, 0.239, 1, 0.176)]

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
