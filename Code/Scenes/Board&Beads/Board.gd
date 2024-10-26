extends Node2D

#EXPORT VARIABLES
#GRID SIZE, DIMENTIONS, SPACE SIZE AND STARTING POSITIONS (CODE AND IN-GAME)
@export var rules: Rules
@export var scoreFade: float = 1.5
@export var RUIextra: float = 20.0
@export var trasitionTiming: float = .1
@export var dieTiming: float = 1
@export var failColor: Color = Color.DIM_GRAY
@export var farAway: Vector2 = Vector2(-100,-100)

@onready var realHeight: int = rules.height - 1
@onready var gridBeads: Node2D = $Main/Grid
@onready var RUI: Control = $UI/RightUI
@onready var LUI: Control = $UI/LeftUI
@onready var Fail: Control = $FailScreen
@onready var HiScoreScene: Control = $HighScoreScreen
@onready var ghostBeads: Array[Node] = %Ghost.get_children()
@onready var baseGroundedTime: float = %Grounded.get_wait_time()
@onready var baseGravTime: float = %Gravity.get_wait_time()

signal dying
signal died
signal processFramed
signal startBreaking
signal endCheck
signal brokeBead
signal brokeAll
signal brokenBeadSFX
signal switchMode
signal modeReact(mode)
signal playSFX(index)
signal playBreak(index)

#CONSTANTS
const fullBead: Resource = preload("res://Scenes/Board&Beads/FullBead.tscn")
const breakerBead: Resource = preload("res://Scenes/Board&Beads/breaker_bead.tscn")
const holdConst: float = .5

#Variables
var fixUp: Array = []
var board: Array[Array]
var chains: Array[Array]
var chainLinkNum: Array[int]
var chainScores: Array[int]
var beadsUpnext: Array[Node2D] = [null, null, null]
var currentBead: Node2D
var inputHoldTime: float = 0
var inputHoldLeft: float = 0
var inputHoldRight: float = 0
var brokenBeads: int = 0
var score: int = 0
var breakNum: int = 0
var chainsSize: int = 0
var linksSize: int = 0
var beadsSize: int = 0
var comboSize: int = 0
var turn: int = 0
var held: bool = false
var breaking: bool = false
var fallPaused: bool = false
var failed: bool = false
var highScored: bool = false
var playZap: bool = false
var refind: bool = false
var moved: bool = false
var moving: bool = false
var breakers: Dictionary = {}

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#Here to load all objects
	#Once they're loaded once, they won't freeze up the game again
	var temp = Globals.bead.instantiate()
	var temp2 = breakerBead.instantiate()
	var holdTween = self.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	$Hold.add_child(temp)
	add_child(temp2)
	#temp2.rippleTiming = .1
	
	temp2.global_position = Vector2(489, 377)
	temp.modulate = Color(Color.WHITE,.001)
	temp2.modulate = Color(Color.WHITE,.01)
	#Spawn a connected bolt from a bead to load it in during loading
	temp.display_chain(0,0)
	temp2.rippleShader.show()
	temp2.ripple()
	holdTween.tween_property($Hold, "modulate", Color.TRANSPARENT, .1)
	$Hold.hide()
	await temp2.rippleEnd
	temp2.queue_free()
	temp.queue_free()
	
	#Make board before adding anything
	board = make_grid()
	
	RUI.position += grid_to_pixel(Vector2i(rules.width + 1,0))
	RUI.position += Vector2(RUIextra, 0)
	#LUI.position.y = grid_to_pixel(Vector2i(-8,0)).y
	LUI.set_ripple_center()
	LUI.breakMeter.set_breakNum(str(breakNum))
	
	#Make debugging easier
	match rules.debug_fills:
		1: fill_board()
		2: fill_column()
		4: make_overhang()
	
	#start the game
	Globals.droughtArray = [0,0,0,0,0]
	Globals.floodArray = [0,0,0,0,0]
	spawn_full_beads()
	pull_next_bead()
	$Main/Ghost/GhostBead.show()
	
	$ColorRect/RichTextLabel.clear()
	$ColorRect/RichTextLabel.append_text("[center]GO!")
	await get_tree().create_timer(.25).timeout
	
	var transitionTween = self.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	transitionTween.tween_property($ColorRect,"position",Vector2($ColorRect.position.x,-1000),trasitionTiming)
	transitionTween.tween_property($UI,"modulate",Color.WHITE,trasitionTiming)
	await transitionTween.finished
	
	pauseFall(false)

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
			manage_drought(beadsUpnext[i])
	LUI.update_next(beadsUpnext)

func pull_next_bead() -> void:
	if rules.spawning:
		turn += 1
		print("------------\nTURN: ",turn,"\n-------------")
		currentBead = beadsUpnext.pop_front()
		beadsUpnext.append(null)
		$Hold.remove_child(currentBead)
		gridBeads.add_child.call_deferred(currentBead)
		
		var effectiveStart = rules.start_pos
		#Push down on certain rotations
		if currentBead.rot.rotation_degrees >= 90.0 and currentBead.rot.rotation_degrees <= 180.0:
			effectiveStart = rules.start_pos + Vector2i(0,1)
		
		currentBead.gridPos[0] = effectiveStart
		board[effectiveStart.x][effectiveStart.y] = currentBead.beads[0]
		currentBead.rot.global_position = grid_to_pixel(effectiveStart)
		
		for bead in currentBead.beads:
			bead.connect("find_adjacent", find_adjacent)
			bead.connect("made_chain", should_play_zap)
			bead.connect("something_changed", should_refind)
		
		full_bead_rotation(effectiveStart, true)
		spawn_full_beads()
		ghost_bead_pos()

func manage_drought(checkedBeads) -> void:
	var willDrought = range(5)
	#Any type found in a full bead will remove the drought count
	#Remove it from will drought
	for bead in checkedBeads.beads:
		willDrought.erase(bead.typeID)
		Globals.droughtArray[bead.typeID] = 0
		Globals.floodArray[bead.typeID] += 1
	
	#For any value still in willDrought, add 1 to the drought array's corresponding value
	for unfound in willDrought:
		Globals.droughtArray[unfound] += 1
		Globals.floodArray[unfound] = clamp(Globals.floodArray[unfound] - 2, 0, Globals.floodArray[unfound])
	
	print("DROUGHT ARRAY: ", Globals.droughtArray)
	print("FLOOD ARRAY: ", Globals.floodArray)

#______________________________
#BASIC CONTROLS: MOVE
#______________________________
func move_bead(ammount, direction = "X", spawning = false) -> void:
	moving = true
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
		ghost_bead_pos()
	
	if not spawning:
		playSFX.emit(0)
		await get_tree().create_timer(0.05).timeout
	
	moving = false

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
	
	if ((Input.is_action_just_pressed("ui_left") or 
	(Input.is_action_pressed("ui_left") and inputHoldLeft >= holdConst))) and can_move("Left"):
		move_bead(-1)
	
	if ((Input.is_action_just_pressed("ui_right") or 
	(Input.is_action_pressed("ui_right") and inputHoldRight >= holdConst)) and can_move("Right")):
		move_bead(1)
	
	if not currentBead.breaker and Input.is_anything_pressed():
		currentBead.sync_position()
		ghost_bead_pos()

func hard_drop(target) -> void:
	#sort acoording to position
	var finalBeads: Array[Vector2i] = currentBead.gridPos.duplicate()
	finalBeads.sort_custom(func(a,b): return a.y > b.y)
	
	#var prevPos: Vector2i = currentBead.gridPos[0]
	for i in (currentBead.beads.size()):
		var index: int = currentBead.gridPos.find(finalBeads[i])
		var pos: Vector2i = target[index]
		
		#First time this happened was when hard dropping from the bottom
		board[currentBead.gridPos[index].x][currentBead.gridPos[index].y] = null
		
		currentBead.gridPos[index] = pos
		board[pos.x][pos.y] = currentBead.beads[index]
		currentBead.positions[index].global_position = grid_to_pixel(pos)
		#prevPos = pos
	
	for i in range(currentBead.beads.size()):
		var loc = find_bead(currentBead.beads[i])
		if loc == null or loc > Vector2i(rules.width, realHeight) or loc < Vector2i(0,0):
			print("Not matching up", loc, currentBead.beads[i].currentType)
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
	if not moved:
		for bead in $Hold.get_children():
			bead.global_position = farAway
		moved = true
	
	if currentBead != null and not breaking and not failed:
		#Fall paused is first so currentBead won't be read after fail screen
		if not fallPaused and not currentBead.placed:
			movement()
			drop()
		
		if currentBead != null and Input.is_action_pressed("ui_down") and not fallPaused:
			inputHoldTime += delta
			held = inputHoldTime > rules.soft_drop
		if currentBead != null and Input.is_action_just_released("ui_down") and not fallPaused:
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
				ghost_bead_pos()
				playSFX.emit(1)
			
		if (currentBead != null and not currentBead.breaker 
		and Input.is_action_just_pressed("Break") and breakNum > 0):
			if rules.breakBead:
				breakNum -= 1
				LUI.breakMeter.set_breakNum(str(breakNum))
				#Get old values to carry over
				var oldPos = currentBead.gridPos[0]
				for pos in currentBead.gridPos:
					board[pos.x][pos.y] = null
				currentBead.queue_free()
				
				#Replace current bead with a breaker bead
				currentBead = breakerBead.instantiate()
				gridBeads.add_child(currentBead)
				currentBead.connect("find_adjacent", find_adjacent)
				currentBead.connect("rippleEnd", continue_breaker)
				currentBead.gridPos[0] = oldPos
				currentBead.global_position = grid_to_pixel(oldPos)
				ghost_bead_pos()
				modeReact.emit(Globals.TempModes.BREAKER)
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
					breaking = true
					beadsSize += chains[i].size()
					brokenBeads += chains[i].size()
					break_order([chains[i].pick_random()], i)
					await self.brokeAll
				
				RUI.update_display(beadsSize,linksSize,chainsSize)
				RUI.update_beads(brokenBeads)
				post_break()
				pauseFall(false)
	
	if Input.is_action_pressed("ui_left"):
		inputHoldLeft += delta
		inputHoldRight = 0.0
	elif Input.is_action_pressed("ui_right"):
		inputHoldLeft = 0.0
		inputHoldRight += delta
	else:
		inputHoldLeft = 0.0
		inputHoldRight = 0.0
	
	processFramed.emit()

#______________________________
#POST TURN PROCESSES
#______________________________
func post_turn() -> void:
	pauseFall(true)
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
			bead.reparent(gridBeads)
			bead.set_name(str(find_bead(bead)))
		second_fix()
		currentBead.queue_free()
	
	currentBead = null
	find_links()
	find_chains(false)
	await check_breakers()
	
	if not rules.breakBead:
		next_turn()

func next_turn() -> void:
	LUI.update_meter(1)
	detect_fail()
	if not failed:
		#Since breaker beads break last do one last fall check
		if fallPaused:
			all_fall()
		
		#Reset grounded & Gravity timer to give the player time to react
		#Bead will show after a single timeout of Grounded to give them time to see the board and rest a second
		%Placed.start()
		await %Placed.timeout
		pauseFall(false)
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
				if bead.breaking:
					continue
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
	playSFX.emit(8)
	
	if not rules.breakBead:
		breakNum -= 1
		LUI.breakMeter.set_breakNum(str(breakNum))
	if breakNum <= 0:
		LUI.breakMeter.breakNotifier.hide()
	
	breaking = false
	#Check for any broken links and new links
	reset_beads()
	find_links()
	find_chains(false)
	await check_breakers()
	
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
			
			if ((board[target.x][target.y] != null and board[target.x][target.y] != bead) or
			 target.x > rules.width or target.x < 0 or target.y > realHeight or target.y < 0):
				display_board()
				print("ANOSANALNL")
			
			if target != Vector2i(i,j):
				print("Found new place")
				check_again= true
				
			#print(bead.currentType,bead," Goes to ",target)
			board[i][j] = null
			board[target.x][target.y] = bead
			bead.global_position = grid_to_pixel(target)
			bead.set_name(str(target))

			lost_beads(bead)
	
	if check_again:
		second_fix()
		all_fall()
	if currentBead != null:
		ghost_bead_pos()

func detect_fail() -> void:
	modeReact.emit(Globals.TempModes.BREAKER)
	#Only check for fail spots
	var inDanger: bool = false
	for i in range(rules.safe_high_columns, rules.width - rules.safe_high_columns):
		for j in range(rules.fail_rows + 1, rules.fail_rows + 2):
			if board[i][j] != null:
				inDanger = true
				break
		
		for j in rules.fail_rows:
			if board[i][j] != null:
				print(Vector2i(i,j),"Found a bead in ",board[i][j])
				inDanger = true
				dying.emit()
				var dyingTween = create_tween().set_ease(Tween.EASE_OUT)
				dyingTween.tween_property(self, "modulate", failColor, dieTiming)
				
				fail_screen()
				break
		
		if inDanger:
			modeReact.emit(Globals.TempModes.DANGER)
		else:
			modeReact.emit(Globals.TempModes.DEFAULT)

func second_fix() -> void:
	for bead in gridBeads.get_children():
		if bead == null or bead == currentBead:
			continue
		var pos = pixel_to_grid(bead)
		var found = find_bead(bead)
		
		if found != pos:
			print(bead.name, find_bead(bead), " vs ", pos)
			board[found.x][found.y] = null
			board[pos.x][pos.y] = bead
		
	for i in rules.width:
		for j in rules.height:
			#or currentBead.in_full_bead(bead)
			var bead = board[i][j]
			if bead == null:
				continue
			if bead.name.ends_with("2"):
				print("IASUHHBHJS")
			
			var pos = pixel_to_grid(bead)
			if Vector2i(i,j) != pos:
				board[i][j] = null
				board[pos.x][pos.y] = bead

func lost_beads(bead) -> void:
	var changed: bool = false
	#If a bead isn't in the board anymore just delete them
	var visible_pos = pixel_to_grid(bead)
	if visible_pos != find_bead(bead):
		print(bead, "LOST!!! :o!", bead.currentType)
		changed = true
		var target = mini_find_bottom(visible_pos,visible_pos.x)
		board[target.x][target.y] = bead
		bead.global_position = grid_to_pixel(target)
		bead.set_name(str(target))
		#bead.queue_free()
	if changed:
		all_fall()

func reset_beads() -> void:
	for i in rules.width:
		for j in rules.height:
			#or currentBead.in_full_bead(bead)
			var bead = board[i][j]
			if bead == null or bead.currentType == "Breaker":
				continue
			bead.reset_links()

#______________________________
#BREAKERS
#______________________________
func check_breakers() -> void:
	var breakerArray: Array = breakers.keys()
	var breakAt: Array = []
	var usingBreakerArray: Array = []
	var breakAtCheck: Array[Array] = []
	var shouldBreak: bool = false
	
	pauseFall(true)
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
			
			if Globals.NewgroundsToggle and usingBreakerArray.size() >= 3:
				print("UNLCOK AIR")
				$Medals/Air.unlock()
	
	#Have all breaker ripples occur at once
	
	if shouldBreak:
		print(breakAtCheck)
		playBreak.emit(clamp(comboSize,0,2))
		print(comboSize, usingBreakerArray)
		await self.startBreaking
		
		for i in range(usingBreakerArray.size()):
			breaking = true
			usingBreakerArray[i].breaking = true
			#If there a chains to break find their full chains
			var breakerChains = find_specific_chains(breakAt[i])
			if is_instance_valid(usingBreakerArray[i]):
				print("Remove ", usingBreakerArray[i])
				var pos = usingBreakerArray[i].gridPos[0]
				board[pos.x][pos.y] = null
				usingBreakerArray[i].destroy_anim()
				brokenBeadSFX.emit()
				
				await usingBreakerArray[i].tree_exiting
				breakers.erase(usingBreakerArray[i])
			else: continue
			
			#print("BREAK AT:", breakAt)
			#print("BREAKER CHAINS:", breakerChains)
			#Once chains are finalized you can't normally find the amoount of links so find them before this
			beadsSize = 0
			
			#Break every chain found at ith breaker bead
			for j in range(breakAt[i].size()):
				#Check if bead already broke
				if not is_instance_valid(breakAt[i][j]):
					continue
				
				var breakIndex = find_linkNum_index(breakerChains[j])
				var finalScore = rules.chainComboMult(chainScores[breakIndex], comboSize)
				beadsSize = breakerChains[j].size()
				brokenBeads += breakerChains[j].size()
				linksSize = chainLinkNum[breakIndex]
				score += finalScore
				print("From ",breakAt[i][j])
				print("Score: ", chainScores[breakIndex], " With Combo ",  finalScore)
				#Make sure the starting value is bracketed into an array
				break_order([breakAt[i][j]], breakIndex)
				await self.brokeAll
				RUI.update_display(beadsSize,linksSize,comboSize, true)
			
			comboSize += 1
			#Should probably find a way to display multiple chain breaks at once
			RUI.update_beads(brokenBeads)
			RUI.update_score(score)
			if highScored:
				HiScoreScene.score = score
	
	if shouldBreak:
		post_break()
	
	else:
		comboSize = 0
		endCheck.emit()
		next_turn()

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

func break_order(chainPart, holdNum) -> void:
	#First find every adjacent bead to break in the future
	#They must be connected to the current bead
	var adjacent: Dictionary = {}
	for bead in chainPart:
		#Skip any beads that were already freed
		if not is_instance_valid(bead):
			continue
		find_adjacent(bead)
		for adj in bead.adjacent:
			#Clear a bead if it's in the chain, first condition is for debugger
			if (is_instance_valid(adj)
			 and chains[holdNum].find(adj) != -1):
				adjacent[adj] = adj
	
	print("Breaking: ",chainPart, " Will break: ",adjacent.keys())
	display_board()
	break_bead(chainPart)
	await self.brokeBead
	var empty = true
	var notEmptied = []
	for bead in chains[holdNum]:
		if bead != null:
			empty = false
			notEmptied.append(bead)
	
	if empty:
		brokeAll.emit()
		return
	#If there are no adjacent beads left find untouched beads
	if adjacent.size() != 0:
		break_order(adjacent.keys(), holdNum)
	else:
		break_order([notEmptied.pick_random()], holdNum)

func break_bead(chainPart) -> void:
	for bead in chainPart:
		if is_instance_valid(bead):
			bead.destroy_anim()
			brokenBeadSFX.emit()
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
		await get_tree().create_timer(0.1).timeout
		
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
	var Xnew: float = $Main.position.x + rules.origin.x + rules.offset.x * gridPos.x
	var Ynew: float = $Main.position.y + rules.origin.y + rules.offset.y * gridPos.y
	
	return Vector2(Xnew, Ynew)

#Turn visual positions into computer positions
func pixel_to_grid(bead) -> Vector2i:
	var Xnew: int = round((bead.global_position.x - rules.origin.x - $Main.position.x) / rules.offset.x)
	var Ynew: int = round((bead.global_position.y - rules.origin.y - $Main.position.y) / rules.offset.y)
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
				if moving: return false
				if newPos.x - 1 < 0: return false
				else: newPos.x -= 1
			"Right":
				if moving: return false
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
func pauseFall(should) -> void:
	if should:
		fallPaused = true
		%Grounded.set_paused(true)
		%SoftDrop.set_paused(true)
		%Gravity.set_paused(true)
		%Ghost.hide()
	else:
		fallPaused = false
		%Grounded.set_paused(false)
		%SoftDrop.set_paused(false)
		%Gravity.set_paused(false)
		%Ghost.show()

func _on_soft_drop_timeout() -> void:
	if can_move("Down"):
		move_bead(1, "Y")
		if not currentBead.breaker:
			currentBead.sync_position()
	else:
		hard_drop(find_drop_bottom(currentBead))

func _on_grounded_timeout() -> void:
	hard_drop(find_drop_bottom(currentBead))

func _on_gravity_timeout() -> void:
	if rules.gravity_on and not Input.is_action_pressed("ui_down"):
		if not can_move("Down") and not held:
			hard_drop(find_drop_bottom(currentBead))
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
	LUI.breakMeter.set_breakNum(str(breakNum))
	playSFX.emit(4)

func _on_right_ui_level_up(level) -> void:
	playSFX.emit(6)
	var factor = level * rules.speedUp
	%Grounded.set_wait_time(baseGroundedTime - factor/5)
	%Gravity.set_wait_time(baseGravTime - factor)
	%Placed.set_wait_time(%Grounded.get_wait_time()/4)

func _on_right_ui_high_score() -> void:
	highScored = true

func _on_right_ui_maxed_level() -> void:
	if Globals.NewgroundsToggle:
		$Medals/Dark.unlock()
	
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
	var placement = Globals.find_placement(score)
	if placement != 7:
		highScored = true
		HiScoreScene.placement = placement
	
	died.emit()
	HiScoreScene.score = RUI.regScore
	HiScoreScene.new_score()
	await NG.scoreboard_submit(13768, score)
	
	if highScored:
		HiScoreScene.new_focus(RUI.regScore, placement)
		var HiScoreTween = HiScoreScene.create_tween()
		HiScoreScene.show()
		HiScoreTween.tween_property($HighScoreScreen, 'modulate', Color.WHITE, scoreFade/2)
		await get_tree().create_timer(scoreFade).timeout
	
	else:
		var failTween = Fail.create_tween()
		Fail.show()
		failTween.tween_property($FailScreen, 'modulate', Color.WHITE, scoreFade/2)
		await get_tree().create_timer(scoreFade).timeout
		Fail.start_focus()

func _on_high_score_screen_proceed() -> void:
	var HiScoreTween = HiScoreScene.create_tween()
	var failTween = Fail.create_tween()
	HiScoreTween.set_parallel(true)
	failTween.set_parallel(true)
	
	Fail.show()
	HiScoreTween.tween_property($HighScoreScreen, 'modulate', Color.TRANSPARENT, scoreFade/2)
	failTween.tween_property($FailScreen, 'modulate', Color.WHITE, scoreFade/2)
	await get_tree().create_timer(scoreFade).timeout
	HiScoreScene.hide()
	Fail.start_focus()

func _on_mode_switch_pressed():
	$Medals/Soul.unlock()
	switchMode.emit()

#______________________________
#GHOST BEADS
#______________________________
func ghost_bead_pos() -> void:
	if currentBead == null:
		return
	
	var target = find_drop_bottom(currentBead)
	if currentBead.breaker:
		ghostBeads[1].hide()
		ghostBeads[2].hide()
		
		ghostBeads[0].global_position = grid_to_pixel(target[0])
		ghostBeads[0].set_color(currentBead)
	else:
		ghostBeads[1].show()
		ghostBeads[2].show()
		
		for i in range(ghostBeads.size()):
			ghostBeads[i].global_position = grid_to_pixel(target[i])
			ghostBeads[i].set_color(currentBead.beads[i])

#______________________________
#DEBUG
#______________________________
func add_bead(pos) -> void:
	var bead = Globals.bead.instantiate()
	gridBeads.add_child(bead)
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
				if board[i][j].currentType == "Sea" or board[i][j].currentType == "Air":
					debugString = str(debugString, "\t",board[i][j].currentType,"\t")
				else:
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
	
