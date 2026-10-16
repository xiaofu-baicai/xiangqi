class_name 象棋规则
extends RefCounted

static func 位于棋盘(棋子: Vector2i) -> bool:
	return 棋子.x >= 0 and 棋子.x < 9 and 棋子.y >= 0 and 棋子.y < 10

static func 位于九宫(棋子: Vector2i, 阵营: int) -> bool:
	return 棋子.x >= 3 and 棋子.x <= 5 and (棋子.y >= 7 and 棋子.y <= 9 if 阵营 == 0 else 棋子.y >= 0 and 棋子.y <= 2)

static func 从配置生成(开局: 开局配置) -> Array:
	var 棋盘: Array = []
	for 序号 in 开局.棋子列表.size():
		var 棋子 := 开局.棋子列表[序号]
		棋盘.append({"编号": 序号, "阵营": 棋子.阵营, "棋种": 棋子.棋种, "坐标": 棋子.棋盘位置, "当前血量": 棋子.血量, "最大血量": 棋子.血量, "攻击力": 1})
	return 棋盘

static func 查找棋子(棋盘: Array, 坐标: Vector2i) -> Dictionary:
	for 棋子: Dictionary in 棋盘:
		if 棋子.坐标 == 坐标:
			return 棋子
	return {}

static func 查找将帅(棋盘: Array, 阵营: int) -> Dictionary:
	for 棋子: Dictionary in 棋盘:
		if 棋子.阵营 == 阵营 and 棋子.棋种 == 棋子配置.棋种类型.将帅:
			return 棋子
	return {}

static func 统计阻挡(棋盘: Array, 起点: Vector2i, 终点: Vector2i) -> int:
	var 步长 := Vector2i(signi(终点.x - 起点.x), signi(终点.y - 起点.y))
	var 游标 := 起点 + 步长
	var 数量 := 0
	while 游标 != 终点:
		if not 查找棋子(棋盘, 游标).is_empty():
			数量 += 1
		游标 += 步长
	return 数量

static func 将帅照面(棋盘: Array) -> bool:
	var 起点 := 查找将帅(棋盘, 0)
	var 终点 := 查找将帅(棋盘, 1)
	return not 起点.is_empty() and not 终点.is_empty() and 起点.坐标.x == 终点.坐标.x and 统计阻挡(棋盘, 起点.坐标, 终点.坐标) == 0

# 只判断几何走法；判断将军时不能递归生成合法行动。
static func 符合走法(棋盘: Array, 棋子: Dictionary, 目标坐标: Vector2i) -> bool:
	if not 位于棋盘(目标坐标) or 目标坐标 == 棋子.坐标:
		return false
	var 目标棋子 := 查找棋子(棋盘, 目标坐标)
	if not 目标棋子.is_empty() and 目标棋子.阵营 == 棋子.阵营:
		return false
	var 位移: Vector2i = 目标坐标 - 棋子.坐标
	var 横距 := absi(位移.x)
	var 纵距 := absi(位移.y)
	match 棋子.棋种:
		棋子配置.棋种类型.将帅:
			return 横距 + 纵距 == 1 and 位于九宫(目标坐标, 棋子.阵营)
		棋子配置.棋种类型.士仕:
			return 横距 == 1 and 纵距 == 1 and 位于九宫(目标坐标, 棋子.阵营)
		棋子配置.棋种类型.象相:
			return 横距 == 2 and 纵距 == 2 and (目标坐标.y >= 5 if 棋子.阵营 == 0 else 目标坐标.y <= 4) and 查找棋子(棋盘, 棋子.坐标 + Vector2i(位移.x / 2, 位移.y / 2)).is_empty()
		棋子配置.棋种类型.马:
			if not ((横距 == 2 and 纵距 == 1) or (横距 == 1 and 纵距 == 2)):
				return false
			var 马腿 := Vector2i(signi(位移.x), 0) if 横距 == 2 else Vector2i(0, signi(位移.y))
			return 查找棋子(棋盘, 棋子.坐标 + 马腿).is_empty()
		棋子配置.棋种类型.车, 棋子配置.棋种类型.炮:
			if 位移.x != 0 and 位移.y != 0:
				return false
			var 数量 := 统计阻挡(棋盘, 棋子.坐标, 目标坐标)
			return 数量 == (1 if 棋子.棋种 == 棋子配置.棋种类型.炮 and not 目标棋子.is_empty() else 0)
		棋子配置.棋种类型.兵卒:
			var 前进方向 := -1 if 棋子.阵营 == 0 else 1
			var 已过河: bool = 棋子.坐标.y <= 4 if 棋子.阵营 == 0 else 棋子.坐标.y >= 5
			return (位移.x == 0 and 位移.y == 前进方向) or (已过河 and 横距 == 1 and 位移.y == 0)
	return false

static func 被将军(棋盘: Array, 阵营: int) -> bool:
	var 将帅数据 := 查找将帅(棋盘, 阵营)
	if 将帅数据.is_empty() or 将帅照面(棋盘):
		return true
	if 将帅数据.当前血量 > 1:
		return false
	for 棋子: Dictionary in 棋盘:
		if 棋子.阵营 != 阵营 and 符合走法(棋盘, 棋子, 将帅数据.坐标):
			return true
	return false

static func 应用行动(棋盘: Array, 行动: Dictionary) -> Array:
	var 结果: Array = 棋盘.duplicate(true)
	var 行动棋子: Dictionary = {}
	for 棋子: Dictionary in 结果:
		if 棋子.编号 == 行动.编号:
			行动棋子 = 棋子
	var 目标棋子 := 查找棋子(结果, 行动.目标)
	if not 目标棋子.is_empty():
		目标棋子.当前血量 -= maxi(1, int(行动棋子.get("攻击力", 1)))
		if 目标棋子.当前血量 > 0:
			return 结果
		结果.erase(目标棋子)
	行动棋子.坐标 = 行动.目标
	return 结果

static func 合法行动(棋盘: Array, 棋子: Dictionary, 目标坐标: Vector2i) -> bool:
	return 符合走法(棋盘, 棋子, 目标坐标) and not 被将军(应用行动(棋盘, {"编号": 棋子.编号, "目标": 目标坐标}), 棋子.阵营)

static func 获取行动(棋盘: Array, 阵营: int) -> Array:
	var 结果: Array = []
	for 棋子: Dictionary in 棋盘:
		if 棋子.阵营 != 阵营:
			continue
		for 纵坐标 in 10:
			for 横坐标 in 9:
				var 目标坐标 := Vector2i(横坐标, 纵坐标)
				if 合法行动(棋盘, 棋子, 目标坐标):
					结果.append({"编号": 棋子.编号, "目标": 目标坐标})
	return 结果

