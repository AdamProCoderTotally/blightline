extends Node
## Loads res://data/*.json. Tuning lives in those files; this script only
## reads fields and checks that a mode does not ask for more waves than exist.

var game: Dictionary = {}
var difficulties: Dictionary = {}
var towers: Array = []
var enemies_by_id: Dictionary = {}
var waves: Dictionary = {}
var map: Dictionary = {}
var load_errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	game = _as_dict(_read("res://data/game_config.json"))
	difficulties = _as_dict(_read("res://data/difficulties.json"))
	var tower_doc := _as_dict(_read("res://data/towers.json"))
	towers = tower_doc.get("towers", [])
	var enemy_doc := _as_dict(_read("res://data/enemies.json"))
	for enemy in enemy_doc.get("enemies", []):
		if enemy is Dictionary and enemy.has("id"):
			enemies_by_id[str(enemy["id"])] = enemy
	waves = _as_dict(_read("res://data/waves.json"))
	map = _as_dict(_read("res://data/map_cinder_pass.json"))
	_validate_wave_counts()
	for message in load_errors:
		push_error(message)


func default_mode() -> Dictionary:
	return mode_by_id(str(difficulties.get("default", game.get("default_difficulty", ""))))


func mode_by_id(mode_id: String) -> Dictionary:
	for mode in difficulties.get("modes", []):
		if mode is Dictionary and str(mode.get("id", "")) == mode_id:
			return mode
	var modes: Array = difficulties.get("modes", [])
	if modes.is_empty() or not (modes[0] is Dictionary):
		return {}
	return modes[0]


func regular_waves() -> Array:
	var value: Variant = waves.get("waves", [])
	return value if value is Array else []


func boss_wave() -> Dictionary:
	return _as_dict(waves.get("boss_wave", {}))


func build_wave_plan(wave_count: int) -> Array:
	var regular := regular_waves()
	var boss := boss_wave()
	var plan: Array = []
	var regular_needed := maxi(wave_count - 1, 0)
	var problem := wave_count_error(wave_count)
	if problem != "":
		push_error(problem)
	for index in mini(regular_needed, regular.size()):
		plan.append(regular[index])
	if wave_count > 0 and not boss.is_empty():
		plan.append(boss)
	return plan


func wave_count_error(wave_count: int) -> String:
	var needed := wave_count - 1
	var have := regular_waves().size()
	if needed > have:
		return "wave_count %d needs %d regular waves; only %d are defined." % [wave_count, needed, have]
	return ""


func _validate_wave_counts() -> void:
	for mode in difficulties.get("modes", []):
		if not (mode is Dictionary):
			continue
		var problem := wave_count_error(int(mode.get("wave_count", 1)))
		if problem != "":
			load_errors.append("%s: %s" % [str(mode.get("id", "mode")), problem])


func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing data file %s" % path)
		return {}
	var parser := JSON.new()
	var err := parser.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		load_errors.append("%s: %s" % [path, parser.get_error_message()])
		return {}
	return parser.data


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
