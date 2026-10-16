extends Node2D

@export var 开局: 开局配置
const 棋子场景表 := {
	0: {0: preload("res://场景/棋子/黑将.tscn"), 1: preload("res://场景/棋子/黑士.tscn"), 2: preload("res://场景/棋子/黑象.tscn"), 3: preload("res://场景/棋子/黑马.tscn"), 4: preload("res://场景/棋子/黑车.tscn"), 5: preload("res://场景/棋子/黑炮.tscn"), 6: preload("res://场景/棋子/黑卒.tscn")},
	1: {0: preload("res://场景/棋子/红帅.tscn"), 1: preload("res://场景/棋子/红仕.tscn"), 2: preload("res://场景/棋子/红象.tscn"), 3: preload("res://场景/棋子/红马.tscn"), 4: preload("res://场景/棋子/红车.tscn"), 5: preload("res://场景/棋子/红炮.tscn"), 6: preload("res://场景/棋子/红兵.tscn")}
}
const 设计尺寸 := Vector2(1920, 1080)
const 墨色 := Color("384638")
const 背景纹理: Texture2D = preload("res://美术资源/场景图/场景1(1).png")
const 棋盘交叉点 := [
	[Vector2(506, 199), Vector2(620, 199), Vector2(734, 199), Vector2(847, 199), Vector2(960, 199), Vector2(1074, 199), Vector2(1187, 199), Vector2(1300, 199), Vector2(1414, 199)],
	[Vector2(501, 275), Vector2(618, 275), Vector2(733, 275), Vector2(848, 275), Vector2(960, 275), Vector2(1075, 275), Vector2(1192, 275), Vector2(1307, 275), Vector2(1420, 275)],
	[Vector2(496, 351), Vector2(614, 351), Vector2(731, 351), Vector2(848, 351), Vector2(960, 351), Vector2(1076, 351), Vector2(1194, 351), Vector2(1312, 351), Vector2(1426, 351)],
	[Vector2(491, 427), Vector2(610, 427), Vector2(729, 427), Vector2(848, 427), Vector2(960, 427), Vector2(1078, 427), Vector2(1197, 427), Vector2(1317, 427), Vector2(1432, 427)],
	[Vector2(486, 503), Vector2(606, 503), Vector2(727, 503), Vector2(848, 503), Vector2(960, 503), Vector2(1079, 503), Vector2(1200, 503), Vector2(1322, 503), Vector2(1438, 503)],
	[Vector2(480, 571), Vector2(602, 571), Vector2(724, 571), Vector2(848, 571), Vector2(960, 571), Vector2(1082, 571), Vector2(1205, 571), Vector2(1327, 571), Vector2(1444, 571)],
	[Vector2(474, 647), Vector2(598, 647), Vector2(721, 647), Vector2(847, 647), Vector2(960, 647), Vector2(1083, 647), Vector2(1209, 647), Vector2(1333, 647), Vector2(1451, 647)],
	[Vector2(468, 727), Vector2(593, 727), Vector2(718, 727), Vector2(846, 727), Vector2(960, 727), Vector2(1085, 727), Vector2(1213, 727), Vector2(1339, 727), Vector2(1458, 727)],
	[Vector2(461, 808), Vector2(587, 808), Vector2(714, 808), Vector2(845, 808), Vector2(960, 808), Vector2(1087, 808), Vector2(1218, 808), Vector2(1345, 808), Vector2(1466, 808)],
	[Vector2(454, 890), Vector2(581, 890), Vector2(709, 890), Vector2(844, 890), Vector2(960, 890), Vector2(1089, 890), Vector2(1224, 890), Vector2(1352, 890), Vector2(1474, 890)]
]
const 棋盘垂直校准 := Vector2(0, 18)
const 棋盘点击半径 := 56.0
const 选中环半径 := 60.0
const 最近一步半径 := 58.0
const 移动光点半径 := 12.0
const 移动光环半径 := 21.0
const 吃子外环半径 := 58.0
const 吃子内环半径 := 50.0
var 字体: SystemFont
var 棋盘: Array = []
var 棋子节点表 := {}
var 选中编号 := -1
var 可行落点: Array[Vector2i] = []
var 当前阵营 := 0
var 已结束 := false
var 思考中 := false
var 对局代数 := 0
var 搜索线程: Thread
var 搜索代数 := 0
var 状态标签: Label
var 详情标签: Label
var 重开按钮: Button
var 历史标签: Label
var 上次起点 := Vector2i(-1, -1)
var 上次终点 := Vector2i(-1, -1)
var 行动次数 := 0
var 已载开局: 开局配置
var 开局路径 := ""
var 语言按钮: OptionButton
var 静态标签: Dictionary = {}
var 标签字号: Dictionary = {}
var 操作说明: Label
var 错误列表: PackedStringArray = []

func _ready() -> void:
	语言管理.初始化()
	get_viewport().size_changed.connect(更新布局)
	更新布局()
	字体 = SystemFont.new()
	字体.font_names = PackedStringArray(["KaiTi", "STKaiti", "Noto Serif CJK SC", "Microsoft YaHei"])
	创建界面()
	get_window().title = 语言管理.文本("墨弈")
	重新开局()

func 更新布局() -> void:
	# 保持棋子圆形，并在任意宽高比下居中显示完整布局。
	position = (get_viewport_rect().size - 设计尺寸) * 0.5
	queue_redraw()

func 创建标签(文本: String, 坐标: Vector2, 字号: int, 颜色: Color = 墨色) -> Label:
	var 标签 := Label.new()
	标签.text = 语言管理.文本(文本)
	标签.name = "文字标签%d" % 静态标签.size()
	静态标签[标签] = 文本
	标签字号[标签] = 字号
	标签.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	标签.position = 坐标
	标签.add_theme_font_override("font", 字体)
	标签.add_theme_font_size_override("font_size", 字号)
	标签.add_theme_color_override("font_color", 颜色)
	标签.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(标签)
	调整标签字号(标签)
	return 标签

func 调整标签字号(标签: Label) -> void:
	var 字号: int = 标签字号[标签]
	if 语言管理.当前语言 == "en" and 标签.position.x < 276 and 标签.position.y < 900:
		for 行文本 in 标签.text.split("\n"):
			while 字号 > 10 and 字体.get_string_size(行文本, HORIZONTAL_ALIGNMENT_LEFT, -1, 字号).x > 165:
				字号 -= 1
	标签.add_theme_font_size_override("font_size", 字号)

func 创建界面() -> void:
	重开按钮 = Button.new()
	重开按钮.name = "重新开局按钮"
	重开按钮.text = 语言管理.文本("重新开局")
	重开按钮.position = Vector2(1080, 820)
	重开按钮.size = Vector2(240, 58)
	重开按钮.add_theme_font_override("font", 字体)
	重开按钮.add_theme_font_size_override("font_size", 23)
	重开按钮.add_theme_color_override("font_color", Color("fff3d6"))
	for 样式名 in ["normal", "hover", "pressed"]:
		var 底框 := StyleBoxFlat.new()
		底框.bg_color = Color("8f3028") if 样式名 == "normal" else Color("b84b39")
		底框.border_color = Color("d8a94e")
		底框.set_border_width_all(2)
		底框.set_corner_radius_all(10)
		重开按钮.add_theme_stylebox_override(样式名, 底框)
	重开按钮.pressed.connect(重新开局)
	add_child(重开按钮)
func 切换语言(选项: int) -> void:
	语言管理.设置语言("en" if 选项 == 1 else "zh_CN")
	语言按钮.select(选项)
	for 标签 in 静态标签:
		标签.text = 语言管理.文本(静态标签[标签])
		调整标签字号(标签)
	get_window().title = 语言管理.文本("墨弈")
	重开按钮.text = 语言管理.文本("重新开局")
	刷新文本()
	for 棋子实例: 基础单位 in 棋子节点表.values():
		棋子实例.queue_redraw()
	queue_redraw()

func 刷新文本() -> void:
	return
func 重新开局() -> void:
	对局代数 += 1
	if 开局 != 已载开局:
		开局路径 = 开局.resource_path if 开局 != null else ""
	if not 开局路径.is_empty():
		# 重新读取子资源，避免恢复默认值的字段残留旧配置。
		开局 = ResourceLoader.load(开局路径, "", ResourceLoader.CACHE_MODE_IGNORE)
	已载开局 = 开局
	for 棋子实例: 基础单位 in 棋子节点表.values():
		棋子实例.queue_free()
	棋子节点表.clear()
	棋盘.clear()
	选中编号 = -1
	可行落点.clear()
	上次起点 = Vector2i(-1, -1)
	上次终点 = Vector2i(-1, -1)
	行动次数 = 0
	已结束 = false
	思考中 = false
	错误列表 = PackedStringArray([语言管理.文本("主场景尚未指定开局配置")])
	if 开局 != null:
		错误列表 = 开局.验证()
	if not 错误列表.is_empty():
		已结束 = true
		刷新文本()
		queue_redraw()
		return
	棋盘 = 象棋规则.从配置生成(开局)
	当前阵营 = 开局.先手阵营
	同步棋子()
	更新回合()
	queue_redraw()

func 同步棋子() -> void:
	var 存活编号 := {}
	for 棋子: Dictionary in 棋盘:
		存活编号[棋子.编号] = true
		if not 棋子节点表.has(棋子.编号):
			var 棋子实例: 基础单位 = 棋子场景表[棋子.阵营][棋子.棋种].instantiate()
			棋子实例.字体 = 字体
			add_child(棋子实例)
			棋子节点表[棋子.编号] = 棋子实例
		棋子节点表[棋子.编号].更新状态(棋子, 棋盘坐标(棋子.坐标))
		棋子节点表[棋子.编号].已选中 = 棋子.编号 == 选中编号
	for 编号 in 棋子节点表.keys():
		if not 存活编号.has(编号):
			棋子节点表[编号].queue_free()
			棋子节点表.erase(编号)

func 更新回合() -> void:
	var 行动列表 := 象棋规则.获取行动(棋盘, 当前阵营)
	if 象棋规则.查找将帅(棋盘, 当前阵营).is_empty() or 行动列表.is_empty():
		已结束 = true
		思考中 = false
	else:
		思考中 = 当前阵营 != 开局.玩家阵营
	刷新文本()

func _process(_帧间隔: float) -> void:
	if 搜索线程 != null and not 搜索线程.is_alive():
		var 行动: Dictionary = 搜索线程.wait_to_finish()
		搜索线程 = null
		if 搜索代数 == 对局代数 and 思考中 and not 已结束 and not 行动.is_empty():
			执行行动(行动)
	if 思考中 and not 已结束 and 搜索线程 == null:
		搜索线程 = Thread.new()
		搜索代数 = 对局代数
		搜索线程.start(象棋电脑.选择行动.bind(棋盘.duplicate(true), 当前阵营))

func _exit_tree() -> void:
	if 搜索线程 != null:
		搜索线程.wait_to_finish()

func _unhandled_input(事件: InputEvent) -> void:
	if not 事件 is InputEventMouseButton or 事件.button_index != MOUSE_BUTTON_LEFT or not 事件.pressed:
		return
	if 已结束 or 思考中:
		return
	var 鼠标坐标: Vector2 = get_global_transform_with_canvas().affine_inverse() * 事件.position
	var 格点 := 最近棋盘格点(鼠标坐标)
	if 格点.x < 0 or 格点.y < 0:
		return
	if 选中编号 >= 0 and 格点 in 可行落点:
		执行行动({"编号": 选中编号, "目标": 格点})
		return
	var 棋子 := 象棋规则.查找棋子(棋盘, 格点)
	选中编号 = -1
	可行落点.clear()
	if not 棋子.is_empty() and 棋子.阵营 == 开局.玩家阵营:
		选中编号 = 棋子.编号
		for 纵坐标 in 10:
			for 横坐标 in 9:
				var 目标坐标 := Vector2i(横坐标, 纵坐标)
				if 象棋规则.合法行动(棋盘, 棋子, 目标坐标):
					可行落点.append(目标坐标)
	同步棋子()
	queue_redraw()

func 执行行动(行动: Dictionary) -> void:
	for 棋子: Dictionary in 棋盘:
		if 棋子.编号 == 行动.编号:
			上次起点 = 棋子.坐标
	上次终点 = 行动.目标
	棋盘 = 象棋规则.应用行动(棋盘, 行动)
	选中编号 = -1
	可行落点.clear()
	行动次数 += 1
	当前阵营 = 1 - 当前阵营
	同步棋子()
	更新回合()
	queue_redraw()

func 棋盘坐标(格点: Vector2i) -> Vector2:
	return 棋盘交叉点[格点.y][格点.x] + 棋盘垂直校准

func 最近棋盘格点(位置: Vector2) -> Vector2i:
	var 最近 := Vector2i(-1, -1)
	var 最近距离 := 棋盘点击半径
	for 行 in 10:
		for 列 in 9:
			var 距离 := 位置.distance_to(棋盘坐标(Vector2i(列, 行)))
			if 距离 < 最近距离:
				最近距离 = 距离
				最近 = Vector2i(列, 行)
	return 最近

func _draw() -> void:
	draw_texture_rect(背景纹理, Rect2(Vector2.ZERO, 设计尺寸), false)
	for 格点 in [上次起点, 上次终点]:
		if 象棋规则.位于棋盘(格点):
			var 位置 := 棋盘坐标(格点)
			draw_circle(位置, 最近一步半径, Color(0.93, 0.67, 0.22, 0.18))
			draw_arc(位置, 最近一步半径, 0, TAU, 48, Color("e5b34f"), 3.5, true)
	for 格点 in 可行落点:
		var 位置 := 棋盘坐标(格点)
		if 象棋规则.查找棋子(棋盘, 格点).is_empty():
			draw_circle(位置, 28.0, Color(0.98, 0.72, 0.18, 0.10))
			draw_circle(位置, 移动光点半径, Color(0.95, 0.76, 0.28, 0.78))
			draw_circle(位置, 5, Color("fff0a6"))
			draw_arc(位置, 移动光环半径, 0, TAU, 32, Color(0.96, 0.71, 0.2, 0.7), 2.0, true)
		else:
			draw_arc(位置, 吃子外环半径, 0, TAU, 64, Color("e0523c"), 5.0, true)
			draw_arc(位置, 吃子内环半径, 0, TAU, 64, Color(0.98, 0.72, 0.26, 0.85), 2.5, true)
