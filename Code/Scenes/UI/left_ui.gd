extends Control

@export var progressTiming: float = .5
@export var rippleTiming: float = 1

@onready var nextBeads: Control = $VBoxContainer/HBoxContainer2/NextBeads
@onready var breakMeter: VBoxContainer = $VBoxContainer/BreakMeter

signal breakReady
signal rippleEnd

var progress: int = 0

#______________________________
#NEXT BEADS
#______________________________
func update_next(beads) -> void:
	for i in range(3):
		nextBeads.update(i,beads[i])

#______________________________
#BREAK PROGRESS
#______________________________
func update_meter(add) -> void:
	progress += add
	set_progress()

func meter_filled() -> void:
	progress = 0
	set_progress()
	breakReady.emit()

func set_progress() -> void:
	var tween = self.create_tween().set_ease(Tween.EASE_OUT)
	var newValue = (progress / 
	((Globals.level * Globals.rules.meterChargeRate) + Globals.rules.meterChargeThres))
	newValue = clamp(newValue, 0, 1)
	#Use a method to tween shader properties
	tween.tween_property(breakMeter.progressBar, "value", newValue * 100.0, progressTiming)
	if newValue == 1:
		meter_filled()

func _on_right_ui_break_gain(beads):
	#Recharge the meter depending on how many beads were broken in a breaker bead combo
	update_meter(beads * Globals.rules.breakBeadRecharge)

#______________________________
#BREAK RIPPLE
#______________________________
func ripple():
	var rippleTween = create_tween().set_ease(Tween.EASE_OUT_IN).set_parallel()
	rippleTween.tween_method(ripple_radius_tween, .001, 2, rippleTiming)
	rippleTween.tween_method(ripple_size_tween, .04, 0, rippleTiming)
	await get_tree().create_timer(rippleTiming).timeout
	rippleEnd.emit()

func ripple_radius_tween(value):
	$Ripple.material.set_shader_parameter("radius", value)

func ripple_size_tween(value):
	$Ripple.material.set_shader_parameter("width", value)

func set_ripple_center() -> void:
	var center: Vector2 = breakMeter.set_ripple_center()
	$Ripple.material.set_shader_parameter("center", center)

func _on_button_pressed():
	update_meter(1)
