extends TextureButton

@onready var animations: AnimationPlayer = $AnimationPlayer

var pressing: bool = false
var hoverUpdate: bool = true
var pressUpdate: bool = true

signal finish

func _ready():
	$AnimationTree.tree_root = $AnimationTree.tree_root.duplicate()
	$AnimationTree.active = true

func _on_pressed():
	$AnimationTree.set("parameters/OneShot/request", "Shoot")

func _on_focus_entered():
	$AnimationTree.set("parameters/Basic/transition_request", "Hover")

func _on_focus_exited():
	if pressing:
		await finish
	
	$AnimationTree.set("parameters/Basic/transition_request", "Default")

func finish_signal():
	finish.emit()
	pressing = false

func fix_anim(anim_index: int):
	var should: bool = false
	match anim_index:
		0:
			should = hoverUpdate
			hoverUpdate = false
		2:
			should = pressUpdate
			pressUpdate = false
	
	if should:
		var fixTrack = animations.get_animation_list()[anim_index]
		animations.stop()
		animations.play(fixTrack)
