extends Node2D

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules
@export var scoreFade: float = 1.5
@export var farAway: Vector2 = Vector2(-100,-100)

@onready var realHeight: int = rules.height - 1
@onready var RUI: Control = $RightUI
@onready var LUI: Control = $LeftUI
@onready var Fail: Control = $FailScreen
@onready var baseGroundedTime: float = %Grounded.get_wait_time()
@onready var baseGravTime: float = %Gravity.get_wait_time()

signal startBreaking
signal endCheck
signal brokeBead
signal brokeAll
signal playSFX(index)
signal playBreak(index)

#CONSTANTS
const fullBead = preload("res://Scenes/Board&Beads/FullBead.tscn")
const uberbead = preload("res://Scenes/Board&Beads/uberbead.tscn")
const breakerBead = preload("res://Scenes/Board&Beads/breaker_bead.tscn")

#Variables
var fixUp: Array = []
var board: Array[Array]
var chains: Array[Array]
var chainLinkNum: Array[int]
var chainScores: Array[int]
var beadsUpnext: Array[Node2D] = [null, null, null]
var currentBead: Node2D
var breakers: Dictionary = {}
var inputHoldTime: float = 0
var holdBreakChain: int = 0
var brokenBeads: int = 0
var score: int = 0
var breakNum: int = 1
var chainsSize: int = 0
var linksSize: int = 0
var beadsSize: int = 0
var comboSize: int = 0
var held: bool = false
var breaking: bool = false
var fallPaused: bool = false
var failed: bool = false
var highScored: bool = false
var playZap: bool = false
var refind: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Here to load all objects
	#Once they're loaded once, they won't freeze up the game again
	var temp = Globals.bead.instantiate()
	var temp2 = breakerBead.instantiate()
	$Hold.add_child(temp)
	$Hold.add_child(temp2)
	#Spawn a connected bolt from a bead to load it in during loading
	temp.display_chain(0,0)
	temp.position = farAway
	temp2.position = farAway
	
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
	LUI.set_ripple_center()
	LUI.breakMeter.breakText.text = str(breakNum)
	
	#Make debugging easier
	match rules.debug_fills:
		1: fill_board()
		2: fill_column()
		4: make_overhang()
	
	#start the game
	spawn_full_beads()
	pull_next_bead()

func make_grid() -> Array[Array]:
	var array: Array[Array] = []
	
	for i in rules.width:
		array.append([])
		for j in rules.height:
			array[i].append(null)
	
	return array

#Array order goes [anchor, clockwise, ccw]
func spawn_full_beads() -> void:
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
			bead.connect("made_chain", should_play_zap)
			bead.connect("something_changed", should_refind)
		
		full_bead_rotation(rules.start_pos, true)
		spawn_full_beads()

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
	if not currentBead.breaker:
		if Input.is_action_just_pressed("ui_accept") and can_rotate("CCW"):
			currentBead.rot.rotation_degrees += fmod(rotation_degrees+90,360)
			if currentBead.rot.rotation_degrees > 360:
				currentBead.rot.rotation_degrees -= 360
			
			full_bead_rotation(currentBead.gridPos[0])
			second_fix()
			
		if Input.is_action_just_pressed("ui_cancel") and can_rotate("CLOCKWISE"):
			currentBead.rot.rotation_degrees += fmod(rotation_degrees-90,360)
			if currentBead.rot.rotation_degrees < 0:
				currentBead.rot.rotation_degrees += 360
			
			full_bead_rotation(currentBead.gridPos[0])
			second_fix()
	
	if Input.is_action_just_pressed("ui_left") and can_move("Left"):
		move_bead(-1)
	
	if Input.is_action_just_pressed("ui_right") and can_move("Right"):
		move_bead(1)
	
	if not currentBead.breaker and Input.is_anything_pressed():
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
	#var prevPos: Vector2i = currentBead.gridPos[0]
	for i in (currentBead.beads.size()):
		var pos: Vector2i = target[i]
		#First time this happened was when hard dropping from the bottom
		board[currentBead.gridPos[i].x][currentBead.gridPos[i].y] = null
		
		currentBead.gridPos[i] = pos
		board[pos.x][pos.y] = currentBead.beads[i]
		currentBead.positions[i].global_position = grid_to_pixel(pos)
		#prevPos = pos
	
	for i in range(currentBead.beads.size()):
		var loc = find_bead(currentBead.beads[i])
		if loc == null or loc > Vector2i(rules.width, realHeight) or loc < Vector2i(0,0):
			print("Not matching up", loc)
			print(currentBead.beads[i],target[i])
			fixUp.append(currentBead.beads[i])
	
	playSFX.emit(2)
	post_turn()

func drop() -> void:
	#Both drop, up is hard drop, down is soft drop
	if Input.is_action_just_pressed("ui_up"):
		print()
		hard_drop(find_drop_bottom(currentBead))
		
	if Input.is_action_just_pressed("ui_down") and can_move("Down"):
		move_bead(1, "Y")
		$Timers/SoftDrop.start()
		if not currentBead.breaker:
			currentBead.sync_position()

#______________________________
#BASIC CONTROLS: ROTATE
#______________________________
func ground_timer_reset(oldPos, newPos) -> void:
	var canDown = can_move("Down")
	if oldPos != newPos and not canDown:
		$Timers/Grounded.start()
	elif canDown:
		$Timers/Grounded.stop()

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
#PROCESSING + BREAK & FLIP
#______________________________
func _process(delta) -> void:
	if currentBead != null and not breaking and not failed:
		#Fall paused is first so currentBead won't be read after fail screen
		if not fallPaused and not currentBead.placed:
			movement()
			drop()
		
		if currentBead != null and Input.is_action_pressed("ui_down") and not fallPaused and not failed:
			inputHoldTime += delta
			held = inputHoldTime > rules.soft_drop
		if currentBead != null and Input.is_action_just_released("ui_down") and not failed:
			$Timers/SoftDrop.stop()
			inputHoldTime = 0
			held = false
		
		if currentBead != null and not currentBead.breaker and Input.is_action_just_pressed("Flip"):
			currentBead.flip()
			
			for i in range(currentBead.gridPos.size()):
				var pos: Vector2i = currentBead.gridPos[i]
				#Only clear own bead
				if board[pos.x][pos.y] == currentBead.beads[i]:
					board[pos.x][pos.y] = null
				
				#Keep board pos.x.y since thats new location of bead
				#Update visual and coded grid position
				currentBead.gridPos[i] = pos
				board[pos.x][pos.y] = currentBead.beads[i]
				currentBead.positions[i].global_position = grid_to_pixel(pos)
				playSFX.emit(1)
			
		if (currentBead != null and not currentBead.breaker 
		and Input.is_action_just_pressed("Break") and breakNum > 0):
			if rules.breakBead:
				breakNum -= 1
				LUI.breakMeter.breakText.text = str(breakNum)
				#Get old values to carry over
				var oldPos = currentBead.gridPos[0]
				for pos in currentBead.gridPos:
					board[pos.x][pos.y] = null
				currentBead.queue_free()
				
				#Replace current bead with a breaker bead
				currentBead = breakerBead.instantiate()
				$Grid.add_child(currentBead)
				currentBead.connect("find_adjacent", find_adjacent)
				currentBead.connect("rippleEnd", continue_breaker)
				currentBead.gridPos[0] = oldPos
				currentBead.global_position = grid_to_pixel(oldPos)
				playSFX.emit(7)
			else:
				#Full Bead should not move during this
				pauseFall(true)
				LUI.ripple()
				playBreak.emit(1)
				#Once chains are finalized you cAan'y normally find the amoount of links so find them before this
				
				find_chains(true)
				chainsSize = chains.size()
				beadsSize = 0
				await LUI.rippleEnd
				for i in range(chains.size()):
					#Make sure the starting value is bracketed into an array
					holdBreakChain = i
					breaking = true
					beadsSize += chains[i].size()
					brokenBeads += chains[i].size()
					break_order([chains[i].pick_random()], chains)
					await self.brokeAll
				
				RUI.update_display(beadsSize,linksSize,chainsSize)
				RUI.update_beads(brokenBeads)
				post_break()
				pauseFall(false)

#______________________________
#POST TURN PROCESSES
#______________________________
func post_turn() -> void:
	currentBead.placed = true
	if not currentBead.breaker:
		currentBead.sync_position()
	
	#Last minute fix before they get removed from currentBeads
	for bead in fixUp:
		var pos = pixel_to_grid(bead)
		board[pos.x][pos.y] = bead
	fixUp.clear()
	
	if currentBead.breaker:
		currentBead.set_name(str(find_bead(currentBead)))
	else:
		for bead in currentBead.beads:
			bead.reparent($Grid)
			bead.set_name(str(find_bead(bead)))
		second_fix()
		currentBead.queue_free()
	
	currentBead = null
	find_links()
	find_chains(false)
	check_breakers()
	
	print(breaking)
	if breaking:
		await self.endCheck
		$Timers/ChainFinish.start()
		await $Timers/ChainFinish.timeout
	
	LUI.update_meter(1)
	detect_fail()
	if not failed:
		#Reset grounded & Gravity timer to give the player time to react
		%Grounded.start()
		%Gravity.start()
		pull_next_bead()
		display_board()

func find_links() -> void:
	#If nothing changes, then this won't
	refind = false
	
	for i in rules.width:
		for j in rules.height:
			var bead = board[i][j]
			if bead == null:
				continue
			if bead.currentType == "Breaker":
				breakers[bead] = bead
				continue
			elif currentBead != null and currentBead.in_full_bead(bead):
				continue
			bead.should_glow()
			if bead.glowing:
				bead.should_chain()
	
	if playZap: 
		playSFX.emit(5)
		playZap = false
	
	#If something changed in the board
	#look at it again to see if that changes anything
	if refind:
		find_links()

func post_break() -> void:
	all_fall()
	
	if not rules.breakBead:
		breakNum -= 1
		LUI.breakMeter.breakText.text = str(breakNum)
	if breakNum <= 0:
		LUI.breakMeter.breakNotifier.hide()
	
	breaking = false
	#Check for any broken links and new links
	reset_beads()
	find_links()
	find_chains(false)
	check_breakers()
	
	print()
	
	if breaking:
		$Timers/ChainFinish.start()
		post_break()
	
	else:
		$Timers/ChainFinish.start()
		await $Timers/ChainFinish.timeout
		chainsSize = 0
		pauseFall(false)
		RUI.remove_displays()

func all_fall() -> void:
	var check_again: bool = false
	for i in range(rules.width):
		#Start at the bottom of the board and push those down first
		for j in range(realHeight,-1,-1):
			var bead = board[i][j]
			if bead == null:
				continue
			elif currentBead != null and currentBead.in_full_bead(bead):
				continue
			
			var target = mini_find_bottom(Vector2i(i,j),i)
			if target.x == -1:
				target = Vector2i(i,j)
			
			if target != Vector2i(i,j):
				print("Found new place")
				check_again= true
				
			#print(bead.currentType,bead," Goes to ",target)
			board[i][j] = null
			board[target.x][target.y] = bead
			bead.global_position = grid_to_pixel(target)
			bead.set_name(str(target))
	
	if check_again:
		all_fall()

func detect_fail() -> void:
	#Only check for fail spots
	for i in range(rules.safe_high_columns, rules.width - rules.safe_high_columns):
		for j in rules.fail_rows:
			if board[i][j] != null:
				print(Vector2i(i,j),"Found a bead in ",board[i][j] )
				fail_screen()
				break

func second_fix() -> void:
	for i in rules.width:
		for j in rules.height:
			#or currentBead.in_full_bead(bead)
			var bead = board[i][j]
			if bead == null:
				continue
			var pos = pixel_to_grid(bead)
			if Vector2i(i,j) != pos:
				board[i][j] = null
				board[pos.x][pos.y] = bead

func reset_beads() -> void:
	for i in rules.width:
		for j in rules.height:
			#or currentBead.in_full_bead(bead)
			var bead = board[i][j]
			if bead == null or bead.currentType == "Breaker":
				continue
			bead.reset_links()

func check_breakers() -> void:
	var breakerArray: Array = breakers.keys()
	var breakAt: Array = []
	var usingBreakerArray: Array = []
	var breakAtCheck: Array[Array] = []
	var shouldBreak: bool = false
	
	#Check every breaker bead if they have chains to break
	#maybe change when the breakers are removed
	for i in range(breakerArray.size()):
		breakAtCheck.append(breakerArray[i].check_should_break())
		if breakAtCheck[i].size() != 0:
			breakerArray[i].ripple()
			shouldBreak = true
			#Log every breaker and their chain into a new array that'll keep the right indexes
			breakAt.append(breakAtCheck[i])
			usingBreakerArray.append(breakerArray[i])
	
	#Have all breaker ripples occur at once
	
	if shouldBreak:
		pauseFall(true)
		playBreak.emit(clamp(comboSize,0,2))
		print(comboSize)
		await self.startBreaking
		
		for i in range(usingBreakerArray.size()):
			breaking = true
			usingBreakerArray[i].breaking = true
			#If there a chains to break find their full chains
			var breakerChains = find_specific_chains(breakAt[i])
			if not is_instance_valid(usingBreakerArray[i]):
				continue
			
			#print("BREAK AT:", breakAt)
			#print("BREAKER CHAINS:", breakerChains)
			#Once chains are finalized you can't normally find the amoount of links so find them before this
			beadsSize = 0
			holdBreakChain = 0
			
			#Break every chain found at ith breaker bead
			for j in range(breakAt[i].size()):
				#Check if 
				if not is_instance_valid(breakAt[i][j]):
					continue
				#Make sure the starting value is bracketed into an array
				var extraIndex = find_linkNum_index(breakerChains[j])
				var finalScore = rules.chainComboMult(chainScores[extraIndex], comboSize)
				beadsSize = breakerChains[j].size()
				brokenBeads += breakerChains[j].size()
				linksSize = chainLinkNum[extraIndex]
				score += finalScore
				print("From ",breakAt[i][j])
				print("Score: ", chainScores[extraIndex], " With Combo ",  finalScore)
				
				break_order([breakAt[i][j]], breakerChains)
				await self.brokeAll
				
				#print()
				holdBreakChain = clamp(holdBreakChain + 1, 0, breakerChains.size()-1)
			
			comboSize += 1
			#Should probably find a way to display multiple chain breaks at once
			RUI.update_display(beadsSize,linksSize,comboSize, true)
			RUI.update_beads(brokenBeads)
			RUI.update_score(score)
	
	#Erase from the script wide var rather than local
	for i in range(breakerArray.size()):
		#If the array still has null values, skip them
		if not is_instance_valid(breakerArray[i]):
			continue
		if breakerArray[i].breaking:
			print("breaking ", breakerArray[i])
			breakerArray[i].destroy_anim()
			var pos = breakerArray[i].gridPos[0]
			board[pos.x][pos.y] = null
			breakers.erase(breakerArray[i])
			await breakerArray[i].tree_exiting
	
	if shouldBreak:
		post_break()
	
	else:
		comboSize = 0
		endCheck.emit()

#______________________________
#CHAIN
#______________________________
func find_chains(addScore: bool) -> void:
	#Make sure there's nothing else in chains to mess up the operation
	chains.clear()
	chainLinkNum.clear()
	chainScores.clear()
	
	for i in rules.width:
		for j in rules.height:
			var bead = board[i][j]
			#skip anything that has breaker or no beads
			if bead == null or bead.currentType == "Breaker":
				continue
			#Work with beads not alreay put in the chain and it has a chain
			if not in_chains(bead) and bead.chainedLinks.size() > 0:
				#The temp chain takes every link that's chained together
				var tempChain = add_links(bead.get_links())
				#Now's the time to get the score and linkSize
				#Right now tempChain's size temp chain's size is the ammount of links it has
				linksSize = tempChain.size()
				chainLinkNum.append(linksSize)
				chainScores.append(rules.indvChainScore(tempChain,linksSize))
				
				if addScore:
					score += rules.totalScore(tempChain)
					print("\n\nTOTAL SCORE: ", score)
					RUI.update_score(score)
				
				#Make the standard chains list for the computer to clear
				chains.append(new_set_chains(tempChain))
	
	print(chainScores)

func break_order(chainPart, holdChains) -> void:
	#First find every adjacent bead to break in the future
	#They must be connected to the current bead
	#REMOVE EVERY INSTANCE OF CHAINS
	var adjacent: Dictionary = {}
	for bead in chainPart:
		#Skip any beads that were already freed
		if not is_instance_valid(bead):
			continue
		find_adjacent(bead)
		for adj in bead.adjacent:
			#Clear a bead if it's in the chain, first condition is for debugger
			if (is_instance_valid(adj)
			 and holdChains[holdBreakChain].find(adj) != -1):
				adjacent[adj] = adj
	
	#print("Breaking: ",chainPart, " Will break: ",adjacent.keys())
	
	break_bead(chainPart)
	await self.brokeBead
	var empty = true
	var notEmptied = []
	for bead in holdChains[holdBreakChain]:
		if bead != null:
			empty = false
			notEmptied.append(bead)
	
	if empty:
		brokeAll.emit()
		return
	#If there are no adjacent beads left find untouched beads
	if adjacent.size() != 0:
		break_order(adjacent.keys(), holdChains)
	else:
		break_order(notEmptied, holdChains)

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

func find_connections(connection, recursion = []) -> Array:
	var tempChain = recursion
	for bead in connection:
		var link = bead.get_links()
		if not in_temp_chain(tempChain, link):
			add_links(link,tempChain)
	
	return tempChain

func add_links(link: Dictionary, recursion: Array = []) -> Array:
	var tempChain: Array = recursion
	#Check if the link is already in the chain if not add it
	if not in_temp_chain(tempChain, link):
		tempChain.append(link)
	
	#Check for any connections the bead has, if check said connection's links
	for bead in link:
		if bead.chainedLinks.size() != 0:
			tempChain = find_connections(bead.chainedLinks, tempChain)
	
	#This is reached where there are no connections left to find
	return tempChain

func shake_order(chainPart, main, size, recursion = {}) -> void:
	#Cut the shake if beads are being broken
	if not breaking:
		#First find every adjacent bead to break in the future
		#They must be connected to the current bead
		var shookBeads: Dictionary = recursion
		var adjacent: Dictionary = {}
		#Get which parts will shake, they will also have their adjacents checked in chains
		for bead in chainPart:
			if not is_instance_valid(bead):
				continue
			
			find_adjacent(bead)
			for adj in bead.adjacent:
				#Only shake beads that have yet to shake
				#It should be in chains[index] but not shookBeads
				if (not shookBeads.has(adj)
				 and main.find(adj) != -1):
					adjacent[adj] = adj
		
		#Shake beads
		for bead in adjacent.keys():
			bead.chain_shake()
		
		#Update which beads shook
		shookBeads.merge(adjacent)
		await get_tree().create_timer(.1).timeout
		
		#If every bead in the chain has yet to be shook keep going
		if shookBeads.size() >= size:
			return
		shake_order(adjacent.keys(), main, size, shookBeads)
	else:
		return
	
#Search functions
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

func find_specific_chains(breakerLinks) -> Array:
	var returnChains: Dictionary = {}
	
	#I don't know why but chain in chains doesn't work here but it works everywhere else
	for chain in chains:
		for link in chains:
			for bead in link:
				if breakerLinks.find(bead) != -1:
					returnChains[link] = link
	
	return returnChains.keys()

func find_linkNum_index(chain) -> int:
	var index: int = chains.find(chain)
	for i in range(chains.size()):
		if chains[i] == chain:
			return i
	if index == -1:
		return 0
	return index

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
	
	if pos.x - 1 >= 0 and is_instance_valid(board[pos.x - 1][pos.y]) and board[pos.x - 1][pos.y] != null:
		adjacent[0] = board[pos.x - 1][pos.y]
	if pos.x + 1 < rules.width and is_instance_valid(board[pos.x + 1][pos.y]) and board[pos.x + 1][pos.y] != null:
		adjacent[1] = board[pos.x + 1][pos.y]
	if pos.y - 1 >= 0 and is_instance_valid(board[pos.x][pos.y - 1]) and board[pos.x][pos.y - 1] != null:
		adjacent[2] = board[pos.x][pos.y - 1]
	if pos.y + 1 < rules.height and is_instance_valid(board[pos.x][pos.y + 1]) and board[pos.x][pos.y + 1] != null:
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
			if hardDropping and not currentBead.breaker:
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
		#Function will skip and if using a breaker 
		var currentBool: bool = ((not currentBead.breaker and not currentBead.in_full_bead(bead,sameBead))
		 or currentBead.breaker)
		if bead != null and currentBool:
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
		if not currentBead.breaker:
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
			if not currentBead.breaker:
				currentBead.sync_position()

func _on_shake_timeout() -> void:
	if chains.size() != 0:
		var rand: int = randi_range(0,chains.size() - 1)
		var part: Array = [chains[rand].pick_random()]
		shake_order(part, chains[rand], chains[rand].size())

func _on_left_ui_break_ready() -> void:
	breakNum += 1
	LUI.breakMeter.breakNotifier.show()
	LUI.breakMeter.breakText.text = str(breakNum)
	playSFX.emit(4)

func _on_right_ui_level_up(level) -> void:
	playSFX.emit(6)
	var factor = level * rules.speedUp
	%Grounded.set_wait_time(baseGroundedTime - factor/5)
	%Gravity.set_wait_time(baseGravTime - factor)

func _on_right_ui_high_score() -> void:
	highScored = true

func _on_right_ui_maxed_level() -> void:
	fail_screen()

func should_play_zap() -> void:
	playZap = true

func should_refind() -> void:
	refind = true

func continue_breaker() -> void:
	startBreaking.emit()

#______________________________
#FAIL SCREEN
#______________________________
func fail_screen() -> void:
	failed = true
	pauseFall(true)
	var display = Globals.display
	var placement = 7
	#If regular score is higher than any of the current Hi scores 
	for i in range(Globals.display.size()):
		if RUI.regScore > display[i][0]:
			placement -= 1
			highScored = true
	
	if highScored:
		var HiScoreTween = $HighScoreScreen.create_tween()
		$HighScoreScreen.show()
		HiScoreTween.tween_property($HighScoreScreen, 'modulate', Color.WHITE, scoreFade/2)
		await get_tree().create_timer(scoreFade).timeout
		$HighScoreScreen.new_focus(RUI.regScore, placement)
	
	else:
		var failTween = Fail.create_tween()
		Fail.show()
		failTween.tween_property($FailScreen, 'modulate', Color.WHITE, scoreFade/2)
		await get_tree().create_timer(scoreFade).timeout
		Fail.start_focus()

func _on_high_score_screen_proceed() -> void:
	var HiScoreTween = $HighScoreScreen.create_tween()
	var failTween = Fail.create_tween()
	HiScoreTween.set_parallel(true)
	failTween.set_parallel(true)
	
	Fail.show()
	HiScoreTween.tween_property($HighScoreScreen, 'modulate', Color.TRANSPARENT, scoreFade/2)
	failTween.tween_property($FailScreen, 'modulate', Color.WHITE, scoreFade/2)
	await get_tree().create_timer(scoreFade).timeout
	$HighScoreScreen.hide()
	Fail.start_focus()

#______________________________
#DEBUG
#______________________________
func add_bead(pos) -> void:
	var bead = Globals.bead.instantiate()
	$Grid.add_child(bead)
	bead.global_position = grid_to_pixel(Vector2i(pos.x,pos.y))
	board[pos.x][pos.y] = bead
	bead.connect("find_adjacent", find_adjacent)
	bead.connect("made_chain", should_play_zap)
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
