extends RefCounted
enum State { AWAITING_COMMAND, MOVING, ENCOUNTER, FINISHED }
var session = preload("res://battle/p2/BattleSession.gd").new()
var state := State.AWAITING_COMMAND
var current: Dictionary = {}
var pending_cell := Vector2i.ZERO

func reset() -> void:
	session.reset()
	current = {}
	state = State.AWAITING_COMMAND
	advance()

func advance() -> void:
	session.refresh()
	if session.result != "":
		state = State.FINISHED
		current = {}
		return
	while true:
		if session.queue.is_empty():
			session.next_round()
		var unit: Dictionary = session.queue.pop_front()
		if not session.fighters(unit).is_empty():
			current = unit
			state = State.AWAITING_COMMAND
			return

func wait_turn() -> bool:
	if state != State.AWAITING_COMMAND:
		return false
	session.logs.append(current.id + " wait")
	advance()
	return true

func defend() -> bool:
	if state != State.AWAITING_COMMAND or current.battle_points < 1:
		return false
	current.battle_points -= 1
	current.defending = true
	session.logs.append(current.id + " defend +50%")
	advance()
	return true

# Caller supplies terrain predicate; path includes origin, is validated before spending.
func begin_move(path: Array, passable: Callable) -> bool:
	if state != State.AWAITING_COMMAND or current.move_locked or current.move_points < 1:
		return false
	if path.size() < 2 or path.size() - 1 > session.movement(current) or Vector2i(path[0]) != current.cell:
		return false
	for i in range(1, path.size()):
		var cell := Vector2i(path[i])
		var delta := cell - Vector2i(path[i - 1])
		if absi(delta.x) + absi(delta.y) != 1 or not passable.call(cell):
			return false
		if session.occupancy.has(cell) and session.occupancy[cell].side != current.side:
			return false
	pending_cell = Vector2i(path.back())
	if session.occupancy.has(pending_cell):
		return false
	current.move_points -= 1
	state = State.MOVING
	return true

func complete_move() -> bool:
	if state != State.MOVING:
		return false
	current.cell = pending_cell
	session.refresh()
	session.logs.append(current.id + " move " + str(pending_cell))
	state = State.AWAITING_COMMAND
	return true

static func distance_increment(a: Vector2i, b: Vector2i) -> int:
	var delta := (a - b).abs()
	return 200 * (maxi(delta.x, delta.y) - 1) + 100 * mini(delta.x, delta.y)
