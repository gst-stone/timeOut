extends Node2D

# 主场景角色舞台：人物与妖物不再只是悬浮在 UI 中，而是落在水墨山水的地面层上。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var pulse := 0.0
var breath := 0.0

const PLAYER_POS := Vector2(555, 300)
const ENEMY_POS := Vector2(835, 300)
const PLAYER_SHADOW := Vector2(555, 390)
const ENEMY_SHADOW := Vector2(835, 390)
const INK := Color("#173442")
const INK_SOFT := Color("#425455")
const PAPER := Color("#eee9dc")
const TEAL := Color("#31576a")
const EARTH := Color("#6b5740")
const RED := Color("#9b4b45")

func _ready() -> void:
    z_index = 8
    player_sprite = _make_sprite("res://assets/player_ink.svg", PLAYER_POS, 0.43)
    enemy_sprite = _make_sprite("res://assets/wolf_ink.svg", ENEMY_POS, 0.34)
    add_child(player_sprite)
    add_child(enemy_sprite)
    queue_redraw()

func _make_sprite(path: String, pos: Vector2, scale_value: float) -> Sprite2D:
    var sprite := Sprite2D.new()
    var texture := load(path) as Texture2D
    sprite.texture = texture
    sprite.position = pos
    sprite.scale = Vector2.ONE * scale_value
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    return sprite

func _process(delta: float) -> void:
    pulse += delta
    breath += delta
    if player_sprite:
        player_sprite.position.y = PLAYER_POS.y + sin(pulse * 1.35) * 3.0
    if enemy_sprite:
        enemy_sprite.position.y = ENEMY_POS.y + sin(pulse * 1.75 + 1.0) * 4.0
    queue_redraw()

func _draw() -> void:
    # Characters are grounded with soft ink shadows and a restrained spiritual aura.
    _draw_shadow(PLAYER_SHADOW, Vector2(72, 15), Color(INK, 0.15))
    _draw_shadow(ENEMY_SHADOW, Vector2(66, 14), Color(INK, 0.14))

    _draw_cultivation_circle(PLAYER_POS + Vector2(0, 82), 58.0, TEAL, 0.12)
    _draw_cultivation_circle(ENEMY_POS + Vector2(0, 78), 50.0, EARTH, 0.10)

    _draw_foot_path()
    _draw_player_mark()
    _draw_enemy_mark()

func _draw_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(25):
        var a := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    draw_colored_polygon(points, color)

func _draw_cultivation_circle(center: Vector2, radius: float, color: Color, alpha: float) -> void:
    var breathing := sin(breath * 1.2) * 2.0
    draw_arc(center, radius + breathing, 0.10, PI * 0.92, 40, Color(color, alpha), 1.4, true)
    draw_arc(center, radius - 9.0, PI + 0.15, TAU - 0.15, 30, Color(color, alpha * 0.65), 1.0, true)
    for i in range(6):
        var a := float(i) / 6.0 * TAU + breath * 0.025
        var p1 := center + Vector2(cos(a), sin(a)) * (radius - 3.0)
        var p2 := center + Vector2(cos(a), sin(a)) * (radius + 6.0)
        draw_line(p1, p2, Color(color, alpha * 0.75), 1.0, true)

func _draw_foot_path() -> void:
    var start := PLAYER_SHADOW.lerp(ENEMY_SHADOW, 0.15)
    var end := ENEMY_SHADOW.lerp(PLAYER_SHADOW, 0.15)
    for i in range(7):
        var t := float(i + 1) / 8.0
        var p := start.lerp(end, t)
        var offset := Vector2(0, sin(t * PI) * 8.0)
        draw_line(p - Vector2(9, 0) + offset, p + Vector2(9, 0) + offset, Color(EARTH, 0.11), 1.0, true)

func _draw_player_mark() -> void:
    var p := PLAYER_POS + Vector2(-42, -106)
    draw_circle(p, 4.0, Color(TEAL, 0.28))
    draw_line(p + Vector2(8, 0), p + Vector2(34, 0), Color(TEAL, 0.20), 1.0, true)
    draw_string(ThemeDB.fallback_font, p + Vector2(42, 5), "修行者", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(INK_SOFT, 0.60))

func _draw_enemy_mark() -> void:
    var p := ENEMY_POS + Vector2(-37, -100)
    draw_circle(p, 4.0, Color(RED, 0.25))
    draw_line(p + Vector2(8, 0), p + Vector2(30, 0), Color(RED, 0.17), 1.0, true)
    draw_string(ThemeDB.fallback_font, p + Vector2(38, 5), "山野妖气", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(INK_SOFT, 0.56))
