extends RefCounted
var units: Array = []
var queue: Array = []
var round_number := 0
var occupancy: Dictionary = {}
var logs: Array[String] = []
var result := ""

func alive(member: Dictionary) -> bool:
	return member.injury < 3 if member.kind == "武将" else member.soldiers > 0

func fighters(unit: Dictionary) -> Array:
	return unit.army.members.filter(func(m): return alive(m))

func speed(unit: Dictionary) -> float:
	var members := fighters(unit)
	var total := 0.0
	for m in members:
		total += m.speed
	return total / members.size() if not members.is_empty() else 0.0

func movement(unit: Dictionary) -> int:
	var distance := 2147483647
	for m in fighters(unit):
		distance = mini(distance, m.move_range)
	return 0 if fighters(unit).is_empty() else distance

func reset() -> void:
	units = preload("res://battle/p2/TestConfig.gd").create()
	round_number = 0
	logs.clear()
	result = ""
	refresh()
	next_round()

func refresh() -> void:
	occupancy.clear()
	var sides: Dictionary = {}
	for unit in units:
		if not fighters(unit).is_empty():
			occupancy[unit.cell] = unit
			sides[unit.side] = true
	result = "draw" if sides.is_empty() else (str(sides.keys()[0]) if sides.size() == 1 else "")

func next_round() -> void:
	round_number += 1
	queue.clear()
	for unit in units:
		unit.defending = false
		unit.move_locked = false
		if round_number > 1:
			unit.move_points = mini(unit.move_cap, unit.move_points + 1)
			unit.battle_points = mini(unit.battle_cap, unit.battle_points + unit.battle_recovery)
		if not fighters(unit).is_empty():
			queue.append(unit)
	queue.sort_custom(func(a, b): return speed(a) > speed(b) if speed(a) != speed(b) else a.id < b.id)
	logs.append("round %d: %s" % [round_number, str(queue.map(func(u): return u.id))])
