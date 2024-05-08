extends Resource
class_name Rules

@export_category("Grid")
@export_group("Dimentions")
@export_range(6,15) var width: int = 9
@export_range(6,15) var height: int = 9 #row 0, 1 and 2 are fail state rows
@export_range(0,15) var safe_high_columns: int = 0
@export_range(0,3) var fail_rows: int = 2
@export_group("Pos & Sizing")
@export var offset: Vector2 = Vector2(65,65)
@export var origin: Vector2 = Vector2(200, 85)
@export var start_pos: Vector2i = Vector2(4,1)

@export_category("Process Constants")
@export var bead_relationships: Relations
@export_group("Timing")
@export_range(0,2) var gravity: float = 1
@export_range(0,1) var soft_drop: float = 1
@export_group("ETC")
@export var rotate_pop_checks: Array[Vector2i] = [Vector2i(0,-1),Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]

@export_category("Scoring")
@export_group("Score")
@export_range(10,100) var beadScore: int = 50
@export_range(0,2,.01) var linkMultiplier: float = .5
@export_range(0,2,.01) var powerMultiplier: float = .15
@export_range(0,2,.01) var chainMultiplier: float = .7
@export_range(0,2,.01) var varietyMultiplier: float = 2
@export_group("Levels")
@export var max_levels: int = 20
@export var bead_levelUp: int = 100
@export_range(0,1,.01) var speedUp: float = .25

@export_category("Debug")
@export_group("Debug")
@export_subgroup("Bools")
@export var gravity_on: bool = true
@export var spawning: bool = true
@export_flags("Grid","Column","Overhang") var debug_fills: int = 0
@export_subgroup("Fills")
@export_range(0,9) var grid_fill: int = 4
@export var column_fill: Vector2i = Vector2i(3,4)
@export var column_pos: Vector2i = Vector2i(3,0)
@export var overhang_dimentions: Vector2i = Vector2i(1,4)
@export var overhang_pos: Vector2i = Vector2i(4,2)

func indvChainScore(chain, linkNum): #Seperate functions cause the two will score a full chain differently
	var linkScore: int = 0
	for link in chain:
		linkScore += link.size() * beadScore * powerMultiplier
	return linkScore  * (linkMultiplier + linkNum - 1)

func totalScore(chains):
	var chainNum = chains.size()
	var finalScore: int = 0
	for chain in chains:
		var linkNum = chain.size()
		var linkScore: int = 0
		for link in chains:
			linkScore += link.size() * beadScore * powerMultiplier
		finalScore += linkScore  * (linkMultiplier + linkNum - 1)
	
	return finalScore * chainNum * chainMultiplier
