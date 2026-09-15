extends Node2D

# 战斗舞台：回合制操作 + 精灵攻击位移 + HP反馈。
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var last_enemy_name := ""
var pulse := 0.0
var hit_flash := 0.0
var previous_enemy_hp := -1
var previous_player_hp := -1
var player_anim := 0.0
var enemy_anim := 0.0
var battle_turn := 1
var skill_cooldown := 0
var guarding := false
var command_buttons: Array[Button] = []
var command_modal: Control
var last_action_text := "等待出招"

const PLAYER_POS := Vector2(590, 235)
const ENEMY_POS := Vector2(835, 235)
const BAR_W := 190.0
const INK := Color("#173442")
const INK_SOFT := Color("#425455")
const PAPER := Color("#eee9dc")
const TEAL := Color("#31576a")
const TEAL_HOVER := Color("#42758a")
const EARTH := Color("#6b5740")
const EARTH_HOVER := Color("#856d50")

func _ready() -> void:
    z_index = 31
    visible = false
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    hit_flash = max(0.0, hit_flash - delta)
    player_anim = max(0.0, player_anim - delta)
    enemy_anim = max(0.0, enemy_anim - delta)

    var root := get_parent()
    if root == null:
        return
    var enemy: Dictionary = root.get("current_enemy")
    var battle_modal = root.get("modal")
    var player_data: Dictionary = root.get("player")
    var battle_open := is_instance_valid(battle_modal) and not enemy.is_empty() and not bool(player_data.get("dead", false))
    if not battle_open:
        visible = false
        last_enemy_name = ""
        previous_enemy_hp = -1
        previous_player_hp = -1
        battle_turn = 1
        skill_cooldown = 0
        guarding = false
        _clear_commands()
        return

    visible = true
    if enemy.get("name", "") != last_enemy_name:
        battle_turn = 1
        skill_cooldown = 0
        guarding = false
        last_action_text = "选择你的行动"
        _show_enemy(enemy)
        _hide_legacy_buttons(battle_modal)
        _build_commands(root, battle_modal)
        previous_enemy_hp = int(root.get("current_enemy_hp"))
        previous_player_hp = int(root.get("player").get("hp", 0))

    var enemy_hp := int(root.get("current_enemy_hp"))
    var player_data2: Dictionary = root.get("player")
    var player_hp := int(player_data2.get("hp", 0))
    var enemy_changed := enemy_hp != previous_enemy_hp
    var player_changed := player_hp != previous_player_hp
    if enemy_changed or player_changed:
        hit_flash = 0.22
        if enemy_changed and enemy_hp < previous_enemy_hp:
            player_anim = 0.16
        if player_changed and player_hp < previous_player_hp:
            enemy_anim = 0.16
        previous_enemy_hp = enemy_hp
        previous_player_hp = player_hp

    var player_offset := Vector2(0, sin(pulse * 2.0) * 3.0)
    var enemy_offset := Vector2(0, sin(pulse * 2.4 + 1.0) * 4.0)
    if player_anim > 0.0:
        player_offset.x += 34.0 * (player_anim / 0.16)
    if enemy_anim > 0.0:
        enemy_offset.x -= 34.0 * (enemy_anim / 0.16)
    if player_sprite:
        player_sprite.position = PLAYER_POS + player_offset
    if enemy_sprite:
        enemy_sprite.position = ENEMY_POS + enemy_offset
    _refresh_commands()
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

    draw_circle(Vector2(650, 240), 86.0, Color(0.72, 0.69, 0.59, 0.10))
    draw_circle(Vector2(775, 240), 86.0, Color(0.48, 0.43, 0.34, 0.09))
    draw_line(Vector2(650, 240), Vector2(775, 240), Color(0.25, 0.34, 0.35, 0.25), 2.0)
    draw_circle(Vector2(650, 240), 5.0, Color("#8b9d92"))
    draw_circle(Vector2(775, 240), 5.0, Color("#8b9d92"))
    _draw_bar(Vector2(495, 305), player_hp, player_max, "林凡  %d/%d" % [player_hp, player_max])
    _draw_bar(Vector2(740, 305), enemy_hp, enemy_max, "%s  %d/%d" % [enemy.get("name", "妖物"), enemy_hp, enemy_max])
    draw_string(ThemeDB.fallback_font, Vector2(495, 350), "第 %d 回合" % battle_turn, HORIZONTAL_ALIGNMENT_LEFT, 180, 15, Color("#5b4931"))
    draw_string(ThemeDB.fallback_font, Vector2(740, 350), last_action_text, HORIZONTAL_ALIGNMENT_LEFT, 220, 15, INK_SOFT)
    if guarding:
        draw_string(ThemeDB.fallback_font, Vector2(495, 375), "护体：本回合受到伤害降低 45%", HORIZONTAL_ALIGNMENT_LEFT, 250, 14, TEAL)
    if hit_flash > 0.0:
        var target := enemy_sprite.position if enemy_sprite else ENEMY_POS
        draw_circle(target, 58.0 + hit_flash * 30.0, Color(0.75, 0.16, 0.12, hit_flash * 1.5))

func _draw_bar(pos: Vector2, hp: int, max_hp: int, text: String) -> void:
    draw_rect(Rect2(pos, Vector2(BAR_W, 18)), Color("#243b3f"), true)
    var ratio := clamp(float(hp) / float(max_hp), 0.0, 1.0)
    draw_rect(Rect2(pos + Vector2(2, 2), Vector2((BAR_W - 4.0) * ratio, 14)), Color("#9b4b45") if ratio < 0.3 else Color("#628f78"), true)
    draw_string(ThemeDB.fallback_font, pos + Vector2(0, -7), text, HORIZONTAL_ALIGNMENT_LEFT, BAR_W, 14, Color("#294247"))

func _hide_legacy_buttons(modal: Control) -> void:
    for child in modal.get_children():
        if child is Button:
            var button: Button = child
            if button.text.contains("自动战斗") or button.text.contains("撤退"):
                button.visible = false
                button.disabled = true

func _build_commands(root: Node, modal: Control) -> void:
    _clear_commands()
    command_modal = modal
    var commands := ["普通攻击", "青云剑诀", "调息护体", "撤退"]
    for i in commands.size():
        var button := Button.new()
        button.text = commands[i]
        button.position = Vector2(485 + i * 165, 525)
        button.size = Vector2(150, 48)
        button.add_theme_font_size_override("font_size", 15)
        var primary := i < 2
        button.add_theme_color_override("font_color", PAPER)
        button.add_theme_stylebox_override("normal", _button_style(TEAL if primary else EARTH))
        button.add_theme_stylebox_override("hover", _button_style(TEAL_HOVER if primary else EARTH_HOVER))
        button.add_theme_stylebox_override("pressed", _button_style(INK))
        match i:
            0: button.pressed.connect(func(): _player_action(root, "attack"))
            1: button.pressed.connect(func(): _player_action(root, "skill"))
            2: button.pressed.connect(func(): _player_action(root, "guard"))
            3: button.pressed.connect(func(): _retreat(root))
        add_child(button)
        command_buttons.append(button)

func _clear_commands() -> void:
    for button in command_buttons:
        if is_instance_valid(button):
            button.queue_free()
    command_buttons.clear()
    command_modal = null

func _button_style(bg: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.set_corner_radius_all(7)
    style.shadow_color = Color(0, 0, 0, 0.14)
    style.shadow_size = 4
    return style

func _player_action(root: Node, action: String) -> void:
    if not is_instance_valid(command_modal):
        return
    var player: Dictionary = root.get("player")
    var enemy: Dictionary = root.get("current_enemy")
    var enemy_hp := int(root.get("current_enemy_hp"))
    if enemy.is_empty() or bool(player.get("dead", false)) or enemy_hp <= 0:
        return

    var weapon: Dictionary = root.get("equipped").get("武器", {})
    var attack := int(player.get("attack", 0)) + int(weapon.get("attack", 0))
    var damage := max(1, attack - int(enemy.get("defense", 0)) + randi_range(0, 5))

    if action == "skill":
        var learned: Array = root.get("skills")
        if not learned.has("青云剑诀"):
            last_action_text = "尚未学会青云剑诀"
            queue_redraw()
            return
        if skill_cooldown > 0:
            last_action_text = "剑诀冷却中，还需 %d 回合" % skill_cooldown
            queue_redraw()
            return
        damage = int(ceil(float(damage) * 1.30)) + 8
        skill_cooldown = 2
        last_action_text = "青云剑诀 · 斩！"
    elif action == "guard":
        guarding = true
        last_action_text = "凝神护体 · 等待反击"
    else:
        last_action_text = "一剑出鞘 · 命中 %d" % damage

    if action != "guard":
        enemy_hp = max(0, enemy_hp - damage)
        root.set("current_enemy_hp", enemy_hp)
        player_anim = 0.16

    if enemy_hp <= 0:
        _win_battle(root, enemy)
        return

    _enemy_action(root, enemy)
    var after_enemy: Dictionary = root.get("player")
    if bool(after_enemy.get("dead", false)):
        return
    battle_turn += 1
    if action != "skill" and skill_cooldown > 0:
        skill_cooldown = max(0, skill_cooldown - 1)
    guarding = false
    _refresh_commands()
    queue_redraw()

func _enemy_action(root: Node, enemy: Dictionary) -> void:
    var player: Dictionary = root.get("player")
    var armor: Dictionary = root.get("equipped").get("防具", {})
    var defense := int(player.get("defense", 0)) + int(armor.get("defense", 0))
    var damage := max(1, int(enemy.get("attack", 10)) - defense + randi_range(0, 4))
    if guarding:
        damage = max(1, int(round(damage * 0.55)))
    player.hp = max(0, int(player.get("hp", 0)) - damage)
    root.set("player", player)
    enemy_anim = 0.16
    last_action_text += " · %s反击 %d" % [enemy.get("name", "妖物"), damage]
    root._add_log("战斗：%s 反击，造成 %d 点伤害。" % [enemy.get("name", "妖物"), damage])
    if int(player.hp) <= 0:
        player.dead = true
        root.set("player", player)
        root._add_log("战斗失败：%s 将你击倒。" % enemy.get("name", "妖物"))
        root._autosave()

func _win_battle(root: Node, enemy: Dictionary) -> void:
    var player: Dictionary = root.get("player")
    var reward := int(enemy.get("reward", 0))
    player.stones = int(player.get("stones", 0)) + reward
    player.cultivation = int(player.get("cultivation", 0)) + reward
    root.set("player", player)
    root._add_log("战斗胜利：击败【%s】，获得 %d 灵石与修为。" % [enemy.get("name", "妖物"), reward])
    var battle_modal = root.get("modal")
    if is_instance_valid(battle_modal):
        battle_modal.queue_free()
    root.set("modal", null)
    root.set("current_enemy", {})
    root.set("current_enemy_hp", 0)
    _clear_commands()
    root._refresh()
    root._autosave()

func _retreat(root: Node) -> void:
    var battle_modal = root.get("modal")
    if is_instance_valid(battle_modal):
        battle_modal.queue_free()
    root.set("modal", null)
    root.set("current_enemy", {})
    root.set("current_enemy_hp", 0)
    var player: Dictionary = root.get("player")
    player.hp = max(1, int(player.get("hp", 0)) - 10)
    root.set("player", player)
    root._add_log("撤离战场：损失 10 点气血。")
    _clear_commands()
    root._refresh()

func _refresh_commands() -> void:
    var root := get_parent()
    if root == null or command_buttons.size() < 2:
        return
    var learned: Array = root.get("skills")
    command_buttons[1].disabled = not learned.has("青云剑诀") or skill_cooldown > 0
    command_buttons[1].text = "青云剑诀" if skill_cooldown <= 0 else "剑诀冷却 %d" % skill_cooldown

func _show_enemy(enemy: Dictionary) -> void:
    last_enemy_name = enemy.get("name", "")
    if player_sprite: player_sprite.queue_free()
    if enemy_sprite: enemy_sprite.queue_free()
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
