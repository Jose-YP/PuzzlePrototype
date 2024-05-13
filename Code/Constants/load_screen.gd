extends CanvasLayer

@export var next_scene = "res://Scenes/Board&Beads/Board.tscn"

signal finished(scene)

# Called when the node enters the scene tree for the first time.
func _ready():
	ResourceLoader.load_threaded_request(next_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$VBoxContainer/ProgressBar.value = progress[0] * 100
	
	#Once finished loading rpelace load screen with board
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		finished.emit(packed_scene)
