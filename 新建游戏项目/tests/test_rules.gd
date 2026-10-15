extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func add(board: Array, side: int, kind: int, pos: Vector2i, hp: int = 1) -> Dictionary:
	var unit := {"id": board.size(), "side": side, "kind": kind, "pos": pos, "hp": hp, "max_hp": hp}
	board.append(unit)
	return unit

func base() -> Array:
	var board: Array = []
	add(board, 0, 0, Vector2i(3, 9))
	add(board, 1, 0, Vector2i(5, 0))
	return board

func _initialize() -> void:
	var setup: GameSetup = load("res://config/default_setup.tres")
	expect(setup.validate().is_empty(), "default setup valid")
	var b := XiangqiRules.from_setup(setup)
	expect(b.size() == 32 and setup.first_side == 0 and setup.player_side == 0, "32 units and black player first")
	expect(XiangqiRules.actions(b, 0).size() == 44, "standard opening has 44 legal actions")
	expect(XiangqiRules.actions(b, 1).size() == 44, "red opening has 44 legal actions")
	for side in 2:
		var counts := [0, 0, 0, 0, 0, 0, 0]
		for unit: Dictionary in b:
			if unit.side == side:
				counts[unit.kind] += 1
		expect(counts == [1, 2, 2, 2, 2, 2, 5], "standard kinds for side %d" % side)

	b = base()
	var rook := add(b, 0, 4, Vector2i(0, 5))
	expect(XiangqiRules.legal(b, rook, Vector2i(0, 1)), "rook moves along clear file")
	expect(not XiangqiRules.pseudo(b, rook, Vector2i(1, 4)), "rook cannot move diagonally")
	add(b, 0, 6, Vector2i(0, 3))
	expect(not XiangqiRules.pseudo(b, rook, Vector2i(0, 1)), "rook blocked")
	expect(not XiangqiRules.pseudo(b, rook, Vector2i(0, 3)), "cannot capture ally")

	b = base()
	var horse := add(b, 0, 3, Vector2i(2, 5))
	expect(XiangqiRules.legal(b, horse, Vector2i(3, 3)), "horse legal L step")
	add(b, 1, 6, Vector2i(2, 4))
	expect(not XiangqiRules.pseudo(b, horse, Vector2i(3, 3)), "horse leg blocked")
	expect(XiangqiRules.pseudo(b, horse, Vector2i(4, 4)), "other horse leg stays free")

	b = base()
	var elephant := add(b, 0, 2, Vector2i(2, 7))
	expect(XiangqiRules.legal(b, elephant, Vector2i(4, 5)), "elephant legal diagonal")
	add(b, 1, 6, Vector2i(3, 6))
	expect(not XiangqiRules.pseudo(b, elephant, Vector2i(4, 5)), "elephant eye blocked")
	elephant.pos = Vector2i(2, 5)
	expect(not XiangqiRules.pseudo(b, elephant, Vector2i(4, 3)), "black elephant cannot cross river")
	var red_elephant := add(b, 1, 2, Vector2i(6, 4))
	expect(not XiangqiRules.pseudo(b, red_elephant, Vector2i(4, 6)), "red elephant cannot cross river")

	b = base()
	var advisor := add(b, 0, 1, Vector2i(4, 8))
	expect(XiangqiRules.pseudo(b, advisor, Vector2i(5, 7)), "advisor diagonal in palace")
	expect(not XiangqiRules.pseudo(b, advisor, Vector2i(3, 7) + Vector2i(-1, -1)), "advisor cannot leave palace")
	expect(XiangqiRules.pseudo(b, b[0], Vector2i(3, 8)), "king one orthogonal step")
	expect(not XiangqiRules.pseudo(b, b[0], Vector2i(2, 9)), "king cannot leave palace")
	expect(not XiangqiRules.pseudo(b, b[0], Vector2i(4, 8)), "king cannot move diagonally")

	b = base()
	var cannon := add(b, 0, 5, Vector2i(0, 7))
	add(b, 1, 4, Vector2i(0, 1))
	expect(not XiangqiRules.pseudo(b, cannon, Vector2i(0, 1)), "cannon capture needs screen")
	expect(XiangqiRules.pseudo(b, cannon, Vector2i(0, 2)), "cannon noncapture without screen")
	add(b, 0, 6, Vector2i(0, 4))
	expect(XiangqiRules.legal(b, cannon, Vector2i(0, 1)), "cannon captures with one screen")
	expect(not XiangqiRules.pseudo(b, cannon, Vector2i(0, 2)), "cannon cannot hop to empty square")
	add(b, 1, 6, Vector2i(0, 3))
	expect(not XiangqiRules.pseudo(b, cannon, Vector2i(0, 1)), "two screens block cannon")

	b = base()
	var pawn := add(b, 0, 6, Vector2i(2, 6))
	expect(XiangqiRules.pseudo(b, pawn, Vector2i(2, 5)), "black pawn forward")
	expect(not XiangqiRules.pseudo(b, pawn, Vector2i(3, 6)), "pawn cannot go sideways before river")
	pawn.pos = Vector2i(2, 4)
	expect(XiangqiRules.pseudo(b, pawn, Vector2i(3, 4)), "pawn sideways after river")
	expect(not XiangqiRules.pseudo(b, pawn, Vector2i(2, 5)), "pawn never backwards")
	var red_pawn := add(b, 1, 6, Vector2i(6, 3))
	expect(XiangqiRules.pseudo(b, red_pawn, Vector2i(6, 4)), "red pawn forward reversed")
	red_pawn.pos = Vector2i(6, 5)
	expect(XiangqiRules.pseudo(b, red_pawn, Vector2i(7, 5)), "red pawn crossed river")

	b = base()
	b[0].pos = Vector2i(4, 9)
	b[1].pos = Vector2i(4, 0)
	b[0].hp = 3
	b[1].hp = 3
	expect(XiangqiRules.facing(b) and XiangqiRules.in_check(b, 0), "facing forbidden even with multi HP")
	var shield := add(b, 0, 4, Vector2i(4, 5))
	expect(not XiangqiRules.facing(b), "intervening piece prevents facing")
	expect(not XiangqiRules.legal(b, shield, Vector2i(3, 5)), "cannot expose facing generals")

	b = base()
	add(b, 1, 4, Vector2i(3, 0))
	expect(XiangqiRules.in_check(b, 0), "rook checks one HP king")
	expect(not XiangqiRules.legal(b, b[0], Vector2i(3, 8)), "king cannot stay on attacked file")
	expect(XiangqiRules.legal(b, b[0], Vector2i(4, 9)), "king can escape check")
	b[0].hp = 2
	expect(not XiangqiRules.in_check(b, 0), "nonlethal attack is not check")
	var hit := XiangqiRules.apply(b, {"id": 2, "to": Vector2i(3, 9)})
	expect(hit[0].hp == 1 and hit[2].pos == Vector2i(3, 0), "king survives damage and attacker stays")
	expect(XiangqiRules.in_check(hit, 0), "king now faces lethal threat")
	expect(b[0].hp == 2, "simulation never mutates real state")

	b = base()
	rook = add(b, 0, 4, Vector2i(0, 5))
	var victim := add(b, 1, 3, Vector2i(0, 3), 2)
	hit = XiangqiRules.apply(b, {"id": rook.id, "to": victim.pos})
	expect(hit.size() == 4 and hit[2].pos == rook.pos and hit[3].hp == 1, "surviving target loses one HP without movement")
	var kill := XiangqiRules.apply(hit, {"id": rook.id, "to": victim.pos})
	expect(kill.size() == 3 and kill[2].pos == victim.pos, "lethal capture occupies target")
	expect(victim.hp == 2, "damage simulation leaves original HP intact")

	# Red king has no safe escape. Moving the checking rook off the file creates stalemate.
	b = []
	add(b, 0, 0, Vector2i(3, 9))
	add(b, 1, 0, Vector2i(4, 0))
	add(b, 0, 4, Vector2i(3, 2))
	add(b, 0, 4, Vector2i(5, 2))
	add(b, 0, 4, Vector2i(4, 3))
	expect(XiangqiRules.in_check(b, 1) and XiangqiRules.actions(b, 1).is_empty(), "checkmate has no safe action")
	b[4].pos = Vector2i(0, 1)
	expect(not XiangqiRules.in_check(b, 1) and XiangqiRules.actions(b, 1).is_empty(), "stalemate also loses")

	var invalid: GameSetup = setup.duplicate(true)
	invalid.pieces[1].position = invalid.pieces[0].position
	expect(not invalid.validate().is_empty(), "duplicate coordinate rejected")
	invalid = setup.duplicate(true)
	invalid.pieces[0].position = Vector2i(-1, 0)
	expect(not invalid.validate().is_empty(), "out of bounds rejected")
	invalid = setup.duplicate(true)
	invalid.pieces[0].health = 0
	expect(not invalid.validate().is_empty(), "nonpositive HP rejected")
	invalid = setup.duplicate(true)
	invalid.pieces[4].kind = PieceSetup.Kind.PAWN
	expect(not invalid.validate().is_empty(), "missing king rejected")
	invalid = setup.duplicate(true)
	invalid.pieces[4].position = Vector2i(4, 5)
	expect(not invalid.validate().is_empty(), "king outside palace rejected")
	invalid = setup.duplicate(true)
	for i in range(invalid.pieces.size() - 1, -1, -1):
		if invalid.pieces[i].kind != PieceSetup.Kind.KING:
			invalid.pieces.remove_at(i)
	expect(not invalid.validate().is_empty(), "facing opening rejected")
	invalid.pieces[0].position = Vector2i(3, 9)
	invalid.pieces[1].position = Vector2i(5, 0)
	invalid.pieces[0].health = 3
	invalid.player_side = PieceSetup.Team.RED
	invalid.first_side = PieceSetup.Team.RED
	expect(invalid.validate().is_empty(), "custom count, HP, side and first turn accepted")
	var before := Time.get_ticks_msec()
	b = XiangqiRules.from_setup(setup)
	var ai := XiangqiAI.choose(b, 1)
	expect(not ai.is_empty() and ai in XiangqiRules.actions(b, 1), "AI selects legal action")
	print("AI opening search: %d ms" % (Time.get_ticks_msec() - before))
	print("Rules: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
