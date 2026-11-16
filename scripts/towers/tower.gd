class_name Tower
extends Node3D
## One scene for every tower. Base stats and both upgrade paths come from
## towers.json. Tiers are bought in order. Once one path reaches the trigger
## tier from game_config (3), the other path stops at the cap (2).

signal changed

const TARGETS: Array[String] = ["first", "last", "strongest", "weakest", "closest"]

var definition: Dictionary = {}
var stats: Dictionary = {}
var flags: Dictionary = {}
var hp: float = 1.0
var max_hp: float = 1.0
var base_hp: float = 1.0
var spent: int = 0
var placed_wave: int = 0
var place_index: int = 0
var is_destroyed: bool = false
var targeting: String = "first"

var _rank_top: int = 0
var _rank_bottom: int = 0
var _cooldown: float = 0.0
var _burst_left: int = 0
var _burst_wait: float = 0.0
var _stun_left: float = 0.0
var _shot_time: float = 0.0
var _ability_cd: float = 0.0
var _overcharge_left: float = 0.0
var _head: Node3D
var _shot: MeshInstance3D


func setup(def: Dictionary) -> void:
	definition = def
	base_hp = float(def.get("hp", 1.0))
	spent = int(def.get("cost", 0))
	placed_wave = GameState.wave_number
	_rank_top = 0
	_rank_bottom = 0
	add_to_group("towers")
	_recompute()
	hp = max_hp
	_build_visual()


func display_name() -> String:
	return str(definition.get("name", definition.get("id", "Tower")))


func path_count() -> int:
	var count := 0
	if definition.has("top"):
		count += 1
	if definition.has("bottom"):
		count += 1
	return count


func tier_count(path_index: int) -> int:
	return _tiers(path_index).size()


func rank(path_index: int) -> int:
	return _rank_top if path_index == 0 else _rank_bottom


func can_upgrade(path_index: int) -> bool:
	if rank(path_index) >= tier_count(path_index):
		return false
	var other := rank(1 - path_index) if path_count() > 1 else 0
	if other >= GameState.upgrade_trigger_tier() and rank(path_index) >= GameState.upgrade_other_cap_tier():
		return false
	return true


func next_tier(path_index: int) -> Dictionary:
	var tiers := _tiers(path_index)
	var index := rank(path_index)
	if index < 0 or index >= tiers.size():
		return {}
	var tier: Variant = tiers[index]
	return tier if tier is Dictionary else {}


func upgrade(path_index: int) -> bool:
	if not can_upgrade(path_index):
		return false
	var tier := next_tier(path_index)
	var cost := int(tier.get("cost", 0))
	if cost > 0 and not GameState.try_spend(cost):
		return false
	spent += cost
	if path_index == 0:
		_rank_top += 1
	else:
		_rank_bottom += 1
	_recompute()
	changed.emit()
	return true


func max_upgrade(path_index: int) -> void:
	while upgrade(path_index):
		pass


func cycle_targeting(step: int) -> void:
	if role() == "economy":
		return
	var index := TARGETS.find(targeting)
	if index < 0:
		index = 0
	var count := TARGETS.size()
	targeting = TARGETS[posmod(index + step, count)]
	changed.emit()


func use_ability() -> bool:
	var ability: Variant = stats.get("ability", null)
	if not (ability is Dictionary) or _ability_cd > 0.0 or _stun_left > 0.0:
		return false
	var spec: Dictionary = ability
	var id := str(spec.get("id", ""))
	if id == "frag_toss":
		var target := _pick_target()
		if target == null:
			return false
		var dtype := str(spec.get("damage_type", "blast"))
		var amount := float(spec.get("damage", 0.0))
		var radius := float(spec.get("splash", 0.0))
		for node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.is_dead:
				continue
			if _xz(enemy.global_position, target.global_position) <= radius or enemy == target:
				_deal(enemy, amount, dtype)
		_ability_cd = float(spec.get("cooldown", 1.0))
		return true
	if id == "overcharge":
		_overcharge_left = float(spec.get("duration", 0.0))
		_ability_cd = float(stats.get("overcharge_cooldown", spec.get("cooldown", 1.0)))
		return true
	return false


func footprint_radius() -> float:
	return float(stats.get("footprint", definition.get("footprint", 1.0)))


func refund_amount() -> int:
	return GameState.refund_for(spent)


func role() -> String:
	return str(stats.get("role", definition.get("base", {}).get("role", "attack")))


func level_label() -> String:
	return "%d-%d" % [_rank_top, _rank_bottom]


func apply_damage(amount: float, source: Node) -> bool:
	if is_destroyed or amount <= 0.0 or not GameState.tower_hp_enabled():
		return false
	if not (source is Enemy) or not (source as Enemy).can_damage_towers:
		return false
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		is_destroyed = true
		remove_from_group("towers")
		queue_free()
	changed.emit()
	return true


func stun(duration: float) -> void:
	if not GameState.tower_hp_enabled():
		return
	_stun_left = maxf(_stun_left, duration)


func regen(extra_ratio: float = 0.0) -> void:
	if is_destroyed or not GameState.tower_hp_enabled():
		return
	var ratio := float(ContentDb.game.get("tower_regen_ratio", 0.1)) + extra_ratio
	hp = minf(max_hp, hp + max_hp * ratio)


func _process(delta: float) -> void:
	if is_destroyed:
		return
	if _shot_time > 0.0:
		_shot_time -= delta
		if _shot_time <= 0.0 and _shot != null:
			_shot.visible = false
	if _ability_cd > 0.0:
		_ability_cd -= delta
	if _overcharge_left > 0.0:
		_overcharge_left -= delta
	if _stun_left > 0.0:
		_stun_left -= delta
		return
	if role() == "economy" or float(stats.get("damage", 0.0)) <= 0.0:
		return
	if str(stats.get("fire_mode", "")) == "auto":
		_cooldown -= delta
		if _cooldown > 0.0:
			return
		var auto_target := _pick_target()
		if auto_target == null:
			return
		_cooldown = float(stats.get("auto_interval", 0.15))
		_emit_shot(auto_target)
		return
	if _burst_left > 0:
		_burst_wait -= delta
		if _burst_wait > 0.0:
			return
		var burst_target := _pick_target()
		if burst_target == null:
			_burst_left = 0
			_cooldown = _reload_time()
			return
		_emit_shot(burst_target)
		_burst_left -= 1
		if _burst_left > 0:
			_burst_wait = float(stats.get("burst_gap", 0.12))
		else:
			_cooldown = _reload_time()
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _pick_target()
	if target == null:
		return
	var rockets := maxi(int(stats.get("rockets", 1)), 1)
	for _rocket in rockets:
		if target == null or not is_instance_valid(target) or target.is_dead:
			break
		_emit_shot(target)
	var burst := maxi(int(stats.get("burst", 1)), 1) - 1
	_burst_left = burst
	if _burst_left > 0:
		_burst_wait = float(stats.get("burst_gap", 0.12))
	else:
		_cooldown = _reload_time()


func _emit_shot(target: Enemy) -> void:
	var dtype := str(stats.get("damage_type", "kinetic"))
	var amount := float(stats.get("damage", 0.0))
	var primary := amount * float(stats.get("primary_multiplier", 1.0))
	_deal(target, primary, dtype)
	var stun_for := float(stats.get("stun_non_boss", 0.0))
	if stun_for > 0.0 and is_instance_valid(target) and not target.is_dead and not target.boss:
		target.apply_stun(stun_for)
	var splash_radius := float(stats.get("splash", 0.0))
	if splash_radius > 0.0 and is_instance_valid(target):
		for node in get_tree().get_nodes_in_group("enemies"):
			var other := node as Enemy
			if other == null or other == target or other.is_dead:
				continue
			if _xz(other.global_position, target.global_position) <= splash_radius:
				_deal(other, amount, dtype)
	var pierce := int(stats.get("pierce", 1))
	if pierce > 1 and is_instance_valid(target):
		var ahead: Array[Enemy] = []
		for node in get_tree().get_nodes_in_group("enemies"):
			var other := node as Enemy
			if other == null or other == target or other.is_dead:
				continue
			if other.path_distance <= target.path_distance:
				continue
			if _xz(global_position, other.global_position) <= float(stats.get("range", 0.0)):
				ahead.append(other)
		ahead.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.path_distance < b.path_distance)
		for index in mini(pierce - 1, ahead.size()):
			_deal(ahead[index], amount, dtype)
	var jumps := maxi(int(round(float(stats.get("chains", 0)))), 0)
	if jumps > 0 and is_instance_valid(target):
		_chain_from(target, amount, jumps)
	if is_instance_valid(target):
		_aim(target.global_position)
		_show_shot(target.global_position)


func _chain_from(origin: Enemy, amount: float, jumps: int) -> void:
	var dtype := str(stats.get("damage_type", "arc"))
	var falloff := float(stats.get("falloff", 0.7))
	var reach := float(stats.get("chain_range", 4.0))
	var damage := amount * falloff
	var previous := origin
	var seen: Array[Enemy] = [origin]
	for _jump in jumps:
		var nxt: Enemy = null
		var best := reach
		for node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.is_dead or enemy in seen:
				continue
			var distance := _xz(enemy.global_position, previous.global_position)
			if distance <= best:
				best = distance
				nxt = enemy
		if nxt == null:
			return
		_deal(nxt, damage, dtype)
		seen.append(nxt)
		previous = nxt
		damage *= falloff


func _deal(enemy: Enemy, amount: float, damage_type: String) -> void:
	if enemy == null or enemy.is_dead or amount <= 0.0:
		return
	var paid := enemy.receive_hit(amount, damage_type, _resist_ignore(damage_type))
	if is_instance_valid(enemy) and not enemy.no_cash:
		GameState.grant_damage_income(paid)


func _resist_ignore(damage_type: String) -> float:
	if bool(flags.get("ignore_%s" % damage_type, false)):
		return 1.0
	return clampf(float(stats.get("%s_resist_ignore" % damage_type, 0.0)), 0.0, 1.0)


func _pick_target() -> Enemy:
	var best: Enemy = null
	var reach := float(stats.get("range", 0.0))
	var best_score := 0.0
	var have := false
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead or not _can_target(enemy):
			continue
		var distance := _xz(global_position, enemy.global_position)
		if distance > reach:
			continue
		var score := _target_score(enemy, distance)
		if not have or _score_better(score, best_score):
			best = enemy
			best_score = score
			have = true
	return best


func _can_target(enemy: Enemy) -> bool:
	if enemy.airborne and not bool(stats.get("air", false)):
		return false
	if enemy.stealth and not bool(stats.get("stealth", false)):
		return false
	return true


func _target_score(enemy: Enemy, distance: float) -> float:
	match targeting:
		"last":
			return -enemy.path_distance
		"strongest":
			return enemy.hp + enemy.shield
		"weakest":
			return -(enemy.hp + enemy.shield)
		"closest":
			return -distance
		_:
			return enemy.path_distance


func _score_better(score: float, best: float) -> bool:
	return score > best


func _reload_time() -> float:
	var reload := maxf(float(stats.get("reload", 1.0)), 0.05)
	if _overcharge_left > 0.0:
		var ability: Variant = stats.get("ability", {})
		var factor := 0.5
		if ability is Dictionary:
			factor = float(ability.get("reload_factor", 0.5))
		reload *= factor
	return reload


func _tiers(path_index: int) -> Array:
	var key := "top" if path_index == 0 else "bottom"
	var value: Variant = definition.get(key, [])
	return value if value is Array else []


func _recompute() -> void:
	var base: Dictionary = definition.get("base", {})
	stats = base.duplicate(true)
	stats["footprint"] = float(definition.get("footprint", 1.0))
	flags.clear()
	_apply_ranks(0, _rank_top)
	_apply_ranks(1, _rank_bottom)
	var per := float(ContentDb.game.get("tower_hp_per_tier_ratio", 0.25))
	var previous := max_hp
	max_hp = base_hp * (1.0 + per * float(_rank_top + _rank_bottom))
	if previous > 0.0 and max_hp > previous:
		hp += max_hp - previous
	if hp > max_hp:
		hp = max_hp


func _apply_ranks(path_index: int, count: int) -> void:
	var tiers := _tiers(path_index)
	for index in mini(count, tiers.size()):
		var tier: Dictionary = tiers[index]
		if tier.has("delta"):
			for key in tier["delta"]:
				var delta: Variant = tier["delta"][key]
				if typeof(delta) == TYPE_FLOAT or typeof(delta) == TYPE_INT:
					stats[key] = float(stats.get(key, 0.0)) + float(delta)
				else:
					stats[key] = delta
		if tier.has("set"):
			for key in tier["set"]:
				stats[key] = tier["set"][key]
		if tier.has("flags"):
			for flag in tier["flags"]:
				flags[str(flag)] = true
				if str(flag) == "stealth":
					stats["stealth"] = true
				elif str(flag) == "air":
					stats["air"] = true
		if tier.has("ability"):
			stats["ability"] = tier["ability"]


func _build_visual() -> void:
	var tint := _tint_color()
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = footprint_radius() * 0.72
	base_mesh.bottom_radius = footprint_radius() * 0.9
	base_mesh.height = 0.55
	base.mesh = base_mesh
	base.position.y = 0.28
	base.material_override = _mat(tint.darkened(0.25), 0.8)
	add_child(base)
	_head = MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.35, maxf(footprint_radius(), 0.8))
	_head.mesh = head_mesh
	_head.position.y = 0.75
	_head.material_override = _mat(tint, 0.55)
	add_child(_head)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0, -head_mesh.size.z * 0.55)
	_head.add_child(muzzle)
	_shot = MeshInstance3D.new()
	var shot_mesh := BoxMesh.new()
	shot_mesh.size = Vector3.ONE
	_shot.mesh = shot_mesh
	_shot.visible = false
	_shot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shot_mat := StandardMaterial3D.new()
	shot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shot_mat.albedo_color = Color(1, 0.92, 0.65)
	shot_mat.emission_enabled = true
	shot_mat.emission = Color(1, 0.86, 0.45)
	_shot.material_override = shot_mat
	add_child(_shot)


func _aim(target: Vector3) -> void:
	if _head == null:
		return
	var flat := target - _head.global_position
	flat.y = 0.0
	if flat.length_squared() < 0.001:
		return
	_head.look_at(_head.global_position + flat, Vector3.UP)


func _show_shot(target: Vector3) -> void:
	if _shot == null or _head == null:
		return
	var muzzle := _head.get_node_or_null("Muzzle") as Node3D
	var from := muzzle.global_position if muzzle != null else _head.global_position
	var length := from.distance_to(target)
	_shot.visible = true
	_shot.look_at_from_position((from + target) * 0.5, target, Vector3.UP)
	_shot.scale = Vector3(0.05, 0.05, maxf(length, 0.05))
	_shot_time = 0.06


func _tint_color() -> Color:
	var tint: Variant = definition.get("tint", [0.5, 0.5, 0.4])
	if tint is Array and tint.size() >= 3:
		return Color(float(tint[0]), float(tint[1]), float(tint[2]))
	return Color(0.5, 0.5, 0.4)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()
