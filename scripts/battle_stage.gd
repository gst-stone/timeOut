extends Node2D

# 战斗舞台：真正显示玩家/妖物精灵、血条与受击反馈。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var last_enemy_name := ""
var pulse := 0.0
var hit_flash := 0.0
var previous_enemy_hp := -1
var previous_player_hp := -1

const PLAYER_POS := Vector2(590, 235)
const ENEMY_POS := Vector2(835, 235)
const BAR_W := 190.0

func _ready() -> void:
    z_index = 31
    visible = false
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    hit_flash = max(0.0, hit_flash - delta)
    var root := get_parent()
    if root == null:
        return
    var enemy: Dictionary = root.get("current_enemy")
    var battle_modal = root.get("modal")
    var battle_open := is_instance_valid(battle_modal) and not enemy.is_empty()
    if not battle_open:
        visible = false
        last_enemy_name = ""
        previous_enemy_hp = -1
        previous_player_hp = -1
        return
    visible = true
    var enemy_hp := int(root.get("current_enemy_hp"))
    var player_data: Dictionary = root.get("player")
    var player_hp := int(player_data.get("hp", 0))
    if enemy.get("name", "") != last_enemy_name:
        _show_enemy(enemy)
        previous_enemy_hp = enemy_hp
        previous_player_hp = player_hp
    elif enemy_hp != previous_enemy_hp or player_hp != previous_player_hp:
        hit_flash = 0.22
        previous_enemy_hp = enemy_hp
        previous_player_hp = player_hp
    if player_sprite:
        player_sprite.position = PLAYER_POS + Vector2(0, sin(pulse * 2.0) * 3.0)
    if enemy_sprite:
        enemy_sprite.position = ENEMY_POS + Vector2(0, sin(pulse * 2.4 + 1.0) * 4.0)
    queue_redraw()

func _draw() -> void:
    if not visible:
        return
    var root := get_parent()
    if root == null:
        return
    var enemy: Dictionary = root.get("current_enemy")
    var player_data: Dictionary = root.get("player")
    var enemy_hp := max(0, int(root.get("current_enemy_hp")))
    var enemy_max := max(1, int(enemy.get("hp", 1)))
    var player_hp := max(0, int(player_data.get("hp", 0)))
    var player_max := max(1, int(player_data.get("max_hp", 1)))
    _draw_bar(Vector2(495, 305), player_hp, player_max, "林凡  %d/%d" % [player_hp, player_max])
    _draw_bar(Vector2(740, 305), enemy_hp, enemy_max, "%s  %d/%d" % [enemy.get("name", "妖物"), enemy_hp, enemy_max])
    if hit_flash > 0.0:
        draw_circle(enemy_sprite.position if enemy_sprite else ENEMY_POS, 58.0 + hit_flash * 30.0, Color(0.75, 0.16, 0.12, hit_flash * 1.5))

func _draw_bar(pos: Vector2, hp: int, max_hp: int, text: String) -> void:
    draw_rect(Rect2(pos, Vector2(BAR_W, 18)), Color("#243b3f"), true)
    var ratio := clamp(float(hp) / float(max_hp), 0.0, 1.0)
    draw_rect(Rect2(pos + Vector2(2, 2), Vector2((BAR_W - 4.0) * ratio, 14)), Color("#9b4b45" if ratio < 0.3 else "#628f78"), true)
    draw_string(ThemeDB.fallback_font, pos + Vector2(0, -7), text, HORIZONTAL_ALIGNMENT_LEFT, BAR_W, 14, Color("#294247"))

func _show_enemy(enemy: Dictionary) -> void:
    last_enemy_name = enemy.get("name", "")
    if player_sprite:
        player_sprite.queue_free()
    if enemy_sprite:
        enemy_sprite.queue_free()
    player_sprite = _make_sprite("res://assets/player_ink.svg", PLAYER_POS, 0.34)
    enemy_sprite = _make_sprite(enemy.get("sprite", "res://assets/wolf_ink.svg"), ENEMY_POS, 0.30)
    add_child(player_sprite)
    add_child(enemy_sprite)

func _make_sprite(path: String, pos: Vector2, scale_value: float) -> Sprite2D:
    var sprite := Sprite2D.new()
    var texture := load(path) as Texture2D
    if texture:
        sprite.texture = texture
    sprite.position = pos
    sprite.scale = Vector2.ONE * scale_value
    return sprite
