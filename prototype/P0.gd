extends CanvasLayer

var armies: Array = []
var panel: PanelContainer
var rows: VBoxContainer
var board: Node
var visits := 0

func _ready() -> void:
	board = get_parent().get_node("GameBoard")
	for side in range(2):
		var prefix := "A" if side == 0 else "B"
		armies.append({"id": prefix, "members": [
			{"id": prefix + "-general", "kind": "武将", "slot": 4, "commander": "", "soldiers": 0, "injury": 0},
			{"id": prefix + "-infantry", "kind": "部队", "slot": 0, "commander": prefix + "-general", "soldiers": 100, "injury": 0},
			{"id": prefix + "-archers", "kind": "部队", "slot": 9, "commander": prefix + "-general", "soldiers": 80, "injury": 0}]})
	board.get_node("Bear").set_meta("army", armies[0])
	board.get_node("Cat").set_meta("army", armies[1])
	var bar := VBoxContainer.new()
	bar.position = Vector2(12, 12)
	add_child(bar)
	var hint := Label.new()
	hint.text = "P0 底座适配 | 熊=A军团，猫=B军团\n点击单位→悬停预览→点击移动；Esc取消。测试入口不限距离。"
	bar.add_child(hint)
	var enter := Button.new()
	enter.text = "A → B：进入测试交战"
	enter.pressed.connect(_enter)
	bar.add_child(enter)
	panel = PanelContainer.new()
	panel.position = Vector2(30, 110)
	panel.size = Vector2(1150, 540)
	add_child(panel)
	rows = VBoxContainer.new()
	panel.add_child(rows)
	panel.hide()

func _enter() -> void:
	if panel.visible or (board._active_unit != null and board._active_unit._is_walking):
		return
	if board._active_unit != null:
		board._deselect_active_unit()
		board._clear_active_unit()
	board.process_mode = Node.PROCESS_MODE_DISABLED
	visits += 1
	panel.show()
	_refresh()
	print("P0 ENTER ", visits, " ", armies)

func _refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = "第 %d 次交战 | 仅测试数据修改，不执行正式伤害规则 | 格位0—11=三排×四列" % visits
	rows.add_child(title)
	for army in armies:
		var heading := Label.new()
		heading.text = "军团 " + army.id
		rows.add_child(heading)
		for member in army.members:
			var line := HBoxContainer.new()
			rows.add_child(line)
			var info := Label.new()
			info.custom_minimum_size.x = 820
			info.text = "%s | %s | 格位%d | 指挥:%s | 兵力%d | 测试伤势%d" % [member.id, member.kind, member.slot, member.commander, member.soldiers, member.injury]
			line.add_child(info)
			var edit := Button.new()
			edit.text = "测试扣10兵" if member.kind == "部队" else "测试伤势+1"
			edit.pressed.connect(func():
				if member.kind == "部队":
					member.soldiers = maxi(0, member.soldiers - 10)
				else:
					member.injury += 1
				print("P0 EDIT ", member)
				_refresh())
			line.add_child(edit)
	var back := Button.new()
	back.text = "返回外部地图（保留位置与成员状态）"
	back.pressed.connect(func():
		panel.hide()
		board.process_mode = Node.PROCESS_MODE_INHERIT
		print("P0 RETURN ", armies))
	rows.add_child(back)
