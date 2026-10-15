extends SceneTree

var checks := 0
var failures := 0
var game: Node2D

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func click(cell: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.point(cell)
	game._unhandled_input(event)

func _initialize() -> void:
	call_deferred("run")

func save_preview(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	expect(picture.save_png(path) == OK, "saved " + path)

func wait_ai() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while (game.thinking or game.thread != null) and Time.get_ticks_msec() < deadline:
		await process_frame
	expect(not game.thinking and game.thread == null, "AI finishes within 15 seconds")

func run() -> void:
	root.size = Vector2i(1440, 1000)
	root.content_scale_size = Vector2i(1440, 1000)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	expect(game.board.size() == 32 and game.units.size() == 32, "scene contains 32 independent units")
	expect(game.turn == 0 and not game.finished and not game.thinking, "black player starts")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	await save_preview("res://artifacts/board_preview.png")
	click(Vector2i(0, 6))
	expect(game.selected_id >= 0 and Vector2i(0, 5) in game.destinations, "select pawn and show legal target")
	var selected: int = game.selected_id
	click(Vector2i(1, 5))
	expect(game.turn == 0 and game.move_count == 0, "invalid target does not consume turn")
	click(Vector2i(0, 6))
	click(Vector2i(0, 5))
	expect(game.turn == 1 and game.thinking and game.move_count == 1, "player action consumes turn")
	expect(XiangqiRules.at(game.board, Vector2i(0, 5)).id == selected, "pawn moved to clicked target")
	click(Vector2i(2, 6))
	expect(game.selected_id == -1 and game.move_count == 1, "input locked during AI turn")
	game.set_process(true)
	await wait_ai()
	expect(game.turn == 0 and game.move_count == 2, "AI returns turn to player")
	for i in 3:
		var moves := XiangqiRules.actions(game.board, 0)
		expect(not moves.is_empty(), "player can continue game")
		game.execute(moves[0])
		await wait_ai()
	expect(game.move_count == 8 and not game.finished, "four consecutive player and AI turns")
	game.set_process(false)
	game.new_game()
	root.size = Vector2i(960, 700)
	await save_preview("res://artifacts/board_small.png")
	click(Vector2i(2, 6))
	click(Vector2i(2, 5))
	expect(game.turn == 1 and XiangqiRules.at(game.board, Vector2i(2, 5)).side == 0, "logical picking remains accurate in resized viewport")
	var logical: Vector2 = game.point(Vector2i(2, 5))
	var window_point: Vector2 = root.get_final_transform() * logical
	expect((root.get_final_transform().affine_inverse() * window_point).distance_to(logical) < 0.01, "stretch transform round trips board point")

	var custom: GameSetup = load("res://config/default_setup.tres").duplicate(true)
	# A duplicate resource must be detached to test in-memory custom setups.
	custom.resource_path = ""
	custom.player_side = PieceSetup.Team.RED
	custom.first_side = PieceSetup.Team.RED
	custom.pieces[0].health = 4
	custom.pieces[9].kind = PieceSetup.Kind.HORSE
	custom.pieces[9].position = Vector2i(1, 6)
	custom.pieces.remove_at(10)
	game.setup = custom
	game.new_game()
	expect(game.board.size() == 31 and game.board[0].hp == 4 and game.board[9].kind == PieceSetup.Kind.HORSE, "custom count, HP, kind and location applied")
	expect(game.turn == 1 and not game.thinking, "custom player and first side applied")
	custom.pieces[0].health = 0
	game.new_game()
	expect(game.finished and game.status.text == "配置错误" and game.board.is_empty(), "configuration errors stop game with visible message")
	click(Vector2i(2, 3))
	expect(game.selected_id == -1, "input locked for invalid or finished game")

	custom = load("res://config/default_setup.tres").duplicate(true)
	custom.resource_path = ""
	custom.first_side = PieceSetup.Team.RED
	game.setup = custom
	game.new_game()
	game.set_process(true)
	await process_frame
	await process_frame
	expect(game.thread != null, "red first starts background search")
	custom.first_side = PieceSetup.Team.BLACK
	game.new_game()
	await wait_ai()
	expect(game.turn == 0 and game.move_count == 0 and game.board.size() == 32, "restart discards old AI result")
	# Trigger nonlethal attack in the real scene, including unit HP feedback.
	game.set_process(false)
	game.board = [
		{"id": 0, "side": 0, "kind": 0, "pos": Vector2i(3, 9), "hp": 1, "max_hp": 1},
		{"id": 1, "side": 1, "kind": 0, "pos": Vector2i(5, 0), "hp": 1, "max_hp": 1},
		{"id": 2, "side": 0, "kind": 4, "pos": Vector2i(0, 5), "hp": 1, "max_hp": 1},
		{"id": 3, "side": 1, "kind": 3, "pos": Vector2i(0, 3), "hp": 2, "max_hp": 2}]
	game.turn = 0
	game.thinking = false
	game.sync_units()
	game.execute({"id": 2, "to": Vector2i(0, 3)})
	expect(game.units[3].state.hp == 1 and game.units[3].damage_flash > 0, "unit receives damage feedback")
	expect(game.turn == 1 and game.board[2].pos == Vector2i(0, 5), "nonlethal attack switches turn without moving attacker")
	await save_preview("res://artifacts/health_preview.png")
	game.board = [
		{"id": 0, "side": 0, "kind": 0, "pos": Vector2i(3, 9), "hp": 1, "max_hp": 1},
		{"id": 1, "side": 1, "kind": 0, "pos": Vector2i(4, 0), "hp": 1, "max_hp": 1},
		{"id": 2, "side": 0, "kind": 4, "pos": Vector2i(3, 2), "hp": 1, "max_hp": 1},
		{"id": 3, "side": 0, "kind": 4, "pos": Vector2i(5, 2), "hp": 1, "max_hp": 1},
		{"id": 4, "side": 0, "kind": 4, "pos": Vector2i(4, 3), "hp": 1, "max_hp": 1}]
	game.turn = 1
	game.finished = false
	game.update_turn()
	expect(game.finished and game.status.text == "你获胜了" and "被将死" in game.detail.text, "checkmate displays victory")
	game.board[4].pos = Vector2i(0, 1)
	game.finished = false
	game.update_turn()
	expect(game.finished and "无合法行动" in game.detail.text, "stalemate displays victory")
	game.turn = 0
	game.board = [game.board[0], game.board[1]]
	game.board[0].pos = Vector2i(4, 9)
	game.board.append({"id": 2, "side": 1, "kind": 4, "pos": Vector2i(3, 7), "hp": 1, "max_hp": 1})
	game.board.append({"id": 3, "side": 1, "kind": 4, "pos": Vector2i(5, 7), "hp": 1, "max_hp": 1})
	game.board.append({"id": 4, "side": 1, "kind": 4, "pos": Vector2i(4, 6), "hp": 1, "max_hp": 1})
	game.finished = false
	game.update_turn()
	expect(game.finished and game.status.text == "本局落败", "player checkmate displays defeat")
	# Save a separate fixture, edit its disk content and verify restart reloads it.
	custom = load("res://config/default_setup.tres").duplicate(true)
	custom.resource_path = ""
	expect(ResourceSaver.save(custom, "res://artifacts/reload_setup.tres") == OK, "save reload fixture")
	game.setup = load("res://artifacts/reload_setup.tres")
	game.new_game()
	var changed: GameSetup = custom.duplicate(true)
	changed.resource_path = ""
	changed.pieces[0].health = 7
	changed.pieces[0].position = Vector2i(0, 8)
	expect(ResourceSaver.save(changed, "res://artifacts/reload_setup.tres") == OK, "update reload fixture on disk")
	game.new_game()
	expect(not game.board.is_empty(), "reload setup valid: " + game.detail.text)
	if not game.board.is_empty():
		expect(game.board[0].hp == 7 and game.board[0].pos == Vector2i(0, 8), "restart reloads saved disk configuration")
	print("Scene: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
