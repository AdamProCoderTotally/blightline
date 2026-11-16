extends Node

var _failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()


func _run() -> void:
	await get_tree().process_frame
	_expect(ContentDb.load_errors.is_empty(), "data loaded: %s" % " ".join(ContentDb.load_errors))
	_check_catalog()
	_check_wave_plan()
	_check_scaling_and_leak()
	await _check_world_rules()
	_check_camera()
	await _check_scenes_boot()
	if _failures.is_empty():
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error(failure)
			print("SMOKE FAIL: ", failure)
		get_tree().quit(1)


func _check_catalog() -> void:
	_expect(ContentDb.towers.size() == 6, "six towers")
	_expect(ContentDb.enemies_by_id.size() == 9, "nine enemies")
	_expect(ContentDb.regular_waves().size() == 29, "29 regular waves")
	_expect(str(ContentDb.boss_wave().get("id", "")) == "boss_wave", "boss wave")
	_expect(str(ContentDb.map.get("display_name", "")) == "Cinder Pass", "map name")
	_expect(is_equal_approx(float(ContentDb.map.get("path", {}).get("width", 0)), 4.0), "path width 4")
	_expect(str(ContentDb.game.get("title", "")) == "BLIGHTLINE", "title")
	_expect(is_equal_approx(float(ContentDb.game.get("cash_per_hp", 0)), 1.0), "cash per hp")
	_expect(str(ContentDb.difficulties.get("default", "")) == "sentinel", "default mode")
	var expected_waves := {"recruit": 16, "sentinel": 24, "ironwall": 30, "overrun": 30}
	var expected_hp := {"recruit": 800, "sentinel": 500, "ironwall": 400, "overrun": 300}
	var expected_cash := {"recruit": 1000, "sentinel": 800, "ironwall": 700, "overrun": 600}
	for mode in ContentDb.difficulties.get("modes", []):
		var mode_id := str(mode.get("id", ""))
		_expect(int(mode.get("wave_count", -1)) == int(expected_waves[mode_id]), "waves %s" % mode_id)
		_expect(int(mode.get("base_hp", -1)) == int(expected_hp[mode_id]), "base hp %s" % mode_id)
		_expect(int(mode.get("start_cash", -1)) == int(expected_cash[mode_id]), "cash %s" % mode_id)
		_expect(is_equal_approx(float(mode.get("sell_ratio", 0)), 0.5), "sell ratio %s" % mode_id)
	var upgrades := 0
	for tower in ContentDb.towers:
		_expect(tower.get("top", []).size() == 5, "top tiers %s" % tower.get("id", ""))
		_expect(tower.get("bottom", []).size() == 5, "bottom tiers %s" % tower.get("id", ""))
		upgrades += tower.get("top", []).size() + tower.get("bottom", []).size()
	_expect(upgrades == 60, "60 upgrades")
	_expect(int(ContentDb.enemies_by_id["mother_blight"]["hp"]) == 30000, "mother blight hp")
	_expect(int(ContentDb.enemies_by_id["mother_blight"]["shield"]) == 10000, "mother blight shield")
	_expect(int(ContentDb.enemies_by_id["gristle"]["hp"]) == 2500, "gristle hp")
	_expect(ContentDb.wave_count_error(31) != "", "wave_count 31 is rejected")
	_expect(ContentDb.wave_count_error(30) == "", "wave_count 30 fits")


func _check_wave_plan() -> void:
	var recruit := ContentDb.build_wave_plan(16)
	var sentinel := ContentDb.build_wave_plan(24)
	var ironwall := ContentDb.build_wave_plan(30)
	_expect(recruit.size() == 16 and str(recruit[-1].get("id", "")) == "boss_wave", "recruit ends on the boss")
	_expect(int(recruit[14].get("wave", 0)) == 15, "recruit plays regular 1..15")
	_expect(sentinel.size() == 24 and int(sentinel[22].get("wave", 0)) == 23, "sentinel regular prefix")
	_expect(str(sentinel[-1].get("id", "")) == "boss_wave", "sentinel boss")
	_expect(ironwall.size() == 30 and int(ironwall[28].get("wave", 0)) == 29, "ironwall uses all 29")
	_expect(str(ironwall[9].get("groups", [])[-1].get("enemy", "")) == "gristle", "wave 10 spawns Gristle")
	_expect(int(ironwall[21].get("groups", [])[-1].get("count", 0)) == 2, "wave 22 spawns two Gristles")


func _check_scaling_and_leak() -> void:
	GameState.leak_damage_mode = "remaining_hp_plus_shield"
	_expect(GameState.leak_amount(10.2, 3.1) == 14, "ceil(hp + shield)")
	_expect(GameState.leak_amount(30.0, 0.0) == 30, "damaged husk leak")
	_expect(GameState.leak_amount(72.0, 24.0) == 96, "full husk leak")
	var shambler: Dictionary = ContentDb.enemies_by_id["shambler"]
	var expected := {"recruit": 7.5, "sentinel": 10.0, "ironwall": 12.5, "overrun": 15.0}
	for mode_id in expected:
		GameState.apply_mode(mode_id)
		_expect(is_equal_approx(GameState.scaled_hp_multiplier(1, false) * float(shambler["hp"]), float(expected[mode_id])), "shambler wave 1 %s" % mode_id)


func _check_world_rules() -> void:
	GameState.apply_mode("sentinel")
	var root := Node3D.new()
	add_child(root)
	var field := Battlefield.new()
	var towers := Node3D.new()
	var placement := PlacementController.new()
	root.add_child(field)
	root.add_child(towers)
	root.add_child(placement)
	field.build(ContentDb.map)
	await get_tree().process_frame
	_expect(is_equal_approx(field.path_length(), 140.0), "path length 140, got %s" % field.path_length())
	placement.configure(ContentDb.towers, field, towers)
	placement.select_build(0)
	var on_road := Vector3(7, 0, 8)
	var open := Vector3(20, 0, 24)
	var road_result: Dictionary = placement.evaluate(on_road, placement.current_def())
	var open_result: Dictionary = placement.evaluate(open, placement.current_def())
	_expect(not road_result["ok"], "road blocked (%s)" % road_result["reason"])
	_expect(open_result["ok"], "open ground valid (%s)" % open_result["reason"])
	var before := GameState.cash
	_expect(placement.try_place(open), "place Picket")
	_expect(GameState.cash == before - 250, "picket costs 250")
	_expect(placement.selected != null and placement.selected.upgrade(0), "buy Scope Rail")
	_expect(GameState.cash == before - 400, "scope rail costs 150")
	_expect(is_equal_approx(float(placement.selected.stats.get("range", 0)), 13.0), "range delta applied")
	placement.sell_selected()
	_expect(GameState.cash == before - 400 + GameState.refund_for(400), "sell refunds 50 percent of 400")
	var wide := Tower.new()
	towers.add_child(wide)
	wide.setup(_blank_tower(7))
	_expect(wide.tier_count(0) == 7, "tier count follows the array")
	for _i in 7:
		_expect(wide.upgrade(0), "upgrade within data length")
	_expect(not wide.can_upgrade(0), "no tier past the data")
	var capped := Tower.new()
	towers.add_child(capped)
	capped.setup(_blank_tower(5))
	_expect(capped.upgrade(0) and capped.upgrade(0) and capped.upgrade(0), "path reaches tier 3")
	_expect(capped.upgrade(1) and capped.upgrade(1), "other path reaches tier 2")
	_expect(not capped.can_upgrade(1), "other path capped at tier 2")
	_expect(capped.upgrade(0) and capped.upgrade(0) and not capped.can_upgrade(0), "5-2 is reachable")
	var basic := Enemy.new()
	root.add_child(basic)
	basic.setup(ContentDb.enemies_by_id["shambler"], field, 1, false, false, 0.0)
	_expect(is_equal_approx(basic.max_hp, 10.0), "sentinel shambler hp")
	var husk := Enemy.new()
	root.add_child(husk)
	husk.setup(ContentDb.enemies_by_id["plated_husk"], field, 5, false, false, 0.0)
	_expect(is_equal_approx(husk.max_hp, 72.0), "wave 5 husk hp")
	_expect(is_equal_approx(husk.max_shield, 24.0), "wave 5 husk shield")
	var shield_before := husk.shield
	var paid := husk.receive_hit(2.0, "kinetic", 0.0)
	_expect(paid == 0.0, "shield pays no cash")
	_expect(is_equal_approx(shield_before - husk.shield, 1.2), "40 percent kinetic resist")
	var ignored := husk.shield
	husk.receive_hit(2.0, "kinetic", 1.0)
	_expect(is_equal_approx(ignored - husk.shield, 2.0), "ignore resistance bypasses the plate")
	var lives := GameState.base_hp
	husk.hp = 30.0
	husk.shield = 0.0
	husk.path_distance = field.path_length() - 0.01
	husk.advance(1.0)
	_expect(GameState.base_hp == lives - 30, "leak is remaining hp + shield")
	GameState.apply_mode("sentinel")
	var shooter := Tower.new()
	towers.add_child(shooter)
	shooter.setup(ContentDb.towers[0])
	var walker := Enemy.new()
	root.add_child(walker)
	walker.setup(ContentDb.enemies_by_id["shambler"], field, 1, false, false, 0.0)
	shooter.global_position = walker.global_position + Vector3(0, 0, 3)
	basic.remove_from_group("enemies")
	var cash_before := GameState.cash
	shooter._process(0.05)
	_expect(walker.hp < walker.max_hp, "picket damages a shambler")
	_expect(GameState.cash == cash_before + int(round(walker.max_hp - walker.hp)), "cash per hp of health damage")
	var bait := Tower.new()
	towers.add_child(bait)
	bait.setup(ContentDb.towers[0])
	var hp_before := bait.hp
	_expect(not bait.apply_damage(25.0, walker), "non-boss tower damage ignored")
	_expect(is_equal_approx(bait.hp, hp_before), "tower hp unchanged")
	var boss := Enemy.new()
	root.add_child(boss)
	boss.setup(ContentDb.enemies_by_id["gristle"], field, 10, false, false, 0.0)
	_expect(is_equal_approx(boss.max_hp, 2500.0), "gristle ignores wave hp slope")
	_expect(bait.apply_damage(25.0, boss), "boss damages towers on sentinel")
	GameState.apply_mode("recruit")
	var safe := Tower.new()
	towers.add_child(safe)
	safe.setup(ContentDb.towers[0])
	_expect(not safe.apply_damage(25.0, boss), "recruit disables tower hp")
	root.queue_free()


func _check_camera() -> void:
	var rig := OverheadCamera.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	add_child(rig)
	rig.set_bounds(Vector2(-8, -6), Vector2(8, 6))
	rig.pitch_deg = 5.0
	rig.target_distance = 400.0
	rig.global_position = Vector3(80, 4, -40)
	rig._process(0.5)
	_expect(rig.pitch_deg >= rig.min_pitch_deg and rig.min_pitch_deg <= 30.0, "pitch clamp includes 30 degrees")
	_expect(rig.target_distance <= rig.max_distance and rig.max_distance >= 60.0, "zoom reaches 60 m")
	_expect(absf(rig.global_position.x) <= 8.0 and absf(rig.global_position.z) <= 6.0, "pan clamped")
	rig.queue_free()


func _check_scenes_boot() -> void:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await get_tree().process_frame
	var blob := ""
	for button in title.find_children("*", "Button", true, false):
		blob += (button as Button).text
	_expect(blob.find("Sentinel") >= 0 and blob.find("Recruit") >= 0 and blob.find("Deploy") >= 0, "title lists modes")
	title.queue_free()
	var game: Node = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	_expect(game.get_node_or_null("Battlefield/EnemyPath") != null, "game builds the path")
	_expect(game.get_node_or_null("OverheadCamera/Camera3D") != null, "overhead camera exists")
	(game.get_node("WaveSpawner") as WaveSpawner).stop()
	_expect(game.process_mode == Node.PROCESS_MODE_ALWAYS, "match keeps input while paused")
	_expect(game.get_node("WaveSpawner").process_mode == Node.PROCESS_MODE_PAUSABLE, "spawner pauses")
	_expect(game.get_node("Enemies").process_mode == Node.PROCESS_MODE_PAUSABLE, "enemies pause")
	_expect(game.get_node("Towers").process_mode == Node.PROCESS_MODE_PAUSABLE, "towers pause")
	var walker := Enemy.new()
	game.get_node("Enemies").add_child(walker)
	walker.setup(ContentDb.enemies_by_id["shambler"], game.get_node("Battlefield") as Battlefield, 1, false, false, 0.0)
	var held := walker.path_distance
	get_tree().paused = true
	for _i in 4:
		await get_tree().process_frame
	_expect(is_equal_approx(walker.path_distance, held), "paused enemies do not walk")
	get_tree().paused = false
	await get_tree().process_frame
	_expect(walker.path_distance > held, "enemies walk after unpause")
	game.queue_free()
	await get_tree().process_frame


func _blank_tower(tiers: int) -> Dictionary:
	var blanks: Array = []
	for _i in tiers:
		blanks.append({"name": "Tier", "cost": 0})
	return {
		"id": "synthetic",
		"name": "Synthetic",
		"cost": 0,
		"hp": 40,
		"footprint": 1.0,
		"base": {"damage": 1, "range": 3, "reload": 1.0, "role": "attack"},
		"top": blanks.duplicate(true),
		"bottom": blanks.duplicate(true),
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
