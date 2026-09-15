extends Node2D

# 第一版精灵舞台：水墨淡彩人物与妖物，放在中央场景卡中。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var pulse := 0.0
const PLAYER_POS := Vector2(555, 255)
const ENEMY_POS := Vector2(835, 255)

func _ready() -> void:
	z_index = 8
	player_sprite = _make_sprite("res://assets/player_ink.svg", PLAYER_POS, 0.43)
	enemy_sprite = _make_sprite("res://assets/wolf_ink.svg", ENEMY_POS, 0.34)
	add_child(player_sprite)
	add_child(enemy_sprite)

func _make_sprite(path: String, pos: Vector2, scale_value: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	var texture := load(path) as Texture2D
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_value
	return sprite

func _process(delta: float) -> void:
	pulse += delta
	if player_sprite:
		player_sprite.position.y = PLAYER_POS.y + sin(pulse * 1.8) * 3.0
	if enemy_sprite:
		enemy_sprite.position.y = ENEMY_POS.y + sin(pulse * 2.2 + 1.0) * 4.0
