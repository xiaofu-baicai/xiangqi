extends SceneTree

var 检查数 := 0
var 失败数 := 0

func 检查(数值: bool, 描述: String) -> void:
	检查数 += 1
	if not 数值:
		失败数 += 1
		push_error("FAIL: " + 描述)

func 添加棋子(棋盘: Array, 阵营: int, 棋种: int, 坐标: Vector2i, 当前血量: int = 1) -> Dictionary:
	var 棋子实例 := {"编号": 棋盘.size(), "阵营": 阵营, "棋种": 棋种, "坐标": 坐标, "当前血量": 当前血量, "最大血量": 当前血量}
	棋盘.append(棋子实例)
	return 棋子实例

func 基础棋盘() -> Array:
	var 棋盘: Array = []
	添加棋子(棋盘, 0, 0, Vector2i(3, 9))
	添加棋子(棋盘, 1, 0, Vector2i(5, 0))
	return 棋盘

func _initialize() -> void:
	var 开局: 开局配置 = load("res://配置/默认开局.tres")
	检查(开局.验证().is_empty(), "default setup valid")
	var 测试棋盘 := 象棋规则.从配置生成(开局)
	检查(测试棋盘.size() == 32 and 开局.先手阵营 == 棋子配置.阵营类型.红方 and 开局.玩家阵营 == 棋子配置.阵营类型.红方, "32 units and red player first")
	检查(象棋规则.获取行动(测试棋盘, 0).size() == 44, "standard opening has 44 legal actions")
	检查(象棋规则.获取行动(测试棋盘, 1).size() == 44, "red opening has 44 legal actions")
	for 阵营 in 2:
		var 分类计数 := [0, 0, 0, 0, 0, 0, 0]
		for 棋子实例: Dictionary in 测试棋盘:
			if 棋子实例.阵营 == 阵营:
				分类计数[棋子实例.棋种] += 1
		检查(分类计数 == [1, 2, 2, 2, 2, 2, 5], "standard kinds for side %d" % 阵营)

	测试棋盘 = 基础棋盘()
	var 车棋 := 添加棋子(测试棋盘, 0, 4, Vector2i(0, 5))
	检查(象棋规则.合法行动(测试棋盘, 车棋, Vector2i(0, 1)), "rook moves along clear file")
	检查(not 象棋规则.符合走法(测试棋盘, 车棋, Vector2i(1, 4)), "rook cannot move diagonally")
	添加棋子(测试棋盘, 0, 6, Vector2i(0, 3))
	检查(not 象棋规则.符合走法(测试棋盘, 车棋, Vector2i(0, 1)), "rook blocked")
	检查(not 象棋规则.符合走法(测试棋盘, 车棋, Vector2i(0, 3)), "cannot capture ally")

	测试棋盘 = 基础棋盘()
	var 马棋 := 添加棋子(测试棋盘, 0, 3, Vector2i(2, 5))
	检查(象棋规则.合法行动(测试棋盘, 马棋, Vector2i(3, 3)), "horse legal L step")
	添加棋子(测试棋盘, 1, 6, Vector2i(2, 4))
	检查(not 象棋规则.符合走法(测试棋盘, 马棋, Vector2i(3, 3)), "horse leg blocked")
	检查(象棋规则.符合走法(测试棋盘, 马棋, Vector2i(4, 4)), "other horse leg stays free")

	测试棋盘 = 基础棋盘()
	var 象棋 := 添加棋子(测试棋盘, 0, 2, Vector2i(2, 7))
	检查(象棋规则.合法行动(测试棋盘, 象棋, Vector2i(4, 5)), "elephant legal diagonal")
	添加棋子(测试棋盘, 1, 6, Vector2i(3, 6))
	检查(not 象棋规则.符合走法(测试棋盘, 象棋, Vector2i(4, 5)), "elephant eye blocked")
	象棋.坐标 = Vector2i(2, 5)
	检查(not 象棋规则.符合走法(测试棋盘, 象棋, Vector2i(4, 3)), "black elephant cannot cross river")
	var 红象 := 添加棋子(测试棋盘, 1, 2, Vector2i(6, 4))
	检查(not 象棋规则.符合走法(测试棋盘, 红象, Vector2i(4, 6)), "red elephant cannot cross river")

	测试棋盘 = 基础棋盘()
	var 士棋 := 添加棋子(测试棋盘, 0, 1, Vector2i(4, 8))
	检查(象棋规则.符合走法(测试棋盘, 士棋, Vector2i(5, 7)), "advisor diagonal in palace")
	检查(not 象棋规则.符合走法(测试棋盘, 士棋, Vector2i(3, 7) + Vector2i(-1, -1)), "advisor cannot leave palace")
	检查(象棋规则.符合走法(测试棋盘, 测试棋盘[0], Vector2i(3, 8)), "king one orthogonal step")
	检查(not 象棋规则.符合走法(测试棋盘, 测试棋盘[0], Vector2i(2, 9)), "king cannot leave palace")
	检查(not 象棋规则.符合走法(测试棋盘, 测试棋盘[0], Vector2i(4, 8)), "king cannot move diagonally")

	测试棋盘 = 基础棋盘()
	var 炮棋 := 添加棋子(测试棋盘, 0, 5, Vector2i(0, 7))
	添加棋子(测试棋盘, 1, 4, Vector2i(0, 1))
	检查(not 象棋规则.符合走法(测试棋盘, 炮棋, Vector2i(0, 1)), "cannon capture needs screen")
	检查(象棋规则.符合走法(测试棋盘, 炮棋, Vector2i(0, 2)), "cannon noncapture without screen")
	添加棋子(测试棋盘, 0, 6, Vector2i(0, 4))
	检查(象棋规则.合法行动(测试棋盘, 炮棋, Vector2i(0, 1)), "cannon captures with one screen")
	检查(not 象棋规则.符合走法(测试棋盘, 炮棋, Vector2i(0, 2)), "cannon cannot hop to empty square")
	添加棋子(测试棋盘, 1, 6, Vector2i(0, 3))
	检查(not 象棋规则.符合走法(测试棋盘, 炮棋, Vector2i(0, 1)), "two screens block cannon")

	测试棋盘 = 基础棋盘()
	var 卒棋 := 添加棋子(测试棋盘, 0, 6, Vector2i(2, 6))
	检查(象棋规则.符合走法(测试棋盘, 卒棋, Vector2i(2, 5)), "black pawn forward")
	检查(not 象棋规则.符合走法(测试棋盘, 卒棋, Vector2i(3, 6)), "pawn cannot go sideways before river")
	卒棋.坐标 = Vector2i(2, 4)
	检查(象棋规则.符合走法(测试棋盘, 卒棋, Vector2i(3, 4)), "pawn sideways after river")
	检查(not 象棋规则.符合走法(测试棋盘, 卒棋, Vector2i(2, 5)), "pawn never backwards")
	var 红兵 := 添加棋子(测试棋盘, 1, 6, Vector2i(6, 3))
	检查(象棋规则.符合走法(测试棋盘, 红兵, Vector2i(6, 4)), "red pawn forward reversed")
	红兵.坐标 = Vector2i(6, 5)
	检查(象棋规则.符合走法(测试棋盘, 红兵, Vector2i(7, 5)), "red pawn crossed river")

	测试棋盘 = 基础棋盘()
	测试棋盘[0].坐标 = Vector2i(4, 9)
	测试棋盘[1].坐标 = Vector2i(4, 0)
	测试棋盘[0].当前血量 = 3
	测试棋盘[1].当前血量 = 3
	检查(象棋规则.将帅照面(测试棋盘) and 象棋规则.被将军(测试棋盘, 0), "facing forbidden even with multi HP")
	var 遮挡棋子 := 添加棋子(测试棋盘, 0, 4, Vector2i(4, 5))
	检查(not 象棋规则.将帅照面(测试棋盘), "intervening piece prevents facing")
	检查(not 象棋规则.合法行动(测试棋盘, 遮挡棋子, Vector2i(3, 5)), "cannot expose facing generals")

	测试棋盘 = 基础棋盘()
	添加棋子(测试棋盘, 1, 4, Vector2i(3, 0))
	检查(象棋规则.被将军(测试棋盘, 0), "rook checks one HP king")
	检查(not 象棋规则.合法行动(测试棋盘, 测试棋盘[0], Vector2i(3, 8)), "king cannot stay on attacked file")
	检查(象棋规则.合法行动(测试棋盘, 测试棋盘[0], Vector2i(4, 9)), "king can escape check")
	测试棋盘[0].当前血量 = 2
	检查(not 象棋规则.被将军(测试棋盘, 0), "nonlethal attack is not check")
	var 受击棋盘 := 象棋规则.应用行动(测试棋盘, {"编号": 2, "目标": Vector2i(3, 9)})
	检查(受击棋盘[0].当前血量 == 1 and 受击棋盘[2].坐标 == Vector2i(3, 0), "king survives damage and attacker stays")
	检查(象棋规则.被将军(受击棋盘, 0), "king now faces lethal threat")
	检查(测试棋盘[0].当前血量 == 2, "simulation never mutates real state")

	测试棋盘 = 基础棋盘()
	车棋 = 添加棋子(测试棋盘, 0, 4, Vector2i(0, 5))
	var 目标棋子 := 添加棋子(测试棋盘, 1, 3, Vector2i(0, 3), 2)
	受击棋盘 = 象棋规则.应用行动(测试棋盘, {"编号": 车棋.编号, "目标": 目标棋子.坐标})
	检查(受击棋盘.size() == 4 and 受击棋盘[2].坐标 == 车棋.坐标 and 受击棋盘[3].当前血量 == 1, "surviving target loses one HP without movement")
	var 吃子棋盘 := 象棋规则.应用行动(受击棋盘, {"编号": 车棋.编号, "目标": 目标棋子.坐标})
	检查(吃子棋盘.size() == 3 and 吃子棋盘[2].坐标 == 目标棋子.坐标, "lethal capture occupies target")
	检查(目标棋子.当前血量 == 2, "damage simulation leaves original HP intact")

	# Red king has no safe escape. Moving the checking rook off the file creates stalemate.
	测试棋盘 = []
	添加棋子(测试棋盘, 0, 0, Vector2i(3, 9))
	添加棋子(测试棋盘, 1, 0, Vector2i(4, 0))
	添加棋子(测试棋盘, 0, 4, Vector2i(3, 2))
	添加棋子(测试棋盘, 0, 4, Vector2i(5, 2))
	添加棋子(测试棋盘, 0, 4, Vector2i(4, 3))
	检查(象棋规则.被将军(测试棋盘, 1) and 象棋规则.获取行动(测试棋盘, 1).is_empty(), "checkmate has no safe action")
	测试棋盘[4].坐标 = Vector2i(0, 1)
	检查(not 象棋规则.被将军(测试棋盘, 1) and 象棋规则.获取行动(测试棋盘, 1).is_empty(), "stalemate also loses")

	var 无效开局: 开局配置 = 开局.duplicate(true)
	无效开局.棋子列表[1].棋盘位置 = 无效开局.棋子列表[0].棋盘位置
	检查(not 无效开局.验证().is_empty(), "duplicate coordinate rejected")
	无效开局 = 开局.duplicate(true)
	无效开局.棋子列表[0].棋盘位置 = Vector2i(-1, 0)
	检查(not 无效开局.验证().is_empty(), "out of bounds rejected")
	无效开局 = 开局.duplicate(true)
	无效开局.棋子列表[0].血量 = 0
	检查(not 无效开局.验证().is_empty(), "nonpositive HP rejected")
	无效开局 = 开局.duplicate(true)
	无效开局.棋子列表[4].棋种 = 棋子配置.棋种类型.兵卒
	检查(not 无效开局.验证().is_empty(), "missing king rejected")
	无效开局 = 开局.duplicate(true)
	无效开局.棋子列表[4].棋盘位置 = Vector2i(4, 5)
	检查(not 无效开局.验证().is_empty(), "king outside palace rejected")
	无效开局 = 开局.duplicate(true)
	for 序号 in range(无效开局.棋子列表.size() - 1, -1, -1):
		if 无效开局.棋子列表[序号].棋种 != 棋子配置.棋种类型.将帅:
			无效开局.棋子列表.remove_at(序号)
	检查(not 无效开局.验证().is_empty(), "facing opening rejected")
	无效开局.棋子列表[0].棋盘位置 = Vector2i(3, 9)
	无效开局.棋子列表[1].棋盘位置 = Vector2i(5, 0)
	无效开局.棋子列表[0].血量 = 3
	无效开局.玩家阵营 = 棋子配置.阵营类型.红方
	无效开局.先手阵营 = 棋子配置.阵营类型.红方
	检查(无效开局.验证().is_empty(), "custom count, HP, side and first turn accepted")
	var 开始时刻 := Time.get_ticks_msec()
	测试棋盘 = 象棋规则.从配置生成(开局)
	var 电脑行动 := 象棋电脑.选择行动(测试棋盘, 1)
	检查(not 电脑行动.is_empty() and 电脑行动 in 象棋规则.获取行动(测试棋盘, 1), "AI selects legal action")
	print("AI opening search: %d ms" % (Time.get_ticks_msec() - 开始时刻))
	print("Rules: %d checks, %d failures" % [检查数, 失败数])
	quit(0 if 失败数 == 0 else 1)
