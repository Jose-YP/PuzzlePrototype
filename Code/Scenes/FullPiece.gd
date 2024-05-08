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

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()
	$Beads.rotation = 0 #In the UI Beads start rotated for some reason

#______________________________
#BOARD FUNCTIONS
#______________________________
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

#______________________________
#NEXT DISPLAY FUNCTIONS
#______________________________
#func recenter():
	#match rot.rotation_degrees:
		#90:
			#$Beads.position = Vector2($Beads.position.x,20)
		#180:
			#$Beads.position = Vector2(75,20)
		#270:
			#$Beads.position = Vector2(75,$Beads.position.y)
#
#func get_true_size() -> Vector2:
	#var currentSize: Vector2 = get_size()
	#for bead in beads:
		#var beadSize = bead.sprite.get_size()
		#print(bead, beadSize)
		#if abs(currentSize.x) < abs(beadSize.x):
			#currentSize.x = beadSize.x
		#if abs(currentSize.y) < abs(beadSize.y):
			#currentSize.y = beadSize.y
	#
	#return currentSize
#
#func fit_in(sizing):
	##scale.x = sizing.x / 
	#pass
