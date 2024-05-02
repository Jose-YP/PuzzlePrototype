extends Node2D

#CONSTANTS
const fullPiece = preload("res://Scenes/FullPiece.tscn")

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules

#Variables
var board: Array[Array]
var currentPiece: Node2D
var inputHoldTime: float = 0
var held: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Make Timers function
	$Timers/Gravity.set_wait_time(rules.gravity)
	$Timers/SoftDrop.set_wait_time(rules.soft_drop)
	$Timers/Grounded.set_paused(false)
	$Timers/SoftDrop.set_paused(false)
	$Timers/Gravity.set_paused(false)
	
	#Make board and start the game
	board = make_grid()
	spawn_piece()
	#Make debugging easier
	if rules.debug_fills & 1:
		fill_board()
	if rules.debug_fills & 2:
		fill_column()
	if rules.debug_fills & 4:
		make_overhang()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in rules.width:
		array.append([])
		for j in rules.height:
			array[i].append(null)
	
	return array

#Array order goes [anchor, clockwise, ccw]
func spawn_piece() -> void:
	currentPiece = fullPiece.instantiate()
	$Grid.add_child(currentPiece)
	currentPiece.gridPos[0] = rules.start_pos
	
	board[rules.start_pos.x][rules.start_pos.y] = currentPiece.pieces[0]
	currentPiece.rot.global_position = grid_to_pixel(rules.start_pos)
	
	currentPiece.sync_position()
	full_piece_rotation(rules.start_pos, true)
	currentPiece.sync_position()

#______________________________
#BASIC CONTROLS
#______________________________
func full_piece_rotation(pos, start = false) -> void:
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
	
	var oldPos: Vector2 = find_piece(currentPiece.pieces[1])
	var oldPos2: Vector2 = find_piece(currentPiece.pieces[2])
	
	if not start:
		board[oldPos.x][oldPos.y] = null
		board[oldPos2.x][oldPos2.y] = null
	
	board[firstPos.x][firstPos.y] = currentPiece.pieces[1]
	board[secondPos.x][secondPos.y] = currentPiece.pieces[2]
	
	currentPiece.gridPos[1] = firstPos
	currentPiece.gridPos[2] = secondPos
	
	currentPiece.positions[0].global_position = grid_to_pixel(pos)
	currentPiece.positions[1].global_position = grid_to_pixel(firstPos)
	currentPiece.positions[2].global_position = grid_to_pixel(secondPos)

func rotate_pop() -> bool:
	return false

func move_piece(ammount, direction = "X") -> void:
	for i in range(currentPiece.gridPos.size()):
		var pos: Vector2 = currentPiece.gridPos[i]
		#Only clear own piece
		if board[pos.x][pos.y] == currentPiece.pieces[i]:
			board[pos.x][pos.y] = null
		
		#move piece
		if direction == "X":
			pos.x += ammount
		else:
			pos.y += ammount
		
		#Keep board pos.x.y since thats new location of piece
		#Update visual and coded grid position
		currentPiece.gridPos[i] = pos
		board[pos.x][pos.y] = currentPiece.pieces[i]
		currentPiece.positions[i].global_position = grid_to_pixel(pos)

func movement() -> void:
	if Input.is_action_just_pressed("ui_accept") and can_rotate("CCW"):
		currentPiece.rot.rotation_degrees += fmod(rotation_degrees+90,360)
		if currentPiece.rot.rotation_degrees > 360:
			currentPiece.rot.rotation_degrees -= 360
		
		full_piece_rotation(currentPiece.gridPos[0])
		
	if Input.is_action_just_pressed("ui_cancel") and can_rotate("CLOCKWISE"):
		currentPiece.rot.rotation_degrees += fmod(rotation_degrees-90,360)
		if currentPiece.rot.rotation_degrees < 0:
			currentPiece.rot.rotation_degrees += 360
		
		full_piece_rotation(currentPiece.gridPos[0])
	
	if Input.is_action_just_pressed("ui_left") and can_move("Left"):
		move_piece(-1)
	
	if Input.is_action_just_pressed("ui_right") and can_move("Right"):
		move_piece(1)
	
	if Input.is_anything_pressed():
		currentPiece.sync_position()

func place() -> void:
	for i in range(currentPiece.pieces.size()):
		var orgPos = find_piece(currentPiece.pieces[i])
		board[orgPos.x][orgPos.y] = null
		var pos = currentPiece.gridPos[i]
		board[pos.x][pos.y] = currentPiece.pieces[i]
	print("Placed at: ", currentPiece.gridPos)
	currentPiece.currentState = currentPiece.STATE.PLACED
	currentPiece = null
	spawn_piece()

func hard_drop(target) -> void:
	print("From: ",currentPiece.gridPos, " To: ", target)
	print("\n break")
	for i in (currentPiece.pieces.size()):
		var pos: Vector2 = target[i]
		board[currentPiece.gridPos[i].x][currentPiece.gridPos[i].y] = null
		
		currentPiece.gridPos[i] = pos
		board[pos.x][pos.y] = currentPiece.pieces[i]
		currentPiece.positions[i].global_position = grid_to_pixel(pos)
	currentPiece.sync_position()
	
	print("Placed at: ", currentPiece.gridPos)
	currentPiece.currentState = currentPiece.STATE.PLACED
	currentPiece = null
	display_board()
	spawn_piece()
	display_board()

func drop() -> void:
	#Both drop, up is hard drop, down is soft drop
	if Input.is_action_just_pressed("ui_up"):
		hard_drop(find_drop_bottom(currentPiece))
		
	if Input.is_action_just_pressed("ui_down") and can_move("Down"):
		move_piece(1, "Y")
		currentPiece.sync_position()
		$Timers/SoftDrop.start()

func _process(delta) -> void:
	if currentPiece.currentState == currentPiece.STATE.MOVE:
		movement()
		drop()
	if currentPiece.currentState == currentPiece.STATE.GROUNDED:
		movement()
		drop()
	
	if Input.is_action_pressed("ui_down"):
		inputHoldTime += delta
		held = inputHoldTime > rules.soft_drop
	if Input.is_action_just_released("ui_down"):
		$Timers/SoftDrop.stop()
		inputHoldTime = 0
		held = false

#______________________________
#POWER
#______________________________

#______________________________
#CHAIN
#______________________________

#______________________________
#BARRAGE & ETC
#______________________________

#______________________________
#REACTIONS
#______________________________

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(gridPos: Vector2) -> Vector2:
	var Xnew: float = rules.origin.x + rules.offset.x * gridPos.x
	var Ynew: float = rules.origin.y + rules.offset.y * gridPos.y
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(piece) -> Vector2:
	var Xnew: int = round((piece.global_position.x - rules.origin.x) / rules.offset.x)
	var Ynew: int = round((piece.global_position.y - rules.origin.y) / rules.offset.y)
	
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

func find_drop_bottom(pieces) -> Array[Vector2]:
	#Handle lowest first, higher pieces can react to lowest's movement
	var finalPos: Array[Vector2] = pieces.gridPos.duplicate()
	var regularIndexes: Array[int] = [0,1,2]
	var low: Array[Vector2] = [Vector2(-1,-1), Vector2(-1,-1), Vector2(-1,-1)]
	
	finalPos.sort_custom(func(a,b): return a.y > b.y)
	for i in range(pieces.gridPos.size()):
		for j in range(finalPos.size()):
			if finalPos[j] == pieces.gridPos[i]:
				regularIndexes[j] = i
	
	print(finalPos, pieces.gridPos, regularIndexes)
	print("\n-----------Break----------")
	
	for i in range(pieces.gridPos.size()): #Find lowest place for each piece
		var regIndex = regularIndexes[i]
		var column: int = int(finalPos[i].x)
		print("Column: ",column," ",pieces.pieces[regIndex].currentType, finalPos[i])
		
		for j in range(finalPos[i].y + 1, rules.height):
			#First regular piece in current piece's column
			if j == rules.height - 1:
				print("\nBreak")
			if board[column][j] != null:
				#If it's not in the current peice, place it normally 
				if not pieces.in_full_piece(board[column][j]):
					print("Found piece ",board[column][j].currentType, board[column][j],
					 " at ", Vector2(column,j), " so ", Vector2(column,j-1))
					low[regIndex] = Vector2(column,j-1)
					break
				else: #Else find where the current peice is and place it above there
					
					var above = low[pieces.pieces.find(board[column][j])].y - 1
					print("Place above ",board[column][j].currentType, low[regularIndexes[i - 1]],
					 " So...", above)
					low[regIndex] = Vector2(column,above)
					break
			if j >= rules.height - 1: #Floor is lowest if a piece wasn't found
				print(pieces.pieces[regIndex].currentType, " Found Floor placing at ",Vector2(column,rules.height-1))
				low[regIndex] = Vector2(column,rules.height-1)
				break
			
		if low[regIndex] == Vector2(-1,-1):
			print("Oops")
			
	
	print(pieces.gridPos, low)
	return low

func can_move(direction) -> bool:
	for i in range(currentPiece.pieces.size()):
		var newPos: Vector2 = currentPiece.gridPos[i]
		#Check if a piece can move horizontally or down
		match direction:
			"Left":
				if newPos.x - 1 < 0: return false
				else: newPos.x -= 1
			"Right":
				if newPos.x + 1 > rules.width - 1: return false
				else: newPos.x += 1
			"Down":
				if newPos.y + 1 > rules.height - 1:
					return false
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
	#Don't ask me how, this is just what I witnessed
	#CCW 90  | X CCW   |   CW X   |180 CW
	# X CW   | CW 0    | 270 CCW  | CCW X
	#X - Anchor, CCW - Counter Clockwise, CW -Clockwise
	var pos: Vector2 = currentPiece.gridPos[0]
	match currentPiece.rot.rotation_degrees:
		0.0:
			if ((direction == "CCW" and pos.y - 1 < 0) or
			(direction != "CCW" and pos.x - 1 < 0)):
				return false
		90.0:
			if ((direction == "CCW" and pos.x - 1 < 0) or
			(direction != "CCW" and pos.y + 1 > rules.height - 1)):
				return false
		180.0:
			if ((direction == "CCW" and pos.y + 1 > rules.height - 1) 
			or (direction != "CCW" and pos.x + 1 > rules.width - 1)):
				return false
		270.0:
			if ((direction == "CCW" and pos.x + 1 > rules.width - 1) 
			or (direction != "CCW" and pos.y - 1 < 0)):
				return false
		
	return true

#______________________________
#TIMERS
#______________________________
func _on_soft_drop_timeout():
	if can_move("Down"):
		move_piece(1, "Y")
		currentPiece.sync_position()
	else:
		place()

func _on_grounded_timeout():
	pass # Replace with function body.

func _on_gravity_timeout():
	if rules.gravity_on:
		if not can_move("Down") and not held:
			place()
		else:
			move_piece(1, "Y")
			currentPiece.sync_position()

#______________________________
#DEBUG
#______________________________
func fill_board() -> void:
	for i in rules.width:
		for j in rules.grid_fill:
			if (rules.height-j-1) <= rules.fail_rows:
				continue
			var piece = Globals.piece.instantiate()
			$Grid.add_child(piece)
			#let the piece fall into pixel position
			#I like how it starts lol
			piece.global_position = grid_to_pixel(Vector2(i,rules.height-j-1))
			#Give the piece it's grid position
			board[i][rules.height-j-1] = piece

func fill_column() -> void:
	pass

func make_overhang() -> void:
	pass

func find_piece(piece) -> Vector2:
	for i in rules.width:
		for j in rules.height:
			if board[i][j] == piece:
				return Vector2(i,j)
	
	return Vector2(-1,-1)

func display_board() -> void:
	for j in rules.height:
		var debugString: String
		for i in rules.width:
			if board[i][j] != null:
				debugString = str(debugString, board[i][j].currentType)
			else:
				debugString = str(debugString, null)
		
		print("Row: ",j,"\t", debugString)
