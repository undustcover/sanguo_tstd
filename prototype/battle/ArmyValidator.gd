extends RefCounted
# Empty commander is reported as pending policy, never silently assigned.
static func validate(armies: Array) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var ids := {}
	var army_ids := {}
	for army in armies:
		if not army is Dictionary or not army.get("id") is String or army.get("id", "").is_empty() or not army.get("members") is Array:
			errors.append("军团必须提供非空字符串id和members数组")
			continue
		if army_ids.has(army.id):
			errors.append("军团ID重复：" + army.id)
		army_ids[army.id] = true
		var slots := {}
		var generals := {}
		var troops: Array = []
		for m in army.members:
			if not m is Dictionary:
				errors.append("成员必须是字典")
				continue
			var valid := true
			for field in ["id", "kind", "commander"]:
				if not m.get(field) is String:
					errors.append("成员缺少字符串字段：" + field)
					valid = false
			for field in ["slot", "soldiers", "injury"]:
				if not m.get(field) is int:
					errors.append("成员缺少整数字段：" + field)
					valid = false
			for field in ["speed", "min_range", "max_range"]:
				if not (m.get(field) is int or m.get(field) is float) or not is_finite(float(m.get(field, NAN))):
					errors.append("成员缺少有限数值字段：" + field)
					valid = false
			if not valid:
				continue
			if m.id.is_empty() or ids.has(m.id):
				errors.append("成员ID为空或重复：" + m.id)
			ids[m.id] = true
			if m.slot < 0 or m.slot >= 12 or slots.has(m.slot):
				errors.append("格位越界或重复：" + m.id)
			slots[m.slot] = true
			if m.soldiers < 0 or m.injury < 0 or m.min_range < 0 or m.max_range < m.min_range:
				errors.append("兵力、伤势或射程数据非法：" + m.id)
			if m.kind == "武将":
				generals[m.id] = true
			elif m.kind == "部队":
				troops.append(m)
			else:
				errors.append("未知成员类型：" + m.id)
		if generals.size() > 3 or troops.size() > 8:
			errors.append("军团超过三将八部队上限：" + army.id)
		var commands := {}
		for m in troops:
			if m.commander.is_empty():
				warnings.append("待定：部队无人指挥：" + m.id)
			elif not generals.has(m.commander):
				errors.append("指挥武将不在本军团：" + m.id)
			else:
				commands[m.commander] = commands.get(m.commander, 0) + 1
		for commander in commands:
			if commands[commander] > 4:
				errors.append("武将指挥超过四支部队：" + commander)
	return {"errors":errors, "warnings":warnings}
