extends Node2D

#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@onready var Board = $"../.."
@onready var rules = Board.rules

#Grid needed an offset and .8 scale to counteract grid
func _draw() -> void:
	#Make the grid from origin to end
	#-offset/2 leads to the top left of every tile
	var drawOrigin = rules.origin - rules.offset/2
	var boardRect: Rect2 = Rect2(drawOrigin,Vector2(rules.offset.x * rules.width,rules.offset.y * rules.height))
	draw_rect(boardRect, Color(0.389, 0.389, 0.389))
	
	for i in rules.width:
		for j in rules.height:
			var pos: Vector2 = Vector2(i,j)
			var rectOrigin:Vector2 = Board.grid_to_pixel(pos) - rules.offset/2
			var tileRect: Rect2 = Rect2(rectOrigin, rules.offset)
			
			draw_rect(tileRect, Color(0.208, 0.208, 0.208, 0.706), false, 1.5)
			
			#DEBUG DRAW
			var debugPos: Vector2 = Board.grid_to_pixel(pos)
			debugPos.x -= 20
			draw_string(ThemeDB.fallback_font, debugPos, str(pos))
