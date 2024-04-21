extends Node2D

#CONSTANTS
const pieces = preload("res://Scenes/SinglePiece.tscn")
const fullPiece = preload("res://Scenes/FullPiece.tscn")

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export_category("Grid")
@export var width: int = 9
@export var height: int = 9 #row 0, 1 and 2 are fail state rows
@export var offset: Vector2 = Vector2(50,50)
@export var origin: Vector2 = Vector2(200, 150)
@export var start_pos: Vector2 = Vector2(5,2)
@export_category("Process Constants")
@export var gravity: float = 9.8
@export var hold_wait: float = 1.5
@export var fail_rows: int = 2

#Variables
var board: Array[Array]
var currentPiece

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	board = make_grid()
	spawn_piece()
	#fill_board()
	display_board()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	
	return array

#______________________________
#BASIC CONTROLS
#______________________________
func spawn_piece() -> void:
	currentPiece = fullPiece.instantiate()
	$Grid.add_child(currentPiece)
	
	#If the rotation puts a piece below center, raise center by 1
	var spawnPos: Vector2 = start_pos
	if currentPiece.rotation_degrees >= 90 and currentPiece.rotation_degrees <= 180: 
		spawnPos.y += 1
		print("Facing down: ",spawnPos)
	currentPiece.global_position = grid_to_pixel(spawnPos)
	print("Center Pirece: ", spawnPos, currentPiece.pieces[0].global_position)
	board[int(spawnPos.x)].insert(int(spawnPos.y), currentPiece.pieces[0])
	
	
	print("\nCenter: ",currentPiece.pieces[0].global_position,  "1: ",currentPiece.pieces[1].global_position, "2: ",currentPiece.pieces[2].global_position,"\n")
	
	#1   ## X1 ##2x ## 2
	#x2  ## 2  ## 1 ##1x 
	#Add two other pieces based on position
	var storedP2G: Vector2 = pixel_to_grid(currentPiece.pieces[1])
	print("Piece 1: ",storedP2G, currentPiece.pieces[1].global_position)
	board[int(storedP2G.x)].insert(int(storedP2G.y), currentPiece.pieces[1])
	
	storedP2G = pixel_to_grid(currentPiece.pieces[2])
	print("\nPiece 2: ",storedP2G, currentPiece.pieces[2].global_position)
	board[int(storedP2G.x)].insert(int(storedP2G.y), currentPiece.pieces[2])

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(gridPos: Vector2) -> Vector2:
	var Xnew: float = origin.x + offset.x * gridPos.x
	var Ynew: float = origin.y + offset.y * gridPos.y
	
	print("Cetner spawn at: ", Vector2(Xnew, Ynew))
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(piece) -> Vector2:
	var start_const: Vector2 = Vector2(origin.x - 50, origin.y + 50)
	var Xnew: int = round((piece.global_position.x - start_const.x) / offset.x)
	var Ynew: int = round((piece.global_position.y - start_const.y) / offset.y)
	
	print("Global: ",piece.global_position.x, " Start const: ", start_const.x)
	print("Global: ",piece.global_position.y, " Start const: ", start_const.y)
	
	return Vector2(Xnew, Ynew)

#______________________________
#DEBUG
#______________________________
func fill_board() -> void:
	for i in width:
		for j in height:
			if j <= fail_rows:
				continue
			var piece = pieces.instantiate()
			$Grid.add_child(piece)
			#let the piece fall into pixel position
			#I like how it starts lol
			piece.position = grid_to_pixel(Vector2(i,j))
			#Give the piece it's grid position
			board[i][j] = piece

func display_board() -> void:
	for j in height:
		var debugString: String
		for i in width:
			if board[i][j] != null:
				debugString = str(debugString, board[i][j].currentType)
			else:
				debugString = str(debugString, null)
		
		print("Row: ",j,"\t", debugString)
