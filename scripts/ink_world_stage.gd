extends Node2D

## Main-scene ink landscape for 《寿元将尽》.
## Kept independent from gameplay so the visual layer can evolve without
## touching cultivation, combat, reincarnation, or UI logic.

const PAPER := Color("#eee9dc")
const PAPER_LIGHT := Color("#f7f3e8")
const PAPER_DARK := Color("#d8d0bf")
const INK := Color("#173442")
const INK_SOFT := Color("#425455")
const MOUNTAIN_FAR := Color("#c2c0b3")
const MOUNTAIN_MID := Color("#929a91")
const MOUNTAIN_NEAR := Color("#596b69")
const WATER := Color("#c7d0ca")
const TEAL := Color("#31576a")
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

    _draw_paper()
    _draw_far_mountains()
    _draw_mist()
    _draw_near_mountains()
    _draw_water_and_ground()
    _draw_ink_branches()
    _draw_seal()
    _draw_floating_dust()

func _draw_paper() -> void:
    draw_rect(Rect2(Vector2.ZERO, viewport_size), PAPER)

    # Very restrained paper bands. They provide depth without becoming a UI gradient.
    for i in range(8):
        var y := float(i) * viewport_size.y / 8.0
        var alpha := 0.018 + float(i % 3) * 0.006
        draw_rect(
            Rect2(0, y, viewport_size.x, viewport_size.y / 8.0 + 1.0),
            Color(PAPER_LIGHT, alpha)
        )

    # Horizontal ink wash at the lower third.
    draw_rect(
        Rect2(0, viewport_size.y * 0.67, viewport_size.x, viewport_size.y * 0.33),
        Color(PAPER_DARK, 0.10)
    )

func _draw_far_mountains() -> void:
    var w := viewport_size.x
    var base := viewport_size.y * 0.67
    var points := PackedVector2Array([
        Vector2(0, base - 100),
        Vector2(w * 0.10, base - 150),
        Vector2(w * 0.18, base - 112),
        Vector2(w * 0.28, base - 205),
        Vector2(w * 0.39, base - 125),
        Vector2(w * 0.51, base - 220),
        Vector2(w * 0.61, base - 145),
        Vector2(w * 0.72, base - 190),
        Vector2(w * 0.83, base - 122),
        Vector2(w * 0.94, base - 178),
        Vector2(w, base - 120),
        Vector2(w, base),
        Vector2(0, base)
    ])
    draw_colored_polygon(points, Color(MOUNTAIN_FAR, 0.52))

    # Broken ridge strokes create an ink-wash feeling without heavy outlines.
    _ridge(Vector2(w * 0.08, base - 150), Vector2(w * 0.28, base - 205), 2.0, Color(INK_SOFT, 0.16))
    _ridge(Vector2(w * 0.40, base - 125), Vector2(w * 0.51, base - 220), 2.0, Color(INK_SOFT, 0.14))
    _ridge(Vector2(w * 0.70, base - 190), Vector2(w * 0.83, base - 122), 2.0, Color(INK_SOFT, 0.12))

func _draw_near_mountains() -> void:
    var w := viewport_size.x
    var base := viewport_size.y * 0.75
    var points := PackedVector2Array([
        Vector2(0, base - 80),
        Vector2(w * 0.07, base - 125),
        Vector2(w * 0.14, base - 96),
        Vector2(w * 0.22, base - 178),
        Vector2(w * 0.30, base - 105),
        Vector2(w * 0.39, base - 142),
        Vector2(w * 0.47, base - 92),
        Vector2(w * 0.57, base - 160),
        Vector2(w * 0.67, base - 103),
        Vector2(w * 0.76, base - 132),
        Vector2(w * 0.86, base - 86),
        Vector2(w * 0.94, base - 135),
        Vector2(w, base - 108),
        Vector2(w, base),
        Vector2(0, base)
    ])
    draw_colored_polygon(points, Color(MOUNTAIN_MID, 0.62))

    # Foreground ridge, deliberately low contrast so the UI remains dominant.
    var near_points := PackedVector2Array([
        Vector2(0, viewport_size.y * 0.79),
        Vector2(w * 0.10, viewport_size.y * 0.74),
        Vector2(w * 0.19, viewport_size.y * 0.78),
        Vector2(w * 0.31, viewport_size.y * 0.70),
        Vector2(w * 0.43, viewport_size.y * 0.77),
        Vector2(w * 0.54, viewport_size.y * 0.71),
        Vector2(w * 0.65, viewport_size.y * 0.77),
        Vector2(w * 0.78, viewport_size.y * 0.72),
        Vector2(w * 0.90, viewport_size.y * 0.78),
        Vector2(w, viewport_size.y * 0.73),
        Vector2(w, viewport_size.y),
        Vector2(0, viewport_size.y)
    ])
    draw_colored_polygon(near_points, Color(MOUNTAIN_NEAR, 0.23))

    _ridge(Vector2(w * 0.08, viewport_size.y * 0.74), Vector2(w * 0.31, viewport_size.y * 0.70), 2.5, Color(INK, 0.22))
    _ridge(Vector2(w * 0.54, viewport_size.y * 0.71), Vector2(w * 0.78, viewport_size.y * 0.72), 2.5, Color(INK, 0.18))

func _draw_mist() -> void:
    var w := viewport_size.x
    var y1 := viewport_size.y * 0.58 + sin(time * 0.18) * 3.0
    var y2 := viewport_size.y * 0.70 + sin(time * 0.14 + 1.7) * 4.0

    _mist_ribbon(y1, 0.16, 120.0)
    _mist_ribbon(y2, 0.11, 170.0)

    # Small drifting cloud fragments.
    for i in range(7):
        var x := fmod(float(i) * 241.0 + time * (4.0 + i * 0.4), w + 260.0) - 130.0
        var y := viewport_size.y * (0.39 + float(i % 3) * 0.075)
        draw_ellipse(Vector2(x, y), Vector2(90.0 + i * 5.0, 16.0), Color(PAPER_LIGHT, 0.12))

func _mist_ribbon(y: float, alpha: float, width: float) -> void:
    var w := viewport_size.x
    var pts := PackedVector2Array()
    for i in range(13):
        var x := float(i) / 12.0 * w
        var yy := y + sin(i * 0.85 + time * 0.10) * 9.0
        pts.append(Vector2(x, yy))
    for i in range(pts.size() - 1):
        draw_line(pts[i], pts[i + 1], Color(PAPER_LIGHT, alpha), width, true)

func _draw_water_and_ground() -> void:
    var y := viewport_size.y * 0.82
    draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(INK_SOFT, 0.17), 2.0, true)
    draw_line(Vector2(0, y + 14), Vector2(viewport_size.x, y + 14), Color(WATER, 0.55), 1.0, true)
    draw_line(Vector2(0, y + 27), Vector2(viewport_size.x, y + 27), Color(WATER, 0.36), 1.0, true)

    # Broken shore marks.
    for i in range(12):
        var x := float(i) * viewport_size.x / 11.0
        var length := 25.0 + float((i * 17) % 35)
        draw_line(
            Vector2(x, y + 6),
            Vector2(x + length, y + 4 + sin(i) * 2.0),
            Color(EARTH, 0.16),
            1.2,
            true
        )

func _draw_ink_branches() -> void:
    var h := viewport_size.y
    var w := viewport_size.x
    # Subtle framing branches in the corners, leaving the central play area open.
    _branch(Vector2(22, h * 0.72), Vector2(105, h * 0.43), -0.30, 0.22)
    _branch(Vector2(w - 24, h * 0.74), Vector2(w - 112, h * 0.48), -2.85, 0.18)

func _branch(start: Vector2, end: Vector2, angle: float, alpha: float) -> void:
    draw_line(start, end, Color(EARTH, alpha), 3.0, true)
    var dir := (end - start).normalized()
    var perp := Vector2(-dir.y, dir.x)
    for i in range(4):
        var t := 0.25 + i * 0.15
        var p := start.lerp(end, t)
        var twig := p + dir.rotated(angle) * (24.0 - i * 3.0)
        draw_line(p, twig, Color(EARTH, alpha * 0.8), 1.8, true)

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

func _ridge(a: Vector2, b: Vector2, width: float, color: Color) -> void:
    var mid := a.lerp(b, 0.5) + Vector2(0, -8)
    var pts := PackedVector2Array([a, mid, b])
    draw_polyline(pts, color, width, true)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(25):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, color)
