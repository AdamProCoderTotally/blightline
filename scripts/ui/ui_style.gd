class_name UiStyle
extends RefCounted

static func panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.11, 0.94)
	box.border_color = Color(1, 1, 1, 0.06)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


static func button(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func style_button(button: Button, selected: bool = false) -> void:
	var base := Color(0.16, 0.2, 0.22) if not selected else Color(0.24, 0.36, 0.3)
	button.add_theme_stylebox_override("normal", button(base))
	button.add_theme_stylebox_override("hover", button(base.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", button(base.lightened(0.2)))
	button.add_theme_stylebox_override("focus", button(base))
	button.add_theme_color_override("font_color", Color(0.94, 0.95, 0.92))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.96))
	button.add_theme_font_size_override("font_size", 16)


static func style_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
