extends Node2D

#Dict doesn't work as the position values aren't pointers to gridPos
#CCW and CLockwise are named as such as they lead CCW/CLockwise rotations
@onready var positions: Array = $Positions.get_children()
@onready var flipPos: Array = $FlipPos.get_children()
@onready var regularPos: Array = positions
@onready var beads: Array = $Beads.get_children()
@onready var beadDict: Dictionary = {$Positions/AnchorPos:[$Beads/Anchor, gridPos[0]],
$Positions/CCWPos:[$Beads/CCW, gridPos[1]],$Positions/ClockwisePos:[$Beads/Clockwise, gridPos[2]]}
@onready var rot = $Positions

enum STATE {MOVE, GROUNDED, PLACED}

var currentState: STATE = STATE.MOVE
var gridPos: Array[Vector2i] = [Vector2i(), Vector2i(), Vector2i()]

func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()

func flip():
	rot = rot.rotation_degrees
	if positions == regularPos:
		positions = $FlipPos.get_children()
		rot = $FlipPos
	else:
		positions = $Positions.get_children()
		rot = $Positions
	sync_position()

#With positions independent from beads I can rotate them and keep orientation fixed
func sync_position() -> void: 
	for i in range(3):
		beads[i].global_position = positions[i].global_position 

func in_full_bead(bead, same = null) -> bool:
	for i in range(beads.size()):
		#Check if the bead is in full bead but not same bead
		if beads[i] == bead and beads[i] != same:
			return true
	
	return false
