class_name PieceUnit
extends Node2D

const NAMES := [["将", "士", "象", "马", "车", "炮", "卒"], ["帅", "仕", "相", "马", "车", "炮", "兵"]]
var state: Dictionary = {}
var selected := false
var damage_flash := 0.0
var font: Font

func _process(delta: float) -> void:
	if damage_flash > 0:
		damage_flash = maxf(0, damage_flash - delta)
		queue_redraw()

func update_state(data: Dictionary, location: Vector2) -> void:
	if not state.is_empty() and data.hp < state.hp:
		damage_flash = 0.7
	state = data.duplicate(true)
	position = location
	queue_redraw()

func _draw() -> void:
	if state.is_empty():
		return
	var ink := Color("252c2b") if state.side == 0 else Color("a63f34")
	draw_circle(Vector2(2, 4), 29, Color(0.12, 0.1, 0.07, 0.19))
	draw_circle(Vector2.ZERO, 29, Color("dfcfac"))
	draw_circle(Vector2(-1, -2), 26, Color("f6ecd4"))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 64, ink, 1.6, true)
	draw_arc(Vector2.ZERO, 23, 0, TAU, 64, Color(ink, 0.5), 0.8, true)
	if selected:
		draw_arc(Vector2.ZERO, 33, 0, TAU, 64, Color("b68b3a"), 2.5, true)
	if damage_flash > 0:
		draw_circle(Vector2.ZERO, 29, Color(0.8, 0.2, 0.1, damage_flash * 0.4))
	var title: String = NAMES[state.side][state.kind]
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	draw_string(font, Vector2(-width / 2, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, ink)
	if state.max_hp > 1:
		draw_style_box(_badge(), Rect2(-24, 20, 48, 18))
		var hp := "%d/%d" % [state.hp, state.max_hp]
		var hp_width := font.get_string_size(hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(-hp_width / 2, 34), hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff4db"))

func _badge() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("43584a")
	box.set_corner_radius_all(5)
	return box
