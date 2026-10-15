extends Node2D

@export var setup: GameSetup
const UNIT_SCENE := preload("res://scenes/piece_unit.tscn")
const ORIGIN := Vector2(360, 195)
const STEP := 72.0
const INK := Color("384638")
var font: SystemFont
var board: Array = []
var units := {}
var selected_id := -1
var destinations: Array[Vector2i] = []
var turn := 0
var finished := false
var thinking := false
var generation := 0
var thread: Thread
var worker_generation := 0
var status: Label
var detail: Label
var restart: Button
var history: Label
var last_from := Vector2i(-1, -1)
var last_to := Vector2i(-1, -1)
var move_count := 0
var loaded_setup: GameSetup
var setup_path := ""

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["KaiTi", "STKaiti", "Noto Serif CJK SC", "Microsoft YaHei"])
	create_ui()
	new_game()

func label_at(text: String, pos: Vector2, size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func create_ui() -> void:
	label_at("墨弈", Vector2(100, 94), 66)
	label_at("山 水 入 局\n落 子 生 风", Vector2(104, 184), 18)
	label_at("象\n棋", Vector2(153, 335), 45)
	label_at("一局天地间", Vector2(116, 480), 20)
	label_at("对  弈", Vector2(1050, 213), 26)
	status = label_at("", Vector2(1050, 278), 30)
	detail = label_at("", Vector2(1050, 330), 19)
	detail.size = Vector2(280, 260)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history = label_at("", Vector2(1050, 585), 18)
	restart = Button.new()
	restart.text = "重新开局"
	restart.position = Vector2(1050, 680)
	restart.size = Vector2(235, 54)
	restart.add_theme_font_override("font", font)
	restart.add_theme_font_size_override("font_size", 23)
	restart.add_theme_color_override("font_color", Color("f7efd9"))
	for name in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("465b4c") if name == "normal" else Color("65785d")
		box.set_corner_radius_all(4)
		restart.add_theme_stylebox_override(name, box)
	restart.pressed.connect(new_game)
	add_child(restart)
	label_at("点击己方棋子，再点击落点\n圆点为移动，红环为攻击\n多血棋子受击存活时留在原位", Vector2(1050, 770), 16)
	label_at("水墨象棋  /  可配置开局", Vector2(100, 920), 16, Color("79816b"))

func new_game() -> void:
	generation += 1
	if setup != loaded_setup:
		setup_path = setup.resource_path if setup != null else ""
	if not setup_path.is_empty():
		# Load fresh subresources so fields omitted at their defaults cannot retain old values.
		setup = ResourceLoader.load(setup_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	loaded_setup = setup
	for unit: PieceUnit in units.values():
		unit.queue_free()
	units.clear()
	board.clear()
	selected_id = -1
	destinations.clear()
	last_from = Vector2i(-1, -1)
	last_to = Vector2i(-1, -1)
	move_count = 0
	finished = false
	thinking = false
	var errors := PackedStringArray(["主场景尚未指定 GameSetup 配置"])
	if setup != null:
		errors = setup.validate()
	if not errors.is_empty():
		finished = true
		status.text = "配置错误"
		detail.text = "\n".join(errors)
		history.text = "请修改开局资源后重开"
		queue_redraw()
		return
	board = XiangqiRules.from_setup(setup)
	turn = setup.first_side
	sync_units()
	update_turn()
	queue_redraw()

func sync_units() -> void:
	var alive := {}
	for p: Dictionary in board:
		alive[p.id] = true
		if not units.has(p.id):
			var unit: PieceUnit = UNIT_SCENE.instantiate()
			unit.font = font
			add_child(unit)
			units[p.id] = unit
		units[p.id].update_state(p, point(p.pos))
		units[p.id].selected = p.id == selected_id
	for id in units.keys():
		if not alive.has(id):
			units[id].queue_free()
			units.erase(id)

func update_turn() -> void:
	var side_name := "黑方" if turn == 0 else "红方"
	var moves := XiangqiRules.actions(board, turn)
	if XiangqiRules.king(board, turn).is_empty() or moves.is_empty():
		finished = true
		thinking = false
		status.text = "你获胜了" if turn != setup.player_side else "本局落败"
		detail.text = "%s%s。\n点击重新开局再战。" % [side_name, "被将死" if XiangqiRules.in_check(board, turn) else "无合法行动"]
	else:
		thinking = turn != setup.player_side
		status.text = "%s · %s" % [side_name, "思考中" if thinking else "请落子"]
		detail.text = "你执%s，%s执%s。\n\n%s" % ["黑棋" if setup.player_side == 0 else "红棋", "电脑", "红棋" if setup.player_side == 0 else "黑棋", "将军！请化解致命威胁。" if XiangqiRules.in_check(board, turn) else "静观棋势，落子无悔。"]
	history.text = "已行动 %d 回合\n将帅受致命威胁时须应将" % move_count

func _process(_delta: float) -> void:
	if thread != null and not thread.is_alive():
		var action: Dictionary = thread.wait_to_finish()
		thread = null
		if worker_generation == generation and thinking and not finished and not action.is_empty():
			execute(action)
	if thinking and not finished and thread == null:
		thread = Thread.new()
		worker_generation = generation
		thread.start(XiangqiAI.choose.bind(board.duplicate(true), turn))

func _exit_tree() -> void:
	if thread != null:
		thread.wait_to_finish()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if finished or thinking:
		return
	var mouse: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	var cell := Vector2i(roundi((mouse.x - ORIGIN.x) / STEP), roundi((mouse.y - ORIGIN.y) / STEP))
	if not XiangqiRules.inside(cell) or mouse.distance_to(point(cell)) > 34:
		return
	if selected_id >= 0 and cell in destinations:
		execute({"id": selected_id, "to": cell})
		return
	var p := XiangqiRules.at(board, cell)
	selected_id = -1
	destinations.clear()
	if not p.is_empty() and p.side == setup.player_side:
		selected_id = p.id
		for y in 10:
			for x in 9:
				var target := Vector2i(x, y)
				if XiangqiRules.legal(board, p, target):
					destinations.append(target)
	sync_units()
	queue_redraw()

func execute(action: Dictionary) -> void:
	for p: Dictionary in board:
		if p.id == action.id:
			last_from = p.pos
	last_to = action.to
	board = XiangqiRules.apply(board, action)
	selected_id = -1
	destinations.clear()
	move_count += 1
	turn = 1 - turn
	sync_units()
	update_turn()
	queue_redraw()

func point(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * STEP

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 1000), Color("e9e4d4"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4621
	for i in 1800:
		var start := Vector2(rng.randf_range(0, 1440), rng.randf_range(0, 1000))
		draw_line(start, start + Vector2(rng.randf_range(1, 5), 0), Color(0.3, 0.27, 0.18, 0.045), 1)
	# Layered distant mountains around the board, drawn with translucent ink.
	for layer in 4:
		var polygon := PackedVector2Array([Vector2(0, 1100)])
		for x in range(0, 1441, 24):
			var y := 860.0 - sin(x * 0.007 + layer * 1.3) * 50 - sin(x * 0.017 + layer) * 25 + layer * 30
			polygon.append(Vector2(x, y))
		polygon.append(Vector2(1440, 1100))
		draw_colored_polygon(polygon, Color(0.24, 0.34, 0.29, 0.045 + layer * 0.008))
	# Bamboo strokes and leaves.
	for stalk in 3:
		var base := Vector2(1320 + stalk * 27, 940)
		var tip := base + Vector2(-55 + stalk * 12, -340 - stalk * 48)
		draw_line(base, tip, Color(0.23, 0.34, 0.26, 0.24), 3, true)
		for node in 7:
			var joint := base.lerp(tip, node / 7.0)
			draw_line(joint - Vector2(4, 0), joint + Vector2(4, 0), Color(0.2, 0.3, 0.23, 0.3), 2)
			var sign_leaf := -1 if node % 2 == 0 else 1
			var leaf_tip := joint + Vector2(46 * sign_leaf, -32)
			draw_colored_polygon(PackedVector2Array([joint, joint + Vector2(18 * sign_leaf, -24), leaf_tip, joint + Vector2(25 * sign_leaf, -9)]), Color(0.22, 0.34, 0.25, 0.22))
	draw_rect(Rect2(285, 120, 736, 797), Color(0.19, 0.18, 0.12, 0.08))
	draw_rect(Rect2(276, 110, 736, 797), Color("f2e8cf"))
	draw_rect(Rect2(288, 122, 712, 773), Color("9b977b"), false, 1)
	draw_rect(Rect2(ORIGIN - Vector2(8, 8), Vector2(592, 664)), INK, false, 2)
	for y in 10:
		draw_line(point(Vector2i(0, y)), point(Vector2i(8, y)), INK, 1.2, true)
	for x in 9:
		if x == 0 or x == 8:
			draw_line(point(Vector2i(x, 0)), point(Vector2i(x, 9)), INK, 1.2, true)
		else:
			draw_line(point(Vector2i(x, 0)), point(Vector2i(x, 4)), INK, 1.2, true)
			draw_line(point(Vector2i(x, 5)), point(Vector2i(x, 9)), INK, 1.2, true)
	for y in [0, 7]:
		draw_line(point(Vector2i(3, y)), point(Vector2i(5, y + 2)), INK, 1, true)
		draw_line(point(Vector2i(5, y)), point(Vector2i(3, y + 2)), INK, 1, true)
	draw_string(font, Vector2(428, 537), "楚 河", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, INK)
	draw_string(font, Vector2(765, 537), "汉 界", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, INK)
	for y in [2, 3, 6, 7]:
		var columns := [1, 7] if y == 2 or y == 7 else [0, 2, 4, 6, 8]
		for x in columns:
			for sx in [-1, 1]:
				if (x == 0 and sx == -1) or (x == 8 and sx == 1):
					continue
				for sy in [-1, 1]:
					var corner := point(Vector2i(x, y)) + Vector2(sx * 5, sy * 5)
					draw_line(corner, corner + Vector2(sx * 8, 0), INK, 1)
					draw_line(corner, corner + Vector2(0, sy * 8), INK, 1)
	for cell in [last_from, last_to]:
		if XiangqiRules.inside(cell):
			draw_circle(point(cell), 33, Color(0.6, 0.47, 0.2, 0.18))
	for cell in destinations:
		if XiangqiRules.at(board, cell).is_empty():
			draw_circle(point(cell), 7, Color("738c69"))
		else:
			draw_arc(point(cell), 34, 0, TAU, 48, Color("b55240"), 2.5, true)
	draw_rect(Rect2(112, 545, 43, 48), Color("a74635"))
	draw_string(font, Vector2(120, 577), "弈", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("f4e8cd"))
	draw_line(Vector2(1050, 258), Vector2(1285, 258), Color("a9ac94"), 1)
