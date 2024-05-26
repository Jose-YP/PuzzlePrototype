extends Node

func fill_board() -> void:
	for i in Globals.rules.width:
		for j in Globals.rules.grid_fill:
			if (Globals.rules.height-j-1) <= Globals.rules.fail_rows:
				continue
			var pos = Vector2i(i,Globals.rules.height-j-1)
			$"..".add_bead(pos)

func fill_column() -> void:
	var columnDim: Vector2i = Globals.rules.column_fill
	var columnPos: Vector2i = Globals.rules.column_pos
	for i in range(columnDim.x):
		for j in range(int(columnDim.y)):
			$"..".add_bead(Vector2i(columnPos.x + i + 1,Globals.rules.height-j-1-columnPos.y))

func make_overhang() -> void:
	var overhangDim: Vector2i = Globals.rules.overhang_dimentions
	var overhangPos: Vector2i = Globals.rules.overhang_pos
	for j in range(int(overhangDim.y)):
		$"..".add_bead(Vector2i(overhangPos.x,Globals.rules.height-j-1))
	
	for i in range(abs(overhangDim.x)):
		var ammount = overhangPos.x+overhangDim.x+i
		$"..".add_bead(Vector2i(ammount,Globals.rules.height-overhangPos.y))

func display_board(board) -> void:
	print("\n_____________________________________________________")
	for j in Globals.rules.height:
		var debugString: String
		for i in Globals.rules.width:
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
	$"..".find_links()
#Erase from the script wide var rather than local
	#for i in range(breakerArray.size()):
		##If the array still has null values, skip them
		#if not is_instance_valid(breakerArray[i]):
			#continue
		#if breakerArray[i].breaking:
			#print("breaking ", breakerArray[i])
			#breakerArray[i].destroy_anim()
			#var pos = breakerArray[i].gridPos[0]
			#board[pos.x][pos.y] = null
			#breakers.erase(breakerArray[i])
			#await breakerArray[i].tree_exiting
