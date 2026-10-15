class_name XiangqiAI
extends RefCounted

const VALUES := [10000.0, 120.0, 120.0, 300.0, 600.0, 350.0, 90.0]

static func evaluate(board: Array, side: int) -> float:
	if XiangqiRules.king(board, side).is_empty():
		return -1000000.0
	if XiangqiRules.king(board, 1 - side).is_empty():
		return 1000000.0
	var score := 0.0
	for p: Dictionary in board:
		var value: float = VALUES[p.kind] * (1.0 + 0.35 * (p.hp - 1))
		value += (4 - absi(p.pos.x - 4)) * 2.0
		if p.kind == PieceSetup.Kind.PAWN:
			value += (9 - p.pos.y if p.side == 0 else p.pos.y) * 8.0
		score += value if p.side == side else -value
	if XiangqiRules.in_check(board, side):
		score -= 45.0
	if XiangqiRules.in_check(board, 1 - side):
		score += 45.0
	return score

static func choose(board: Array, side: int) -> Dictionary:
	var moves := XiangqiRules.actions(board, side)
	var best := -INF
	var choices: Array = []
	for move: Dictionary in moves:
		var next := XiangqiRules.apply(board, move)
		var replies := XiangqiRules.actions(next, 1 - side)
		var score := 1000000.0 if replies.is_empty() else INF
		for reply: Dictionary in replies:
			score = minf(score, evaluate(XiangqiRules.apply(next, reply), side))
			if score < best:
				break
		if score > best:
			best = score
			choices = [move]
		elif is_equal_approx(score, best):
			choices.append(move)
	return choices.pick_random() if not choices.is_empty() else {}
