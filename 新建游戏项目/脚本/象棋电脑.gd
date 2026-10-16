class_name 象棋电脑
extends RefCounted

const 棋子价值 := [10000.0, 120.0, 120.0, 300.0, 600.0, 350.0, 90.0]

static func 评估(棋盘: Array, 阵营: int) -> float:
	if 象棋规则.查找将帅(棋盘, 阵营).is_empty():
		return -1000000.0
	if 象棋规则.查找将帅(棋盘, 1 - 阵营).is_empty():
		return 1000000.0
	var 分数 := 0.0
	for 棋子: Dictionary in 棋盘:
		var 数值: float = 棋子价值[棋子.棋种] * (1.0 + 0.35 * (棋子.当前血量 - 1))
		数值 += (4 - absi(棋子.坐标.x - 4)) * 2.0
		if 棋子.棋种 == 棋子配置.棋种类型.兵卒:
			数值 += (9 - 棋子.坐标.y if 棋子.阵营 == 0 else 棋子.坐标.y) * 8.0
		分数 += 数值 if 棋子.阵营 == 阵营 else -数值
	if 象棋规则.被将军(棋盘, 阵营):
		分数 -= 45.0
	if 象棋规则.被将军(棋盘, 1 - 阵营):
		分数 += 45.0
	return 分数

static func 选择行动(棋盘: Array, 阵营: int) -> Dictionary:
	var 行动列表 := 象棋规则.获取行动(棋盘, 阵营)
	var 最优分数 := -INF
	var 最优行动列表: Array = []
	for 候选行动: Dictionary in 行动列表:
		var 后续棋盘 := 象棋规则.应用行动(棋盘, 候选行动)
		var 应对列表 := 象棋规则.获取行动(后续棋盘, 1 - 阵营)
		var 分数 := 1000000.0 if 应对列表.is_empty() else INF
		for 应对: Dictionary in 应对列表:
			分数 = minf(分数, 评估(象棋规则.应用行动(后续棋盘, 应对), 阵营))
			if 分数 < 最优分数:
				break
		if 分数 > 最优分数:
			最优分数 = 分数
			最优行动列表 = [候选行动]
		elif is_equal_approx(分数, 最优分数):
			最优行动列表.append(候选行动)
	return 最优行动列表.pick_random() if not 最优行动列表.is_empty() else {}
