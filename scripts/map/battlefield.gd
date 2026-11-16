class_name Battlefield
extends Node3D
## Builds Cinder Pass (or whichever map is in data) from boxes and a path curve.
## Placement is free on the ground. The road is a corridor around the path,
## not a set of grid tiles.

var map: Dictionary = {}
var surface_y: float = 0.1
var path_width: float = 3.6
var ground_min := Vector2(-1, -1)
var ground_max := Vector2(1, 1)
var enemy_path: Path3D
var _points: Array[Vector3] = []
var _blockers: Array[Rect2] = []


func build(map_data: Dictionary) -> void:
	map = map_data
	_clear_generated()
	surface_y = float(map.get("surface_y", 0.1))
	var ground: Dictionary = map.get("ground", {})
	var gmin: Array = ground.get("min", [-10, -10])
	var gmax: Array = ground.get("max", [10, 10])
	ground_min = Vector2(float(gmin[0]), float(gmin[1]))
	ground_max = Vector2(float(gmax[0]), float(gmax[1]))
	var palette: Dictionary = map.get("palette", {})
	_add_floor(palette)
	_build_path(palette)
	_build_blockers()
	_build_scenery()
	_add_marker(_points[0] if not _points.is_empty() else Vector3.ZERO, palette.get("spawn", [0.4, 0.6, 0.5]), str(map.get("spawn_label", "Spawn")))
	_add_marker(_points[-1] if not _points.is_empty() else Vector3.ZERO, palette.get("core", [0.6, 0.4, 0.3]), str(map.get("core_label", "Core")))


func path_length() -> float:
	if enemy_path == null or enemy_path.curve == null:
		return 0.0
	return enemy_path.curve.get_baked_length()


func sample_path(distance: float) -> Vector3:
	var curve := enemy_path.curve
	var length := curve.get_baked_length()
	var sampled: Vector3 = enemy_path.global_transform * curve.sample_baked(clampf(distance, 0.0, length))
	sampled.y = surface_y
	return sampled


func distance_to_path(point: Vector3) -> float:
	if _points.size() < 2:
		return INF
	var best := INF
	for index in _points.size() - 1:
		best = minf(best, _distance_to_segment(point, _points[index], _points[index + 1]))
	return best


func contains_footprint(point: Vector3, radius: float) -> bool:
	return (
		point.x - radius >= ground_min.x
		and point.x + radius <= ground_max.x
		and point.z - radius >= ground_min.y
		and point.z + radius <= ground_max.y
	)


func hits_blocker(point: Vector3, radius: float) -> bool:
	var flat := Vector2(point.x, point.z)
	for blocker in _blockers:
		var grown := blocker.grow(radius)
		if grown.has_point(flat):
			return true
	return false


func focus_bounds() -> Rect2:
	return Rect2(ground_min, ground_max - ground_min)


func _build_path(palette: Dictionary) -> void:
	var path_data: Dictionary = map.get("path", {})
	path_width = float(path_data.get("width", 3.6))
	_points.clear()
	enemy_path = Path3D.new()
	enemy_path.name = "EnemyPath"
	var curve := Curve3D.new()
	curve.bake_interval = 0.1
	for raw in path_data.get("points", []):
		var point := Vector3(float(raw[0]), 0.0, float(raw[2] if raw.size() > 2 else raw[1]))
		_points.append(point)
		curve.add_point(point)
	enemy_path.curve = curve
	_add_generated(enemy_path)
	var road_color := _color(palette.get("road", [0.25, 0.23, 0.2]))
	for index in _points.size() - 1:
		var a := _points[index]
		var b := _points[index + 1]
		var flat := Vector2(b.x - a.x, b.z - a.z)
		var length := flat.length()
		if length < 0.001:
			continue
		var mesh := BoxMesh.new()
		mesh.size = Vector3(path_width, 0.08, length)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.position = (a + b) * 0.5
		visual.position.y = 0.04
		visual.rotation.y = atan2(flat.x, flat.y)
		visual.material_override = _material(road_color, 0.9)
		_add_generated(visual)


func _build_blockers() -> void:
	_blockers.clear()
	for blocker in map.get("blockers", []):
		_add_prop(blocker, true)


func _build_scenery() -> void:
	for piece in map.get("scenery", []):
		_add_prop(piece, false)


func _add_prop(prop: Variant, blocks: bool) -> void:
	if not (prop is Dictionary):
		return
	var center: Array = prop.get("center", [0, 0, 0])
	var size: Array = prop.get("size", [1, 1, 1])
	var extents := Vector3(float(size[0]), float(size[1]), float(size[2]))
	var origin := Vector3(float(center[0]), float(center[1]), float(center[2]))
	var mesh := BoxMesh.new()
	mesh.size = extents
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = origin
	visual.material_override = _material(_color(prop.get("tint", [0.45, 0.42, 0.38])), 0.92)
	_add_generated(visual)
	if blocks:
		_blockers.append(Rect2(
			Vector2(origin.x - extents.x * 0.5, origin.z - extents.z * 0.5),
			Vector2(extents.x, extents.z)
		))


func _add_floor(palette: Dictionary) -> void:
	var size := ground_max - ground_min
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.4, size.y)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = Vector3((ground_min.x + ground_max.x) * 0.5, -0.2, (ground_min.y + ground_max.y) * 0.5)
	visual.material_override = _material(_color(palette.get("floor", [0.34, 0.33, 0.3])), 0.95)
	_add_generated(visual)


func _add_marker(point: Vector3, tint: Variant, text: String) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.35
	mesh.height = 1.4
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = Vector3(point.x, surface_y + 0.7, point.z)
	visual.material_override = _material(_color(tint), 0.7)
	_add_generated(visual)
	var label := Label3D.new()
	label.text = text
	label.font_size = 42
	label.position = visual.position + Vector3(0, 1.15, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = _color(tint).lightened(0.35)
	_add_generated(label)


func _distance_to_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
	var ap := Vector2(point.x - a.x, point.z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var denom := ab.length_squared()
	var t := 0.0 if denom < 0.000001 else clampf(ap.dot(ab) / denom, 0.0, 1.0)
	var closest := Vector2(a.x, a.z) + ab * t
	return closest.distance_to(Vector2(point.x, point.z))


func _add_generated(node: Node) -> void:
	node.add_to_group("generated_map")
	add_child(node)


func _clear_generated() -> void:
	for node in get_tree().get_nodes_in_group("generated_map"):
		if node.get_parent() == self:
			node.queue_free()


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _color(value: Variant) -> Color:
	if value is Array and value.size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]))
	return Color(0.5, 0.5, 0.5)
