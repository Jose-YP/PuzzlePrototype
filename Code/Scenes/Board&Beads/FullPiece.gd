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
	check_flood()
	check_drought()
	
	var string: String = ""
	for i in range(beads.size()):
		string = str(string, "\t", beads[i].currentType)
	print("Types for This current Bead", string)

func check_drought() -> void:
	var drought = Globals.droughtArray
	for i in range(drought.size()):
		#Check if any drought value is over the limit
		if drought[i] >= Globals.rules.droughtVal:
			print("Rerolling for ", drought[i])
			#Take a random number of beads, no three colors from this
			var num = randi_range(2,3)
			var tempBeads: Array = beads.duplicate()
			#Reroll every randomly chosen bead into that type
			for j in range(num):
				var bead = tempBeads[randi_range(0,tempBeads.size()-1)]
				if bead.typeID != i:
					#Array of just the droughted type ensures type appears
					bead.randomize_type([i])
				tempBeads.erase(bead)
			break

func check_flood() -> void:
	var flood = Globals.floodArray
	var reroll = range(Globals.bead_types.size())
	var willReroll = []
	#Get the reroll arrays
	for i in range(flood.size()):
		if flood[i] >= Globals.rules.floodVal:
			reroll.erase(i)
			willReroll.append(i)
	
	#If any of the current types in the full bead have 
	for type in willReroll:
		print("Rerolling away ", Globals.bead_types[type])
		reroll.erase(type)
		for i in range(beads.size()):
			if beads[i].typeID == type:
				beads[i].randomize_type(reroll)

#______________________________
#BOARD FUNCTIONS
#______________________________
func determine_reroll():
	var types: Dictionary = {0:0, 1:0, 2:0, 3:0, 4:0}
	var rerollTypes: Array[int] = []
	var reroll: bool = true
	for bead in beads:
		#For every type found add 1 to it's place in the dictionary
		types[bead.typeID] += 1 
	for type in types:
		if types[type] > 1:
			reroll = false
		if types[type] != 0:
			#If the type shows up in the type dict as 1 or more add it to the reroll
			rerollTypes.append(type)
	var chance = randi_range(0,100)
	if reroll and chance >= three_type_chance:
		var index = range(3).pick_random()
		rerollTypes.erase(beads[index].typeID)
		print(beads[index].currentType, " Reroll,", rerollTypes)
		var tempReroll = rerollTypes
		beads[index].randomize_type(tempReroll)
	elif reroll: print("unlucky")
	else: print(reroll, chance >= three_type_chance)

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
