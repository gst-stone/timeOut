extends Node

# 轮回天赋：永久因果点 + 三条成长路线。
# 不修改主循环结构，直接利用 meta 字典持久化。
var last_life_no := -1
var panel: Control
var initialized := false

const TALENTS := [
    {"id":"insight", "name":"悟道", "desc":"永久悟性 +1", "cost":1},
    {"id":"fortune", "name":"天命", "desc":"永久气运 +1", "cost":1},
    {"id":"body", "name":"淬体", "desc":"永久体质 +1", "cost":1},
    {"id":"longevity", "name":"延寿", "desc":"每世初始寿元上限 +5", "cost":2}
]

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    var root := get_parent()
    if root == null or not "player" in root:
        return
    var player: Dictionary = root.get("player")
    if player.is_empty():
        return
    var life_no := int(player.get("life_no", 1))
    if not initialized:
        last_life_no = life_no
        initialized = true
    if life_no != last_life_no:
        last_life_no = life_no
        _grant_karma(root)

func _grant_karma(root: Node) -> void:
    var meta: Dictionary = root.get("meta")
    var karma := int(meta.get("karma", 0))
    karma += 1
    meta["karma"] = karma
    root.set("meta", meta)
    root._add_log("轮回因果：获得 1 点因果点。")
    root._refresh()
    root._autosave()

func open(root: Node) -> void:
    if is_instance_valid(panel):
        panel.queue_free()
    panel = root._panel(Vector2(420, 125), Vector2(760, 560))
    panel.z_index = 42
    root.add_child(panel)
    root.set("modal", panel)

    var meta: Dictionary = root.get("meta")
    var karma := int(meta.get("karma", 0))
    var title = root._label("轮回天赋", 28, Color("#173442"))
    title.position = Vector2(30, 22)
    title.size = Vector2(650, 42)
    panel.add_child(title)

    var info = root._label("因果点：%d\n上一世的修行不会消失，它会变成下一世的优势。" % karma, 18, Color("#425455"))
    info.position = Vector2(30, 72)
    info.size = Vector2(680, 70)
    panel.add_child(info)

    for i in TALENTS.size():
        var t: Dictionary = TALENTS[i]
        var level := int(meta.get("talent_" + t.id, 0))
        var button = root._button("%s  Lv.%d   · %d因果点" % [t.name, level, t.cost], Vector2(35, 165 + i * 78), Vector2(310, 56))
        button.pressed.connect(func(): _buy(root, t.id))
        panel.add_child(button)
        var desc = root._label(t.desc, 16, Color("#667272"))
        desc.position = Vector2(365, 170 + i * 78)
        desc.size = Vector2(330, 45)
        panel.add_child(desc)

    var close = root._button("关闭", Vector2(540, 475), Vector2(150, 52))
    close.pressed.connect(func(): _close(root))
    panel.add_child(close)

func _buy(root: Node, id: String) -> void:
    if not is_instance_valid(panel):
        return
    var meta: Dictionary = root.get("meta")
    var definition: Dictionary = {}
    for t in TALENTS:
        if t.id == id:
            definition = t
            break
    if definition.is_empty():
        return
    var karma := int(meta.get("karma", 0))
    var cost := int(definition.cost)
    if karma < cost:
        root._add_log("因果点不足，无法领悟【%s】。" % definition.name)
        return
    karma -= cost
    meta["karma"] = karma
    meta["talent_" + id] = int(meta.get("talent_" + id, 0)) + 1
    match id:
        "insight": meta.comprehension += 1
        "fortune": meta.luck += 1
        "body": meta.physique += 1
        "longevity": meta["longevity_bonus"] = int(meta.get("longevity_bonus", 0)) + 5
    root.set("meta", meta)
    root._add_log("领悟轮回天赋【%s】：%s。" % [definition.name, definition.desc])
    root._refresh()
    root._autosave()
    _close(root)

func _close(root: Node) -> void:
    if is_instance_valid(panel):
        panel.queue_free()
    panel = null
    root.set("modal", null)
