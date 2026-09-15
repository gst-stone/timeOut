extends Control

# 寿元将尽 V0.2
# 轮回核心：命格 -> 修炼/探索 -> 死亡结算 -> 永久成长 -> 下一世

const REALMS := ["炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫"]
const ENEMIES := [
    {"name":"山野狼妖", "hp":80, "attack":12, "defense":3, "reward":60},
    {"name":"黑鳞蛇妖", "hp":120, "attack":15, "defense":5, "reward":90},
    {"name":"赤焰虎", "hp":180, "attack":20, "defense":8, "reward":140},
    {"name":"青面鬼", "hp":250, "attack":25, "defense":10, "reward":220},
    {"name":"铁甲妖熊", "hp":400, "attack":35, "defense":15, "reward":350}
]

var font: Font
var player: Dictionary
var meta := {"comprehension":0, "luck":0, "physique":0}
var fate: Dictionary = {}
var fate_pool: Array = []
var logs: Array[String] = []
var status_label: Label
var resource_label: Label
var cultivation_label: Label
var hp_label: Label
var attribute_label: Label
var event_label: Label
var log_label: Label
var fate_label: Label
var center_title: Label
var action_buttons: Array[Button] = []
var overlay: ColorRect

func _ready() -> void:
    randomize()
    font = SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun", "Arial"])
    _new_life(false)
    _build_ui()
    _refresh()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#dce8e3"))
    draw_rect(Rect2(0, 0, size.x, 255), Color("#b7d0d2"))
    draw_rect(Rect2(0, 255, size.x, size.y - 255), Color("#d7dfd0"))
    var mountains = [
        PackedVector2Array([Vector2(-30,390),Vector2(210,110),Vector2(430,390)]),
        PackedVector2Array([Vector2(220,400),Vector2(535,70),Vector2(820,400)]),
        PackedVector2Array([Vector2(650,390),Vector2(980,105),Vector2(1280,390)]),
        PackedVector2Array([Vector2(1050,400),Vector2(1300,135),Vector2(1530,400)])
    ]
    for i in mountains.size():
        draw_colored_polygon(mountains[i], Color(0.28, 0.40, 0.39, 0.12 + i * 0.025))
    for x in range(0, int(size.x), 170):
        draw_line(Vector2(x,410), Vector2(x + 75,345), Color(0.2,0.3,0.3,0.11), 2)

func _new_life(is_reincarnation: bool) -> void:
    var previous_meta := meta.duplicate()
    if is_reincarnation:
        var reward := ReincarnationSystem.calculate_meta_reward(int(player.realm), int(player.level))
        meta = ReincarnationSystem.apply_reward(meta, reward)
    var life_no := int(player.get("reincarnations", -1)) + (1 if is_reincarnation else 1)
    if not is_reincarnation:
        life_no = 1
    fate_pool = _load_fates()
    fate = _roll_fate()
    var comp := 5 + int(meta.comprehension) + int(fate.get("effects", {}).get("comprehension", 0))
    var luck := 5 + int(meta.luck) + int(fate.get("effects", {}).get("luck", 0))
    var physique := 5 + int(meta.physique) + int(fate.get("effects", {}).get("physique", 0))
    var max_age := 80 + int(meta.physique) * 2 + int(fate.get("effects", {}).get("max_age", 0))
    player = {
        "name":"林凡", "age":18, "max_age":max_age, "realm":0, "level":1,
        "cultivation":0, "required":100, "hp":100 + physique * 10, "max_hp":100 + physique * 10,
        "attack":10 + physique, "defense":5 + int(physique / 2),
        "comprehension":comp, "luck":luck, "physique":physique, "stones":100,
        "reincarnations":(0 if not is_reincarnation else int(player.get("reincarnations",0)) + 1),
        "permanent_comprehension":int(meta.comprehension), "permanent_luck":int(meta.luck),
        "permanent_physique":int(meta.physique), "dead":false, "life_no":life_no
    }
    logs.clear()
    _add_log("第 %d 世开始。命格：【%s】。" % [life_no, fate.name])
    if is_reincarnation:
        _add_log("上一世留下因果：悟性 +%d，气运 +%d，体质 +%d。" % [meta.comprehension - previous_meta.comprehension, meta.luck - previous_meta.luck, meta.physique - previous_meta.physique])

func _load_fates() -> Array:
    var file := FileAccess.open("res://data/fate.json", FileAccess.READ)
    if file:
        var parsed = JSON.parse_string(file.get_as_text())
        if parsed is Dictionary and parsed.has("fates"):
            return parsed.fates
    return [{"id":"ordinary","name":"凡骨","description":"平凡，却足够坚韧。","effects":{"comprehension":0,"luck":0,"physique":1}}]

func _roll_fate() -> Dictionary:
    if fate_pool.is_empty():
        return {}
    var weighted: Array = []
    for f in fate_pool:
        var weight := 10
        if f.id == "short_life": weight = 7
        if f.id == "heavenly_root": weight = 5
        if f.id == "fortunate": weight = 5
        for i in weight: weighted.append(f)
    return weighted[randi_range(0, weighted.size()-1)].duplicate(true)

func _build_ui() -> void:
    queue_redraw()
    var header := ColorRect.new(); header.color = Color("#173442"); header.position=Vector2.ZERO; header.size=Vector2(size.x,76); add_child(header)
    var title := _label("寿元将尽",30,Color("#f3ead4")); title.position=Vector2(28,14); title.size=Vector2(190,45); add_child(title)
    status_label=_label("",17,Color("#e8f0e8")); status_label.position=Vector2(220,15); status_label.size=Vector2(800,45); add_child(status_label)
    resource_label=_label("",17,Color("#e8d9a6")); resource_label.position=Vector2(1080,17); resource_label.size=Vector2(330,40); add_child(resource_label)

    var left:=_panel(Vector2(24,96),Vector2(310,610)); add_child(left)
    var lt:=_label("这一世",24,Color("#173442")); lt.position=Vector2(22,18); lt.size=Vector2(250,38); left.add_child(lt)
    fate_label=_label("",16,Color("#5b4931")); fate_label.position=Vector2(22,70); fate_label.size=Vector2(265,130); left.add_child(fate_label)
    cultivation_label=_label("",17,Color("#254c5a")); cultivation_label.position=Vector2(22,215); cultivation_label.size=Vector2(265,55); left.add_child(cultivation_label)
    hp_label=_label("",17,Color("#254c5a")); hp_label.position=Vector2(22,275); hp_label.size=Vector2(265,55); left.add_child(hp_label)
    attribute_label=_label("",16,Color("#30434a")); attribute_label.position=Vector2(22,345); attribute_label.size=Vector2(265,220); left.add_child(attribute_label)

    var center:=_panel(Vector2(354,96),Vector2(680,610)); add_child(center)
    center_title=_label("青云宗 · 后山静修",22,Color("#173442")); center_title.position=Vector2(25,18); center_title.size=Vector2(500,38); center.add_child(center_title)
    var scene_card:=ColorRect.new(); scene_card.color=Color("#c5d6d0"); scene_card.position=Vector2(25,70); scene_card.size=Vector2(630,225); center.add_child(scene_card)
    var scene_text:=_label("云海 · 飞瀑 · 古松 · 灵气\n\n「一世只有数十年。\n你准备如何走完这一生？」",21,Color("#36535a")); scene_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; scene_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; scene_text.position=Vector2(40,82); scene_text.size=Vector2(600,200); center.add_child(scene_text)
    var action_title:=_label("当前行动",19,Color("#173442")); action_title.position=Vector2(25,320); action_title.size=Vector2(200,35); center.add_child(action_title)
    var b1:=_button("修炼 · 1年",Vector2(25,365),Vector2(195,58)); b1.pressed.connect(_cultivate); center.add_child(b1); action_buttons.append(b1)
    var b2:=_button("探索 · 1年",Vector2(242,365),Vector2(195,58)); b2.pressed.connect(_explore); center.add_child(b2); action_buttons.append(b2)
    var b3:=_button("突破",Vector2(459,365),Vector2(196,58)); b3.pressed.connect(_breakthrough); center.add_child(b3); action_buttons.append(b3)
    var save:=_button("保存",Vector2(25,440),Vector2(130,48)); save.pressed.connect(_save); center.add_child(save)
    var load:=_button("读取",Vector2(170,440),Vector2(130,48)); load.pressed.connect(_load); center.add_child(load)
    var fate_btn:=_button("查看命格",Vector2(315,440),Vector2(155,48)); fate_btn.pressed.connect(_show_fate); center.add_child(fate_btn)
    var restart:=_button("重新开局",Vector2(485,440),Vector2(170,48)); restart.pressed.connect(_restart); center.add_child(restart)
    var tip:=_label("寿元是最珍贵的资源。\n修炼提升境界，探索获得资源，也可能提前结束这一世。",15,Color("#596b69")); tip.position=Vector2(25,510); tip.size=Vector2(620,70); center.add_child(tip)

    var right:=_panel(Vector2(1056,96),Vector2(360,610)); add_child(right)
    var rt:=_label("命运记录",23,Color("#173442")); rt.position=Vector2(20,18); rt.size=Vector2(300,38); right.add_child(rt)
    event_label=_label("",17,Color("#425455")); event_label.position=Vector2(20,70); event_label.size=Vector2(320,175); right.add_child(event_label)
    var log_title:=_label("近期日志",19,Color("#173442")); log_title.position=Vector2(20,265); log_title.size=Vector2(300,35); right.add_child(log_title)
    log_label=_label("",14,Color("#667272")); log_label.position=Vector2(20,310); log_label.size=Vector2(320,245); right.add_child(log_label)

    var nav:=ColorRect.new(); nav.color=Color("#173442"); nav.position=Vector2(0,730); nav.size=Vector2(size.x,170); add_child(nav)
    var nav_items: Array[String] = ["角色","修炼","探索","战斗","装备","功法","命格","轮回"]
    for i in nav_items.size():
        var nb:=_button(nav_items[i],Vector2(35+i*177,775),Vector2(150,54)); add_child(nb)
        if nav_items[i]=="轮回": nb.pressed.connect(_reincarnate)
        if nav_items[i]=="命格": nb.pressed.connect(_show_fate)
    var footer:=_label("一世轮回，道途无尽",16,Color("#d7dfd7")); footer.position=Vector2(50,850); footer.size=Vector2(300,30); add_child(footer)

func _label(text:String,size_px:int,color:Color)->Label:
    var l:=Label.new(); l.text=text; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l

func _panel(pos:Vector2,panel_size:Vector2)->Panel:
    var p:=Panel.new(); p.position=pos; p.size=panel_size
    var s:=StyleBoxFlat.new(); s.bg_color=Color(0.95,0.94,0.87,0.94); s.border_color=Color("#9caea9"); s.set_border_width_all(2); s.set_corner_radius_all(8); p.add_theme_stylebox_override("panel",s); return p

func _button(text:String,pos:Vector2,button_size:Vector2)->Button:
    var b:=Button.new(); b.text=text; b.position=pos; b.size=button_size; b.add_theme_font_override("font",font); b.add_theme_font_size_override("font_size",15)
    var n:=StyleBoxFlat.new(); n.bg_color=Color("#31576a"); n.set_corner_radius_all(8); var h=n.duplicate(); h.bg_color=Color("#42758a"); b.add_theme_stylebox_override("normal",n); b.add_theme_stylebox_override("hover",h); b.add_theme_color_override("font_color",Color("#f4f0df")); return b

func _refresh()->void:
    status_label.text="%s    %d岁/%d岁    寿元 %d年    %s · %d层" % [player.name,player.age,player.max_age,player.max_age-player.age,REALMS[player.realm],player.level]
    resource_label.text="◆ %d 灵石    ◇ 第 %d 世" % [player.stones,player.reincarnations+1]
    cultivation_label.text="修为\n%d / %d" % [player.cultivation,player.required]
    hp_label.text="气血\n%d / %d" % [player.hp,player.max_hp]
    attribute_label.text="攻击      %d\n防御      %d\n悟性      %d\n气运      %d\n体质      %d\n\n轮回永久\n悟性 +%d   气运 +%d   体质 +%d" % [player.attack,player.defense,player.comprehension,player.luck,player.physique,meta.comprehension,meta.luck,meta.physique]
    fate_label.text="命格 · %s\n\n%s\n\n效果：%s" % [fate.name,fate.description,_format_effects(fate.effects)]
    log_label.text="\n\n".join(logs)
    for b in action_buttons: b.disabled=player.dead
    if player.dead: event_label.text="这一世已经结束。\n\n%s\n\n最终境界：%s · %d层\n\n点击底部【轮回】进入下一世。" % [fate.name,REALMS[player.realm],player.level]
    else: event_label.text="这一世的命格已经决定。\n\n%s\n\n%s" % [fate.name,fate.description]

func _format_effects(e:Dictionary)->String:
    var parts:Array[String]=[]
    if int(e.get("comprehension",0))!=0: parts.append("悟性 %+d" % int(e.comprehension))
    if int(e.get("luck",0))!=0: parts.append("气运 %+d" % int(e.luck))
    if int(e.get("physique",0))!=0: parts.append("体质 %+d" % int(e.physique))
    if int(e.get("max_age",0))!=0: parts.append("寿元上限 %+d" % int(e.max_age))
    return "、".join(parts) if not parts.is_empty() else "无"

func _add_log(text:String)->void:
    logs.push_front(text)
    if logs.size()>8: logs.pop_back()
    if is_instance_valid(log_label): log_label.text="\n\n".join(logs)

func _cultivate()->void:
    if player.dead:return
    player.age+=1
    var gain:=int(22.0*(1.0+player.comprehension*0.07))
    player.cultivation+=gain; player.hp=min(player.max_hp,player.hp+5)
    _add_log("修炼一年：修为 +%d。" % gain); event_label.text="闭关修炼\n\n灵气汇入经脉。\n\n修为 +%d\n寿元 -1年" % gain
    _check_breakthrough(); _check_death(); _refresh(); _autosave()

func _explore()->void:
    if player.dead:return
    player.age+=1
    var roll:=randf()+player.luck*0.01
    if roll<0.34:
        var enemy:Dictionary=ENEMIES[randi_range(0,min(ENEMIES.size()-1,player.realm+1))]
        var win:=_battle(enemy)
        if win:
            player.stones+=int(enemy.reward); var gain:=int(enemy.reward*0.5); player.cultivation+=gain
            event_label.text="荒野遭遇\n\n【%s】\n\n战斗胜利。\n灵石 +%d\n修为 +%d" % [enemy.name,enemy.reward,gain]; _add_log("击败 %s，获得灵石 %d。" % [enemy.name,enemy.reward])
        else:
            event_label.text="荒野遭遇\n\n【%s】\n\n你负伤逃回宗门。" % enemy.name; _add_log("与 %s 激战后落败。" % enemy.name)
    elif roll<0.72:
        var reward:=randi_range(30,120)+player.luck*3; player.stones+=reward; player.cultivation+=reward
        event_label.text="山中奇遇\n\n发现一处灵脉。\n\n灵石 +%d\n修为 +%d" % [reward,reward]; _add_log("探索发现灵脉，获得资源。")
    else:
        player.max_age+=1; player.age=max(0,player.age-1); event_label.text="寿元机缘\n\n天地灵气洗练肉身。\n\n寿元上限 +1年"; _add_log("获得长生机缘，寿元上限 +1。")
    _check_breakthrough(); _check_death(); _refresh(); _autosave()

func _battle(enemy:Dictionary)->bool:
    var ehp:int=enemy.hp
    while player.hp>0 and ehp>0:
        ehp-=max(1,player.attack-int(enemy.defense)+randi_range(-2,5))
        if ehp<=0:return true
        player.hp-=max(1,int(enemy.attack)-player.defense+randi_range(-2,4))
    return false

func _breakthrough()->void:
    if player.dead:return
    if player.cultivation<player.required:
        event_label.text="突破失败\n\n还需要 %d 点修为。" % (player.required-player.cultivation); _add_log("突破失败：修为不足。"); return
    _do_breakthrough(); _refresh(); _autosave()

func _check_breakthrough()->void:
    if player.cultivation>=player.required:_do_breakthrough()

func _do_breakthrough()->void:
    player.cultivation-=player.required
    if player.level<12: player.level+=1
    elif player.realm<REALMS.size()-1: player.realm+=1; player.level=1
    player.required=max(100,int(100.0*pow(2.0,player.realm)*player.level*player.level))
    player.max_hp+=30; player.attack+=5; player.defense+=3; player.hp=player.max_hp
    event_label.text="突破成功\n\n境界：%s · %d层\n\n气血、攻击、防御全面提升。" % [REALMS[player.realm],player.level]
    _add_log("突破成功：%s · %d层。" % [REALMS[player.realm],player.level])

func _check_death()->void:
    if player.age>=player.max_age or player.hp<=0:
        player.age=player.max_age; player.dead=true
        _add_log("第 %d 世结束。最终停留在 %s · %d层。" % [player.life_no,REALMS[player.realm],player.level])

func _reincarnate()->void:
    if not player.dead:return
    var reward:=ReincarnationSystem.calculate_meta_reward(int(player.realm),int(player.level))
    event_label.text="轮回结算\n\n本世：%s · %d层\n\n永久因果：悟性 +%d\n气运 +%d\n体质 +%d" % [REALMS[player.realm],player.level,reward.comprehension,reward.luck,reward.physique]
    _new_life(true); _refresh(); _autosave()

func _show_fate()->void:
    event_label.text="命格 · %s\n\n%s\n\n%s" % [fate.name,fate.description,_format_effects(fate.effects)]
    _add_log("查看命格：【%s】。" % fate.name)

func _save()->void:
    var data:=player.duplicate(true); data["meta"]=meta.duplicate(true); data["fate"]=fate.duplicate(true); data["logs"]=logs.duplicate()
    if SaveSystem.save_game(data): _add_log("已保存当前命运。"); event_label.text="保存成功\n\n这一世的进度已经记录。"
    else: event_label.text="保存失败\n\n无法写入本地存档。"
    _refresh()

func _autosave()->void:
    var data:=player.duplicate(true); data["meta"]=meta.duplicate(true); data["fate"]=fate.duplicate(true); data["logs"]=logs.duplicate()
    SaveSystem.save_game(data)

func _load()->void:
    var data:=SaveSystem.load_game()
    if data.is_empty(): event_label.text="暂无存档\n\n先进行一次修炼或探索吧。"; return
    player=data.duplicate(true); meta=data.get("meta",{"comprehension":0,"luck":0,"physique":0}); fate=data.get("fate",_roll_fate()); logs=data.get("logs",["读取存档成功。"])
    event_label.text="读取成功\n\n命运继续。"; _refresh()

func _restart()->void:
    meta={"comprehension":0,"luck":0,"physique":0}; _new_life(false); _refresh(); _autosave(); event_label.text="新的故事开始了。\n\n命格已经重新生成。"

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed:
        if event.keycode==KEY_R: _reincarnate()
        elif event.keycode==KEY_F5: _save()
        elif event.keycode==KEY_F9: _load()
