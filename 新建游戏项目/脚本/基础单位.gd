class_name 基础单位
extends Node2D

signal 受伤信号(剩余生命值: int)
signal 死亡信号

var 状态: Dictionary = {}
var 已选中 := false
var 受击闪光 := 0.0
var 字体: Font
@export var 攻击力: int = 1
@export var 棋子纹理: Texture2D

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

func 攻击(目标: 基础单位) -> void:
	if is_instance_valid(目标):
		目标.受伤(攻击力)

func 受伤(伤害: int = 1) -> void:
	if 状态.is_empty():
		return
	状态.当前血量 = maxi(0, 状态.当前血量 - maxi(1, 伤害))
	受击闪光 = 0.7
	受伤信号.emit(状态.当前血量)
	if 状态.当前血量 <= 0:
		死亡信号.emit()
	queue_redraw()

func _draw() -> void:
	if 状态.is_empty():
		return
	var 棋色 := Color("a63f34") if 状态.阵营 == 棋子配置.阵营类型.红方 else Color("252c2b")
	if 棋子纹理 != null:
		# 节点原点位于棋子底座中心，人物主体向上延伸。
		draw_texture_rect(棋子纹理, Rect2(-60, -120, 120, 120), false)
	else:
		draw_circle(Vector2(2, 4), 38, Color(0.12, 0.1, 0.07, 0.19))
		draw_circle(Vector2.ZERO, 38, Color("dfcfac"))
		draw_arc(Vector2.ZERO, 37, 0, TAU, 64, 棋色, 2.0, true)
	if 已选中:
		draw_arc(Vector2.ZERO, 60, 0, TAU, 64, Color("b68b3a"), 4.0, true)
	if 受击闪光 > 0:
		draw_circle(Vector2(0, -42), 58, Color(0.8, 0.2, 0.1, 受击闪光 * 0.4))
	if 状态.最大血量 > 1 and 字体 != null:
		draw_style_box(_血量底框(), Rect2(-30, 10, 60, 20))
		var 当前血量 := "%d/%d" % [状态.当前血量, 状态.最大血量]
		var 血量宽度 := 字体.get_string_size(当前血量, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(字体, Vector2(-血量宽度 / 2, 25), 当前血量, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff4db"))

func _血量底框() -> StyleBoxFlat:
	var 底框 := StyleBoxFlat.new()
	底框.bg_color = Color("43584a")
	底框.set_corner_radius_all(5)
	return 底框
