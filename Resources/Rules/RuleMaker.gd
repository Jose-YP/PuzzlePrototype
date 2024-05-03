extends Resource
class_name Rules

@export_category("Grid")
@export_group("Dimentions")
@export_range(6,15) var width: int = 9
@export_range(6,15) var height: int = 9 #row 0, 1 and 2 are fail state rows
@export_range(0,3) var fail_rows: int = 2
@export_group("Pos & Sizing")
@export var offset: Vector2 = Vector2(65,65)
@export var origin: Vector2 = Vector2(200, 85)
@export var start_pos: Vector2i = Vector2(4,1)

@export_category("Process Constants")
@export var piece_relationships: Relations
@export_group("Timing")
@export_range(0,2) var gravity: float = 1
@export_range(0,1) var soft_drop: float = 1
@export_group("ETC")
@export var rotate_pop_checks: Array[Vector2i] = [Vector2i(0,-1),Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]


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
