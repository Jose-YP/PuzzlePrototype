extends Node2D

#CONSTANTS
const fullPiece = preload("res://Scenes/FullPiece.tscn")

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules

#Variables
var board: Array[Array]
var links: Array[Array]
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
	
	var rel = rules.piece_relationships
	Globals.glow_num = rel.glow_num
	Globals.relation_flags = [rel.earthRelations, rel.liquidRelations, rel.airRelations,
	rel.lightRelations, rel.darkRelations]
	#Make debugging easier
	match rules.debug_fills:
		1: fill_board()
		2: fill_column()
		4: make_overhang()
		_: find_links()
	
	#Make board and start the game
	board = make_grid()
	spawn_piece()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in rules.width:
		array.append([])
		for j in rules.height:
			array[i].append(null)
	
	return array

#Array order goes [anchor, clockwise, ccw]
func spawn_piece() -> void:
	if rules.spawning:
		currentPiece = fullPiece.instantiate()
		$Grid.add_child(currentPiece)
		currentPiece.gridPos[0] = rules.start_pos
		
		board[rules.start_pos.x][rules.start_pos.y] = currentPiece.pieces[0]
		currentPiece.rot.global_position = grid_to_pixel(rules.start_pos)
		
		for piece in currentPiece.pieces:
			piece.connect("find_adjacent", find_adjacent)
		
		full_piece_rotation(rules.start_pos, true)

#______________________________
#BASIC CONTROLS
#______________________________
func ground_timer_reset(oldPos, newPos) -> void:
	if oldPos != newPos and currentPiece.currentState == currentPiece.STATE.GROUNDED:
		$Timers/Grounded.start()

func full_piece_rotation(pos, start = false) -> void:
	var allNewPos: Array[Vector2i] = [pos,pos,pos]
	var allOldPos: Array[Vector2i] = [pos, find_piece(currentPiece.pieces[1]), find_piece(currentPiece.pieces[2])]
	
	if currentPiece.rot.rotation_degrees == 360:
		currentPiece.rot.rotation_degrees = 0
	
	#Rotation is  a float value
	match currentPiece.rot.rotation_degrees:
		0.0:
			allNewPos[1].y += 1
			allNewPos[2].x += 1
		90.0:
			allNewPos[1].x += 1
			allNewPos[2].y -= 1
		180.0:
			allNewPos[1].y -= 1
			allNewPos[2].x -= 1
		270.0:
			allNewPos[1].x -= 1
			allNewPos[2].y += 1
	
	#Spawning pieces will give oldPos of (-1,-1) basically deleting (8,8)
	if not start:
		board[allOldPos[1].x][allOldPos[1].y] = null
		board[allOldPos[2].x][allOldPos[2].y] = null
	
	allNewPos = rotate_pop(allNewPos)
	
	for i in range(currentPiece.positions.size()):
		ground_timer_reset(allOldPos[i], allNewPos[i])
		board[allNewPos[i].x][allNewPos[i].y] = currentPiece.pieces[i]
		currentPiece.gridPos[i] = allNewPos[i]
		currentPiece.positions[i].global_position = grid_to_pixel(allNewPos[i])
	
	currentPiece.sync_position()

func rotate_pop(newPos) -> Array[Vector2i]:
	var temp: Array[Vector2i]
	
	for i in range(rules.rotate_pop_checks.size()):
		temp = mini_rotate_pop(newPos.duplicate(), rules.rotate_pop_checks[i])
		
		if temp != newPos:
			var valid: bool = rotate_pop_cond(newPos)
			for pos in temp:
				if pos.x >= rules.width - 1 or pos.x < 0 or pos.y >= rules.height - 1 or pos.y < 0:
					print(rules.rotate_pop_checks[i], "Doesn't work")
					valid = false
			if valid:
				print("\n\nIs Valid: ", temp)
				return temp
	
	return newPos

func mini_rotate_pop(newPos, ammount) -> Array[Vector2i]:
	if not rotate_pop_cond(newPos):
		return newPos
	else:
		for i in range(newPos.size()):
			newPos[i] += ammount
		return newPos

func move_piece(ammount, direction = "X") -> void:
	for i in range(currentPiece.gridPos.size()):
		var pos: Vector2i = currentPiece.gridPos[i]
		#Only clear own piece
		if board[pos.x][pos.y] == currentPiece.pieces[i]:
			board[pos.x][pos.y] = null
		
		#move piece
		if direction == "X":
			pos.x = clamp(pos.x + ammount, 0, rules.width - 1)
		else:
			pos.y = clamp(pos.y + ammount, 0,rules.height - 1)
		
		ground_timer_reset(currentPiece.gridPos[i], pos)
		
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
	
	post_turn()

func hard_drop(target) -> void:
	for i in (currentPiece.pieces.size()):
		var pos: Vector2i = target[i]
		board[currentPiece.gridPos[i].x][currentPiece.gridPos[i].y] = null
		
		currentPiece.gridPos[i] = pos
		board[pos.x][pos.y] = currentPiece.pieces[i]
		currentPiece.positions[i].global_position = grid_to_pixel(pos)
	
	post_turn()

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
#POST TURN PROCESSES
#______________________________
func post_turn() -> void:
	currentPiece.currentState = currentPiece.STATE.PLACED
	currentPiece.sync_position()
	
	for piece in currentPiece.pieces:
		piece.reparent($Grid)
	
	currentPiece.queue_free()
	currentPiece = null
	
	print("\n")
	display_board()
	find_links()
	
	spawn_piece()

func find_links() -> void:
	for i in rules.width:
		for j in rules.height:
			var piece = board[i][j]
			if piece == null:
				continue
			piece.should_glow()

#______________________________
#POWER, CHAIN & BARRAGE
#______________________________

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(gridPos: Vector2i) -> Vector2:
	var Xnew: float = rules.origin.x + rules.offset.x * gridPos.x
	var Ynew: float = rules.origin.y + rules.offset.y * gridPos.y
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(piece) -> Vector2i:
	var Xnew: int = round((piece.global_position.x - rules.origin.x) / rules.offset.x)
	var Ynew: int = round((piece.global_position.y - rules.origin.y) / rules.offset.y)
	
	return Vector2i(Xnew, Ynew)

func find_piece(piece) -> Vector2i:
	for i in rules.width:
		for j in rules.height:
			if board[i][j] == piece:
				return Vector2i(i,j)
	
	return Vector2i(-1,-1)

#Adjacent array: [left,right,up,down] with null for any \wo a piece
func find_adjacent(piece) -> void:
	var adjacent: Array = [null, null, null, null]
	var pos = pixel_to_grid(piece)
	
	if pos.x - 1 >= 0 and board[pos.x - 1][pos.y] != null:
		adjacent[0] = board[pos.x - 1][pos.y]
	if pos.x + 1 < rules.width and board[pos.x + 1][pos.y] != null:
		adjacent[1] = board[pos.x + 1][pos.y]
	if pos.y - 1 >= 0 and board[pos.x][pos.y - 1] != null:
		adjacent[2] = board[pos.x][pos.y - 1]
	if pos.y + 1 < rules.height and board[pos.x][pos.y + 1] != null:
		adjacent[3] = board[pos.x][pos.y + 1]
	
	piece.adjacent = adjacent

func find_drop_bottom(pieces) -> Array[Vector2i]:
	#Handle lowest first, higher pieces can react to lowest's movement
	var finalPos: Array[Vector2i] = pieces.gridPos.duplicate()
	var regularIndexes: Array[int] = [0,1,2]
	var low: Array[Vector2i] = [Vector2i(-1,-1), Vector2i(-1,-1), Vector2i(-1,-1)]
	
	finalPos.sort_custom(func(a,b): return a.y > b.y)
	for i in range(pieces.gridPos.size()):
		for j in range(finalPos.size()):
			if finalPos[j] == pieces.gridPos[i]:
				regularIndexes[j] = i
	
	for i in range(pieces.gridPos.size()): #Find lowest place for each piece
		var regIndex = regularIndexes[i]
		var column: int = int(finalPos[i].x)
		
		for j in range(finalPos[i].y + 1, rules.height):
			#First regular piece in current piece's column
			if board[column][j] != null:
				#If it's not in the current peice, place it normally 
				if not pieces.in_full_piece(board[column][j]):
					low[regIndex] = Vector2i(column,j-1)
					break
				else: #Else find where the current peice is and place it above there
					
					var above = low[pieces.pieces.find(board[column][j])].y - 1
					low[regIndex] = Vector2i(column,above)
					break
			if j >= rules.height - 1: #Floor is lowest if a piece wasn't found
				low[regIndex] = Vector2i(column,rules.height-1)
				break
	
	return low

func can_move(direction) -> bool:
	for i in range(currentPiece.pieces.size()):
		var newPos: Vector2i = currentPiece.gridPos[i]
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
	var pos: Vector2i = currentPiece.gridPos[0]
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

func rotate_pop_cond(newPos) -> bool:
	var hit: bool = false
	#Check if the new position would override any current pieces
	for pos in newPos:
		if board[pos.x][pos.y] != null and not currentPiece.in_full_piece(board[pos.x][pos.y]):
			hit = true
			break
	
	return hit

#______________________________
#TIMERS
#______________________________
func _on_soft_drop_timeout():
	$Timers/Gravity.start()
	
	if can_move("Down"):
		move_piece(1, "Y")
		currentPiece.sync_position()
	else:
		place()

func _on_grounded_timeout():
	place()

func _on_gravity_timeout():
	$Timers/SoftDrop.start()
	if rules.gravity_on:
		if not can_move("Down") and not held:
			place()
		else:
			move_piece(1, "Y")
			currentPiece.sync_position()

#______________________________
#DEBUG
#______________________________
func add_piece(pos) -> void:
	var piece = Globals.piece.instantiate()
	$Grid.add_child(piece)
	piece.global_position = grid_to_pixel(Vector2i(pos.x,pos.y))
	board[pos.x][pos.y] = piece
	piece.connect("find_adjacent", find_adjacent)

func fill_board() -> void:
	for i in rules.width:
		for j in rules.grid_fill:
			if (rules.height-j-1) <= rules.fail_rows:
				continue
			var piece = Globals.piece.instantiate()
			$Grid.add_child(piece)
			#let the piece fall into pixel position
			#I like how it starts lol
			piece.global_position = grid_to_pixel(Vector2i(i,rules.height-j-1))
			#Give the piece it's grid position
			board[i][rules.height-j-1] = piece

func fill_column() -> void:
	var columnDim: Vector2i = rules.column_fill
	for j in range(int(columnDim.y)):
		add_piece(Vector2i(columnDim.x,rules.height-j-1))

func make_overhang() -> void:
	var overhangDim: Vector2i = rules.overhang_dimentions
	
	for j in range(int(overhangDim.y)):
		add_piece(Vector2i(overhangDim.x,rules.height-j-1))
	
	for i in range(1,int(overhangDim.x)):
		add_piece(Vector2i(overhangDim.x+i,overhangDim.y+1))

func display_board() -> void:
	for j in rules.height:
		var debugString: String
		for i in rules.width:
			if board[i][j] != null:
				debugString = str(debugString, board[i][j].currentType)
			else:
				debugString = str(debugString, null)
		
		print("Row: ",j,"\t", debugString)
