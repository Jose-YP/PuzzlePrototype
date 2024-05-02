extends Resource
class_name Rules

@export_category("Grid")
@export_range(6,15) var width: int = 9
@export_range(6,15) var height: int = 9 #row 0, 1 and 2 are fail state rows
@export var offset: Vector2 = Vector2(65,65)
@export var origin: Vector2 = Vector2(200, 85)
@export var start_pos: Vector2 = Vector2(4,1)
@export_category("Process Constants")
@export_range(0,2) var gravity: float = 1
@export_range(0,1) var soft_drop: float = 1
@export_range(0,3) var fail_rows: int = 2
@export_group("Debug")
@export var gravity_on: bool = true
@export_range(0,9) var grid_fill: int = 4
@export var column_fill: Vector2 = Vector2(3,4)
@export var overhang_dimentions: Vector2 = Vector2(4,2)
