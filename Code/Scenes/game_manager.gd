extends CanvasLayer

@onready var nextBeads = $VBoxContainer/NextBeads

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_next(beads):
	for i in range(3):
		nextBeads.update(i,beads[i])
