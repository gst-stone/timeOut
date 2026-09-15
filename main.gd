extends Control

# 寿元将尽 - Godot 4 MVP
# 第一版目标：修炼 -> 探索 -> 战斗 -> 寿元 -> 死亡 -> 轮回

var player := {
	"name": "林凡",
	"age": 18,
	"max_age": 80,
	"realm": 0,
	"level": 1,
	"cultivation": 0,
	"required": 100,
	"hp": 100,
	"max_hp": 100,
	"attack": 10,
	"defense": 5,
	"comprehension": 5,
	"luck": 5,
	"physique": 5,
	"stones": 100,
	"reincarnations": 0,
	"permanent_comprehension": 0,
	"permanent_luck": 0,
	"permanent_physique": 0,
	"dead": false
}

const REALMS := ["炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫"]
const ENEMIES := [
	{"name":"山野狼妖", "hp":80, "attack":12, "defense":3, "reward":60},
	{"name":"黑鳞蛇妖", "hp":120, "attack":15, "defense":5, "reward":90},
	{"name":"赤焰虎", "hp":180, "attack":20, "defense":8, "reward":140},
	{"name":"青面鬼", "hp":250, "attack":25, "defense":10, "reward":220},
	{"name":"铁甲妖熊", "hp":400, "attack":35, "defense":15, "reward":350}
]

var font: Font
var log_label: Label
var status_label: Label
var cultivation_label: Label
var hp_label: Label
var attribute_label: Label
var event_label: Label
var action_buttons: Array[Button] = []

func _ready() -> void:
	randomize()
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun", "Arial"])
	_build_ui()
	_refresh()

func _draw() -> void:
	# 水墨山水背景：不依赖外部素材，先保证项目开箱即跑。
	draw_rect(Rect2(Vector2.ZERO, size), Color("#dceaf0"))
	draw_rect(Rect2(0, 0, size.x, 250), Color("#b9d8e2"))
	draw_rect(Rect2(0, 250, size.x, size.y - 250), Color("#d7e0d3"))

	var mountains = [
		PackedVector2Array([Vector2(0,360),Vector2(210,120),Vector2(410,350)]),
		PackedVector2Array([Vector2(230,380),Vector2(520,80),Vector2(800,380)]),
		PackedVector2Array([Vector2(670,370),Vector2(980,110),Vector2(1250,380)]),
		PackedVector2Array([Vector2(1050,380),Vector2(1280,150),Vector2(1540,380)])
	]
	for i in mountains.size():
		draw_colored_polygon(mountains[i], Color(0.38, 0.50, 0.50, 0.22 + i * 0.015))

	for x in range(0, int(size.x), 180):
		draw_line(Vector2(x, 390), Vector2(x + 80, 320), Color(0.2,0.3,0.3,0.12), 2)

func _build_ui() -> void:
	queue_redraw()

	var header := ColorRect.new()
	header.color = Color("#173442")
	header.position = Vector2(0, 0)
	header.size = Vector2(size.x, 76)
	add_child(header)

	var title := _label("寿元将尽", 30, Color("#f3ead4"))
	title.position = Vector2(28, 16)
	title.size = Vector2(180, 45)
	add_child(title)

	status_label = _label("", 18, Color("#e8f0e8"))
	status_label.position = Vector2(230, 17)
	status_label.size = Vector2(720, 42)
	add_child(status_label)

	var resource := _label("◆ 100 灵石    ◇ 轮回 0", 18, Color("#e8d9a6"))
	resource.name = "ResourceLabel"
	resource.position = Vector2(1060, 18)
	resource.size = Vector2(330, 40)
	add_child(resource)

	# 左侧角色属性
	var left := _panel(Vector2(24, 96), Vector2(310, 610))
	add_child(left)

	var lt := _label("角色属性", 24, Color("#173442"))
	lt.position = Vector2(22, 18)
	lt.size = Vector2(250, 38)
	left.add_child(lt)

	cultivation_label = _label("", 17, Color("#254c5a"))
	cultivation_label.position = Vector2(22, 72)
	cultivation_label.size = Vector2(265, 42)
	left.add_child(cultivation_label)

	hp_label = _label("", 17, Color("#254c5a"))
	hp_label.position = Vector2(22, 118)
	hp_label.size = Vector2(265, 42)
	left.add_child(hp_label)

	attribute_label = _label("", 17, Color("#30434a"))
	attribute_label.position = Vector2(22, 175)
	attribute_label.size = Vector2(265, 250)
	left.add_child(attribute_label)

	var root_title := _label("五行灵根", 18, Color("#173442"))
	root_title.position = Vector2(22, 430)
	root_title.size = Vector2(260, 35)
	left.add_child(root_title)

	var roots := _label("金  ███████░░  20\n木  █████░░░░  15\n水  ████████░  28\n火  ██████░░░  18\n土  █████░░░░  16", 14, Color("#5b6869"))
	roots.position = Vector2(22, 470)
	roots.size = Vector2(260, 120)
	left.add_child(roots)

	# 中央区域
	var center := _panel(Vector2(354, 96), Vector2(680, 610))
	add_child(center)

	var sect := _label("青云宗 · 外门弟子", 21, Color("#173442"))
	sect.position = Vector2(25, 18)
	sect.size = Vector2(360, 36)
	center.add_child(sect)

	var meditation := _label("山中静修", 18, Color("#526565"))
	meditation.position = Vector2(25, 64)
	meditation.size = Vector2(200, 35)
	center.add_child(meditation)

	var scene_card := ColorRect.new()
	scene_card.color = Color("#c6d7d2")
	scene_card.position = Vector2(25, 108)
	scene_card.size = Vector2(630, 225)
	center.add_child(scene_card)

	var mountain_text := _label("云海 · 飞瀑 · 古松 · 灵气\n\n                 「静心凝神，方可窥见大道。」", 21, Color("#36535a"))
	mountain_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mountain_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mountain_text.position = Vector2(30, 115)
	mountain_text.size = Vector2(620, 205)
	center.add_child(mountain_text)

	var action_title := _label("当前行动", 19, Color("#173442"))
	action_title.position = Vector2(25, 350)
	action_title.size = Vector2(200, 35)
	center.add_child(action_title)

	var cultivate_btn := _button("开始修炼 · 1日", Vector2(25, 400), Vector2(190, 58))
	cultivate_btn.pressed.connect(_cultivate)
	center.add_child(cultivate_btn)
	action_buttons.append(cultivate_btn)

	var explore_btn := _button("外出探索 · 1年", Vector2(235, 400), Vector2(190, 58))
	explore_btn.pressed.connect(_explore)
	center.add_child(explore_btn)
	action_buttons.append(explore_btn)

	var breakthrough_btn := _button("尝试突破", Vector2(445, 400), Vector2(190, 58))
	breakthrough_btn.pressed.connect(_breakthrough)
	center.add_child(breakthrough_btn)
	action_buttons.append(breakthrough_btn)

	var tip := _label("寿元是最珍贵的资源。\n每一次选择，都可能改变这一世的结局。", 16, Color("#596b69"))
	tip.position = Vector2(25, 480)
	tip.size = Vector2(600, 70)
	center.add_child(tip)

	# 右侧事件
	var right := _panel(Vector2(1056, 96), Vector2(360, 610))
	add_child(right)

	var rt := _label("当前事件", 23, Color("#173442"))
	rt.position = Vector2(20, 18)
	rt.size = Vector2(300, 38)
	right.add_child(rt)

	event_label = _label("山中无事\n\n你盘坐在青云宗后山。\n灵气如雾，松涛阵阵。\n\n今日适合静心修炼。", 17, Color("#425455"))
	event_label.position = Vector2(20, 70)
	event_label.size = Vector2(320, 180)
	right.add_child(event_label)

	var log_title := _label("近期日志", 19, Color("#173442"))
	log_title.position = Vector2(20, 270)
	log_title.size = Vector2(300, 35)
	right.add_child(log_title)

	log_label = _label("第一世开始。\n你踏入青云宗，成为外门弟子。", 14, Color("#667272"))
	log_label.position = Vector2(20, 315)
	log_label.size = Vector2(320, 230)
	right.add_child(log_label)

	# 底部导航
	var nav := ColorRect.new()
	nav.color = Color("#173442")
	nav.position = Vector2(0, 730)
	nav.size = Vector2(size.x, 170)
	add_child(nav)

	var nav_items := ["角色", "修炼", "探索", "战斗", "装备", "功法", "命格", "轮回"]
	for i in nav_items.size():
		var b := _button(nav_items[i], Vector2(60 + i * 165, 775), Vector2(135, 54))
		b.modulate = Color(0.88, 0.93, 0.91)
		add_child(b)

	var footer := _label("一世轮回，道途无尽", 16, Color("#d7dfd7"))
	footer.position = Vector2(50, 850)
	footer.size = Vector2(300, 30)
	add_child(footer)

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _panel(pos: Vector2, panel_size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.94, 0.87, 0.94)
	style.border_color = Color("#9caea9")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", style)
	return p

func _button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = button_size
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#31576a")
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	var hover := normal.duplicate()
	hover.bg_color = Color("#42758a")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_color_override("font_color", Color("#f4f0df"))
	return b

func _refresh() -> void:
	status_label.text = "%s    年龄 %d/%d    寿元 %d年    %s · %d层" % [player.name, player.age, player.max_age, player.max_age - player.age, REALMS[player.realm], player.level]
	cultivation_label.text = "修为\n%d / %d" % [player.cultivation, player.required]
	hp_label.text = "气血\n%d / %d" % [player.hp, player.max_hp]
	attribute_label.text = "攻击      %d\n防御      %d\n悟性      %d\n气运      %d\n体质      %d\n\n灵石      %d\n轮回      %d" % [player.attack, player.defense, player.comprehension, player.luck, player.physique, player.stones, player.reincarnations]
	var resource := get_node_or_null("ResourceLabel")
	if resource:
		resource.text = "◆ %d 灵石    ◇ 轮回 %d" % [player.stones, player.reincarnations]
	for b in action_buttons:
		b.disabled = player.dead
	if player.dead:
		event_label.text = "寿元已尽\n\n你的这一世已经结束。\n\n大道无情，轮回有路。\n\n请点击下方【轮回】。"
	queue_redraw()

func _add_log(text: String) -> void:
	log_label.text = text + "\n\n" + log_label.text

func _cultivate() -> void:
	if player.dead:
		return
	player.age += 1
	var gain := int(20.0 * (1.0 + player.comprehension * 0.08))
	player.cultivation += gain
	player.hp = min(player.max_hp, player.hp + 5)
	_add_log("修炼一日，获得修为 +%d。" % gain)
	event_label.text = "静心修炼\n\n灵气缓缓进入经脉。\n\n修为 +%d\n寿元 -1年" % gain
	_check_breakthrough()
	_check_death()
	_refresh()

func _explore() -> void:
	if player.dead:
		return
	player.age += 1
	var roll := randf()
	if roll < 0.38:
		var enemy: Dictionary = ENEMIES[randi_range(0, min(REALMS.size() - 1, player.realm + 1))]
		var result := _battle(enemy)
		if result:
			player.stones += int(enemy.reward)
			var gain := int(enemy.reward * 0.45)
			player.cultivation += gain
			event_label.text = "荒野遭遇\n\n【%s】\n\n战斗胜利。\n灵石 +%d\n修为 +%d" % [enemy.name, enemy.reward, gain]
			_add_log("击败 %s，获得灵石 %d。" % [enemy.name, enemy.reward])
		else:
			event_label.text = "荒野遭遇\n\n【%s】\n\n你不敌妖物，重伤而归。" % enemy.name
			_add_log("与 %s 激战后落败。" % enemy.name)
	elif roll < 0.72:
		var reward := randi_range(30, 120)
		player.stones += reward
		player.cultivation += reward
		event_label.text = "山中奇遇\n\n你在溪边发现一块灵石。\n\n灵石 +%d\n修为 +%d" % [reward, reward]
		_add_log("探索发现灵石，资源增加。")
	else:
		player.max_age += 1
		player.age = max(0, player.age - 1)
		event_label.text = "寿元机缘\n\n一缕天地灵气融入体内。\n\n寿元上限 +1年"
		_add_log("获得一缕长生机缘，寿元上限 +1。")
	_check_breakthrough()
	_check_death()
	_refresh()

func _battle(enemy: Dictionary) -> bool:
	var enemy_hp: int = enemy.hp
	while player.hp > 0 and enemy_hp > 0:
		var player_damage := maxi(1, player.attack - int(enemy.defense) + randi_range(-2, 5))
		enemy_hp -= player_damage
		if enemy_hp <= 0:
			return true
		var enemy_damage := maxi(1, int(enemy.attack) - player.defense + randi_range(-2, 4))
		player.hp -= enemy_damage
	return false

func _breakthrough() -> void:
	if player.dead:
		return
	if player.cultivation < player.required:
		event_label.text = "突破失败\n\n当前修为不足。\n\n还需要 %d 点修为。" % (player.required - player.cultivation)
		_add_log("尝试突破失败：修为不足。")
		return
	_do_breakthrough()
	_refresh()

func _check_breakthrough() -> void:
	if player.cultivation >= player.required:
		_do_breakthrough()

func _do_breakthrough() -> void:
	player.cultivation -= player.required
	if player.level < 12:
		player.level += 1
	elif player.realm < REALMS.size() - 1:
		player.realm += 1
		player.level = 1
	else:
		player.level = 12
	player.required = max(100, int(100.0 * pow(2.0, player.realm) * player.level * player.level))
	player.max_hp += 30
	player.attack += 5
	player.defense += 3
	player.hp = player.max_hp
	event_label.text = "突破成功\n\n境界：%s · %d层\n\n气血、攻击、防御全面提升。" % [REALMS[player.realm], player.level]
	_add_log("突破成功：%s · %d层。" % [REALMS[player.realm], player.level])

func _check_death() -> void:
	if player.age >= player.max_age or player.hp <= 0:
		player.age = player.max_age
		player.dead = true
		event_label.text = "寿元已尽\n\n这一世的修行到此为止。\n\n你最终停留在：%s · %d层" % [REALMS[player.realm], player.level]
		_add_log("这一世结束。你开始回望自己走过的道路。")

func _reincarnate() -> void:
	if not player.dead:
		return
	player.reincarnations += 1
	if player.realm >= 2:
		player.permanent_luck += 1
	if player.realm >= 4:
		player.permanent_physique += 1
	player.permanent_comprehension += 1
	var pc = player.permanent_comprehension
	var pl = player.permanent_luck
	var pp = player.permanent_physique
	player = {
		"name": "林凡",
		"age": 18,
		"max_age": 80 + pp * 2,
		"realm": 0,
		"level": 1,
		"cultivation": 0,
		"required": 100,
		"hp": 100 + pp * 10,
		"max_hp": 100 + pp * 10,
		"attack": 10 + pp,
		"defense": 5 + pp / 2,
		"comprehension": 5 + pc,
		"luck": 5 + pl,
		"physique": 5 + pp,
		"stones": 100 + player.reincarnations * 20,
		"reincarnations": player.reincarnations,
		"permanent_comprehension": pc,
		"permanent_luck": pl,
		"permanent_physique": pp,
		"dead": false
	}
	event_label.text = "轮回归来\n\n你的灵魂再次降临人间。\n\n这一世，你比上一世更强。"
	log_label.text = "第 %d 世开始。\n\n命运再次展开。" % player.reincarnations
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if player.dead:
			_reincarnate()
