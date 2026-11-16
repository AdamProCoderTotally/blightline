extends CanvasLayer

var _mode: Label
var _hp: Label
var _cash: Label
var _wave: Label
var _status: Label
var _boss: Label
var _build_row: HFlowContainer
var _action_row: HFlowContainer
var _build_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top(root)
	_build_bottom(root)
	_refresh_all()
	GameState.base_hp_changed.connect(func(_v: int) -> void: _refresh_stats())
	GameState.cash_changed.connect(func(_v: int) -> void: _refresh_stats())
	GameState.wave_changed.connect(func(_n: int, _t: int) -> void: _refresh_stats())
	GameState.status_changed.connect(func(text: String) -> void: _status.text = text)
	var placement := _placement()
	if placement != null:
		placement.build_changed.connect(func(_def: Dictionary) -> void: _refresh_build_styles())
		placement.selection_changed.connect(func(_tower: Tower) -> void: _refresh_actions())


func _process(_delta: float) -> void:
	_refresh_boss()
	_refresh_limit_labels()


func _build_top(root: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_left = 12
	margin.offset_top = 12
	margin.offset_right = -12
	margin.offset_bottom = 132
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 18)
	box.add_child(row)
	_mode = _stat(row, "Mode")
	_hp = _stat(row, "Base HP")
	_cash = _stat(row, "Cash")
	_wave = _stat(row, "Wave")
	_boss = Label.new()
	UiStyle.style_label(_boss, 15, Color(0.86, 0.55, 0.48))
	box.add_child(_boss)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.style_label(_status, 15, Color(0.82, 0.84, 0.8))
	box.add_child(_status)


func _build_bottom(root: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_left = 12
	margin.offset_top = -210
	margin.offset_right = -12
	margin.offset_bottom = -12
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_build_row = HFlowContainer.new()
	_build_row.add_theme_constant_override("h_separation", 8)
	box.add_child(_build_row)
	_action_row = HFlowContainer.new()
	_action_row.add_theme_constant_override("h_separation", 8)
	box.add_child(_action_row)
	for index in ContentDb.towers.size():
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		var captured := index
		button.pressed.connect(func() -> void:
			var placement := _placement()
			if placement != null:
				placement.select_build(captured)
		)
		_build_row.add_child(button)
		_build_buttons.append(button)
	var skip := Button.new()
	skip.text = "Skip wave"
	skip.focus_mode = Control.FOCUS_NONE
	UiStyle.style_button(skip)
	skip.pressed.connect(func() -> void:
		var spawner := get_parent().get_node_or_null("WaveSpawner") as WaveSpawner
		if spawner != null:
			spawner.request_skip()
	)
	box.add_child(skip)
	_refresh_build_styles()


func _stat(parent: Node, caption: String) -> Label:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var title := Label.new()
	title.text = caption
	UiStyle.style_label(title, 12, Color(0.68, 0.72, 0.7))
	box.add_child(title)
	var value := Label.new()
	UiStyle.style_label(value, 20, Color(0.95, 0.94, 0.9))
	box.add_child(value)
	return value


func _refresh_all() -> void:
	_refresh_stats()
	_status.text = GameState.status
	_refresh_actions()
	_refresh_limit_labels()


func _refresh_stats() -> void:
	if _hp == null:
		return
	_mode.text = str(GameState.mode.get("name", "—")).to_upper()
	_hp.text = "%d / %d" % [GameState.base_hp, GameState.base_hp_max]
	_cash.text = "$%d" % GameState.cash
	if GameState.wave_number <= 0:
		_wave.text = "Prep / %d" % GameState.wave_total
	else:
		_wave.text = "%d / %d" % [GameState.wave_number, GameState.wave_total]


func _refresh_boss() -> void:
	if _boss == null:
		return
	var line := ""
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead or not bool(enemy.definition.get("boss_bar", false)):
			continue
		line = "%s  %d" % [enemy.definition.get("name", "Boss"), int(round(enemy.hp + enemy.shield))]
		if enemy.shield > 0.0:
			line += "  (shield %d)" % int(round(enemy.shield))
		break
	_boss.text = line
	_boss.visible = line != ""


func _refresh_limit_labels() -> void:
	var placement := _placement()
	for index in _build_buttons.size():
		if index >= ContentDb.towers.size():
			continue
		var def: Dictionary = ContentDb.towers[index]
		var text := "%d  %s  $%d" % [index + 1, str(def.get("name", def.get("id", ""))), int(def.get("cost", 0))]
		var limit: Variant = def.get("limit", null)
		if limit != null and placement != null:
			text += "  %d/%d" % [placement.count_of(str(def.get("id", ""))), int(limit)]
		_build_buttons[index].text = text


func _refresh_build_styles() -> void:
	var placement := _placement()
	var selected := placement.build_index if placement != null else -1
	for index in _build_buttons.size():
		UiStyle.style_button(_build_buttons[index], index == selected)


func _refresh_actions() -> void:
	if _action_row == null:
		return
	for child in _action_row.get_children():
		child.queue_free()
	var placement := _placement()
	if placement == null or placement.selected == null or not is_instance_valid(placement.selected):
		return
	var tower := placement.selected
	_add_path_button(tower, 0, "Top")
	_add_path_button(tower, 1, "Bottom")
	var info := Label.new()
	info.text = "%s  %s  ·  %s" % [tower.display_name(), tower.level_label(), tower.targeting.capitalize()]
	UiStyle.style_label(info, 14, Color(0.9, 0.9, 0.86))
	_action_row.add_child(info)
	var sell := Button.new()
	sell.text = "Sell $%d" % tower.refund_amount()
	sell.focus_mode = Control.FOCUS_NONE
	UiStyle.style_button(sell)
	sell.pressed.connect(func() -> void:
		placement.sell_selected()
		_refresh_actions()
	)
	_action_row.add_child(sell)


func _add_path_button(tower: Tower, path_index: int, path_name: String) -> void:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var pips := ""
	for index in tower.tier_count(path_index):
		pips += "●" if index < tower.rank(path_index) else "○"
	if not tower.can_upgrade(path_index):
		if tower.rank(path_index) >= tower.tier_count(path_index):
			button.text = "%s %s  MAX" % [path_name, pips]
		else:
			button.text = "%s %s  capped at %d" % [path_name, pips, GameState.upgrade_other_cap_tier()]
		button.disabled = true
	else:
		var tier := tower.next_tier(path_index)
		button.text = "%s %s\n%s  $%d" % [path_name, pips, str(tier.get("name", "Upgrade")), int(tier.get("cost", 0))]
		button.disabled = GameState.cash < int(tier.get("cost", 0))
	UiStyle.style_button(button)
	var captured := path_index
	button.pressed.connect(func() -> void:
		if tower.upgrade(captured):
			_refresh_actions()
		else:
			GameState.flash_status("That upgrade is blocked.")
	)
	_action_row.add_child(button)


func _placement() -> PlacementController:
	return get_parent().get_node_or_null("Placement") as PlacementController
