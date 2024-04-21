extends Node2D

enum STATE {MOVE, PLACED}

var pieces: Array 
var currentState: STATE = STATE.MOVE

func _ready() -> void:
	var rotNum: int = randi_range(0,3)
	rotation_degrees = 90 * rotNum
	
	pieces = [$SinglePiece,$SinglePiece2,$SinglePiece3]

func _process(_delta):
	if currentState == STATE.MOVE:
		if Input.is_action_just_pressed("ui_accept"):
			rotation_degrees = fmod(rotation_degrees+90,360)
		if Input.is_action_just_pressed("ui_cancel"):
			rotation_degrees = fmod(rotation_degrees-90,360)
		if Input.is_action_just_pressed("ui_left"):
			pass
		if Input.is_action_just_pressed("ui_right"):
			pass
		if Input.is_action_just_pressed("ui_up"):
			pass
		if Input.is_action_just_pressed("ui_down"):
			pass
