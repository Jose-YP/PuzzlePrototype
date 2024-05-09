extends Node2D

@export var BoardColor: Color = Color(0.389, 0.389, 0.389)
@export var FailColor: Color = Color(1,1,1)
@export var TileColor: Color = Color(0.208, 0.208, 0.208, 0.6)
@export var debug: bool = true

#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@onready var Board = $"../.."
@onready var rules = Board.rules

#Grid needed an offset and .8 scale to counteract grid
func _draw() -> void:
	#Make the grid from origin to end
	#-offset/2 leads to the top left of every tile
	var drawOrigin = rules.origin - rules.offset/2
	var drawEnd = Vector2(rules.offset.x * rules.width,rules.offset.y * rules.height)
	var boardRect: Rect2 = Rect2(drawOrigin,drawEnd)
	var failOrigin = Vector2(Board.grid_to_pixel(Vector2i(rules.safe_high_columns,0)).x - rules.offset.x/2, drawOrigin.y)
	var failEnd = Vector2(rules.offset.x * (rules.width - rules.safe_high_columns * 2),rules.offset.y * rules.fail_rows)
	var failRect: Rect2 = Rect2(failOrigin,failEnd)
	draw_rect(boardRect, BoardColor)
	draw_rect(failRect, FailColor)
	for i in rules.width:
		for j in rules.height:
			var pos: Vector2 = Vector2(i,j)
			var rectOrigin:Vector2 = Board.grid_to_pixel(pos) - rules.offset/2
			var tileRect: Rect2 = Rect2(rectOrigin, rules.offset)
			
			#Draw the grid by drawing a rect minus the fill
			draw_rect(tileRect, TileColor, false, 1.5)
			
			#DEBUG DRAW
			if debug:
				var debugPos: Vector2 = Board.grid_to_pixel(pos)
				debugPos.x -= 20
				draw_string(ThemeDB.fallback_font, debugPos, str(pos))
