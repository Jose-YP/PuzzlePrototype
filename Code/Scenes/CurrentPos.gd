extends Node

#Current pos will make it easy to find the posiiton of every piece in the full piece
#Make this it's own node so it can be referenced by other variables like a pointer
var gridPos: Array[Vector2] = [Vector2(), Vector2(), Vector2()]

func _process(_delta):
	if gridPos[0] == Vector2(0,0):
		print("AAAAA")
