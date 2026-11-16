extends Control

var _selected: int = 0
var _cards: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(str(ContentDb.game.get("title", "BLIGHTLINE")))
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.07, 0.08, 0.09)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = str(ContentDb.game.get("title", "BLIGHTLINE"))
	UiStyle.style_label(title, 36, Color(0.95, 0.93, 0.86))
	box.add_child(title)
	var place := Label.new()
	place.text = "%s  ·  %s" % [str(ContentDb.map.get("display_name", "Cinder Pass")), str(ContentDb.game.get("faction", ""))]
	UiStyle.style_label(place, 16, Color(0.78, 0.74, 0.64))
	box.add_child(place)
	if not ContentDb.load_errors.is_empty():
		var err := Label.new()
		err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		err.text = "Data failed to load:\n" + "\n".join(ContentDb.load_errors)
		UiStyle.style_label(err, 14, Color(0.9, 0.45, 0.38))
		box.add_child(err)
		return
	var modes: Array = ContentDb.difficulties.get("modes", [])
	var default_id := str(ContentDb.difficulties.get("default", ""))
	for index in modes.size():
		var mode: Dictionary = modes[index]
		if str(mode.get("id", "")) == default_id:
			_selected = index
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.text = _card_text(mode)
		var captured := index
		button.pressed.connect(func() -> void:
			_selected = captured
			_restyle()
		)
		box.add_child(button)
		_cards.append(button)
	var deploy := Button.new()
	deploy.text = "Deploy"
	deploy.focus_mode = Control.FOCUS_NONE
	deploy.pressed.connect(_deploy)
	box.add_child(deploy)
	_cards.append(deploy)
	_restyle()


func _card_text(mode: Dictionary) -> String:
	var notes: PackedStringArray = PackedStringArray()
	notes.append(str(mode.get("tagline", "")))
	if not bool(mode.get("tower_hp_enabled", true)):
		notes.append("Towers can't be destroyed.")
	var stealth: Variant = mode.get("stealth_from_wave", null)
	if stealth != null:
		notes.append("All enemies stealthed from wave %s." % str(stealth))
	return "%s   %s\n%d waves   ·   Base HP %d   ·   Cash %d\nHP ×%s   ·   speed ×%s   ·   %s" % [
		str(mode.get("name", mode.get("id", "Mode"))),
		_pips(int(mode.get("rating", 1))),
		int(mode.get("wave_count", 0)),
		int(mode.get("base_hp", 0)),
		int(mode.get("start_cash", 0)),
		str(mode.get("enemy_hp_mult", 1)),
		str(mode.get("enemy_speed_mult", 1)),
		" ".join(notes),
	]


func _pips(rating: int) -> String:
	var max_rating := 1
	for mode in ContentDb.difficulties.get("modes", []):
		max_rating = maxi(max_rating, int(mode.get("rating", 1)))
	var text := ""
	for index in max_rating:
		text += "●" if index < rating else "○"
	return text


func _restyle() -> void:
	for index in _cards.size() - 1:
		UiStyle.style_button(_cards[index], index == _selected)
	UiStyle.style_button(_cards[-1], true)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	var modes: Array = ContentDb.difficulties.get("modes", [])
	if key == KEY_DOWN or key == KEY_RIGHT:
		_selected = mini(_selected + 1, modes.size() - 1)
		_restyle()
	elif key == KEY_UP or key == KEY_LEFT:
		_selected = maxi(_selected - 1, 0)
		_restyle()
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_deploy()
	elif key >= KEY_1 and key < KEY_1 + modes.size():
		_selected = key - KEY_1
		_restyle()
		_deploy()


func _deploy() -> void:
	var modes: Array = ContentDb.difficulties.get("modes", [])
	if modes.is_empty():
		return
	GameState.apply_mode(str(modes[_selected].get("id", "")))
	get_tree().change_scene_to_file("res://scenes/game.tscn")
