extends Node2D

# 第一版精灵舞台：使用可缩放 SVG 精灵，保持水墨淡彩风格。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var pulse := 0.0

func _ready() -> void:
	player_sprite = _make_sprite("res://assets/player_ink.svg", Vector2(205, 365), 0.72)
	enemy_sprite = _make_sprite("res://assets/wolf_ink.svg", Vector2(475, 385), 0.58)
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
		player_sprite.position.y = 365.0 + sin(pulse * 1.8) * 3.0
	if enemy_sprite:
		enemy_sprite.position.y = 385.0 + sin(pulse * 2.2 + 1.0) * 4.0
