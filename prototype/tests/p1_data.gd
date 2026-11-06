extends SceneTree
const Validator = preload("res://battle/ArmyValidator.gd")
const Rules = preload("res://battle/Encounter.gd")
func m(id: String, slot: int, kind: String = "部队", commander: String = "g") -> Dictionary:
	return {"id":id,"slot":slot,"kind":kind,"commander":commander,"soldiers":100,"injury":0,"speed":100,"min_range":100.0,"max_range":590.0}
func army(members: Array) -> Array:
	return [{"id":"A","members":members}]
func _initialize() -> void:
	var full: Array = [m("g",8,"武将",""),m("g2",9,"武将",""),m("g3",10,"武将","")]
	for i in range(8):
		full.append(m("t%d" % i,i,"部队","g" if i < 4 else "g2"))
	assert(Validator.validate(army(full)).errors.is_empty())
	var invalid = full.duplicate(true)
	invalid[7].commander = "g"
	assert(not Validator.validate(army(invalid)).errors.is_empty())
	invalid = full.duplicate(true)
	invalid.append(m("g4",11,"武将",""))
	assert(not Validator.validate(army(invalid)).errors.is_empty())
	invalid = full.duplicate(true)
	invalid.append(m("t9",11))
	assert(not Validator.validate(army(invalid)).errors.is_empty())
	for patch in [{"slot":12},{"slot":8},{"id":"g"},{"commander":"foreign"},{"min_range":600},{"soldiers":-1}]:
		invalid = full.duplicate(true)
		invalid[3].merge(patch,true)
		assert(not Validator.validate(army(invalid)).errors.is_empty())
	invalid = full.duplicate(true)
	invalid[3].commander = ""
	var report = Validator.validate(army(invalid))
	assert(report.errors.is_empty() and report.warnings.size() == 1)
	assert(not Validator.validate([{}]).errors.is_empty())
	# Disabled general no longer protects the member behind; injury persists.
	var a = m("a",0,"武将","")
	var general = m("b",0,"武将","")
	general.injury = 3
	var rear = m("rear",4,"部队","b")
	var r = Rules.new()
	var pair = [{"id":"A","members":[a]},{"id":"B","members":[general,rear]}]
	r.start(pair,42)
	assert(rear in r.targets(a) and general not in r.targets(a))
	a.injury = 2
	r.start(pair,42)
	assert(a.injury == 2 and general.injury == 3)
	# Invalid input fails closed and cannot perform an attack.
	pair[1].members[1].slot = 0
	r.start(pair,42)
	assert(r.finished and r.current.is_empty() and not r.attack("rear"))
	print("P1 CLOSEOUT PASS: full roster, limits, identities, slots, command, malformed data, disabled protection, persistent injury")
	quit()
