extends TextureButton

@onready var animations: AnimationPlayer = $AnimationPlayer

var pressing: bool = false
var hoverUpdate: bool = true
var pressUpdate: bool = true

signal finish

func _ready():
	$AnimationTree.tree_root = $AnimationTree.tree_root.duplicate()
	$AnimationTree.active = true
	texture_normal = texture_normal.duplicate()

func _on_pressed():
	print("AAAAA")
	$AnimationTree.set("parameters/OneShot/request", 1)
	texture_normal = texture_normal.duplicate()

func _on_focus_entered():
	$AnimationTree.set("parameters/Basic/transition_request", "Hover")
	texture_normal = texture_normal.duplicate()

func _on_focus_exited():
	if pressing:
		await finish
	
	animations.stop()
	$AnimationTree.set("parameters/Basic/transition_request", "Default")
	texture_normal = texture_normal.duplicate()
	hoverUpdate = true

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
		animations.stop()
