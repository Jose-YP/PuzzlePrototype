extends Control

@onready var nextSlots: Array[PanelContainer] = [%NextContain,%Next2,%Next3]
@onready var currentBeads: Array[Control] = [%FullBead, %FullBead2, %FullBead3]

# Called when the node enters the scene tree for the first time.
func _ready():
	scale_beads()
	pass

func scale_beads():
	for slot in nextSlots:
		var beads = slot.get_child(0)
		beads.set_scale(Vector2(.25,.25))


func place_bead():
	pass
