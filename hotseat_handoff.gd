extends Control

## A turn boundary, not a second results/menu flow. The gameplay owner decides
## when held controls have released and when another fresh turn can begin.

signal start_requested

const Art = preload("res://games/dolces_adventure/dolce_art.gd")

var panel: PanelContainer
var title: Label
var copy: Label
var button: Button


func _init() -> void:
	name = "HotSeatHandoff"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("30261f", 0.96)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("59422f")
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(title)
	copy = Label.new()
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_color_override("font_color", Art.CREAM)
	layout.add_child(copy)
	button = Button.new()
	button.pressed.connect(start_requested.emit)
	layout.add_child(button)
	hide()


func show_turn(player_name: String, previous: String, color: Color) -> void:
	title.text = player_name.to_upper() + " / YOUR TURN"
	title.add_theme_color_override("font_color", color)
	copy.text = (
		previous + "\nSame course, fresh hearts and food.\nRelease the controls, then pass them on."
	)
	button.text = "Start " + player_name
	button.accessibility_description = title.text + ". " + copy.text
	button.disabled = true
	show()


func fit(area: Vector2, readability: float) -> void:
	panel.custom_minimum_size.x = minf(760.0, area.x / readability - 48.0) * readability
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 24 * readability
	style.content_margin_right = 24 * readability
	style.content_margin_top = 20 * readability
	style.content_margin_bottom = 20 * readability
	(panel.get_child(0) as VBoxContainer).add_theme_constant_override(
		"separation", roundi(16 * readability)
	)
	title.add_theme_font_size_override("font_size", roundi(32 * readability))
	copy.add_theme_font_size_override("font_size", roundi(22 * readability))
	button.add_theme_font_size_override("font_size", roundi(24 * readability))
	button.custom_minimum_size.y = 72 * readability
