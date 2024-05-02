extends Node2D

#CONSTANTS
const fullPiece = preload("res://Scenes/FullPiece.tscn")

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules

#Variables
var board: Array[Array]
var currentPiece: Node2D

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
	fill_board()

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
	
	full_piece_rotation(rules.start_pos)
	currentPiece.sync_position()

#______________________________
#BASIC CONTROLS
#______________________________
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
		var pos: Vector2 = currentPiece.gridPos[i]
		var check = board[pos.x][pos.y]
		#Only clear own piece
		if check == currentPiece.pieces[i]:
			check = null
		
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
	
	#Both drop, up is hard drop, down is soft drop
	if Input.is_action_just_pressed("ui_up"):
		pass
	if Input.is_action_just_pressed("ui_down") and can_move("Down"):
		move_piece(-1, "Y")
	
	if Input.is_anything_pressed():
		currentPiece.sync_position()

func _process(_delta) -> void:
	if currentPiece.currentState == currentPiece.STATE.MOVE:
		movement()
	if currentPiece.currentState == currentPiece.STATE.GROUNDED:
		movement()

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
	print(currentPiece.pieces)
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
					print("Hit Floor")
					return false
				else: newPos.y += 1
			"Up":
				if newPos.y - 1 < 0: return false
				else: newPos.y -= 1
		
		var piece = board[newPos.x][newPos.y]
		print(piece)
		if piece != null and not currentPiece.in_full_piece(piece):
			display_board()
			print("Found ", piece.currentType, " in ", newPos, " bellow ", 
			currentPiece.pieces[i].currentType, currentPiece.gridPos[i])
			return false
		else:
			print(piece != null, not currentPiece.in_full_piece(piece))
	
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
	pass # Replace with function body.

func _on_grounded_timeout():
	pass # Replace with function body.

func _on_gravity_timeout():
	if rules.gravity_on:
		if not can_move("Down"):
			for i in range(currentPiece.pieces.size()):
				var orgPos = find_piece(currentPiece.pieces[i])
				board[orgPos.x][orgPos.y] = null
				var pos = currentPiece.gridPos[i]
				board[pos.x][pos.y] = currentPiece.pieces[i]
			print("Placed at: ", currentPiece.gridPos)
			currentPiece.currentState = currentPiece.STATE.PLACED
			currentPiece = null
			spawn_piece()
		
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
