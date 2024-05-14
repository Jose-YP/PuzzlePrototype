extends Control

@export var progressTiming: float = .5
@export var rippleTiming: float = 1

@onready var nextBeads: Control = $VBoxContainer/NextBeads
@onready var progressBar: ColorRect = $VBoxContainer/HBoxContainer/PanelContainer/BreakProgress
@onready var breakText: RichTextLabel = $VBoxContainer/HBoxContainer/PanelContainer2/RichTextLabel
@onready var breakNotifier: PanelContainer = $VBoxContainer/HBoxContainer/PanelContainer2

signal breakReady
signal rippleEnd

var rules: Rules
var progress: int = 0

# Called when the node enters the scene tree for the first time.
func update_next(beads) -> void:
	for i in range(3):
		nextBeads.update(i,beads[i])

func update_meter(add) -> void:
	progress += add
	set_progress()

func meter_filled() -> void:
	progress = 0
	set_progress()
	breakReady.emit()

func set_progress() -> void:
	var currentValue = progressBar.material.get_shader_parameter("value")
	var tween = get_tree().create_tween()
	var newValue = (progress / 
	((Globals.level * rules.meterChargeRate) + rules.meterChargeThres))
	newValue = clamp(newValue, 0, 1)
	#Use a method to tween shader properties
	tween.tween_method(tween_progress, currentValue, newValue, progressTiming)
	if newValue == 1:
		meter_filled()

func ripple():
	var rippleTween = create_tween().set_ease(Tween.EASE_OUT_IN).set_parallel()
	rippleTween.tween_method(ripple_radius_tween, .001, 1, rippleTiming)
	rippleTween.tween_method(ripple_size_tween, .04, 0, rippleTiming)
	await get_tree().create_timer(rippleTiming).timeout
	rippleEnd.emit()


func ripple_radius_tween(value):
	$Ripple.material.set_shader_parameter("radius", value)

func ripple_size_tween(value):
	$Ripple.material.set_shader_parameter("width", value)

func tween_progress(value) -> void:
	progressBar.material.set_shader_parameter("value", value)

func _on_button_pressed() -> void:
	ripple()

func set_ripple_center(pos):
	var center: Vector2 = pos.normalized()
	print(center)
	$Ripple.material.set_shader_parameter("center", center)
