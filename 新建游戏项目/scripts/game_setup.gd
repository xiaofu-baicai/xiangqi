class_name GameSetup
extends Resource

@export var player_side: PieceSetup.Team = PieceSetup.Team.BLACK
@export var first_side: PieceSetup.Team = PieceSetup.Team.BLACK
@export var pieces: Array[PieceSetup] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var occupied := {}
	var kings := [0, 0]
	for index in pieces.size():
		var p := pieces[index]
		if p == null:
			errors.append("第 %d 个棋子为空" % (index + 1))
			continue
		if p.side < 0 or p.side > 1 or p.kind < 0 or p.kind > 6:
			errors.append("第 %d 个棋子的阵营或种类无效" % (index + 1))
			continue
		if not XiangqiRules.inside(p.position):
			errors.append("第 %d 个棋子坐标越界：%s" % [index + 1, p.position])
		if occupied.has(p.position):
			errors.append("坐标 %s 存在重叠棋子" % p.position)
		occupied[p.position] = true
		if p.health < 1:
			errors.append("第 %d 个棋子的血量必须大于零" % (index + 1))
		if p.kind == PieceSetup.Kind.KING:
			kings[p.side] += 1
			if not XiangqiRules.in_palace(p.position, p.side):
				errors.append("将帅必须位于己方九宫")
	for side in 2:
		if kings[side] != 1:
			errors.append("%s必须恰好有一个将帅" % ("黑方" if side == 0 else "红方"))
	if player_side < 0 or player_side > 1 or first_side < 0 or first_side > 1:
		errors.append("玩家阵营或先手方无效")
	if errors.is_empty() and XiangqiRules.facing(XiangqiRules.from_setup(self)):
		errors.append("开局不得将帅照面")
	return errors
