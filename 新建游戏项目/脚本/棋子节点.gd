class_name 棋子节点
extends Node2D

const 棋名 := [["帅", "仕", "相", "马", "车", "炮", "兵"], ["将", "士", "象", "马", "车", "炮", "卒"]]
var 状态: Dictionary = {}
var 已选中 := false
var 受击闪光 := 0.0
var 字体: Font

func _process(帧间隔: float) -> void:
	if 受击闪光 > 0:
		受击闪光 = maxf(0, 受击闪光 - 帧间隔)
		queue_redraw()

func 更新状态(数据: Dictionary, 位置: Vector2) -> void:
	if not 状态.is_empty() and 数据.当前血量 < 状态.当前血量:
		受击闪光 = 0.7
	状态 = 数据.duplicate(true)
	position = 位置
	queue_redraw()

func _draw() -> void:
	if 状态.is_empty():
		return
	var 棋色 := Color("a63f34") if 状态.阵营 == 棋子配置.阵营类型.红方 else Color("252c2b")
	draw_circle(Vector2(2, 4), 29, Color(0.12, 0.1, 0.07, 0.19))
	draw_circle(Vector2.ZERO, 29, Color("dfcfac"))
	draw_circle(Vector2(-1, -2), 26, Color("f6ecd4"))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 64, 棋色, 1.6, true)
	draw_arc(Vector2.ZERO, 23, 0, TAU, 64, Color(棋色, 0.5), 0.8, true)
	if 已选中:
		draw_arc(Vector2.ZERO, 33, 0, TAU, 64, Color("b68b3a"), 2.5, true)
	if 受击闪光 > 0:
		draw_circle(Vector2.ZERO, 29, Color(0.8, 0.2, 0.1, 受击闪光 * 0.4))
	# 棋面始终使用传统汉字，不随界面语言切换。
	var 棋名文本: String = 棋名[状态.阵营][状态.棋种]
	var 字号 := 34
	var 宽度 := 字体.get_string_size(棋名文本, HORIZONTAL_ALIGNMENT_LEFT, -1, 字号).x
	draw_string(字体, Vector2(-宽度 / 2, 12), 棋名文本, HORIZONTAL_ALIGNMENT_LEFT, -1, 字号, 棋色)
	if 状态.最大血量 > 1:
		draw_style_box(_血量底框(), Rect2(-24, 20, 48, 18))
		var 当前血量 := "%d/%d" % [状态.当前血量, 状态.最大血量]
		var 血量宽度 := 字体.get_string_size(当前血量, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(字体, Vector2(-血量宽度 / 2, 34), 当前血量, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff4db"))

func _血量底框() -> StyleBoxFlat:
	var 底框 := StyleBoxFlat.new()
	底框.bg_color = Color("43584a")
	底框.set_corner_radius_all(5)
	return 底框
