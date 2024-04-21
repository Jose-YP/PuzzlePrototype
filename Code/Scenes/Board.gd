extends Node2D

#CONSTANTS
const pieces = preload("res://Scenes/SinglePiece.tscn")
const fullPiece = preload("res://Scenes/FullPiece.tscn")

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var width: int = 9
@export var height: int = 7
@export var x_offset: float = 64
@export var y_offset: float = -5
@export var x_start: float = 64
@export var y_start: float = 800
@export var start_pos: Vector2 = Vector2(5,7)

#Variables
var board: Array[Array]

#______________________________
#INITIALIZATION
#______________________________
func _ready():
	board = make_grid()
	fill_board()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
		print("Column, ",i,"\t",array[i])
	
	return array

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(i, j) -> Vector2:
	var Xnew: float = x_start + x_offset * i
	var Ynew: float = y_start + y_offset * j
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(xPixel, yPixel) -> Vector2:
	var Xnew: int = round((xPixel - x_start) / x_offset)
	var Ynew: int = round((yPixel - y_start) / -y_offset)
	
	return Vector2(Xnew, Ynew)

#______________________________
#DEBUG
#______________________________
func fill_board() -> void:
	for i in width:
		for j in height:
			if j == 0:
				continue
			var piece = pieces.instantiate()
			$Grid.add_child(piece)
			#let the piece fall into pixel position
			#I like how it starts lol
			piece.position = grid_to_pixel(i,j)
			#Give the piece it's grid position
			board[i][j] = piece
