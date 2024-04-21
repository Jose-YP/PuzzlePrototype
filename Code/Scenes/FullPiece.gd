extends Node2D

func _ready():
	var rotNum: int = randi_range(0,3)
	rotation_degrees = 90 * rotNum
