class_name Enemy
extends Node3D

signal resolved

var definition: Dictionary = {}
var hp: float = 1.0
var max_hp: float = 1.0
var shield: float = 0.0
var max_shield: float = 0.0
var speed: float = 1.0
var path_distance: float = 0.0
var wave_number: int = 1
var stealth: bool = false
var airborne: bool = false
var no_cash: bool = false
var boss: bool = false
var can_damage_towers: bool = false
var is_dead: bool = false
var resists: Dictionary = {}

var _battlefield: Battlefield
var _length: float = 0.0
var _lateral: float = 0.0
var _stun_left: float = 0.0
var _heal_cd: float = 0.0
var _frenzy: bool = false
var _attack_cd: Dictionary = {}
var _body: MeshInstance3D
var _shield_mesh: MeshInstance3D
var _health: MeshInstance3D


func setup(def: Dictionary, battlefield: Battlefield, wave: int, is_stealth: bool, cashless: bool, start_distance: float) -> void:
	definition = def
	_battlefield = battlefield
	_length = battlefield.path_length()
	wave_number = wave
	boss = bool(def.get("boss", false))
	var multiplier := GameState.scaled_hp_multiplier(wave, boss)
	max_hp = float(def.get("hp", 1.0)) * multiplier
	hp = max_hp
	max_shield = float(def.get("shield", 0.0)) * multiplier
	shield = max_shield
	speed = float(def.get("speed", 1.0)) * GameState.enemy_speed_multiplier()
	airborne = bool(def.get("airborne", false))
	var forced := GameState.stealth_from_wave()
	stealth = is_stealth or (forced > 0 and wave >= forced)
	no_cash = cashless
	can_damage_towers = bool(def.get("can_damage_towers", false))
	resists = def.get("resist", {})
	var spread := float(ContentDb.game.get("path_lateral_offset", 0.6))
	_lateral = randf_range(-spread, spread)
	path_distance = start_distance
	for attack in def.get("attacks", []):
		if attack is Dictionary:
			_attack_cd[str(attack.get("id", ""))] = float(attack.get("interval", 1.0))
	var heal: Variant = def.get("heal", null)
	if heal is Dictionary:
		_heal_cd = float(heal.get("interval", 3.0))
	add_to_group("enemies")
	_build_visual(float(def.get("visual_scale", 1.0)))
	global_position = _sample(path_distance)


func apply_stun(duration: float) -> void:
	if bool(definition.get("stun_immune", false)) or boss:
		return
	_stun_left = maxf(_stun_left, duration)


func receive_hit(amount: float, damage_type: String, resist_ignore: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var resist := float(resists.get(damage_type, 0.0))
	resist *= 1.0 - clampf(resist_ignore, 0.0, 1.0)
	var remaining := amount * (1.0 - clampf(resist, 0.0, 90.0) / 100.0)
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	var health_dealt := 0.0
	if remaining > 0.0 and hp > 0.0:
		health_dealt = minf(hp, remaining)
		hp -= health_dealt
	_update_bars()
	_check_frenzy()
	if hp <= 0.0:
		_finish(true)
	return health_dealt


func advance(delta: float) -> void:
	if is_dead or _battlefield == null:
		return
	if _stun_left > 0.0:
		_stun_left = maxf(_stun_left - delta, 0.0)
		return
	path_distance += speed * delta
	if path_distance >= _length:
		path_distance = _length
		global_position = _sample(_length)
		_finish(false)
		return
	global_position = _sample(path_distance)
	_face_along_path()


func _process(delta: float) -> void:
	advance(delta)
	if is_dead:
		return
	_heal(delta)
	_run_attacks(delta)
	_billboard_health()


func _sample(distance: float) -> Vector3:
	var point := _battlefield.sample_path(distance)
	var ahead := _battlefield.sample_path(minf(distance + 0.5, _length))
	var forward := ahead - point
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
		var side := Vector3(-forward.z, 0.0, forward.x)
		point += side * _lateral
	if airborne:
		point.y += float(ContentDb.game.get("air_height", 4.0))
	return point


func _finish(killed: bool) -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	if killed:
		_on_death_effects()
	else:
		GameState.damage_base(GameState.leak_amount(hp, shield))
	resolved.emit()
	queue_free()


func _on_death_effects() -> void:
	var spawn: Variant = definition.get("on_death_spawn", null)
	if spawn is Dictionary:
		var spawner := get_tree().get_first_node_in_group("wave_spawner") as WaveSpawner
		if spawner != null:
			for _index in int(spawn.get("count", 0)):
				spawner.spawn_enemy(str(spawn.get("enemy", "")), wave_number, stealth, true, path_distance)
	var stun: Variant = definition.get("on_death_stun", null)
	if stun is Dictionary:
		for node in get_tree().get_nodes_in_group("towers"):
			var tower := node as Tower
			if tower == null or tower.is_destroyed:
				continue
			if _xz(global_position, tower.global_position) <= float(stun.get("radius", 0.0)):
				tower.stun(float(stun.get("duration", 0.0)))


func _heal(delta: float) -> void:
	var spec: Variant = definition.get("heal", null)
	if not (spec is Dictionary):
		return
	_heal_cd -= delta
	if _heal_cd > 0.0:
		return
	_heal_cd = float(spec.get("interval", 3.0))
	var radius := float(spec.get("radius", 6.0))
	for node in get_tree().get_nodes_in_group("enemies"):
		var ally := node as Enemy
		if ally == null or ally == self or ally.is_dead:
			continue
		if _xz(global_position, ally.global_position) > radius:
			continue
		var amount := minf(float(spec.get("ratio", 0.08)) * ally.max_hp, float(spec.get("max_per_target", 150.0)))
		ally.hp = minf(ally.max_hp, ally.hp + amount)
		ally._update_bars()


func _check_frenzy() -> void:
	if _frenzy:
		return
	var spec: Variant = definition.get("frenzy", null)
	if not (spec is Dictionary) or max_hp <= 0.0:
		return
	if hp / max_hp > float(spec.get("hp_ratio", 0.3)):
		return
	_frenzy = true
	speed *= 1.0 + float(spec.get("speed_bonus", 0.0))


func _run_attacks(delta: float) -> void:
	var attacks: Variant = definition.get("attacks", [])
	if not (attacks is Array):
		return
	for attack in attacks:
		if not (attack is Dictionary):
			continue
		var id := str(attack.get("id", ""))
		_attack_cd[id] = float(_attack_cd.get(id, 0.0)) - delta
		if float(_attack_cd[id]) > 0.0:
			continue
		var interval := float(attack.get("interval", 1.0))
		if _frenzy and id == "bile_mortar":
			var frenzy: Dictionary = definition.get("frenzy", {})
			interval = float(frenzy.get("bile_interval", interval))
		_attack_cd[id] = interval
		_perform_attack(attack)


func _perform_attack(attack: Dictionary) -> void:
	if not GameState.tower_hp_enabled() and not attack.has("spawn"):
		return
	if attack.has("spawn"):
		var spawner := get_tree().get_first_node_in_group("wave_spawner") as WaveSpawner
		if spawner == null:
			return
		for _index in int(attack.get("count", 0)):
			spawner.spawn_enemy(str(attack.get("spawn", "")), wave_number, stealth, true, path_distance)
		return
	var reach := float(attack.get("range", 0.0))
	if str(attack.get("target", "")) == "all_towers":
		for node in get_tree().get_nodes_in_group("towers"):
			var tower := node as Tower
			if tower == null or tower.is_destroyed:
				continue
			if _xz(global_position, tower.global_position) > reach:
				continue
			_hit_tower(tower, attack)
		return
	var chosen := _pick_tower(str(attack.get("target", "closest")), reach)
	if chosen != null:
		_hit_tower(chosen, attack)


func _hit_tower(tower: Tower, attack: Dictionary) -> void:
	if attack.has("tower_damage"):
		tower.apply_damage(float(attack.get("tower_damage", 0.0)), self)
	if attack.has("stun"):
		tower.stun(float(attack.get("stun", 0.0)))


func _pick_tower(mode: String, reach: float) -> Tower:
	var best: Tower = null
	var best_spent := -1
	var best_index := -1
	var best_distance := reach
	for node in get_tree().get_nodes_in_group("towers"):
		var tower := node as Tower
		if tower == null or tower.is_destroyed:
			continue
		var distance := _xz(global_position, tower.global_position)
		if distance > reach:
			continue
		if mode == "most_expensive":
			if tower.spent > best_spent or (tower.spent == best_spent and tower.place_index >= best_index):
				best = tower
				best_spent = tower.spent
				best_index = tower.place_index
		elif distance <= best_distance:
			best = tower
			best_distance = distance
	return best


func _build_visual(scale_factor: float) -> void:
	var tint := _color(definition.get("tint", [0.45, 0.5, 0.34]))
	_body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32 * scale_factor
	capsule.height = maxf(0.9 * scale_factor, capsule.radius * 2.1)
	_body.mesh = capsule
	_body.position.y = capsule.height * 0.5
	var body_mat := _mat(tint, 0.7)
	if stealth:
		body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		body_mat.albedo_color.a = 0.35
	_body.material_override = body_mat
	add_child(_body)
	_shield_mesh = MeshInstance3D.new()
	var shell := SphereMesh.new()
	shell.radius = 0.55 * scale_factor
	shell.height = shell.radius * 2.0
	_shield_mesh.mesh = shell
	_shield_mesh.position.y = capsule.height * 0.45
	var shield_mat := _mat(Color(0.45, 0.62, 0.9, 0.28), 0.2)
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shield_mesh.material_override = shield_mat
	_shield_mesh.visible = shield > 0.0
	add_child(_shield_mesh)
	_health = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.9 * maxf(scale_factor, 0.6), 0.08, 0.08)
	_health.mesh = bar
	_health.position = Vector3(0, capsule.height + 0.25, 0)
	_health.material_override = _mat(Color(0.75, 0.28, 0.22), 1.0)
	add_child(_health)
	_update_bars()


func _update_bars() -> void:
	if _shield_mesh != null:
		_shield_mesh.visible = shield > 0.05
	if _health == null or max_hp <= 0.0:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_health.scale.x = maxf(ratio, 0.001)
	_health.position.x = -0.45 * (1.0 - ratio)


func _billboard_health() -> void:
	if _health == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_health.look_at(cam.global_position, Vector3.UP)


func _face_along_path() -> void:
	var ahead := _sample(minf(path_distance + 0.45, _length))
	var flat := ahead - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return
	look_at(global_position + flat, Vector3.UP)


func _color(value: Variant) -> Color:
	if value is Array and value.size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]))
	return Color(0.45, 0.5, 0.34)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()
