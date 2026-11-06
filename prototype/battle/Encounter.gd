extends RefCounted
# Pure rules: no scene/animation dependencies. Persistent dictionaries belong to caller.
var armies: Array
var order: Array = []
var waiting: Array = []
var spent: Dictionary = {}
var log_lines: Array[String] = []
var current: Dictionary = {}
var finished := false
var rng := RandomNumberGenerator.new()

func alive(m: Dictionary) -> bool:
	return m.injury < 3 if m.kind == "武将" else m.soldiers > 0

func distance(a: Dictionary, b: Dictionary) -> int:
	return 100 + 100 * (int(a.slot / 4) + int(b.slot / 4)) + 30 * absi(a.slot % 4 - b.slot % 4)

func targets(a: Dictionary) -> Array:
	var result: Array = []
	for army in armies:
		if army.id == a.side:
			continue
		for b in army.members:
			if not alive(b) or distance(a, b) < int(floor(a.min_range)) or distance(a, b) > int(floor(a.max_range)):
				continue
			var blocked := false
			for front in army.members:
				if alive(front) and front.slot % 4 == b.slot % 4 and int(front.slot / 4) < int(b.slot / 4):
					blocked = true
			if not blocked:
				result.append(b)
	return result

func start(data: Array, seed_value: int) -> void:
	armies = data
	rng.seed = seed_value
	order.clear()
	waiting.clear()
	spent.clear()
	log_lines.clear()
	finished = false
	current = {}
	var validation = preload("res://battle/ArmyValidator.gd").validate(data)
	if data.size() != 2:
		validation.errors.append("一次交战需要两个军团")
	if not validation.errors.is_empty():
		finished = true
		for error in validation.errors:
			log_lines.append("数据错误：" + error)
		return
	for warning in validation.warnings:
		log_lines.append(warning)
	for side in range(armies.size()):
		for m in armies[side].members:
			m.side = armies[side].id
			m.rank_speed = m.speed + (200 if side == 0 else 0)
			m.tie = rng.randf()
			if alive(m):
				order.append(m)
	order.sort_custom(func(a, b): return a.rank_speed > b.rank_speed if a.rank_speed != b.rank_speed else a.tie > b.tie)
	log_lines.append("开始交战 seed=%d；进攻方+200；行动恢复，战损保留" % seed_value)
	advance()

func advance() -> void:
	current = {}
	# Each complete attack/counter pair gives waiting actors priority.
	for m in waiting.duplicate():
		if not alive(m) or spent.has(m.id):
			waiting.erase(m)
		elif not targets(m).is_empty():
			waiting.erase(m)
			current = m
			log_lines.append("待机重返：" + m.id)
			return
	while not order.is_empty():
		var m: Dictionary = order.pop_front()
		if not alive(m) or spent.has(m.id):
			continue
		if targets(m).is_empty():
			waiting.append(m)
			waiting.sort_custom(func(a, b): return a.rank_speed > b.rank_speed if a.rank_speed != b.rank_speed else a.tie > b.tie)
			log_lines.append("无合法目标，待机：" + m.id)
		else:
			current = m
			return
	finished = true
	log_lines.append("交战结束：无剩余有效行动；战损保留")

func hit(a: Dictionary, b: Dictionary, counter: bool) -> void:
	spent[a.id] = true
	if b.kind == "部队":
		b.soldiers = maxi(0, b.soldiers - 10)
	else:
		b.injury += 1
	log_lines.append("%s %s → %s（距离%d），受击后兵力%d / 伤势%d" % ["反击" if counter else "攻击", a.id, b.id, distance(a,b), b.soldiers, b.injury])

func attack(target_id: String) -> bool:
	if finished or current.is_empty():
		return false
	for b in targets(current):
		if b.id != target_id:
			continue
		var a := current
		hit(a,b,false)
		if alive(b) and not spent.has(b.id) and a in targets(b):
			hit(b,a,true)
		advance()
		return true
	return false
