extends CanvasLayer
const Rules = preload("res://battle/Encounter.gd")
var rules = Rules.new()
var panel: PanelContainer
var content: VBoxContainer
var owner_p0: Node


func _ready() -> void:
	owner_p0 = get_parent().get_node("P0")
	var launch := Button.new()
	launch.position = Vector2(12, 88)
	launch.text = "P1：内部交战测试台"
	launch.pressed.connect(open)
	add_child(launch)
	panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(1250, 690)
	add_child(panel)
	content = VBoxContainer.new()
	panel.add_child(content)
	panel.hide()

func open() -> void:
	if panel.visible or owner_p0.panel.visible:
		return
	var board = owner_p0.board
	if board._active_unit != null:
		if board._active_unit._is_walking:
			return
		board._deselect_active_unit()
		board._clear_active_unit()
	board.process_mode = Node.PROCESS_MODE_DISABLED
	for army in owner_p0.armies:
		for m in army.members:
			if not m.has("speed"):
				m.speed = 100 if m.kind == "武将" else (400 if m.slot == 9 else 200)
				m.min_range = 100.0
				m.max_range = 590.0 if m.slot == 9 else 300.0
	rules.start(owner_p0.armies, 42)
	panel.show()
	refresh()

func label(text: String, parent: Node) -> void:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", 14)
	parent.add_child(node)

func refresh() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	label("P1 内部交战 | 双方手动选敌 | 临时伤害：扣10兵 / 伤势+1，3点失能 | 种子42", content)
	var formations := HBoxContainer.new()
	content.add_child(formations)
	for army in owner_p0.armies:
		var column := VBoxContainer.new()
		formations.add_child(column)
		label("军团 " + army.id + "（前排→中排→后排，同列对位）", column)
		var grid := GridContainer.new()
		grid.columns = 4
		column.add_child(grid)
		for slot in range(12):
			var cell := Label.new()
			cell.custom_minimum_size = Vector2(150, 65)
			cell.add_theme_font_size_override("font_size", 14)
			cell.text = "格%d 空" % slot
			for m in army.members:
				if m.slot == slot:
					cell.text = "%s\n兵%d 伤%d %s\n速%d 射程%d—%d" % [m.id, m.soldiers, m.injury, "已行动" if rules.spent.has(m.id) else ("可行动" if rules.alive(m) else "失能"), m.rank_speed, m.min_range, m.max_range]
			grid.add_child(cell)
	if rules.finished:
		label("本次交战结束。返回后再次进入恢复行动，不恢复战损。", content)
	else:
		label("当前行动：" + rules.current.id + "；点击合法目标执行攻击及可能的反击：", content)
		var choices := HBoxContainer.new()
		content.add_child(choices)
		for target in rules.targets(rules.current):
			var button := Button.new()
			button.text = "%s 距离%d" % [target.id, rules.distance(rules.current,target)]
			button.pressed.connect(func():
				rules.attack(target.id)
				refresh())
			choices.add_child(button)
	var logs := TextEdit.new()
	logs.custom_minimum_size = Vector2(1200, 220)
	logs.editable = false
	logs.text = "\n".join(rules.log_lines)
	content.add_child(logs)
	var back := Button.new()
	back.text = "返回外部战场（保留战损；未完成时视为测试中止）"
	back.pressed.connect(func():
		panel.hide()
		owner_p0.board.process_mode = Node.PROCESS_MODE_INHERIT)
	content.add_child(back)

