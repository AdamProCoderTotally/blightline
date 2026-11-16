class_name PlacementController
extends Node
## Free placement. The footprint must sit on the ground, clear the road by
## half the path width plus the footprint, miss blockers, and not overlap
## another tower. Supply Depot also stops at its data limit.

signal build_changed(def: Dictionary)
signal selection_changed(tower: Tower)

const TOWER_SCENE := preload("res://scenes/tower.tscn")

var battlefield: Battlefield
var towers_root: Node3D
var defs: Array = []
var build_index: int = -1
var selected: Tower = null
var _placed: Array[Tower] = []
var _preview: MeshInstance3D
var _range_ring: MeshInstance3D
var _cost_label: Label3D
var _preview_radius: float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_preview()


func configure(tower_defs: Array, field: Battlefield, root: Node3D) -> void:
	defs = tower_defs
	battlefield = field
	towers_root = root
	build_index = -1
	_ensure_preview()
	if _preview.get_parent() != towers_root:
		_preview.reparent(towers_root)
		_range_ring.reparent(towers_root)
		_cost_label.reparent(towers_root)


func current_def() -> Dictionary:
	if build_index < 0 or build_index >= defs.size():
		return {}
	var def: Variant = defs[build_index]
	return def if def is Dictionary else {}


func select_build(index: int) -> void:
	if index < 0 or index >= defs.size():
		build_index = -1
		build_changed.emit({})
		return
	build_index = index
	build_changed.emit(current_def())


func count_of(tower_id: String) -> int:
	var count := 0
	for tower in _placed:
		if is_instance_valid(tower) and not tower.is_destroyed and str(tower.definition.get("id", "")) == tower_id:
			count += 1
	return count


func evaluate(point: Vector3, def: Dictionary) -> Dictionary:
	if def.is_empty():
		return {"ok": false, "reason": ""}
	if GameState.defeated:
		return {"ok": false, "reason": "The pass is already lost."}
	var radius := float(def.get("footprint", def.get("footprint_radius", 1.0)))
	if not battlefield.contains_footprint(point, radius):
		return {"ok": false, "reason": "Outside the buildable ground."}
	if battlefield.hits_blocker(point, radius):
		return {"ok": false, "reason": "Terrain is in the way."}
	var needed := battlefield.path_width * 0.5 + radius + float(ContentDb.game.get("extra_road_clearance", 0.0))
	if battlefield.distance_to_path(point) < needed:
		return {"ok": false, "reason": "Too close to the road."}
	var gap := float(ContentDb.game.get("extra_tower_gap", 0.0))
	for tower in _placed:
		if not is_instance_valid(tower) or tower.is_destroyed:
			continue
		if _xz(point, tower.global_position) < radius + tower.footprint_radius() + gap:
			return {"ok": false, "reason": "Overlaps another tower."}
	var limit: Variant = def.get("limit", null)
	if limit != null and count_of(str(def.get("id", ""))) >= int(limit):
		return {"ok": false, "reason": "Placement limit reached (%d)." % int(limit)}
	if GameState.cash < int(def.get("cost", 0)):
		return {"ok": false, "reason": "Not enough cash."}
	return {"ok": true, "reason": ""}


func try_place(point: Vector3) -> bool:
	var def := current_def()
	var result := evaluate(point, def)
	if not result["ok"]:
		if str(result["reason"]) != "":
			GameState.flash_status(str(result["reason"]))
		return false
	var cost := int(def.get("cost", 0))
	if not GameState.try_spend(cost):
		GameState.flash_status("Not enough cash.")
		return false
	var tower := TOWER_SCENE.instantiate() as Tower
	towers_root.add_child(tower)
	tower.place_index = _placed.size()
	tower.global_position = Vector3(point.x, battlefield.surface_y, point.z)
	tower.setup(def)
	_placed.append(tower)
	if not Input.is_key_pressed(KEY_SHIFT):
		_select(tower)
	return true


func sell_selected() -> void:
	if selected == null or not is_instance_valid(selected):
		return
	GameState.add_cash(selected.refund_amount())
	_placed.erase(selected)
	selected.queue_free()
	_select(null)


func tower_at(point: Vector3) -> Tower:
	var closest: Tower = null
	var closest_distance := INF
	for tower in _placed:
		if not is_instance_valid(tower) or tower.is_destroyed:
			continue
		var distance := _xz(point, tower.global_position)
		if distance <= tower.footprint_radius() and distance < closest_distance:
			closest = tower
			closest_distance = distance
	return closest


func _process(_delta: float) -> void:
	if battlefield == null or _preview == null:
		return
	var point = _ground_point(get_viewport().get_mouse_position())
	var def := current_def()
	if point == null or def.is_empty() or tower_at(point) != null:
		_preview.visible = false
		_range_ring.visible = false
		_cost_label.visible = false
		return
	var world: Vector3 = point
	var radius := float(def.get("footprint", 1.0))
	var result := evaluate(world, def)
	_preview.visible = true
	_range_ring.visible = float(def.get("base", {}).get("range", def.get("range", 0.0))) > 0.0
	_cost_label.visible = true
	var lifted := Vector3(world.x, battlefield.surface_y + 0.08, world.z)
	_preview.global_position = lifted
	_range_ring.global_position = lifted
	_cost_label.global_position = lifted + Vector3(0, 0.8, 0)
	_cost_label.text = "$%d" % int(def.get("cost", 0))
	if not is_equal_approx(radius, _preview_radius):
		_preview_radius = radius
		var mesh := _preview.mesh as CylinderMesh
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		_rebuild_ring(_preview_range(def))
	var tint := Color(0.35, 0.85, 0.45, 0.45) if result["ok"] else Color(0.9, 0.28, 0.22, 0.45)
	(_preview.material_override as StandardMaterial3D).albedo_color = tint
	_cost_label.modulate = Color(0.85, 1, 0.85) if result["ok"] else Color(1, 0.7, 0.65)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_key(event as InputEventKey)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		var point = _ground_point(mouse.position)
		if point == null:
			return
		var hovered := tower_at(point)
		if hovered != null:
			_select(hovered)
			return
		if build_index >= 0:
			try_place(point)


func _key(key: InputEventKey) -> void:
	var index := key.keycode - KEY_1
	if index >= 0 and index < mini(defs.size(), 6):
		select_build(index)
		return
	if key.keycode == KEY_Q:
		select_build(-1)
		_select(null)
		return
	if key.keycode == KEY_ESCAPE:
		if selected != null or build_index >= 0:
			select_build(-1)
			_select(null)
		else:
			get_tree().paused = not get_tree().paused
		return
	if key.keycode == KEY_BACKSPACE or key.keycode == KEY_DELETE:
		sell_selected()
		return
	if selected == null or not is_instance_valid(selected):
		return
	if key.keycode == KEY_E:
		if key.ctrl_pressed:
			selected.max_upgrade(0)
		elif not selected.upgrade(0):
			GameState.flash_status(_upgrade_block_reason(selected, 0))
	elif key.keycode == KEY_R:
		if key.ctrl_pressed:
			selected.max_upgrade(1)
		elif not selected.upgrade(1):
			GameState.flash_status(_upgrade_block_reason(selected, 1))
	elif key.keycode == KEY_C:
		selected.cycle_targeting(-1)
	elif key.keycode == KEY_V:
		selected.cycle_targeting(1)
	elif key.keycode == KEY_G:
		if not selected.use_ability():
			GameState.flash_status("No ability ready.")


func _upgrade_block_reason(tower: Tower, path_index: int) -> String:
	if not tower.can_upgrade(path_index):
		if tower.rank(path_index) >= tower.tier_count(path_index):
			return "MAX"
		return "Path capped at %d." % GameState.upgrade_other_cap_tier()
	return "Not enough cash."


func _preview_range(def: Dictionary) -> float:
	var base: Dictionary = def.get("base", {})
	return float(base.get("range", 0.0))


func _select(tower: Tower) -> void:
	selected = tower if tower != null and is_instance_valid(tower) else null
	selection_changed.emit(selected)


func _ground_point(screen: Vector2) -> Variant:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var origin := cam.project_ray_origin(screen)
	var direction := cam.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return null
	var t := -origin.y / direction.y
	if t < 0.0:
		return null
	return origin + direction * t


func _ensure_preview() -> void:
	if _preview != null:
		return
	_preview = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.08
	_preview.mesh = mesh
	_preview.material_override = _ghost(Color(0.4, 0.9, 0.45, 0.4))
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_preview.visible = false
	add_child(_preview)
	_range_ring = MeshInstance3D.new()
	_range_ring.material_override = _ghost(Color(0.75, 0.88, 0.78, 0.9))
	_range_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_range_ring.visible = false
	add_child(_range_ring)
	_cost_label = Label3D.new()
	_cost_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cost_label.font_size = 28
	_cost_label.visible = false
	add_child(_cost_label)


func _rebuild_ring(radius: float) -> void:
	if radius <= 0.0:
		_range_ring.visible = false
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for step in 65:
		var angle := TAU * float(step) / 64.0
		mesh.surface_add_vertex(Vector3(cos(angle) * radius, 0.05, sin(angle) * radius))
	mesh.surface_end()
	_range_ring.mesh = mesh


func _ghost(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()
