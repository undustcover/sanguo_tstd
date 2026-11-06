extends RefCounted
# Fresh dictionaries on every reset; fixture attributes are deliberately synthetic.
static func create() -> Array:
	var result: Array = []
	for i in range(4):
		var id: String = ["A1", "A2", "B1", "B2"][i]
		var general := {"id": id + "-general", "kind": "武将", "slot": 0, "commander": "", "soldiers": 0, "injury": 0, "speed": [300, 200, 250, 200][i], "move_range": 4, "min_range": 100.0, "max_range": 590.0, "divine_power": 0.0, "divine_cap": 100.0}
		var members: Array = [general]
		if i != 1:
			var troop := general.duplicate(true)
			troop.merge({"id": id + "-troop", "kind": "部队", "slot": 4, "commander": general.id, "soldiers": 100, "move_range": 3}, true)
			members.append(troop)
		result.append({"id": id, "side": "A" if i < 2 else "B", "cell": Vector2i(1 + (i % 2) * 2, 1 if i < 2 else 5), "army": {"id": id, "members": members}, "move_points": 1, "battle_points": 2, "move_cap": 4 if i == 1 else 1, "battle_cap": 6 if i == 1 else 2, "battle_recovery": 4 if i == 1 else 2, "move_locked": false, "defending": false})
	return result

