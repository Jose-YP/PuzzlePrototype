extends Node2D

@export var rippleTiming: float = 1.0

signal find_adjacent
signal rippleEnd

var currentType: String = "Breaker"
var adjacent: Array = []
var breaking: bool = false


#______________________________
#CHECKING CHAINS
#______________________________

#______________________________
#RIPPLE
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
	var center: Vector2 = $Sprite2D.global_position / (get_window().size as Vector2)
	center = Vector2(center.x,center.y*2)
	print(center)
	$Ripple.material.set_shader_parameter("center", center)
