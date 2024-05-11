extends Node2D

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules
@onready var realHeight: int = rules.height - 1
@onready var RUI: Control = $RightUI
@onready var LUI: Control = $LeftUI
@onready var baseGroundedTime = %Grounded.get_wait_time()
@onready var baseGravTime = %Gravity.get_wait_time()

signal brokeBead
signal brokeAll
signal fail
signal main
signal playSFX(index)

#CONSTANTS
const fullBead = preload("res://Scenes/Board&Beads/FullBead.tscn")

#Variables
var board: Array[Array]
var chains: Array[Array]
var fixUp: Array = []
var currentBead: Node2D
var beadsUpnext: Array[Node2D] = [null, null, null]
var inputHoldTime: float = 0
var holdBreakChain: int = 0
var brokenBeads: int = 0
var score: int = 0
var breakNum: int = 0
var held: bool = false
var breaking: bool = false
var fallPaused: bool = false
var highScored: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Make board before adding anything
	board = make_grid()
	
	#Make Timers function
	%Gravity.set_wait_time(rules.gravity)
	%SoftDrop.set_wait_time(rules.soft_drop)
	pauseFall(false)
	
	var rel = rules.bead_relationships
	Globals.glow_num = rel.glow_num
	Globals.relation_flags = [rel.earthRelations, rel.seaRelations, rel.airRelations,
	rel.lightRelations, rel.darkRelations]
	
	RUI.position += grid_to_pixel(Vector2i(rules.width+1,1))
	LUI.position.y += grid_to_pixel(Vector2i(0,1)).y
	RUI.rules = rules
	LUI.rules = rules
	
	#Make debugging easier
	match rules.debug_fills:
		1: fill_board()
		2: fill_column()
		4: make_overhang()
	
	#start the game
	spawn_beads()
	pull_next_bead()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in rules.width:
		array.append([])
		for j in rules.height:
			array[i].append(null)
	
	return array

#Array order goes [anchor, clockwise, ccw]
func spawn_beads() -> void:
	for i in range(3):
		if beadsUpnext[i] == null:
			beadsUpnext[i] = fullBead.instantiate()
			$Hold.add_child(beadsUpnext[i])
	LUI.update_next(beadsUpnext)

func pull_next_bead() -> void:
	if rules.spawning:
		currentBead = beadsUpnext.pop_front()
		beadsUpnext.append(null)
		$Hold.remove_child(currentBead)
		$Grid.add_child(currentBead)
		currentBead.gridPos[0] = rules.start_pos
		
		board[rules.start_pos.x][rules.start_pos.y] = currentBead.beads[0]
		currentBead.rot.global_position = grid_to_pixel(rules.start_pos)
		
		for bead in currentBead.beads:
			bead.connect("find_adjacent", find_adjacent)
		
		full_bead_rotation(rules.start_pos, true)
		spawn_beads()

#______________________________
#BASIC CONTROLS: MOVE
#______________________________
func move_bead(ammount, direction = "X") -> void:
	for i in range(currentBead.gridPos.size()):
		var pos: Vector2i = currentBead.gridPos[i]
		#Only clear own bead
		if board[pos.x][pos.y] == currentBead.beads[i]:
			board[pos.x][pos.y] = null
		
		#move bead
		if direction == "X":
			pos.x = clamp(pos.x + ammount, 0, rules.width - 1)
		else:
			pos.y = clamp(pos.y + ammount, 0,realHeight)
		
		ground_timer_reset(currentBead.gridPos[i], pos)
		
		#Keep board pos.x.y since thats new location of bead
		#Update visual and coded grid position
		currentBead.gridPos[i] = pos
		board[pos.x][pos.y] = currentBead.beads[i]
		currentBead.positions[i].global_position = grid_to_pixel(pos)
		playSFX.emit(0)

func movement() -> void:
	if Input.is_action_just_pressed("ui_accept") and can_rotate("CCW"):
		currentBead.rot.rotation_degrees += fmod(rotation_degrees+90,360)
		if currentBead.rot.rotation_degrees > 360:
			currentBead.rot.rotation_degrees -= 360
		
		full_bead_rotation(currentBead.gridPos[0])
		
	if Input.is_action_just_pressed("ui_cancel") and can_rotate("CLOCKWISE"):
		currentBead.rot.rotation_degrees += fmod(rotation_degrees-90,360)
		if currentBead.rot.rotation_degrees < 0:
			currentBead.rot.rotation_degrees += 360
		
		full_bead_rotation(currentBead.gridPos[0])
	
	if Input.is_action_just_pressed("ui_left") and can_move("Left"):
		move_bead(-1)
	
	if Input.is_action_just_pressed("ui_right") and can_move("Right"):
		move_bead(1)
	
	if Input.is_anything_pressed():
		currentBead.sync_position()

func place() -> void:
	for i in range(currentBead.beads.size()):
		var orgPos = find_bead(currentBead.beads[i])
		board[orgPos.x][orgPos.y] = null
		var pos = currentBead.gridPos[i]
		board[pos.x][pos.y] = currentBead.beads[i]
	
	playSFX.emit(3)
	post_turn()

func hard_drop(target) -> void:
	print(target)
	var prevPos: Vector2i = currentBead.gridPos[0]
	for i in (currentBead.beads.size()):
		display_board()
		var pos: Vector2i = target[i]
		#First time this happened was when hard dropping from the bottom
		board[currentBead.gridPos[i].x][currentBead.gridPos[i].y] = null
		
		currentBead.gridPos[i] = pos
		board[pos.x][pos.y] = currentBead.beads[i]
		currentBead.positions[i].global_position = grid_to_pixel(pos)
		print("Now: ",pos, board[pos.x][pos.y], " Prev: ", prevPos, board[prevPos.x][prevPos.y])
		if board[pos.x][pos.y] == null:
			print()
		if board[prevPos.x][prevPos.y] == null and i != 0:
			print(i != 0)
			
		prevPos = pos
	
	for i in range(currentBead.beads.size()):
		var loc = find_bead(currentBead.beads[i])
		print(loc)
		if loc == null or loc > Vector2i(rules.width, realHeight) or loc < Vector2i(0,0):
			print(currentBead.beads[i],target[i])
			fixUp.append(currentBead.beads[i])
	
	playSFX.emit(2)
	post_turn()

func drop() -> void:
	#Both drop, up is hard drop, down is soft drop
	if Input.is_action_just_pressed("ui_up"):
		hard_drop(find_drop_bottom(currentBead))
		
	if Input.is_action_just_pressed("ui_down") and can_move("Down"):
		move_bead(1, "Y")
		currentBead.sync_position()
		$Timers/SoftDrop.start()

#______________________________
#BASIC CONTROLS: ROTATE
#______________________________
func ground_timer_reset(oldPos, newPos) -> void:
	if oldPos != newPos and currentBead.currentState == currentBead.STATE.GROUNDED:
		$Timers/Grounded.start()

func full_bead_rotation(pos, start = false) -> void:
	var allNewPos: Array[Vector2i] = [pos,pos,pos]
	var allOldPos: Array[Vector2i] = [pos, find_bead(currentBead.beads[1]), find_bead(currentBead.beads[2])]
	
	if currentBead.rot.rotation_degrees == 360:
		currentBead.rot.rotation_degrees = 0
	
	#Rotation is  a float value
	match currentBead.rot.rotation_degrees:
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
	
	#Spawning beads will give oldPos of (-1,-1) basically deleting (8,8)
	if not start:
		board[allOldPos[1].x][allOldPos[1].y] = null
		board[allOldPos[2].x][allOldPos[2].y] = null
	
	allNewPos = rotate_pop(allNewPos)
	
	for i in range(currentBead.positions.size()):
		ground_timer_reset(allOldPos[i], allNewPos[i])
		board[allNewPos[i].x][allNewPos[i].y] = currentBead.beads[i]
		currentBead.gridPos[i] = allNewPos[i]
		currentBead.positions[i].global_position = grid_to_pixel(allNewPos[i])
	
	currentBead.sync_position()
	if start == false:
		playSFX.emit(1)

func rotate_pop(newPos) -> Array[Vector2i]:
	var temp: Array[Vector2i]
	
	for i in range(rules.rotate_pop_checks.size()):
		temp = mini_rotate_pop(newPos.duplicate(), rules.rotate_pop_checks[i])
		
		if temp != newPos:
			var valid: bool = not rotate_pop_cond(temp)
			if not valid:
				continue
			for pos in temp:
				if not within_bounds(pos) or not within_bounds(pos,"Y"):
					valid = false
			if valid:
				return temp
	
	return newPos

func mini_rotate_pop(newPos, ammount) -> Array[Vector2i]:
	if rotate_pop_cond(newPos):
		for i in range(newPos.size()):
			newPos[i] += ammount
	return newPos

#______________________________
#PROCESSING
#______________________________
func _process(delta) -> void:
	if not breaking:
		if currentBead.currentState == currentBead.STATE.MOVE and not fallPaused:
			movement()
			drop()
		if currentBead.currentState == currentBead.STATE.GROUNDED and not fallPaused:
			movement()
			drop()
		
		if Input.is_action_pressed("ui_down") and not fallPaused:
			inputHoldTime += delta
			held = inputHoldTime > rules.soft_drop
		if Input.is_action_just_released("ui_down"):
			$Timers/SoftDrop.stop()
			inputHoldTime = 0
			held = false
		if Input.is_action_just_pressed("Y") and breakNum > 0:
			#Full Bead should not move during this
			pauseFall(true)
			find_chains()
			for i in range(chains.size()):
				#Make sure the starting value is bracketed into an array
				holdBreakChain = i
				breaking = true
				brokenBeads += chains[i].size()
				break_order([chains[i].pick_random()])
				await brokeAll
			print("\n\n Finish")
			RUI.update_beads(brokenBeads)
			post_break()
			pauseFall(false)

#______________________________
#POST TURN PROCESSES
#______________________________
func post_turn() -> void:
	currentBead.currentState = currentBead.STATE.PLACED
	currentBead.sync_position()
	
	for bead in currentBead.beads:
		bead.reparent($Grid)
		bead.set_name(str(find_bead(bead)))
	
	currentBead.queue_free()
	currentBead = null
	
	for bead in fixUp: #Last minute fix
		var pos = pixel_to_grid(bead)
		board[pos.x][pos.y] = bead
	
	detect_fail()
	LUI.update_meter(1)
	display_board()
	find_links()
	
	pull_next_bead()

func find_links() -> void:
	for i in rules.width:
		for j in rules.height:
			var bead = board[i][j]
			if bead == null: #skip anything that has glowing or no beads
				continue
			bead.should_glow()
			if bead.glowing:
				bead.should_chain()

func post_break() -> void:
	for i in range(rules.width):
		#Start at the bottom of the board and push those down first
		for j in range(realHeight,-1,-1):
			var bead = board[i][j]
			if currentBead.in_full_bead(bead) or bead == null:
				continue
			
			var target = mini_find_bottom(Vector2i(i,j),i)
			if target.x == -1:
				target = Vector2i(i,j)
			
			print("Bottom of ", bead, " is ", target)
			board[i][j] = null
			board[target.x][target.y] = bead
			bead.global_position = grid_to_pixel(target)
			bead.set_name(str(target))
	
	$Timers/ChainFinish.start()
	await  $Timers/ChainFinish.timeout
	
	breaking = false
	breakNum -= 1
	LUI.breakText.text = str(breakNum)
	if breakNum < 1:
		LUI.breakNotifier.hide()
	
	#Check for any broken links and new links
	find_links()

func detect_fail() -> void:
	#Only check for fail spots
	for i in range(rules.safe_high_columns, rules.width - rules.safe_high_columns):
		for j in rules.fail_rows:
			if board[i][j] != null:
				print("Found a bead in ",board[i][j] )
				fail.emit()

#______________________________
#CHAIN
#______________________________
func find_chains() -> void:
	chains.clear()
	
	for i in rules.width:
		for j in rules.height:
			var bead = board[i][j]
			if bead == null: #skip anything that has glowing or no beads
				continue
			if not in_chains(bead) and bead.chainedLinks.size() > 0:
				var tempChain = add_links(bead.get_links())
				score = rules.totalScore(tempChain)
				print("\n\nTOTAL SCORE: ", score)
				RUI.update_score(score)
				chains.append(new_set_chains(tempChain))
	
	print(chains)

func break_order(chainPart) -> void:
	#First find every adjacent bead to break in the future
	#They must be connected to the current bead
	var adjacent: Dictionary = {}
	for bead in chainPart:
		if not is_instance_valid(bead):
			continue
		find_adjacent(bead)
		for adj in bead.adjacent:
			if (is_instance_valid(adj)
			 and chains[holdBreakChain].find(adj) != -1):
				adjacent[adj] = adj
	
	print("Breaking: ",chainPart, " Will break: ",adjacent.keys())
	
	break_bead(chainPart)
	await brokeBead
	var empty = true
	for bead in chains[holdBreakChain]:
		if bead != null:
			empty = false
	if empty:
		brokeAll.emit()
		return
	break_order(adjacent.keys())

func break_bead(chainPart) -> void:
	for bead in chainPart:
		if is_instance_valid(bead):
			bead.destroy_anim()
	$Timers/ChainClear.start()
	await $Timers/ChainClear.timeout
	emit_signal("brokeBead")
	
	for bead in chainPart:
		if is_instance_valid(bead):
			var pos = find_bead(bead)
			board[pos.x][pos.y] = null
			bead.queue_free()

func find_connections(connection, recursion = []) -> Array:
	var tempChain = recursion
	for bead in connection:
		var link = bead.get_links()
		if not in_temp_chain(tempChain, link):
			add_links(link,tempChain)
	
	return tempChain

func add_links(link: Dictionary, recursion: Array = []) -> Array:
	var tempChain: Array = recursion
	if not in_temp_chain(tempChain, link):
		tempChain.append(link)
	
	for bead in link:
		if bead.chainedLinks.size() != 0:
			tempChain = find_connections(bead.chainedLinks, tempChain)
	
	return tempChain

func in_temp_chain(tempChain, link) -> bool:
	for tempLink in tempChain:
		if link == tempLink:
			return true
	return false

func new_set_chains(tempChain) -> Array:
	var finalChain: = []
	for link in tempChain:
		for bead in link:
			finalChain.append(link[bead])
	return finalChain

func in_chains(bead) -> bool:
	for chain in chains:
		if chain.find(bead) != -1:
			return true
	return false

#______________________________
#CONVERSION
#______________________________
#Turn computer positions into visual positions
func grid_to_pixel(gridPos: Vector2i) -> Vector2:
	var Xnew: float = rules.origin.x + rules.offset.x * gridPos.x
	var Ynew: float = rules.origin.y + rules.offset.y * gridPos.y
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(bead) -> Vector2i:
	var Xnew: int = round((bead.global_position.x - rules.origin.x) / rules.offset.x)
	var Ynew: int = round((bead.global_position.y - rules.origin.y) / rules.offset.y)
	return Vector2i(Xnew, Ynew)

func find_bead(bead) -> Vector2i:
	for i in rules.width:
		for j in rules.height:
			if board[i][j] == bead:
				return Vector2i(i,j)
	
	return Vector2i(-1,-1)

#Adjacent array: [left,right,up,down] with null for any \wo a bead
func find_adjacent(bead) -> void:
	var adjacent: Array = [null, null, null, null]
	var pos = find_bead(bead)
	
	if pos.x - 1 >= 0 and board[pos.x - 1][pos.y] != null:
		adjacent[0] = board[pos.x - 1][pos.y]
	if pos.x + 1 < rules.width and board[pos.x + 1][pos.y] != null:
		adjacent[1] = board[pos.x + 1][pos.y]
	if pos.y - 1 >= 0 and board[pos.x][pos.y - 1] != null:
		adjacent[2] = board[pos.x][pos.y - 1]
	if pos.y + 1 < rules.height and board[pos.x][pos.y + 1] != null:
		adjacent[3] = board[pos.x][pos.y + 1]
	
	bead.adjacent = adjacent

func find_drop_bottom(beads) -> Array[Vector2i]:
	#Handle lowest first, higher beads can react to lowest's movement
	var finalPos: Array[Vector2i] = beads.gridPos.duplicate()
	var regularIndexes: Array[int] = [0,1,2]
	var low: Array[Vector2i] = beads.gridPos.duplicate()
	
	finalPos.sort_custom(func(a,b): return a.y > b.y)
	for i in range(beads.gridPos.size()):
		for j in range(finalPos.size()):
			if finalPos[j] == beads.gridPos[i]:
				regularIndexes[j] = i
	
	for i in range(beads.gridPos.size()): #Find lowest place for each bead
		var regIndex = regularIndexes[i]
		var column: int = int(finalPos[i].x)
		var target = mini_find_bottom(finalPos[i],column,low[regIndex],true)
		if target.x == -1:
			var above = low[beads.beads.find(board[column][target.y])].y - 1
			low[regIndex] = Vector2i(column,above)
		else:
			low[regIndex] = target
	return low

func mini_find_bottom(pos,column,default = pos,hardDropping = false) -> Vector2i:
	for j in range(pos.y + 1, rules.height):
		#First regular bead in current bead's column
		if board[column][j] != null:
			var inCurrent: bool = false
			if hardDropping:
				var Bead = currentBead
				inCurrent = Bead.in_full_bead(board[column][j], board[pos.x][pos.y])
			
			#If it's not in the current peice, place it normally 
			if not inCurrent:
				return Vector2i(column,j-1)
			#Find if the current bead is already on the floor
			elif default.y == realHeight: 
				break
			else: #Else find where the current peice is and place it above there
				return Vector2i(-1,j)
		if j >= realHeight: #Floor is lowest if a bead wasn't found
			return Vector2i(column,realHeight)
	return default

func can_move(direction) -> bool:
	for i in range(currentBead.beads.size()):
		var newPos: Vector2i = currentBead.gridPos[i]
		var sameBead = board[newPos.x][newPos.y]
		#Check if a bead can move horizontally or down
		match direction:
			"Left":
				if newPos.x - 1 < 0: return false
				else: newPos.x -= 1
			"Right":
				if newPos.x + 1 > rules.width - 1: return false
				else: newPos.x += 1
			"Down":
				if newPos.y + 1 > realHeight:
					return false
				else: newPos.y += 1
			"Up":
				if newPos.y - 1 < 0: return false
				else: newPos.y -= 1
		
		var bead = board[newPos.x][newPos.y]
		if bead != null and not currentBead.in_full_bead(bead,sameBead):
			return false
	
	return true

#Check if the rotation will hit the wall
func can_rotate(direction = "CCW") -> bool:
	#Don't ask me how, this is just what I witnessed
	#CCW 90  | X CCW   |   CW X   |180 CW
	# X CW   | CW 0    | 270 CCW  | CCW X
	#X - Anchor, CCW - Counter Clockwise, CW -Clockwise
	var pos: Vector2i = currentBead.gridPos[0]
	match currentBead.rot.rotation_degrees:
		0.0:
			if ((direction == "CCW" and pos.y - 1 < 0) or
			(direction != "CCW" and pos.x - 1 < 0)):
				return false
		90.0:
			if ((direction == "CCW" and pos.x - 1 < 0) or
			(direction != "CCW" and pos.y + 1 > realHeight)):
				return false
		180.0:
			if ((direction == "CCW" and pos.y + 1 > realHeight) 
			or (direction != "CCW" and pos.x + 1 > rules.width - 1)):
				return false
		270.0:
			if ((direction == "CCW" and pos.x + 1 > rules.width - 1) 
			or (direction != "CCW" and pos.y - 1 < 0)):
				return false
		
	return true

func rotate_pop_cond(newPos) -> bool:
	#Check if the new position would override any current beads
	for pos in newPos:
		if not within_bounds(pos) or not within_bounds(pos,"Y"):
			return true
		if board[pos.x][pos.y] != null and not currentBead.in_full_bead(board[pos.x][pos.y]):
			return true
	return false

func within_bounds(pos,where = "X") -> bool:
	if where == "X":
		if pos.x >= rules.width - 1 or pos.x < 0:
			return false
	else:
		if pos.y >= realHeight or pos.y < 0:
			return false
	
	return true

#______________________________
#TIMERS & OUTSIDE SIGNALS
#______________________________
func pauseFall(should):
	if should:
		fallPaused = true
		%Grounded.set_paused(true)
		%SoftDrop.set_paused(true)
		%Gravity.set_paused(true)
	else:
		fallPaused = false
		%Grounded.set_paused(false)
		%SoftDrop.set_paused(false)
		%Gravity.set_paused(false)

func _on_soft_drop_timeout() -> void:
	if can_move("Down"):
		move_bead(1, "Y")
		currentBead.sync_position()
	else:
		place()

func _on_grounded_timeout() -> void:
	place()

func _on_gravity_timeout() -> void:
	if rules.gravity_on:
		if not can_move("Down") and not held:
			place()
		else:
			move_bead(1, "Y")
			currentBead.sync_position()

func _on_left_ui_break_ready():
	breakNum += 1
	LUI.breakNotifier.show()
	LUI.breakText.text = str(breakNum)

func _on_right_ui_level_up(level):
	var factor = level * rules.speedUp
	%Grounded.set_wait_time(baseGroundedTime - factor)
	%Gravity.set_wait_time(baseGravTime - factor)

func _on_right_ui_high_score():
	highScored = true

#______________________________
#FAIL SCREEN
#______________________________
func fail_screen() -> void:
	var display = Globals.display
	for i in range(Globals.display.size()):
		if score > display[i][1]:
			highScored = true

#______________________________
#DEBUG
#______________________________
func add_bead(pos) -> void:
	var bead = Globals.bead.instantiate()
	$Grid.add_child(bead)
	bead.global_position = grid_to_pixel(Vector2i(pos.x,pos.y))
	board[pos.x][pos.y] = bead
	bead.connect("find_adjacent", find_adjacent)
	bead.set_name(str(pos))

func fill_board() -> void:
	for i in rules.width:
		for j in rules.grid_fill:
			if (rules.height-j-1) <= rules.fail_rows:
				continue
			var pos = Vector2i(i,rules.height-j-1)
			add_bead(pos)

func fill_column() -> void:
	var columnDim: Vector2i = rules.column_fill
	var columnPos: Vector2i = rules.column_pos
	for i in range(columnDim.x):
		for j in range(int(columnDim.y)):
			add_bead(Vector2i(columnPos.x + i + 1,rules.height-j-1-columnPos.y))

func make_overhang() -> void:
	var overhangDim: Vector2i = rules.overhang_dimentions
	var overhangPos: Vector2i = rules.overhang_pos
	for j in range(int(overhangDim.y)):
		add_bead(Vector2i(overhangPos.x,rules.height-j-1))
	
	for i in range(abs(overhangDim.x)):
		var ammount = overhangPos.x+overhangDim.x+i
		add_bead(Vector2i(ammount,rules.height-overhangPos.y))

func display_board() -> void:
	print("\n_____________________________________________________")
	for j in rules.height:
		var debugString: String
		for i in rules.width:
			if board[i][j] != null:
				debugString = str(debugString, "\t",board[i][j].currentType)
			else:
				debugString = str(debugString, "\t",null)
		
		print("Row: ",j,"\t", debugString)
	print("_____________________________________________________\n")

func display_array(array) -> void:
	var display: String = ""
	for bead in array:
		display = str(display, ", ", bead.name,bead.currentType)
	print(display)

func _on_debug_timeout() -> void:
	find_links()