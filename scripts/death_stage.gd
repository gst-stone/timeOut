extends Node2D

# 死亡结算舞台：寿元耗尽/战败后展示本世成绩，并提供轮回/天赋入口。
var shown := false
var pulse := 0.0
var reincarnation_button: Button
var talent_button: Button

func _ready() -> void:
    z_index = 40
    visible = false

func _process(delta: float) -> void:
    pulse += delta
    var root := get_parent()
    if root == null:
        return
    var player: Dictionary = root.get("player")
    var dead := bool(player.get("dead", false))
    if not dead:
        visible = false
        shown = false
        _clear_buttons()
        return
    visible = true
    if not shown:
        shown = true
        _build_buttons(root)
    queue_redraw()

func _clear_buttons() -> void:
    if is_instance_valid(reincarnation_button):
        reincarnation_button.queue_free()
    if is_instance_valid(talent_button):
        talent_button.queue_free()
    reincarnation_button = null
    talent_button = null

func _build_buttons(root: Node) -> void:
    _clear_buttons()
    reincarnation_button = Button.new()
    reincarnation_button.text = "轮回 · 开启下一世"
    reincarnation_button.position = Vector2(465, 610)
    reincarnation_button.size = Vector2(270, 58)
    reincarnation_button.add_theme_font_size_override("font_size", 17)
    reincarnation_button.add_theme_color_override("font_color", Color("#f4f0df"))
    reincarnation_button.add_theme_stylebox_override("normal", _button_style(Color("#31576a")))
    reincarnation_button.add_theme_stylebox_override("hover", _button_style(Color("#42758a")))
    reincarnation_button.pressed.connect(func(): root._reincarnate())
    add_child(reincarnation_button)

    talent_button = Button.new()
    talent_button.text = "因果天赋"
    talent_button.position = Vector2(755, 610)
    talent_button.size = Vector2(270, 58)
    talent_button.add_theme_font_size_override("font_size", 17)
    talent_button.add_theme_color_override("font_color", Color("#f4f0df"))
    talent_button.add_theme_stylebox_override("normal", _button_style(Color("#6b5740")))
    talent_button.add_theme_stylebox_override("hover", _button_style(Color("#856d50")))
    talent_button.pressed.connect(func(): _open_talents(root))
    add_child(talent_button)

func _button_style(bg: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.set_corner_radius_all(8)
    return style

func _open_talents(root: Node) -> void:
    var talents = root.get_node_or_null("ReincarnationTalents")
    if talents and talents.has_method("open"):
        talents.open(root)

func _draw() -> void:
    if not visible:
        return
    var root := get_parent()
    if root == null:
        return
    var player: Dictionary = root.get("player")
    var meta: Dictionary = root.get("meta")
    draw_rect(Rect2(370, 85, 920, 690), Color(0.05, 0.09, 0.11, 0.94), true)
    draw_rect(Rect2(390, 105, 880, 650), Color(0.93, 0.91, 0.83, 0.99), true)
    draw_rect(Rect2(410, 125, 840, 2), Color("#9caea9"), true)
    draw_string(ThemeDB.fallback_font, Vector2(465, 180), "一世终焉", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#173442"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 225), "第 %d 世 · %s · %d 层" % [player.get("life_no",1), root.REALMS[player.get("realm",0)], player.get("level",1)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#5b4931"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 275), "享年 %d 岁 / 寿元 %d 岁" % [player.get("age",0), player.get("max_age",0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#425455"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 315), "修为 %d    灵石 %d" % [player.get("cultivation",0), player.get("stones",0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#425455"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 370), "本世沉淀", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#173442"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 410), "悟性 +%d     气运 +%d     体质 +%d" % [int(player.get("realm",0)/2), int(player.get("level",1)/4), int(player.get("realm",0)/3)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#667272"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 475), "永久因果", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#173442"))
    draw_string(ThemeDB.fallback_font, Vector2(465, 510), "悟性 %d    气运 %d    体质 %d    因果点 %d" % [meta.get("comprehension",0), meta.get("luck",0), meta.get("physique",0), meta.get("karma",0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#667272"))
    var y := 690 + sin(pulse * 2.0) * 2.0
    draw_string(ThemeDB.fallback_font, Vector2(465, y), "死亡不是终点。下一世，会从你留下的因果开始。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#5b4931"))
