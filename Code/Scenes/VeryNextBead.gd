extends Control

@export var small: bool = false
@export var orderText: String = "NEXT"
#Replace Full bead later
@onready var fullBead = $FullBead

# Called when the node enters the scene tree for the first time.
func _ready():
	if small:
		for tabs in %NextContain.get_children():
			tabs.small = true
			tabs.resize()
			$HBoxContainer/Next/VBoxContainer/Text.hide()
	else:
		$HBoxContainer/Next/VBoxContainer/Text.clear()
		$HBoxContainer/Next/VBoxContainer/Text.append_text(str("[center]",orderText))
	fullBead.sync_position()
	change_bead()

func change_bead():
	#CCW 0  | X CCW    |   CW X   |270 CW
	# X CW  | CW 90    | 180 CCW  | CCW X
	# [Anchor, CCW, Clockwise]
	match fullBead.rot.rotation_degrees:
		0.0:
			%"(0,0)".current_tab = fullBead.beads[1].typeID
			%"(1,0)".current_tab = 5
			%"(0,1)".current_tab = fullBead.beads[0].typeID
			%"(1,1)".current_tab = fullBead.beads[2].typeID
		90.0:
			%"(0,0)".current_tab = fullBead.beads[0].typeID
			%"(1,0)".current_tab = fullBead.beads[1].typeID
			%"(0,1)".current_tab = fullBead.beads[2].typeID
			%"(1,1)".current_tab = 5
		180.0:
			%"(0,0)".current_tab = fullBead.beads[2].typeID
			%"(1,0)".current_tab = fullBead.beads[0].typeID
			%"(0,1)".current_tab = 5
			%"(1,1)".current_tab = fullBead.beads[1].typeID
		270.0:
			%"(0,0)".current_tab = 5
			%"(1,0)".current_tab = fullBead.beads[2].typeID
			%"(0,1)".current_tab = fullBead.beads[1].typeID
			%"(1,1)".current_tab = fullBead.beads[0].typeID
