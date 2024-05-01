extends Node2D

@onready var positions: Array = $Positions.get_children()
@onready var pieces: Array = $Pieces.get_children()
#Dict doesn't work as the position values aren't pointers to currentPos
@onready var pieceDict: Dictionary = {$Positions/AnchorPos:[$Pieces/Anchor, currentPos[0]],
$Positions/Marker2D2:[$Pieces/SinglePiece2, currentPos[1]],$Positions/Marker2D3:[$Pieces/SinglePiece3, currentPos[2]]}
@onready var rot = $Positions

enum STATE {MOVE, PLACED}

var currentState: STATE = STATE.MOVE
var currentPos: Array[Vector2] = [Vector2(), Vector2(), Vector2()]

func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()

#With positions independent from pieces I can rotate them and keep orientation fixed
func sync_position() -> void: 
	for i in range(3):
		pieces[i].global_position = positions[i].global_position 
