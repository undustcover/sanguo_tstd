extends SceneTree
const Rules = preload("res://battle/Encounter.gd")
func member(id: String, slot: int, speed: int = 100, reach: float = 590.0) -> Dictionary:
	return {"id":id,"kind":"部队","slot":slot,"speed":speed,"min_range":100.0,"max_range":reach,"soldiers":100,"injury":0,"commander":""}
func data(a: Array,b: Array) -> Array:
	return [{"id":"A","members":a},{"id":"B","members":b}]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var r = Rules.new()
	var a = member("a",0)
	var b = member("b",8)
	r.start(data([a],[b]),42)
	a.max_range = 277.8
	assert(r.distance(a,b) == 300 and r.targets(a).is_empty())
	a.slot = 8
	a.max_range = 499.9
	assert(r.distance(a,b) == 500 and r.targets(a).is_empty())
	b.slot = 10
	assert(r.distance(a,b) == 560)
	a.slot = 0
	a.max_range = 590.0
	b.slot = 4
	var front = member("front",0)
	r.start(data([a],[b,front]),42)
	assert(b not in r.targets(a))
	front.soldiers = 0
	assert(b in r.targets(a))
	# Counter consumes action, never counter-chains, state persists between starts.
	b.slot = 0
	r.start(data([a],[b]),42)
	assert(r.current.id == "a")
	assert(r.attack("b"))
	assert(a.soldiers == 90 and b.soldiers == 90 and r.finished)
	r.start(data([a],[b]),42)
	assert(r.spent.is_empty() and a.soldiers == 90 and b.soldiers == 90)
	# Dead defender cannot counter.
	b.soldiers = 10
	r.attack("b")
	assert(a.soldiers == 90 and b.soldiers == 0)
	# Fast actor waits, ally breaks protection, waiting actor jumps ahead.
	var archer = member("archer",8,900,400)
	archer.min_range = 400.0
	var infantry = member("infantry",0,800,100)
	var slow = member("slow",1,0,100)
	front = member("front",0,0,100)
	front.soldiers = 10
	b = member("rear",4,0,100)
	r.start(data([archer,infantry,slow],[front,b]),42)
	assert(r.current.id == "infantry" and archer in r.waiting)
	r.attack("front")
	assert(r.current.id == "archer")
	assert(r.attack("rear"))
	# No legal target terminates without infinite waits.
	a = member("a",8,100,100)
	b = member("b",8,100,100)
	r.start(data([a],[b]),42)
	assert(r.finished)
	# Identical seed reproduces ties.
	a = member("a",0,100)
	b = member("b",0,300)
	r.start(data([a],[b]),91)
	var first: String = r.current.id
	r.start(data([a],[b]),91)
	assert(r.current.id == first)
	# General injury threshold prevents counter and blocking.
	a = member("a",0)
	b = member("general",0)
	b.kind = "武将"
	b.injury = 2
	r.start(data([a],[b]),42)
	assert(not r.attack("missing") and r.spent.is_empty())
	assert(r.attack("general"))
	assert(b.injury == 3 and a.soldiers == 100 and not r.alive(b))
	# Scene wiring and actual target button.
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var bench = scene.get_node("P1")
	bench.open()
	assert(bench.panel.visible and scene.get_node("GameBoard").process_mode == Node.PROCESS_MODE_DISABLED)
	bench.content.get_child(3).get_child(0).pressed.emit()
	assert(not bench.rules.log_lines.is_empty())
	var guard := 0
	while not bench.rules.finished and guard < 30:
		bench.rules.attack(bench.rules.targets(bench.rules.current)[0].id)
		guard += 1
	assert(bench.rules.finished and guard < 30)
	bench.refresh()
	bench.content.get_child(bench.content.get_child_count()-1).pressed.emit()
	assert(not bench.panel.visible)
	print("P1 PASS: range, columns, protection, counter, wait re-entry, termination, seed, scene lifecycle")
	quit()


