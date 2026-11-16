class_name WaveSpawner
extends Node

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

var battlefield: Battlefield
var enemies_root: Node3D
var skip_requested: bool = false
var spawn_finished: bool = false

var _alive: int = 0
var _stop: bool = false
var _spawn_token: int = 0
var _advance: bool = false
var _clock: float = 0.0
var _clock_limit: float = -1.0
var _timing: bool = false


func _ready() -> void:
	add_to_group("wave_spawner")


func configure(field: Battlefield, root: Node3D) -> void:
	battlefield = field
	enemies_root = root


func begin() -> void:
	_stop = false
	_run()


func stop() -> void:
	_stop = true
	_spawn_token += 1


func request_skip() -> void:
	if spawn_finished and not _stop:
		skip_requested = true


func spawn_enemy(enemy_id: String, wave_number: int, stealth: bool, no_cash: bool, start_distance: float) -> void:
	var def: Variant = ContentDb.enemies_by_id.get(enemy_id, {})
	if not (def is Dictionary) or (def as Dictionary).is_empty():
		push_error("Unknown enemy '%s'." % enemy_id)
		return
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemies_root.add_child(enemy)
	enemy.setup(def, battlefield, wave_number, stealth, no_cash, start_distance)
	_alive += 1
	enemy.resolved.connect(_on_resolved)


func _process(delta: float) -> void:
	if not _timing:
		return
	GameState.wave_time_left = -1.0 if _clock_limit < 0.0 else maxf(_clock_limit - _clock, 0.0)
	if _clock_limit >= 0.0:
		_clock += delta
		if _clock >= _clock_limit:
			_advance = true
	if skip_requested and spawn_finished:
		skip_requested = false
		_advance = true


func _run() -> void:
	var prep := float(ContentDb.game.get("prep_seconds", 20.0))
	GameState.set_wave(0, GameState.wave_total)
	GameState.wave_time_left = prep
	GameState.set_status("Prep. Place off the road before the first wave.")
	if prep > 0.0:
		await get_tree().create_timer(prep).timeout
	if not _running():
		return
	var plan := ContentDb.build_wave_plan(GameState.wave_total)
	for index in plan.size():
		if not _running():
			return
		var wave: Dictionary = plan[index]
		var wave_number := index + 1
		var last := index == plan.size() - 1
		_start_wave(wave, wave_number, last)
		if last or _clock_limit < 0.0:
			while _alive > 0 and _running():
				await get_tree().process_frame
			if not _running():
				return
			_timing = false
			_pay_depots(wave_number)
			_regen_towers()
			GameState.mark_victory()
			return
		while not _advance and _running():
			await get_tree().process_frame
		if not _running():
			return
		_timing = false
		_pay_depots(wave_number)
		_spawn_token += 1


func _start_wave(wave: Dictionary, wave_number: int, last: bool) -> void:
	_advance = false
	skip_requested = false
	spawn_finished = false
	_spawn_token += 1
	_clock = 0.0
	var timer: Variant = wave.get("timer", null)
	_clock_limit = -1.0 if timer == null else float(timer)
	_timing = not last and _clock_limit >= 0.0
	if last or _clock_limit < 0.0:
		_timing = false
		GameState.wave_time_left = -1.0
	GameState.set_wave(wave_number, GameState.wave_total)
	GameState.grant_wave_bonus(wave_number)
	_regen_towers()
	var radio := str(wave.get("radio", ""))
	GameState.set_status(radio if radio != "" else "Wave %d is on the road." % wave_number)
	_spawn_wave(wave, wave_number, _spawn_token)


func _spawn_wave(wave: Dictionary, wave_number: int, token: int) -> void:
	var gap := float(ContentDb.game.get("group_gap", 2.0))
	var groups: Array = wave.get("groups", [])
	for group_index in groups.size():
		var group: Dictionary = groups[group_index]
		var count := int(group.get("count", 1))
		var spacing := float(group.get("spacing", 0.5))
		var enemy_id := str(group.get("enemy", ""))
		var stealth := bool(group.get("stealth", false))
		for _n in count:
			if token != _spawn_token or not _running():
				return
			spawn_enemy(enemy_id, wave_number, stealth, false, 0.0)
			if spacing > 0.0:
				await get_tree().create_timer(spacing).timeout
		if group_index < groups.size() - 1 and gap > 0.0:
			await get_tree().create_timer(gap).timeout
	if token == _spawn_token:
		spawn_finished = true


func _pay_depots(ending_wave: int) -> void:
	for node in get_tree().get_nodes_in_group("towers"):
		var tower := node as Tower
		if tower == null or tower.is_destroyed or tower.role() != "economy":
			continue
		if tower.placed_wave >= ending_wave:
			continue
		GameState.add_cash_amount(float(tower.stats.get("payout", 0.0)) * GameState.income_mult())
		var heal := int(round(float(tower.stats.get("base_heal", 0.0))))
		if heal > 0:
			GameState.restore_base(heal)
		if bool(tower.flags.get("repair_bay", false)):
			var radius := float(tower.stats.get("repair_radius", 0.0))
			var ratio := float(tower.stats.get("repair_ratio", 0.0))
			for other_node in get_tree().get_nodes_in_group("towers"):
				var other := other_node as Tower
				if other == null or other.is_destroyed:
					continue
				var delta := other.global_position - tower.global_position
				delta.y = 0.0
				if delta.length() <= radius:
					other.regen(ratio)


func _regen_towers() -> void:
	for node in get_tree().get_nodes_in_group("towers"):
		var tower := node as Tower
		if tower != null and not tower.is_destroyed:
			tower.regen(0.0)


func _on_resolved() -> void:
	_alive = maxi(_alive - 1, 0)


func _running() -> bool:
	return is_inside_tree() and not _stop and not GameState.defeated
