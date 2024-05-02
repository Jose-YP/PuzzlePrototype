extends Node2D

#CONSTANTS
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

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	
	return array

func _draw() -> void:
	#Make the grid from origin to end
	#-offset/2 leads to the top left of every tile
	var drawOrigin = origin - offset/2
	var boardRect: Rect2 = Rect2(drawOrigin,Vector2(offset.x * width,offset.y * height))
	draw_rect(boardRect, Color(0.389, 0.389, 0.389))
	
	for i in width:
		for j in height:
			var pos: Vector2 = Vector2(i,j)
			var rectOrigin:Vector2 = grid_to_pixel(pos) - offset/2
			var tileRect: Rect2 = Rect2(rectOrigin, offset)
			
			draw_rect(tileRect, Color(0.208, 0.208, 0.208, 0.706), false, 1.5)
			
			#DEBUG DRAW
			var debugPos: Vector2 = grid_to_pixel(pos)
			debugPos.x -= 20
			draw_string(ThemeDB.fallback_font, debugPos, str(pos))

#______________________________
#BASIC CONTROLS
#______________________________
#Array order goes [anchor, clockwise, ccw]
func spawn_piece() -> void:
	currentPiece = fullPiece.instantiate()
	$Grid.add_child(currentPiece)
	currentPiece.gridPos[0] = start_pos
	
	board[start_pos.x][start_pos.y] = currentPiece.pieces[0]
	currentPiece.rot.global_position = grid_to_pixel(start_pos)
	
	full_piece_rotation(start_pos)
	currentPiece.sync_position()
	print(currentPiece.gridPos)

func full_piece_rotation(pos) -> void:
	var firstPos: Vector2 = pos
	var secondPos: Vector2 = pos
	
	if currentPiece.rot.rotation_degrees == 360:
		currentPiece.rot.rotation_degrees = 0
	
	#Rotation is  a float value
	match currentPiece.rot.rotation_degrees:
		0.0:
			firstPos.y += 1
			secondPos.x += 1
		90.0:
			firstPos.x += 1
			secondPos.y -= 1
		180.0:
			firstPos.y -= 1
			secondPos.x -= 1
		270.0:
			firstPos.x -= 1
			secondPos.y += 1
	
	board[firstPos.x][firstPos.y] = currentPiece.pieces[1]
	board[secondPos.x][secondPos.y] = currentPiece.pieces[2]
	
	currentPiece.gridPos[1] = firstPos
	currentPiece.gridPos[2] = secondPos
	
	currentPiece.positions[0].global_position = grid_to_pixel(pos)
	currentPiece.positions[1].global_position = grid_to_pixel(firstPos)
	currentPiece.positions[2].global_position = grid_to_pixel(secondPos)
	
	#print("Rotation: ", currentPiece.rot.rotation_degrees, "Center: ", pos,"\n",
	#" First: ", currentPiece.pieces[1].currentType, firstPos, currentPiece.positions[1].global_position,
	#"\n Second: ", currentPiece.pieces[2].currentType, secondPos, currentPiece.positions[2].global_position)

func rotate_pop() -> bool:
	return false

func move_piece(ammount, direction = "X") -> void:
	for i in range(currentPiece.gridPos.size()):
		if direction == "X":
			currentPiece.gridPos[i].x += ammount
		else:
			currentPiece.gridPos[i].y += ammount
		currentPiece.positions[i].global_position = grid_to_pixel(currentPiece.gridPos[i])

func _process(_delta) -> void:
	if currentPiece.currentState == currentPiece.STATE.MOVE:
		if Input.is_action_just_pressed("ui_accept") and can_rotate("CCW"):
			print("Clockwise")
			currentPiece.rot.rotation_degrees += fmod(rotation_degrees+90,360)
			if currentPiece.rot.rotation_degrees > 360:
				currentPiece.rot.rotation_degrees -= 360
			
			full_piece_rotation(currentPiece.gridPos[0])
		
		if Input.is_action_just_pressed("ui_cancel") and can_rotate("CLOCKWISE"):
			print("Counterclock")
			currentPiece.rot.rotation_degrees += fmod(rotation_degrees-90,360)
			if currentPiece.rot.rotation_degrees < 0:
				currentPiece.rot.rotation_degrees += 360
			
			full_piece_rotation(currentPiece.gridPos[0])
		
		if Input.is_action_just_pressed("ui_left") and can_move("Left"):
			move_piece(-1)
		
		if Input.is_action_just_pressed("ui_right") and can_move("Right"):
			move_piece(1)
		
		#Both drop, up is hard drop, down is soft drop
		if Input.is_action_just_pressed("ui_up"):
			pass
		if Input.is_action_just_pressed("ui_down") and can_move("Down"):
			move_piece(-1, "Y")
		
		if Input.is_anything_pressed():
			currentPiece.sync_position()

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(gridPos: Vector2) -> Vector2:
	var Xnew: float = origin.x + offset.x * gridPos.x
	var Ynew: float = origin.y + offset.y * gridPos.y
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(piece) -> Vector2:
	var Xnew: int = round((piece.global_position.x - origin.x) / offset.x)
	var Ynew: int = round((piece.global_position.y - origin.y) / offset.y)
	
	#print("Global: ",piece.global_position.x, " Start const: ", start_pos.x, 
	#"Global: ",piece.global_position.y, " Start const: ", start_pos.y)
	#print(Vector2(Xnew, Ynew))
	return Vector2(Xnew, Ynew)

#Adjacent array: [left,right,up,down] with null for any \wo a piece
func find_adjacent(piece) -> Array:
	var adjacent: Array = [null, null, null, null]
	var pos = pixel_to_grid(piece)
	
	if board[pos.x - 1][pos.y] != null:
		adjacent[0] = board[pos.x - 1][pos.y]
	if board[pos.x + 1][pos.y] != null:
		adjacent[1] = board[pos.x - 1][pos.y]
	if board[pos.x][pos.y - 1] != null:
		adjacent[2] = board[pos.x - 1][pos.y]
	if board[pos.x][pos.y + 1] != null:
		adjacent[3] = board[pos.x - 1][pos.y]

	return adjacent

func can_move(direction) -> bool:
	for i in range(currentPiece.pieces.size()):
		var newPos: Vector2 = currentPiece.gridPos[i]
		#Check if a piece can move horizontally or down
		match direction:
			"Left":
				if newPos.x - 1 < 0: return false
				else: newPos.x -= 1
			"Right":
				if newPos.x + 1 > width - 1: return false
				else: newPos.x += 1
			"Down":
				if newPos.y + 1 < height - 1: return false
				else: newPos.y += 1
			"Up":
				if newPos.y - 1 < 0: return false
				else: newPos.y -= 1
		
		var piece = board[newPos.x][newPos.y]
		if piece != null and not currentPiece.in_full_piece(piece):
			return false
	
	return true

#Check if the rotation will hit the wall
func can_rotate(direction = "CCW") -> bool:
	print(currentPiece.rot.rotation_degrees, currentPiece.gridPos)
	#CCW 90  | X CCW   | CW X   |180 CW
	# X CW   | CW 0    | 270 CCW| CCW X
	var pos: Vector2 = currentPiece.gridPos[0]
	match currentPiece.rot.rotation_degrees:
		0.0:
			if ((direction == "CCW" and pos.y - 1 < 0) or
			(direction != "CCW" and pos.x - 1 < 0)):
				return false
			else: print(270,(pos.y - 1 < 0),(pos.x - 1 < 0))
		90.0:
			if ((direction == "CCW" and pos.x - 1 < 0) or
			(direction != "CCW" and pos.y + 1 > height - 1)):
				return false
			else: print(90, (pos.x - 1 < 0), (pos.y + 1 > height - 1))
		180.0:
			if ((direction == "CCW" and pos.y + 1 > height - 1) 
			or (direction != "CCW" and pos.x + 1 > width - 1)):
				print(180, (pos.y + 1 > height - 1), (pos.x + 1 > width - 1))
				return false
			else: print(180, (pos.y + 1 > height - 1), (pos.x + 1 > width - 1))
		270.0:
			if ((direction == "CCW" and pos.x + 1 > width - 1) 
			or (direction != "CCW" and pos.y - 1 < 0)):
				return false
			else: print(0,(pos.x + 1 > width - 1), (pos.y - 1 < 0))
		
	return true

#______________________________
#DEBUG
#______________________________
func fill_board() -> void:
	for i in width:
		for j in height:
			if j <= fail_rows:
				continue
			var piece = Globals.pieces.instantiate()
			$Grid.add_child(piece)
			#let the piece fall into pixel position
			#I like how it starts lol
			piece.position = grid_to_pixel(Vector2(i,j))
			#Give the piece it's grid position
			board[i][j] = piece

func find_piece(piece) -> Vector2:
	for i in width:
		for j in height:
			if board[i][j] == piece:
				return Vector2(i,j)
	
	return Vector2(-1,-1)

func display_board() -> void:
	for j in height:
		var debugString: String
		for i in width:
			if board[i][j] != null:
				debugString = str(debugString, board[i][j].currentType)
			else:
				debugString = str(debugString, null)
		
		print("Row: ",j,"\t", debugString)
