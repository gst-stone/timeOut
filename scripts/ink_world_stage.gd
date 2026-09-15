extends Node2D

## Main-scene ink landscape for 《寿元将尽》.
## 参考概念图：青绿设色水墨山水 —— 天光渐变、层叠远山、山腰云海、飞瀑、
## 松林、远寺剪影与纸墨氛围颗粒。与玩法逻辑完全解耦，只负责视觉层。

const PAPER_LIGHT := Color("#f7f3e8")
const INK := Color("#173442")
const INK_SOFT := Color("#425455")
const SKY_TOP := Color("#c7d5dd")
const SKY_LOW := Color("#f0ede0")
const PEAK_SKY := Color("#b6c4cc")
const PEAK_FAR := Color("#93a7ac")
const PEAK_MID := Color("#6e8689")
const PEAK_NEAR := Color("#46595a")
const PEAK_BASE := Color("#2f4245")
const PINE := Color("#35504f")
const WATER := Color("#cfd9d3")
const EARTH := Color("#6b5740")
const RED := Color("#9b4b45")

var viewport_size := Vector2(1440, 820)
var time := 0.0

func _ready() -> void:
	z_index = -5
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	viewport_size = get_viewport_rect().size
	if viewport_size.x < 900.0:
		viewport_size = Vector2(1440, 820)

	_draw_sky()
	_draw_far_peaks()
	_draw_cloud_wall()
	_draw_mid_peaks()
	_draw_drifting_clouds()
	_draw_near_ridge()
	_draw_water_and_ground()
	_draw_frame_branches()
	_draw_seal()
	_draw_floating_dust()
	_draw_vignette()

func _draw_sky() -> void:
	# 天光渐变：淡青 -> 暖纸色，用横向色带模拟水墨晕染。
	var horizon := viewport_size.y * 0.68
	var bands := 36
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var y := t * horizon
		var c := SKY_TOP.lerp(SKY_LOW, t)
		draw_rect(Rect2(0, y, viewport_size.x, horizon / float(bands) + 1.0), c)

func _draw_far_peaks() -> void:
	# 最高远的尖峰群，颜色最浅，形成空气透视。
	var w := viewport_size.x
	var base := viewport_size.y * 0.66
	var points := PackedVector2Array([
		Vector2(0, base - viewport_size.y * 0.10),
		Vector2(w * 0.07, base - viewport_size.y * 0.26),
		Vector2(w * 0.15, base - viewport_size.y * 0.14),
		Vector2(w * 0.24, base - viewport_size.y * 0.34),
		Vector2(w * 0.31, base - viewport_size.y * 0.18),
		Vector2(w * 0.42, base - viewport_size.y * 0.30),
		Vector2(w * 0.50, base - viewport_size.y * 0.12),
		Vector2(w * 0.58, base - viewport_size.y * 0.36),
		Vector2(w * 0.66, base - viewport_size.y * 0.16),
		Vector2(w * 0.75, base - viewport_size.y * 0.28),
		Vector2(w * 0.84, base - viewport_size.y * 0.13),
		Vector2(w * 0.93, base - viewport_size.y * 0.22),
		Vector2(w, base - viewport_size.y * 0.09),
		Vector2(w, base),
		Vector2(0, base)
	])
	draw_colored_polygon(points, Color(PEAK_SKY, 0.92))
	_ridge(Vector2(w * 0.10, base - viewport_size.y * 0.24), Vector2(w * 0.24, base - viewport_size.y * 0.34), 2.0, Color(INK_SOFT, 0.14))
	_ridge(Vector2(w * 0.50, base - viewport_size.y * 0.12), Vector2(w * 0.58, base - viewport_size.y * 0.36), 2.0, Color(INK_SOFT, 0.13))
	_ridge(Vector2(w * 0.76, base - viewport_size.y * 0.26), Vector2(w * 0.93, base - viewport_size.y * 0.20), 2.0, Color(INK_SOFT, 0.11))

func _draw_cloud_wall() -> void:
	# 山腰云海：一排宽而柔的云团，盖住远山山脚。
	var w := viewport_size.x
	var y := viewport_size.y * (0.585 + sin(time * 0.16) * 0.004)
	for i in range(9):
		var cx := w * (0.06 + float(i) * 0.115) + sin(time * 0.22 + float(i) * 1.3) * 12.0
		var cy := y + sin(float(i) * 2.1) * 7.0
		var rx := 110.0 + float(i % 4) * 26.0
		_draw_ink_ellipse(Vector2(cx, cy), Vector2(rx, 15.0 + float(i % 3) * 4.0), Color(PAPER_LIGHT, 0.42))
		_draw_ink_ellipse(Vector2(cx + rx * 0.4, cy - 8.0), Vector2(rx * 0.55, 9.0), Color(PAPER_LIGHT, 0.34))
	_mist_ribbon(viewport_size.y * 0.63, 0.14, 130.0)

func _draw_mid_peaks() -> void:
	# 中景主峰：颜色加深，其上安放青云宗寺塔剪影与一道飞瀑。
	var w := viewport_size.x
	var base := viewport_size.y * 0.74
	var points := PackedVector2Array([
		Vector2(0, base - viewport_size.y * 0.08),
		Vector2(w * 0.09, base - viewport_size.y * 0.16),
		Vector2(w * 0.18, base - viewport_size.y * 0.09),
		Vector2(w * 0.30, base - viewport_size.y * 0.24),
		Vector2(w * 0.38, base - viewport_size.y * 0.12),
		Vector2(w * 0.47, base - viewport_size.y * 0.28),
		Vector2(w * 0.55, base - viewport_size.y * 0.14),
		Vector2(w * 0.63, base - viewport_size.y * 0.22),
		Vector2(w * 0.72, base - viewport_size.y * 0.10),
		Vector2(w * 0.81, base - viewport_size.y * 0.18),
		Vector2(w * 0.90, base - viewport_size.y * 0.07),
		Vector2(w, base - viewport_size.y * 0.12),
		Vector2(w, base),
		Vector2(0, base)
	])
	draw_colored_polygon(points, Color(PEAK_FAR, 0.90))

	# 青云宗寺塔：立于 w*0.47 主峰顶。
	_pagoda(Vector2(w * 0.47, base - viewport_size.y * 0.272), 13.0, Color(INK, 0.46))
	# 飞瀑：从 w*0.63 峰腰垂落。
	_waterfall(Vector2(w * 0.635, base - viewport_size.y * 0.17), base - viewport_size.y * 0.035, WATER)

func _draw_drifting_clouds() -> void:
	# 漂移的白云，穿过中景山腰，制造“云在山中行”的层次。
	var w := viewport_size.x
	for i in range(10):
		var speed := 5.0 + float(i % 4) * 1.6
		var x := fmod(float(i) * 187.0 + time * speed, w + 320.0) - 160.0
		var y := viewport_size.y * (0.36 + float(i % 4) * 0.055)
		var rx := 84.0 + float(i % 5) * 22.0
		var a := 0.20 + float(i % 3) * 0.09
		_draw_ink_ellipse(Vector2(x, y), Vector2(rx, 12.0 + float(i % 3) * 3.0), Color(PAPER_LIGHT, a))
		_draw_ink_ellipse(Vector2(x + rx * 0.5, y - 7.0), Vector2(rx * 0.5, 8.0), Color(PAPER_LIGHT, a * 0.8))

func _draw_near_ridge() -> void:
	# 近景山脊：墨色最重，脊线上立松林剪影。
	var w := viewport_size.x
	var base := viewport_size.y * 0.83
	var points := PackedVector2Array([
		Vector2(0, base - viewport_size.y * 0.06),
		Vector2(w * 0.11, base - viewport_size.y * 0.13),
		Vector2(w * 0.22, base - viewport_size.y * 0.05),
		Vector2(w * 0.33, base - viewport_size.y * 0.11),
		Vector2(w * 0.45, base - viewport_size.y * 0.04),
		Vector2(w * 0.56, base - viewport_size.y * 0.10),
		Vector2(w * 0.68, base - viewport_size.y * 0.05),
		Vector2(w * 0.79, base - viewport_size.y * 0.09),
		Vector2(w * 0.90, base - viewport_size.y * 0.03),
		Vector2(w, base - viewport_size.y * 0.07),
		Vector2(w, base + viewport_size.y * 0.10),
		Vector2(0, base + viewport_size.y * 0.10)
	])
	draw_colored_polygon(points, Color(PEAK_MID, 0.88))

	# 松林：沿脊线错落。
	var pine_xs: Array[float] = [0.05, 0.13, 0.24, 0.36, 0.44, 0.52, 0.64, 0.74, 0.85, 0.95]
	for i in pine_xs.size():
		var px := w * pine_xs[i]
		var py := base - viewport_size.y * (_ridge_y(pine_xs[i]) + 0.004)
		_pine(Vector2(px, py), viewport_size.y * (0.055 + float(i % 3) * 0.012), Color(PINE, 0.85))

	# 最前景墨色坡脚。
	var foot := PackedVector2Array([
		Vector2(0, viewport_size.y * 0.92),
		Vector2(w * 0.2, viewport_size.y * 0.965),
		Vector2(w * 0.5, viewport_size.y * 0.93),
		Vector2(w * 0.8, viewport_size.y * 0.97),
		Vector2(w, viewport_size.y * 0.94),
		Vector2(w, viewport_size.y),
		Vector2(0, viewport_size.y)
	])
	draw_colored_polygon(foot, Color(PEAK_BASE, 0.55))

func _ridge_y(t: float) -> float:
	# 近景脊线高度的近似采样，用于把松树立在脊线上。
	var h := 0.06
	if t < 0.11: h = lerpf(0.06, 0.13, t / 0.11)
	elif t < 0.22: h = lerpf(0.13, 0.05, (t - 0.11) / 0.11)
	elif t < 0.33: h = lerpf(0.05, 0.11, (t - 0.22) / 0.11)
	elif t < 0.45: h = lerpf(0.11, 0.04, (t - 0.33) / 0.12)
	elif t < 0.56: h = lerpf(0.04, 0.10, (t - 0.45) / 0.11)
	elif t < 0.68: h = lerpf(0.10, 0.05, (t - 0.56) / 0.12)
	elif t < 0.79: h = lerpf(0.05, 0.09, (t - 0.68) / 0.11)
	elif t < 0.90: h = lerpf(0.09, 0.03, (t - 0.79) / 0.11)
	else: h = lerpf(0.03, 0.07, (t - 0.90) / 0.10)
	return h

func _draw_water_and_ground() -> void:
	var y := viewport_size.y * 0.885
	draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(INK_SOFT, 0.16), 2.0, true)
	# 水面碎光。
	for i in range(10):
		var x := fmod(float(i) * 173.0 + time * 6.0, viewport_size.x + 90.0) - 45.0
		var yy := y + 8.0 + float(i % 4) * 7.0
		draw_line(Vector2(x, yy), Vector2(x + 26.0 + float(i % 3) * 10.0, yy), Color(PAPER_LIGHT, 0.30), 1.4, true)

func _draw_frame_branches() -> void:
	var h := viewport_size.y
	var w := viewport_size.x
	# 两角探出的松枝，框住画面，中央留给 UI 与人物。
	_branch(Vector2(26, h * 0.76), Vector2(120, h * 0.46), -0.32, 0.30)
	_branch(Vector2(w - 28, h * 0.78), Vector2(w - 124, h * 0.50), -2.82, 0.26)

func _branch(start: Vector2, end: Vector2, angle: float, alpha: float) -> void:
	draw_line(start, end, Color(EARTH, alpha), 3.4, true)
	var dir := (end - start).normalized()
	var perp := Vector2(-dir.y, dir.x)
	for i in range(4):
		var t := 0.25 + i * 0.15
		var p := start.lerp(end, t)
		var twig := p + dir.rotated(angle) * (26.0 - i * 3.0)
		draw_line(p, twig, Color(EARTH, alpha * 0.8), 1.8, true)
		# 枝头松针团。
		_draw_ink_ellipse(twig, Vector2(13.0, 5.0), Color(PINE, alpha * 0.75))
	_draw_ink_ellipse(end + dir * 4.0, Vector2(16.0, 6.0), Color(PINE, alpha * 0.85))

func _draw_seal() -> void:
	var pos := Vector2(viewport_size.x - 92, 82)
	draw_circle(pos, 27.0, Color(RED, 0.08))
	draw_arc(pos, 25.0, 0.0, TAU, 32, Color(RED, 0.22), 2.0, true)
	draw_arc(pos, 18.0, 0.4, 5.4, 24, Color(RED, 0.14), 1.0, true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-10, 6), "命", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(RED, 0.28))

func _draw_floating_dust() -> void:
	var w := viewport_size.x
	var h := viewport_size.y
	for i in range(18):
		var x := fmod(i * 113.0 + time * (2.0 + (i % 4)), w)
		var y := fmod(i * 67.0 + time * (1.0 + (i % 3) * 0.25), h * 0.84)
		draw_circle(Vector2(x, y), 1.0 + float(i % 2), Color(INK_SOFT, 0.08))

func _draw_vignette() -> void:
	# 四缘极淡的墨色收边，让画面有卷轴感。
	var w := viewport_size.x
	var h := viewport_size.y
	for i in range(6):
		var t := float(i) / 6.0
		var a := 0.045 * (1.0 - t)
		draw_rect(Rect2(0, t * h * 0.10, w, h * 0.10 / 6.0 + 1.0), Color(INK, a * 0.6))
		draw_rect(Rect2(0, h - t * h * 0.10 - h * 0.10 / 6.0, w, h * 0.10 / 6.0 + 1.0), Color(INK, a))
		draw_rect(Rect2(t * w * 0.06, 0, w * 0.06 / 6.0 + 1.0, h), Color(INK, a * 0.7))
		draw_rect(Rect2(w - t * w * 0.06 - w * 0.06 / 6.0, 0, w * 0.06 / 6.0 + 1.0, h), Color(INK, a * 0.7))

func _mist_ribbon(y: float, alpha: float, width: float) -> void:
	var w := viewport_size.x
	var pts := PackedVector2Array()
	for i in range(13):
		var x := float(i) / 12.0 * w
		var yy := y + sin(i * 0.85 + time * 0.10) * 9.0
		pts.append(Vector2(x, yy))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], Color(PAPER_LIGHT, alpha), width, true)

func _pagoda(pos: Vector2, s: float, color: Color) -> void:
	# 三层密檐小塔剪影：pos 为塔基中心。
	for i in range(3):
		var spread := s * (1.0 - float(i) * 0.2)
		var y := pos.y - float(i) * s * 0.72
		var pts := PackedVector2Array([
			Vector2(pos.x - spread, y),
			Vector2(pos.x + spread, y),
			Vector2(pos.x + spread * 0.62, y - s * 0.5),
			Vector2(pos.x - spread * 0.62, y - s * 0.5)
		])
		draw_colored_polygon(pts, color)
		# 出檐。
		draw_line(Vector2(pos.x - spread * 1.12, y - s * 0.5), Vector2(pos.x + spread * 1.12, y - s * 0.5), color, 2.0, true)
	draw_line(Vector2(pos.x, pos.y - s * 2.2), Vector2(pos.x, pos.y - s * 2.6), color, 2.0, true)

func _waterfall(top: Vector2, bottom_y: float, color: Color) -> void:
	var steps := 10
	for s in range(steps):
		var t0 := float(s) / float(steps)
		var t1 := float(s + 1) / float(steps)
		var sway := sin(time * 1.2 + t0 * 5.0) * 2.0
		var y0 := lerpf(top.y, bottom_y, t0)
		var y1 := lerpf(top.y, bottom_y, t1)
		var x0 := top.x + sin(t0 * 2.6) * 4.0 + sway
		var x1 := top.x + sin(t1 * 2.6) * 4.0 + sway
		draw_line(Vector2(x0, y0), Vector2(x1, y1), Color(color, 0.55 - t0 * 0.28), 3.2 - t0 * 1.6, true)
	_draw_ink_ellipse(Vector2(top.x, bottom_y), Vector2(15.0, 4.5), Color(PAPER_LIGHT, 0.5))

func _pine(pos: Vector2, h: float, color: Color) -> void:
	# 松树剪影：短干 + 4 层伞盖。
	draw_line(pos, pos + Vector2(0, -h * 0.32), color, 2.0, true)
	for i in range(4):
		var t := float(i) / 4.0
		var cy := pos.y - h * (0.28 + t * 0.60)
		var cw := h * (0.36 - t * 0.22)
		var pts := PackedVector2Array([
			Vector2(pos.x - cw, cy),
			Vector2(pos.x, cy - h * 0.17),
			Vector2(pos.x + cw, cy)
		])
		draw_colored_polygon(pts, color)

func _ridge(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var mid := a.lerp(b, 0.5) + Vector2(0, -8)
	var pts := PackedVector2Array([a, mid, b])
	draw_polyline(pts, color, width, true)

func _draw_ink_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
