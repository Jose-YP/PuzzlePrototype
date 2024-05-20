extends Node2D

@export var rippleTiming: float = 1.0
@export var rippleOffset: Vector2 = Vector2(0.01,0.01)
@export_range(0,.5,.01) var burnTiming: float = .05

@onready var brakSFX: Array[AudioStreamPlayer] = [%Break, %Break2, %Break3, %Break4]
@onready var sprite: TextureRect = $TextureRect
@onready var glow: Sprite2D = $Glow

signal find_adjacent
signal rippleEnd

#Beads & positions is here just to easily integrate into old code
var currentType: String = "Breaker"
var adjacent: Array = []
var beads: Array = [self]
var positions: Array = [self]
var gridPos: Array[Vector2i] = [Vector2i(0,0)]
var breaker: bool = true
var placed: bool = false
var breaking: bool = false
var rippled: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	material.set_shader_parameter("dissolve_value",1.0)

#______________________________
#CHECKING CHAINS
#______________________________
func check_should_break() -> Array:
	var breakChains: Array = []
	find_adjacent.emit(self)
	for i in range(adjacent.size()):
		var should_break: bool = false
		var adj = adjacent[i]
		if adj == null:
			continue
		
		#These will be checked last so chained should be accurate
		var links: Dictionary = adj.get_links()
		for link in links:
			if link.chained:
				should_break = true
				break
		
		if should_break:
			breakChains.append(adj)
	
	return breakChains

#______________________________
#RIPPLE
#______________________________
func ripple():
	set_ripple_center()
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
	
	var center: Vector2 = global_position / (get_window().size as Vector2)
	
	#I need to find a way to get the center y to update as it should
	center = Vector2(center.x,center.y ) + rippleOffset
	$Ripple.material.set_shader_parameter("center", center)
	print(center)
	#* 1.15
	#print(center.y / 1.15, "||", get_window().size.y, "||", global_position.y, "||", center.y / 1.15 * get_window().size.y,)

func _on_ripple_end():
	rippled = true

#______________________________
#DESTROYING PIECES
#______________________________
func destroy_anim():
	#Destroy chains
	breaking = true
	brakSFX.pick_random().play()
	
	#Destroy bead
	var tween = self.create_tween()
	tween.tween_method(set_burn, 1.0, 0.0, burnTiming)
	await tween.finished
	queue_free()

func set_burn(value: float):
	material.set_shader_parameter("dissolve_value",value)

func _on_button_pressed():
	ripple()
