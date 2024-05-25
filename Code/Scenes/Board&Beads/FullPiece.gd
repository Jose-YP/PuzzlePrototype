extends Node2D

@export_range(0,100) var three_type_chance: int = 25

#Dict doesn't work as the position values aren't pointers to gridPos
#CCW and CLockwise are named as such as they lead CCW/CLockwise rotations
@onready var positions: Array = $Positions.get_children()
@onready var beads: Array = $Beads.get_children()
@onready var beadDict: Dictionary = {$Positions/AnchorPos:[$Beads/Anchor, gridPos[0]],
$Positions/CCWPos:[$Beads/CCW, gridPos[1]],$Positions/ClockwisePos:[$Beads/Clockwise, gridPos[2]]}
@onready var rot = $Positions

var placed: bool = false
var gridPos: Array[Vector2i] = [Vector2i(), Vector2i(), Vector2i()]
var flipped: bool = false
var breaker: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Randomize Rotation
	var rotNum: int = randi_range(0,3)
	rot.rotation_degrees = 90 * rotNum
	
	sync_position()
	$Beads.rotation = 0 #In the UI Beads start rotated for some reason
	determine_reroll()
	check_drought()

func check_drought() -> void:
	var drought = Globals.droughtArray
	for i in range(drought.size()):
		#Check if any drought value is over the limit
		if drought[i] >= Globals.rules.droughtVal:
			print("Rerolling for ", Globals.bead_types[i])
			#Take a random number of beads, no three colors from this
			var num = randi_range(2,3)
			var tempBeads = beads.duplicate()
			#Reroll every randomly chosen bead into that type
			for j in range(num):
				var bead = tempBeads.pop_at(randi_range(0,tempBeads.size()))
				if bead.typeID != i:
					#Array of just the droughted type ensures type appears
					bead.randomize_type([i])
			break

#______________________________
#BOARD FUNCTIONS
#______________________________
func determine_reroll():
	var types: Dictionary = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
	var rerollTypes: Array[int] = []
	var reroll: bool = true
	for bead in beads:
		types[bead.typeID] += 1 
	for type in types:
		if types[type] > 1:
			reroll = false
		if types[type] != 0:
			rerollTypes.append(type)
	var chance = randi_range(0,100)
	if reroll and chance > three_type_chance:
		var index = range(3).pick_random()
		rerollTypes.pop_at(index)
		var tempReroll = rerollTypes
		beads[index].randomize_type(tempReroll)

func flip():
	if flipped:
		$Beads.move_child($Beads/CCW,1)
	else:
		$Beads.move_child($Beads/Clockwise,1)
	
	flipped = not flipped
	beads = $Beads.get_children()
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
