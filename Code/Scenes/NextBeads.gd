extends Control

@onready var nextSlots: Array[PanelContainer] = [%NextContain,%Next2,%Next3]
@onready var currentBeads: Array[Control] = [%FullBead, %FullBead2, %FullBead3]
@onready var positions: Array[Marker2D] = [%Marker2D, %Marker2D2, %Marker2D3]

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(currentBeads.size()):
		currentBeads[i].recenter()
		print(currentBeads[i].position)
		#currentBeads[i].global_position = positions[i].global_position

func scale_beads():
	for i in range(nextSlots.size()):
		var bead = nextSlots[i].get_child(0)
		bead.global_position = positions[i].global_position

func restart_beads():
	pass
