extends Node3D

@onready var sun: DirectionalLight3D = $Sun
@onready var fill: DirectionalLight3D = $Fill
@onready var camera_rig: OverheadCamera = $OverheadCamera
@onready var battlefield: Battlefield = $Battlefield
@onready var towers: Node3D = $Towers
@onready var enemies: Node3D = $Enemies
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var placement: PlacementController = $Placement


func _ready() -> void:
	# Match-level keys (P, Home, F, Space) have to arrive while the tree is
	# paused. Mark the simulation nodes pausable explicitly so they do not
	# inherit this and keep walking the wave.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sim in [battlefield, towers, enemies, spawner]:
		sim.process_mode = Node.PROCESS_MODE_PAUSABLE
	_setup_light()
	if GameState.mode.is_empty():
		GameState.apply_mode("")
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(str(ContentDb.game.get("title", "BLIGHTLINE")))
	if not ContentDb.load_errors.is_empty():
		GameState.set_status("Data failed to load. " + " ".join(ContentDb.load_errors))
		return
	_apply_camera_config()
	battlefield.build(ContentDb.map)
	var bounds := battlefield.focus_bounds()
	var padding := float(ContentDb.game.get("camera", {}).get("bounds_padding", 5.0))
	camera_rig.global_position = Vector3(bounds.get_center().x, 0.0, bounds.get_center().y)
	camera_rig.set_bounds(bounds.position - Vector2(padding, padding), bounds.end + Vector2(padding, padding))
	camera_rig.capture_home()
	placement.configure(ContentDb.towers, battlefield, towers)
	spawner.configure(battlefield, enemies)
	spawner.begin()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if key.keycode == KEY_HOME:
		camera_rig.reset_home()
	elif key.keycode == KEY_F:
		GameState.cycle_speed()
	elif key.keycode == KEY_P:
		get_tree().paused = not get_tree().paused
	elif key.keycode == KEY_SPACE:
		spawner.request_skip()


func _apply_camera_config() -> void:
	var config: Dictionary = ContentDb.game.get("camera", {})
	camera_rig.min_pitch_deg = float(config.get("min_pitch", camera_rig.min_pitch_deg))
	camera_rig.max_pitch_deg = float(config.get("max_pitch", camera_rig.max_pitch_deg))
	camera_rig.min_distance = float(config.get("min_distance", camera_rig.min_distance))
	camera_rig.max_distance = float(config.get("max_distance", camera_rig.max_distance))
	camera_rig.pan_speed = float(config.get("pan_speed", camera_rig.pan_speed))
	camera_rig.pitch_deg = float(config.get("default_pitch", camera_rig.pitch_deg))
	camera_rig.distance = float(config.get("default_distance", camera_rig.distance))
	camera_rig.target_distance = camera_rig.distance


func _setup_light() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.62, 0.66)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.64, 0.66, 0.62)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	$WorldEnvironment.environment = environment
	sun.rotation_degrees = Vector3(-48, -36, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	fill.rotation_degrees = Vector3(-28, 140, 0)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
