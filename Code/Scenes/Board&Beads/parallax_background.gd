@tool
extends ParallaxBackground

@export var scrolling_speed: float = 100.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scroll_offset += scrolling_speed * delta
