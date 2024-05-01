extends Node2D

@onready var positions: Array = $Positions.get_children()
@onready var pieces: Array = $Pieces.get_children()
@onready var rot = $Positions

enum STATE {MOVE, PLACED}

var currentPos: Vector2
var currentState: STATE = STATE.MOVE

func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()

#With positions independent from pieces I can rotate them and keep orientation fixed
func sync_position() -> void: 
	for i in range(3):
		pieces[i].global_position = positions[i].global_position 
