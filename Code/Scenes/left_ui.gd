extends Control

@export var progressTiming: float = .5

@onready var nextBeads = $VBoxContainer/NextBeads
@onready var progressBar = $VBoxContainer/PanelContainer/BreakProgress
@onready var breakText = $VBoxContainer/PanelContainer/BreakProgress/Label
@onready var breakNotifier = $VBoxContainer/HBoxContainer/PanelContainer2

signal breakReady

var rules: Rules
var progress: int = 0

# Called when the node enters the scene tree for the first time.
func update_next(beads):
	for i in range(3):
		nextBeads.update(i,beads[i])

func update_meter(add):
	progress += add
	set_progress()

func meter_filled():
	progress = 0
	set_progress()
	breakReady.emit()

func set_progress():
	var currentValue = progressBar.material.get_shader_parameter("value")
	var tween = get_tree().create_tween()
	var newValue = (progress / 
	((Globals.level * rules.meterChargeRate) + rules.meterChargeThres))
	newValue = clamp(newValue, 0, 1)
	#Use a method to tween shader properties
	tween.tween_method(tween_progress, currentValue, newValue, progressTiming)
	if newValue == 1:
		meter_filled()

func tween_progress(value):
	progressBar.material.set_shader_parameter("value", value)

func _on_button_pressed():
	update_meter(1)
