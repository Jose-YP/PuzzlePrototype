extends TextureButton

@onready var animations: AnimationPlayer = $AnimationPlayer

var pressing: bool = false

signal finish

func _ready():
	$AnimationTree.tree_root = $AnimationTree.tree_root.duplicate()
	$AnimationTree.active = true
	print(NodePath("."))
	$AnimationPlayer.set_root_node(NodePath("."))
	#texture_normal = texture_normal.duplicate()

func set_anim_root(root):
	print(get_tree_string())
	print(root)
	$AnimationPlayer.set_root_node(root)

func _process(_delta):
	pass
	
	#if not texture_normal is CompressedTexture2D:
		#print(name, texture_normal.region)

func _on_pressed():
	#position = Vector2(194,258.5)
	$AnimationTree.set("parameters/OneShot/request", "Shoot")
	#texture_normal = texture_normal.duplicate()

func _on_focus_entered():
	$AnimationTree.set("parameters/Basic/transition_request", "Hover")
	#texture_normal = texture_normal.duplicate()

func _on_focus_exited():
	if pressing:
		await finish
	
	$AnimationTree.set("parameters/Basic/transition_request", "Default")
	#texture_normal = texture_normal.duplicate()

func finish_signal():
	finish.emit()
	pressing = false

func _change_region(_p_region, _s_size):
	print("SOMETHING JUST HAPPENED")
	#texture_normal.region = 

func _on_animation_player_current_animation_changed(animName):
	print(animName)
