extends Control

@export var recenterMove: Vector2 = Vector2(74,20)

# Called when the node enters the scene tree for the first time.
func _ready():
	$FullBead.rot.global_position = $Marker2D.global_position
	match $FullBead.rot.rotation_degrees:
		90:
			$FullBead.global_position.y += recenterMove.y 
		180:
			$FullBead.global_position += recenterMove
		270:
			$FullBead.global_position.x += recenterMove.x
	$FullBead.sync_position()

func change_bead():
	pass
