extends Node2D

# 战斗舞台：探索遭遇妖物时，把玩家与妖物精灵真正放入战斗区域。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var last_enemy_name := ""
var pulse := 0.0

const PLAYER_POS := Vector2(590, 255)
const ENEMY_POS := Vector2(835, 255)

func _ready() -> void:
    z_index = 20
    visible = false

func _process(delta: float) -> void:
    pulse += delta
    var root := get_parent()
    if root == null:
        return
    var enemy: Dictionary = root.get("current_enemy")
    var battle_modal = root.get("modal")
    var battle_open := is_instance_valid(battle_modal) and not enemy.is_empty()
    if not battle_open:
        visible = false
        return
    visible = true
    if enemy.get("name", "") != last_enemy_name:
        _show_enemy(enemy)
    if player_sprite:
        player_sprite.position = PLAYER_POS + Vector2(0, sin(pulse * 2.0) * 3.0)
    if enemy_sprite:
        enemy_sprite.position = ENEMY_POS + Vector2(0, sin(pulse * 2.4 + 1.0) * 4.0)

func _show_enemy(enemy: Dictionary) -> void:
    last_enemy_name = enemy.get("name", "")
    if player_sprite:
        player_sprite.queue_free()
    if enemy_sprite:
        enemy_sprite.queue_free()
    player_sprite = _make_sprite("res://assets/player_ink.svg", PLAYER_POS, 0.42)
    enemy_sprite = _make_sprite(enemy.get("sprite", "res://assets/wolf_ink.svg"), ENEMY_POS, 0.34)
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
