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
func spawn_piece() -> void:
	currentPiece = fullPiece.instantiate()
	$Grid.add_child(currentPiece)
	currentPiece.currentPos[0] = start_pos
	
	board[start_pos.x][start_pos.y] = currentPiece.pieces[0]
	currentPiece.rot.global_position = grid_to_pixel(start_pos)
	
	full_piece_rotation(start_pos)
	currentPiece.sync_position()
	print(currentPiece.currentPos)

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
	
	currentPiece.currentPos[1] = firstPos
	currentPiece.currentPos[2] = secondPos
	
	currentPiece.positions[1].global_position = grid_to_pixel(firstPos)
	currentPiece.positions[2].global_position = grid_to_pixel(secondPos)
	
	#print("Rotation: ", currentPiece.rot.rotation_degrees, "Center: ", pos,"\n",
	#" First: ", currentPiece.pieces[1].currentType, firstPos, currentPiece.positions[1].global_position,
	#"\n Second: ", currentPiece.pieces[2].currentType, secondPos, currentPiece.positions[2].global_position)

func move_piece() -> void:
	pass
	
func _process(_delta) -> void:
	if currentPiece.currentState == currentPiece.STATE.MOVE:
		if Input.is_action_just_pressed("ui_accept"):
			currentPiece.rot.rotation_degrees += fmod(rotation_degrees+90,360)
			
			if currentPiece.rot.rotation_degrees > 360:
				currentPiece.rot.rotation_degrees -= 360
			
			full_piece_rotation(currentPiece.currentPos[0])
		
		if Input.is_action_just_pressed("ui_cancel"):
			currentPiece.rot.rotation_degrees += fmod(rotation_degrees-90,360)
			
			if currentPiece.rot.rotation_degrees < 0:
				currentPiece.rot.rotation_degrees += 360
			
			full_piece_rotation(currentPiece.currentPos[0])
		
		
		if Input.is_action_just_pressed("ui_left"):
			#Find which piece is closest to the left
			#Prioritize them in the list
			var leftPos: Array[Node] = currentPiece.positions
			leftPos.sort_custom(func(a,b): return a.global_position.y < b.global_position.y)
			leftPos.sort_custom(func(a,b): return a.global_position.x < b.global_position.x)
			print("-----------LEFT------------")
			print(currentPiece.currentPos)
			
			for i in range(leftPos.size()):
				var pos: Vector2 = pixel_to_grid(leftPos[i])
				var nextPos: Vector2 =  Vector2(clamp(pos.x - 1,0,width - 1), pos.y)
				var regularIndex: int = currentPiece.currentPos.find(pos)
				print(currentPiece.pieces[regularIndex].currentType, leftPos[i].global_position, pos)
				print("Old Pos: ",pos ,"New Pos: ",nextPos, "Regular Index: ", regularIndex)
				
				#To prevent pieces from moving into already existent pieces
				if board[nextPos.x][nextPos.y] != null:
					print(board[nextPos.x][nextPos.y])
					break
				
				if nextPos == Vector2(0,0) or pos == Vector2(0,0):
					pass
				
				board[pos.x][pos.y] = null
				
				board[nextPos.x][nextPos.y] = currentPiece.pieces[regularIndex]
				currentPiece.currentPos[regularIndex] = nextPos
				
				currentPiece.currentPos[regularIndex].global_position = grid_to_pixel(nextPos)
				print(currentPiece.pieces[regularIndex].currentType, nextPos)
			
		if Input.is_action_just_pressed("ui_right"):
			#Find which piece is closest to the right
			#Prioritize them in the list
			var rightPos: Array[Node] = currentPiece.positions
			rightPos.sort_custom(func(a,b): return a.global_position.y < b.global_position.y)
			rightPos.sort_custom(func(a,b): return a.global_position.x > b.global_position.x)
			print("-----------RIGHT------------")
			print(currentPiece.currentPos)
			
			for i in range(rightPos.size()):
				var pos: Vector2 = pixel_to_grid(rightPos[i])
				var nextPos: Vector2 =  Vector2(clamp(pos.x + 1,0,width - 1), pos.y)
				var regularIndex: int = currentPiece.currentPos.find(pos)
				
				print(currentPiece.pieces[regularIndex].currentType, pos)
				print("Old Pos: ",pos ,"New Pos: ",nextPos)
				
				#To prevent pieces from moving into already existent pieces
				if board[nextPos.x][nextPos.y] != null:
					break
				   
				board[pos.x][pos.y] = null
				
				pos = Vector2(clamp(pos.x + 1,0,width), pos.y)
				
				board[pos.x][pos.y] = currentPiece.pieces[regularIndex]
				currentPiece.currentPos[regularIndex] = pos
				
				rightPos[i].global_position = grid_to_pixel(pos)
		
		#Both drop, up is hard drop, down is soft drop
		if Input.is_action_just_pressed("ui_up"):
			pass
		if Input.is_action_just_pressed("ui_down"):
			#Find which piece is closest to the right
			#Prioritize them in the list
			var floorPos: Array[Node] = currentPiece.positions
			floorPos.sort_custom(func(a,b): return a.global_position.y > b.global_position.y)
			
			for i in range(floorPos.size()):
				var regularIndex: int = currentPiece.positions.find(floorPos[i])
				var pos: Vector2 = currentPiece.currentPos[regularIndex]
				var nextPos: Vector2 =  Vector2(clamp(pos.x,0,width - 1), clamp(pos.y + 1, 0, height - 1))
				
				#To prevent pieces from moving into already existent pieces
				if board[nextPos.x][nextPos.y] != null:
					break
				
				board[pos.x][pos.y] = null
				
				pos = Vector2(clamp(pos.x,0,width), clamp(pos.y + 1, 0, height))
				
				board[pos.x][pos.y] = currentPiece.pieces[regularIndex]
				currentPiece.currentPos[regularIndex] = pos
				
				floorPos[i].global_position = grid_to_pixel(pos)
		
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
