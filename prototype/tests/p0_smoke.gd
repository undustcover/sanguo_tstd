extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var p0 = scene.get_node("P0")
	var board = scene.get_node("GameBoard")
	var bear = board.get_node("Bear")
	var original_position = bear.position
	assert(bear.get_meta("army") == p0.armies[0])
	board._select_unit(bear.cell)
	var target = bear.cell + Vector2.RIGHT
	board._on_Cursor_moved(target)
	board._move_active_unit(target)
	await bear.walk_finished
	await process_frame
	assert(bear.cell == target)
	assert(bear.position != original_position)
	var moved_position = bear.position
	p0._enter()
	assert(board.process_mode == Node.PROCESS_MODE_DISABLED)
	# Use actual UI button signals to test editing and returning.
	p0.rows.get_child(3).get_child(1).pressed.emit()
	assert(p0.armies[0].members[1].soldiers == 90)
	assert(p0.armies[1].members[1].soldiers == 100)
	p0.rows.get_child(p0.rows.get_child_count() - 1).pressed.emit()
	assert(board.process_mode == Node.PROCESS_MODE_INHERIT)
	p0._enter()
	assert(p0.visits == 2)
	assert(p0.armies[0].members[1].soldiers == 90)
	assert(bear.position == moved_position)
	print("P0 SMOKE PASS: movement, independent state, input lock, return, re-entry")
	quit()
