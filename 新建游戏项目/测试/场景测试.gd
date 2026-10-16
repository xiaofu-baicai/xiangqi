extends SceneTree

var 检查数 := 0
var 失败数 := 0
var 游戏: Node2D

func 检查(数值: bool, 描述: String) -> void:
	检查数 += 1
	if not 数值:
		失败数 += 1
		push_error("FAIL: " + 描述)

func 点击(格点: Vector2i) -> void:
	var 事件 := InputEventMouseButton.new()
	事件.button_index = MOUSE_BUTTON_LEFT
	事件.pressed = true
	事件.position = 游戏.get_global_transform_with_canvas() * 游戏.棋盘坐标(格点)
	游戏._unhandled_input(事件)

func _initialize() -> void:
	call_deferred("运行测试")

func 保存预览(路径: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var 图像 := root.get_texture().get_image()
	检查(图像.save_png(路径) == OK, "saved " + 路径)

func 等待电脑() -> void:
	var 截止时刻 := Time.get_ticks_msec() + 15000
	while (游戏.思考中 or 游戏.搜索线程 != null) and Time.get_ticks_msec() < 截止时刻:
		await process_frame
	检查(not 游戏.思考中 and 游戏.搜索线程 == null, "AI finishes within 15 seconds")

func 运行测试() -> void:
	语言管理.偏好文件 = "user://测试语言偏好.cfg"
	if FileAccess.file_exists(语言管理.偏好文件):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(语言管理.偏好文件))
	语言管理.初始化()
	语言管理.读取偏好()
	检查(语言管理.当前语言 == "zh_CN", "新用户默认中文")
	语言管理.设置语言("en")
	语言管理.设置语言("zh_CN", false)
	语言管理.读取偏好()
	检查(语言管理.当前语言 == "en", "恢复已保存的英文偏好")
	语言管理.设置语言("invalid", false)
	检查(语言管理.当前语言 == "zh_CN", "无效语言回退中文")
	var 中文: Translation = load("res://翻译/中文.tres")
	var 英文: Translation = load("res://翻译/英文.tres")
	检查(中文.get_message_count() == 英文.get_message_count(), "两种语言条目数量一致")
	for 原文 in 中文.get_message_list():
		检查(not 英文.get_message(原文).is_empty(), "英文译文覆盖：" + 原文)
	root.size = Vector2i(1440, 1000)
	root.content_scale_size = Vector2i(1440, 1000)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	游戏 = load("res://场景/主场景.tscn").instantiate()
	root.add_child(游戏)
	游戏.set_process(false)
	await process_frame
	检查(游戏.棋盘.size() == 32 and 游戏.棋子节点表.size() == 32, "scene contains 32 independent units")
	检查(游戏.当前阵营 == 棋子配置.阵营类型.红方 and not 游戏.已结束 and not 游戏.思考中, "red player starts")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://验证产物"))
	await 保存预览("res://验证产物/棋盘预览.png")
	点击(Vector2i(0, 6))
	检查(游戏.选中编号 >= 0 and Vector2i(0, 5) in 游戏.可行落点, "select pawn and show legal target")
	var 已选中: int = 游戏.选中编号
	var 原棋盘: Array = 游戏.棋盘.duplicate(true)
	var 原落点: Array = 游戏.可行落点.duplicate()
	游戏.切换语言(1)
	检查(游戏.状态标签.text == "Red · Your move" and 游戏.重开按钮.text == "New Game", "英文动态状态和按钮")
	检查(游戏.棋盘 == 原棋盘 and 游戏.选中编号 == 已选中 and 游戏.可行落点 == 原落点 and 游戏.行动次数 == 0, "切换语言保留棋局与选中状态")
	检查(语言管理.文本("楚 河") == "CHU RIVER", "棋盘说明切换英文，棋面保留中文")
	await 保存预览("res://验证产物/英文棋盘.png")
	游戏.切换语言(0)
	点击(Vector2i(1, 5))
	检查(游戏.当前阵营 == 0 and 游戏.行动次数 == 0, "invalid target does not consume turn")
	点击(Vector2i(0, 6))
	点击(Vector2i(0, 5))
	检查(游戏.当前阵营 == 1 and 游戏.思考中 and 游戏.行动次数 == 1, "player action consumes turn")
	检查(象棋规则.查找棋子(游戏.棋盘, Vector2i(0, 5)).编号 == 已选中, "pawn moved to clicked target")
	点击(Vector2i(2, 6))
	检查(游戏.选中编号 == -1 and 游戏.行动次数 == 1, "input locked during AI turn")
	游戏.set_process(true)
	await 等待电脑()
	检查(游戏.当前阵营 == 0 and 游戏.行动次数 == 2, "AI returns turn to player")
	for 序号 in 3:
		var 行动列表 := 象棋规则.获取行动(游戏.棋盘, 0)
		检查(not 行动列表.is_empty(), "player can continue game")
		游戏.执行行动(行动列表[0])
		await 等待电脑()
	检查(游戏.行动次数 == 8 and not 游戏.已结束, "four consecutive player and AI turns")
	游戏.set_process(false)
	游戏.重新开局()
	root.size = Vector2i(960, 700)
	await 保存预览("res://验证产物/小窗口棋盘.png")
	for 窗口尺寸 in [Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(900, 1200)]:
		root.size = 窗口尺寸
		await process_frame
		await process_frame
		var 视口尺寸 := 游戏.get_viewport_rect().size
		检查((游戏.position + 游戏.设计尺寸 * 0.5).distance_to(视口尺寸 * 0.5) < 1.0, "composition centered at %s" % 窗口尺寸)
		检查(游戏.position.x >= -0.1 and 游戏.position.y >= -0.1, "complete composition visible at %s" % 窗口尺寸)
		for 语言选项 in [0, 1]:
			游戏.切换语言(语言选项)
			await 保存预览("res://验证产物/棋盘_%dx%d_%s.png" % [窗口尺寸.x, 窗口尺寸.y, 语言管理.当前语言])
			检查(游戏.状态标签.position.x + 游戏.状态标签.size.x < 1440, "状态标签位于设计范围")
			检查(游戏.历史标签.position.y + 游戏.历史标签.size.y < 游戏.重开按钮.position.y, "历史说明不遮挡重开按钮")
	游戏.切换语言(0)
	root.size = Vector2i(960, 700)
	await process_frame
	await process_frame
	点击(Vector2i(2, 6))
	点击(Vector2i(2, 5))
	检查(游戏.当前阵营 == 1 and 象棋规则.查找棋子(游戏.棋盘, Vector2i(2, 5)).阵营 == 0, "logical picking remains accurate in resized viewport")
	var 逻辑坐标: Vector2 = 游戏.棋盘坐标(Vector2i(2, 5))
	var 窗口坐标: Vector2 = root.get_final_transform() * 逻辑坐标
	检查((root.get_final_transform().affine_inverse() * 窗口坐标).distance_to(逻辑坐标) < 0.01, "stretch transform round trips board point")

	var 自定义开局: 开局配置 = load("res://配置/默认开局.tres").duplicate(true)
	# A duplicate resource must be detached to test in-memory custom setups.
	自定义开局.resource_path = ""
	自定义开局.玩家阵营 = 棋子配置.阵营类型.红方
	自定义开局.先手阵营 = 棋子配置.阵营类型.红方
	自定义开局.棋子列表[0].血量 = 4
	自定义开局.棋子列表[9].棋种 = 棋子配置.棋种类型.马
	自定义开局.棋子列表[9].棋盘位置 = Vector2i(1, 6)
	自定义开局.棋子列表.remove_at(10)
	游戏.开局 = 自定义开局
	游戏.重新开局()
	检查(游戏.棋盘.size() == 31 and 游戏.棋盘[0].当前血量 == 4 and 游戏.棋盘[9].棋种 == 棋子配置.棋种类型.马, "custom count, HP, kind and location applied")
	检查(游戏.当前阵营 == 棋子配置.阵营类型.红方 and not 游戏.思考中, "custom player and first side applied")
	自定义开局.棋子列表[0].血量 = 0
	游戏.重新开局()
	检查(游戏.已结束 and 游戏.状态标签.text == "配置错误" and 游戏.棋盘.is_empty(), "configuration errors stop game with visible message")
	游戏.切换语言(1)
	检查(游戏.状态标签.text == "Invalid Setup" and "Piece 1 must have positive health." in 游戏.详情标签.text, "配置错误即时切换英文并保留参数")
	await 保存预览("res://验证产物/英文错误提示.png")
	游戏.切换语言(0)
	点击(Vector2i(2, 3))
	检查(游戏.选中编号 == -1, "input locked for invalid or finished game")

	自定义开局 = load("res://配置/默认开局.tres").duplicate(true)
	自定义开局.resource_path = ""
	自定义开局.先手阵营 = 棋子配置.阵营类型.黑方
	游戏.开局 = 自定义开局
	游戏.重新开局()
	游戏.set_process(true)
	await process_frame
	await process_frame
	检查(游戏.搜索线程 != null, "black first starts background search")
	var 原线程: Thread = 游戏.搜索线程
	var 原代数: int = 游戏.对局代数
	游戏.切换语言(1)
	检查(游戏.搜索线程 == 原线程 and 游戏.对局代数 == 原代数 and 游戏.思考中, "电脑思考时切换不重启线程或棋局")
	游戏.切换语言(0)
	自定义开局.先手阵营 = 棋子配置.阵营类型.红方
	游戏.重新开局()
	await 等待电脑()
	检查(游戏.当前阵营 == 棋子配置.阵营类型.红方 and 游戏.行动次数 == 0 and 游戏.棋盘.size() == 32, "restart discards old AI result")
	# Trigger nonlethal attack in the real scene, including unit HP feedback.
	游戏.set_process(false)
	游戏.棋盘 = [
		{"编号": 0, "阵营": 0, "棋种": 0, "坐标": Vector2i(3, 9), "当前血量": 1, "最大血量": 1},
		{"编号": 1, "阵营": 1, "棋种": 0, "坐标": Vector2i(5, 0), "当前血量": 1, "最大血量": 1},
		{"编号": 2, "阵营": 0, "棋种": 4, "坐标": Vector2i(0, 5), "当前血量": 1, "最大血量": 1},
		{"编号": 3, "阵营": 1, "棋种": 3, "坐标": Vector2i(0, 3), "当前血量": 2, "最大血量": 2}]
	游戏.当前阵营 = 0
	游戏.思考中 = false
	游戏.同步棋子()
	游戏.执行行动({"编号": 2, "目标": Vector2i(0, 3)})
	检查(游戏.棋子节点表[3].状态.当前血量 == 1 and 游戏.棋子节点表[3].受击闪光 > 0, "unit receives damage feedback")
	检查(游戏.当前阵营 == 1 and 游戏.棋盘[2].坐标 == Vector2i(0, 5), "nonlethal attack switches turn without moving attacker")
	await 保存预览("res://验证产物/血量预览.png")
	游戏.棋盘 = [
		{"编号": 0, "阵营": 0, "棋种": 0, "坐标": Vector2i(3, 9), "当前血量": 1, "最大血量": 1},
		{"编号": 1, "阵营": 1, "棋种": 0, "坐标": Vector2i(4, 0), "当前血量": 1, "最大血量": 1},
		{"编号": 2, "阵营": 0, "棋种": 4, "坐标": Vector2i(3, 2), "当前血量": 1, "最大血量": 1},
		{"编号": 3, "阵营": 0, "棋种": 4, "坐标": Vector2i(5, 2), "当前血量": 1, "最大血量": 1},
		{"编号": 4, "阵营": 0, "棋种": 4, "坐标": Vector2i(4, 3), "当前血量": 1, "最大血量": 1}]
	游戏.当前阵营 = 1
	游戏.已结束 = false
	游戏.更新回合()
	检查(游戏.已结束 and 游戏.状态标签.text == "你获胜了" and "被将死" in 游戏.详情标签.text, "checkmate displays victory")
	游戏.棋盘[4].坐标 = Vector2i(0, 1)
	游戏.已结束 = false
	游戏.更新回合()
	检查(游戏.已结束 and "无合法行动" in 游戏.详情标签.text, "stalemate displays victory")
	游戏.当前阵营 = 0
	游戏.棋盘 = [游戏.棋盘[0], 游戏.棋盘[1]]
	游戏.棋盘[0].坐标 = Vector2i(4, 9)
	游戏.棋盘.append({"编号": 2, "阵营": 1, "棋种": 4, "坐标": Vector2i(3, 7), "当前血量": 1, "最大血量": 1})
	游戏.棋盘.append({"编号": 3, "阵营": 1, "棋种": 4, "坐标": Vector2i(5, 7), "当前血量": 1, "最大血量": 1})
	游戏.棋盘.append({"编号": 4, "阵营": 1, "棋种": 4, "坐标": Vector2i(4, 6), "当前血量": 1, "最大血量": 1})
	游戏.已结束 = false
	游戏.更新回合()
	检查(游戏.已结束 and 游戏.状态标签.text == "本局落败", "player checkmate displays defeat")
	# Save a separate fixture, edit its disk content and verify restart reloads it.
	自定义开局 = load("res://配置/默认开局.tres").duplicate(true)
	自定义开局.resource_path = ""
	检查(ResourceSaver.save(自定义开局, "res://验证产物/重载开局.tres") == OK, "save reload fixture")
	游戏.开局 = load("res://验证产物/重载开局.tres")
	游戏.重新开局()
	var 修改开局: 开局配置 = 自定义开局.duplicate(true)
	修改开局.resource_path = ""
	修改开局.棋子列表[0].血量 = 7
	修改开局.棋子列表[0].棋盘位置 = Vector2i(0, 8)
	检查(ResourceSaver.save(修改开局, "res://验证产物/重载开局.tres") == OK, "update reload fixture on disk")
	游戏.重新开局()
	检查(not 游戏.棋盘.is_empty(), "reload setup valid: " + 游戏.详情标签.text)
	if not 游戏.棋盘.is_empty():
		检查(游戏.棋盘[0].当前血量 == 7 and 游戏.棋盘[0].坐标 == Vector2i(0, 8), "restart reloads saved disk configuration")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(语言管理.偏好文件))
	print("Scene: %d checks, %d failures" % [检查数, 失败数])
	游戏.queue_free()
	await process_frame
	quit(0 if 失败数 == 0 else 1)
