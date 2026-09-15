extends Node

# 随机奇遇系统：独立于主循环，可直接观察玩家年龄变化并触发选择事件。
var last_age := -1
var actions_since_event := 0
var event_open := false

const EVENTS := [
    {"title":"古井映月", "text":"后山古井映出一轮陌生明月。井中似有一枚玉简。", "a":"取出玉简", "b":"封井离开"},
    {"title":"白鹤传书", "text":"一只白鹤落在石阶前，衔来一封没有署名的旧信。", "a":"拆信参悟", "b":"将信焚毁"},
    {"title":"残阵遗迹", "text":"探索时发现残破阵眼，灵气正在缓慢泄漏。", "a":"修补阵眼", "b":"收取散逸灵气"},
    {"title":"山中老人", "text":"白发老人坐在古松下，说愿以一段剑意换你一杯清茶。", "a":"以茶换剑意", "b":"询问长生之道"},
    {"title":"血月妖风", "text":"夜色忽然变红，远处传来妖兽低吼。你感到危险，也感到机缘。", "a":"迎风而上", "b":"闭关避祸"}
]

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    var root := get_parent()
    if root == null or not "player" in root:
        return
    var player: Dictionary = root.get("player")
    if player.is_empty() or bool(player.get("dead", false)):
        return
    var age := int(player.get("age", 18))
    if last_age < 0:
        last_age = age
        return
    if age != last_age:
        actions_since_event += 1
        last_age = age
        if actions_since_event >= randi_range(3, 6) and not event_open:
            actions_since_event = 0
            _open_event(root)

func _open_event(root: Node) -> void:
    var event: Dictionary = EVENTS[randi_range(0, EVENTS.size() - 1)]
    event_open = true
    var old_modal = root.get("modal")
    if is_instance_valid(old_modal):
        old_modal.queue_free()
    var panel = root._panel(Vector2(455, 170), Vector2(700, 430))
    panel.z_index = 40
    root.add_child(panel)
    root.set("modal", panel)

    var title = root._label("奇遇 · " + event.title, 28, Color("#173442"))
    title.position = Vector2(30, 25)
    title.size = Vector2(620, 45)
    panel.add_child(title)

    var text = root._label(event.text + "\n\n命运没有标准答案。", 19, Color("#425455"))
    text.position = Vector2(30, 95)
    text.size = Vector2(630, 125)
    panel.add_child(text)

    var a = root._button(event.a, Vector2(45, 250), Vector2(280, 60))
    a.pressed.connect(func(): _resolve(root, panel, event, true))
    panel.add_child(a)
    var b = root._button(event.b, Vector2(370, 250), Vector2(280, 60))
    b.pressed.connect(func(): _resolve(root, panel, event, false))
    panel.add_child(b)

    var hint = root._label("每一世的选择都会留下痕迹。", 15, Color("#667272"))
    hint.position = Vector2(30, 350)
    hint.size = Vector2(620, 35)
    panel.add_child(hint)

func _resolve(root: Node, panel: Control, event: Dictionary, first: bool) -> void:
    var player: Dictionary = root.get("player")
    if first:
        player.stones += 45
        player.cultivation += 55
        player.luck += 1
        root.set("player", player)
        root._add_log("奇遇【%s】：选择「%s」，获得灵石与修为。" % [event.title, event.a])
        root.set("event_label", root.get("event_label"))
    else:
        player.max_age += 2
        player.hp = min(int(player.max_hp), int(player.hp) + 18)
        root.set("player", player)
        root._add_log("奇遇【%s】：选择「%s」，寿元上限与气血得到提升。" % [event.title, event.b])
    if is_instance_valid(panel):
        panel.queue_free()
    root.set("modal", null)
    event_open = false
    root._refresh()
    root._autosave()
