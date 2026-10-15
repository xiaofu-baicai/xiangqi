class_name XiangqiRules
extends RefCounted

static func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < 9 and p.y >= 0 and p.y < 10

static func in_palace(p: Vector2i, side: int) -> bool:
	return p.x >= 3 and p.x <= 5 and (p.y >= 7 and p.y <= 9 if side == 0 else p.y >= 0 and p.y <= 2)

static func from_setup(setup: GameSetup) -> Array:
	var board: Array = []
	for i in setup.pieces.size():
		var p := setup.pieces[i]
		board.append({"id": i, "side": p.side, "kind": p.kind, "pos": p.position, "hp": p.health, "max_hp": p.health})
	return board

static func at(board: Array, pos: Vector2i) -> Dictionary:
	for p: Dictionary in board:
		if p.pos == pos:
			return p
	return {}

static func king(board: Array, side: int) -> Dictionary:
	for p: Dictionary in board:
		if p.side == side and p.kind == PieceSetup.Kind.KING:
			return p
	return {}

static func blockers(board: Array, a: Vector2i, b: Vector2i) -> int:
	var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var cursor := a + step
	var count := 0
	while cursor != b:
		if not at(board, cursor).is_empty():
			count += 1
		cursor += step
	return count

static func facing(board: Array) -> bool:
	var a := king(board, 0)
	var b := king(board, 1)
	return not a.is_empty() and not b.is_empty() and a.pos.x == b.pos.x and blockers(board, a.pos, b.pos) == 0

# Geometric movement only. Check detection must not recursively generate legal moves.
static func pseudo(board: Array, p: Dictionary, target: Vector2i) -> bool:
	if not inside(target) or target == p.pos:
		return false
	var victim := at(board, target)
	if not victim.is_empty() and victim.side == p.side:
		return false
	var d: Vector2i = target - p.pos
	var dx := absi(d.x)
	var dy := absi(d.y)
	match p.kind:
		PieceSetup.Kind.KING:
			return dx + dy == 1 and in_palace(target, p.side)
		PieceSetup.Kind.ADVISOR:
			return dx == 1 and dy == 1 and in_palace(target, p.side)
		PieceSetup.Kind.ELEPHANT:
			return dx == 2 and dy == 2 and (target.y >= 5 if p.side == 0 else target.y <= 4) and at(board, p.pos + Vector2i(d.x / 2, d.y / 2)).is_empty()
		PieceSetup.Kind.HORSE:
			if not ((dx == 2 and dy == 1) or (dx == 1 and dy == 2)):
				return false
			var leg := Vector2i(signi(d.x), 0) if dx == 2 else Vector2i(0, signi(d.y))
			return at(board, p.pos + leg).is_empty()
		PieceSetup.Kind.ROOK, PieceSetup.Kind.CANNON:
			if d.x != 0 and d.y != 0:
				return false
			var count := blockers(board, p.pos, target)
			return count == (1 if p.kind == PieceSetup.Kind.CANNON and not victim.is_empty() else 0)
		PieceSetup.Kind.PAWN:
			var forward := -1 if p.side == 0 else 1
			var crossed: bool = p.pos.y <= 4 if p.side == 0 else p.pos.y >= 5
			return (d.x == 0 and d.y == forward) or (crossed and dx == 1 and d.y == 0)
	return false

static func in_check(board: Array, side: int) -> bool:
	var k := king(board, side)
	if k.is_empty() or facing(board):
		return true
	if k.hp > 1:
		return false
	for p: Dictionary in board:
		if p.side != side and pseudo(board, p, k.pos):
			return true
	return false

static func apply(board: Array, action: Dictionary) -> Array:
	var result: Array = board.duplicate(true)
	var mover: Dictionary = {}
	for p: Dictionary in result:
		if p.id == action.id:
			mover = p
	var victim := at(result, action.to)
	if not victim.is_empty():
		victim.hp -= 1
		if victim.hp > 0:
			return result
		result.erase(victim)
	mover.pos = action.to
	return result

static func legal(board: Array, p: Dictionary, target: Vector2i) -> bool:
	return pseudo(board, p, target) and not in_check(apply(board, {"id": p.id, "to": target}), p.side)

static func actions(board: Array, side: int) -> Array:
	var result: Array = []
	for p: Dictionary in board:
		if p.side != side:
			continue
		for y in 10:
			for x in 9:
				var target := Vector2i(x, y)
				if legal(board, p, target):
					result.append({"id": p.id, "to": target})
	return result
