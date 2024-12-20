extends Node2D

@export var beads: Array[CompressedTexture2D]
@export var chainedVFX: PackedScene = preload("res://Scenes/Constants/connected.tscn")
@export var shakeRange: Vector2 = Vector2(.5,0)
@export_range(0,.5,.01) var shakeSpeed: float = .05
@export_range(0,.5,.01) var burnTiming: float = .05

@onready var linkArray: Node = $LinkArray
@onready var sprite = $Images/Sprite
@onready var glow: Sprite2D = $Images/Glow
@onready var chainPos: Array[Array] = [[%L1,%L2],[%R1,%R2],[%U1,%U2],[%D1,%D2]]
@onready var chainedLinks: Array[Node] = []
@onready var connectionBolts: Node2D = $Images/Connections

signal find_adjacent
signal made_chain
signal something_changed

var typeID: int = 0
var typeFlag: int = 1
var chainedNum: int = 0
var currentType: String = "Earth"
var chainedWith: Array[int] = [-1,-1,-1,-1]
var adjacent: Array = []
var chainNodes: Array = [null,null,null,null]
var hardDropped: bool = true
var glowing: bool = false
var breaking: bool = false
var shaking: bool = false
var chained: bool = false
var second_fix: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	randomize_type(range(Globals.bead_types.size()))

func randomize_type(array) -> void:
	typeID = array.pick_random()
	currentType = Globals.bead_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	sprite.texture = beads[typeID]
	material.set_shader_parameter("dissolve_value",1.0)
	material.set_shader_parameter("modulate",Globals.bead_colors[typeID])
	connectionBolts.modulate = Globals.link_colors[typeID]
	shakeSpeed = Globals.beadSpeeds[typeID]

func reset_links():
	chainedWith = [-1,-1,-1,-1]
	adjacent.clear()
	chainedNum = 0
	chained = false
	chainedLinks.clear()
	chainNodes = [null,null,null,null]
	glowing = false
	glow.hide()
	for bolt in connectionBolts.get_children():
		connectionBolts.remove_child(bolt)
		bolt.die()
	reset_link()

#______________________________
#MANAGING LINKS
#______________________________
func should_glow(skip = null) -> void:
	find_adjacent.emit(self)
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or adj.currentType == "Breaker":
			continue
		
		var links: Dictionary = get_links()
		#if adj can but isn't linked to bead + make sure to skip same bead
		if adj.currentType == currentType and not links.has(adj) and adj != skip:
			link_beads(adj)
			adj.should_glow(self) #Find other beads adj is linked to
	
	for bead in get_links(true):
		bead.manage_glow()

func link_beads(adj) -> void:
	#Sync links
	for bead in adj.get_links():
		set_links(bead)
	
	var link = get_links()
	#Keep every linked bead in the same order
	for bead in link:
		if bead.get_links() != link:
			bead.set_links(self)

func manage_glow() -> void:
	#If this var is different by the end then board should know
	var temp: bool = glowing
	var chainTemp: bool = chained
	if get_links().size() >= Globals.glow_num:
		glow.show()
		glowing = true
		#Figure out how much it should glow depending on whether or not it's in a chain
		#If any of it's linked nodes has a chain Node, it's in a chain
		
		for link in get_links(true):
			if link.chainNodes != [null,null,null,null]:
				chained = true
		if not chained:
			if temp != glowing:
				something_changed.emit()
				$AnimationPlayer.play("Glow")
			else:
				glow.self_modulate = Color(1,1,1,0.569)
		if chained:
			if chainTemp != chained:
				something_changed.emit()
				$AnimationPlayer.play("MakeConnection")
			else:
				glow.self_modulate = Color.WHITE
	
	else:
		glow.hide()
		glowing = false

#______________________________
#MANAGING CONNECTIONS
#______________________________
func should_chain() -> void:
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or adj.currentType == "Breaker" or not adj.glowing:
			continue
		
		#Check if chains array has to updated when links update
		if adj.typeFlag & Globals.relation_flags[typeID] and chainedLinks.find(adj) == -1:
			make_chain(adj)
			if chainNodes[i] == null and adj.chainNodes[Globals.otherConnectionNum[i]] == null:
				made_chain.emit()
				display_chain(i,0)
				adj.display_chain(i,1)

func make_chain(adj) -> void:
	#Sync chains
	adj.set_chains(self)
	set_chains(adj)

func display_chain(direction,using) -> void:
	#Doesn't work
	var VFX: AnimatedSprite2D = chainedVFX.instantiate()
	connectionBolts.add_child(VFX)
	VFX.position = chainPos[direction][using].position
	
	if direction > 1:
		VFX.rotation_degrees = VFX.horiRot
	else:
		VFX.rotation_degrees = -VFX.horiRot
	#Add them to make sure they 
	if using == 0:
		chainNodes[direction] = VFX
	else:
		chainNodes[Globals.otherConnectionNum[direction]] = VFX

func chain_shake() -> void:
	var pos = $Images.position
	var shakeTween = self.create_tween()
	var shakeDist = shakeRange
	shakeTween.tween_property($Images,"position",pos - shakeDist,shakeSpeed)
	shakeTween.tween_property($Images,"position",pos + shakeDist,shakeSpeed)
	shakeTween.tween_property($Images,"position",pos - shakeDist,shakeSpeed)
	shakeTween.tween_property($Images,"position",pos + shakeDist,shakeSpeed)
	shakeTween.tween_property($Images,"position",pos,shakeSpeed)

#______________________________
#GET SET VALUES
#______________________________
func get_links(array:bool = false):
	if array:
		return linkArray.linkedBeads.keys()
	else:
		return linkArray.linkedBeads

func set_links(value) -> void:
	get_links().merge(value.get_links())
	value.get_links().merge(get_links())

func get_all_chains() -> Array:
	var array: Array = []
	
	for value in chainedLinks:
		array.append(value.get_links())
	
	return array

func set_chains(value) -> void:
	var links: Dictionary = value.get_links()
	var alreadyThere: bool = false
	for bead in chainedLinks:
		if links.has(bead):
			alreadyThere = true
	
	if not alreadyThere:
		chainedLinks.append(value)

func reset_link():
	linkArray.linkedBeads = {self : self}

#____a__________________________
#DESTROYING PIECES
#______________________________
func destroy_anim():
	#Destroy bead
	var tween = self.create_tween()
	tween.tween_method(set_burn, 1.0, 0.0, burnTiming)
	await tween.finished
	queue_free()

func set_burn(value: float):
	material.set_shader_parameter("dissolve_value",value)
