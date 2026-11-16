extends Node
## One match. Difficulty multipliers, leak rounding, sell ratio, and income
## all come from data/game_config.json and data/difficulties.json.

signal base_hp_changed(value: int)
signal cash_changed(value: int)
signal wave_changed(number: int, total: int)
signal status_changed(text: String)
signal finished(victory: bool)

var mode: Dictionary = {}
var base_hp: int = 0
var base_hp_max: int = 0
var cash: int = 0
var wave_number: int = 0
var wave_total: int = 0
var wave_time_left: float = -1.0
var leak_damage_mode: String = "remaining_hp_plus_shield"
var sell_refund_ratio: float = 0.5
var status: String = ""
var defeated: bool = false
var victorious: bool = false
var speed_step: int = 0

var _status_base: String = ""
var _flash_token: int = 0
var _cash_fraction: float = 0.0
const SPEEDS: Array[float] = [1.0, 1.5, 2.0]


func _ready() -> void:
	leak_damage_mode = str(ContentDb.game.get("leak_damage_mode", "remaining_hp_plus_shield"))


func apply_mode(mode_id: String) -> void:
	mode = ContentDb.mode_by_id(mode_id) if mode_id != "" else ContentDb.default_mode()
	base_hp_max = int(mode.get("base_hp", 500))
	base_hp = base_hp_max
	cash = int(mode.get("start_cash", 0))
	_cash_fraction = 0.0
	wave_total = int(mode.get("wave_count", 1))
	wave_number = 0
	wave_time_left = -1.0
	defeated = false
	victorious = false
	sell_refund_ratio = float(mode.get("sell_ratio", 0.5))
	speed_step = 0
	Engine.time_scale = 1.0
	var tree := get_tree()
	if tree != null:
		tree.paused = false
	_status_base = ""
	status = ""
	base_hp_changed.emit(base_hp)
	cash_changed.emit(cash)
	wave_changed.emit(wave_number, wave_total)
	status_changed.emit(status)


func enemy_hp_mult() -> float:
	return float(mode.get("enemy_hp_mult", 1.0))


func boss_hp_mult() -> float:
	return float(mode.get("boss_hp_mult", 1.0))


func enemy_speed_multiplier() -> float:
	return float(mode.get("enemy_speed_mult", 1.0))


func income_mult() -> float:
	return float(mode.get("income_mult", 1.0))


func tower_hp_enabled() -> bool:
	return bool(mode.get("tower_hp_enabled", true))


func stealth_from_wave() -> int:
	var value: Variant = mode.get("stealth_from_wave", null)
	if value == null:
		return -1
	return int(value)


func scaled_hp_multiplier(wave: int, is_boss: bool) -> float:
	if is_boss:
		return boss_hp_mult()
	var slope := float(ContentDb.game.get("hp_mult_slope", 0.05))
	return (1.0 + slope * float(wave - 1)) * enemy_hp_mult()


func try_spend(amount: int) -> bool:
	if amount < 0 or cash < amount or defeated:
		return false
	cash -= amount
	cash_changed.emit(cash)
	return true


func add_cash(amount: int) -> void:
	add_cash_amount(float(amount))


func add_cash_amount(amount: float) -> void:
	if amount <= 0.0:
		return
	_cash_fraction += amount
	var whole := int(_cash_fraction)
	if whole <= 0:
		return
	_cash_fraction -= float(whole)
	cash += whole
	cash_changed.emit(cash)


func grant_damage_income(health_damage: float) -> void:
	if health_damage <= 0.0:
		return
	var per_hp := float(ContentDb.game.get("cash_per_hp", 1.0))
	add_cash_amount(health_damage * per_hp * income_mult())


func grant_wave_bonus(wave: int) -> void:
	var base := float(ContentDb.game.get("wave_bonus_base", 75))
	var step := float(ContentDb.game.get("wave_bonus_step", 25))
	add_cash_amount((base + step * float(wave)) * income_mult())


func damage_base(amount: int) -> void:
	if defeated or amount <= 0:
		return
	base_hp = maxi(base_hp - amount, 0)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		defeated = true
		set_status("The pass is lost.")
		finished.emit(false)


func restore_base(amount: int) -> void:
	if amount <= 0 or defeated:
		return
	base_hp = mini(base_hp + amount, base_hp_max)
	base_hp_changed.emit(base_hp)


func leak_amount(remaining_hp: float, remaining_shield: float) -> int:
	# v1.1: ceil(remaining HP + remaining shield). No fixed leak and no boss exception.
	var raw := 0.0
	match leak_damage_mode:
		"remaining_hp":
			raw = remaining_hp
		"fixed":
			return maxi(int(ContentDb.game.get("fixed_leak_damage", 1)), 0)
		_:
			raw = remaining_hp + remaining_shield
	return maxi(ceili(maxf(raw, 0.0)), 0)


func refund_for(spent: int) -> int:
	return int(round(float(spent) * sell_refund_ratio))


func upgrade_trigger_tier() -> int:
	var rules: Dictionary = ContentDb.game.get("upgrade_rules", {})
	return int(rules.get("soft_cap_trigger_tier", 3))


func upgrade_other_cap_tier() -> int:
	var rules: Dictionary = ContentDb.game.get("upgrade_rules", {})
	return int(rules.get("other_path_cap_tier", 2))


func cycle_speed() -> void:
	speed_step = (speed_step + 1) % SPEEDS.size()
	Engine.time_scale = SPEEDS[speed_step]


func set_wave(number: int, total: int) -> void:
	wave_number = number
	wave_total = total
	wave_changed.emit(number, total)


func set_status(text: String) -> void:
	_status_base = text
	status = text
	status_changed.emit(status)


func flash_status(text: String) -> void:
	_flash_token += 1
	var token := _flash_token
	status = text
	status_changed.emit(status)
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(1.8).timeout.connect(func() -> void:
		if token != _flash_token or defeated:
			return
		status = _status_base
		status_changed.emit(status)
	)


func mark_victory() -> void:
	if defeated or victorious:
		return
	victorious = true
	set_status("The pass held.")
	finished.emit(true)
