extends Node2D

@onready var positions: Array = $Positions.get_children()
@onready var pieces: Array = $Pieces.get_children()
#Dict doesn't work as the position values aren't pointers to gridPos
@onready var pieceDict: Dictionary = {$Positions/AnchorPos:[$Pieces/Anchor, gridPos[0]],
$Positions/Marker2D2:[$Pieces/SinglePiece2, gridPos[1]],$Positions/Marker2D3:[$Pieces/SinglePiece3, gridPos[2]]}
@onready var rot = $Positions

enum STATE {MOVE, PLACED}

var currentState: STATE = STATE.MOVE
var gridPos: Array[Vector2] = [Vector2(), Vector2(), Vector2()]

func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()

#With positions independent from pieces I can rotate them and keep orientation fixed
func sync_position() -> void: 
	for i in range(3):
		pieces[i].global_position = positions[i].global_position 

func in_full_piece(piece) -> bool:
	for i in range(pieces.size()):
		if pieces[i] == piece:
			return true
	
	return false
