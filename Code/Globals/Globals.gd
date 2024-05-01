extends Node

const piece = preload("res://Scenes/SinglePiece.tscn")
const piece_types: Array[String] = ["Earth","Liquid","Air","Light","Dark"]
const piece_colors: Array[Color] = [Color(0.631, 0.125, 0.125),Color(0.137, 0.6, 0.91),Color(1,1,1),
Color(0.898, 0.91, 0.137),Color(0.478, 0.071, 0.365)]
