extends Control

# 寿元将尽 V1
# 单机修仙轮回：命格 / 修炼 / 探索 / 战斗 / 装备 / 功法 / 轮回

const REALMS := ["炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫"]
const AREAS := [
    {"name":"青云后山", "risk":1, "reward":50, "enemies":[0,1]},
    {"name":"黑风谷", "risk":2, "reward":100, "enemies":[1,2,3]},
    {"name":"赤焰秘境", "risk":3, "reward":220, "enemies":[2,3,4]}
]
const ENEMIES := [
    {"name":"山野狼妖", "hp":80, "attack":12, "defense":3, "reward":60, "sprite":"res://assets/wolf_ink.svg"},
    {"name":"黑鳞蛇妖", "hp":125, "attack":16, "defense":5, "reward":95, "sprite":"res://assets/snake_ink.svg"},
    {"name":"赤焰虎", "hp":190, "attack":21, "defense":8, "reward":145, "sprite":"res://assets/tiger_ink.svg"},
    {"name":"青面鬼", "hp":270, "attack":27, "defense":11, "reward":230, "sprite":"res://assets/wolf_ink.svg"},
    {"name":"铁甲妖熊", "hp":430, "attack":36, "defense":16, "reward":380, "sprite":"res://assets/bear_ink.svg"}
]
const EQUIPMENT := [
    {"name":"青竹剑", "slot":"武器", "attack":8, "defense":0, "desc":"普通灵竹炼制的长剑。"},
    {"name":"玄铁剑", "slot":"武器", "attack":18, "defense":2, "desc":"沉重，却锋利异常。"},
    {"name":"云纹道袍", "slot":"防具", "attack":0, "defense":10, "desc":"云纹护体，可挡风刃。"},
    {"name":"玄龟甲", "slot":"防具", "attack":0, "defense":22, "desc":"以玄龟灵甲炼制。"},
    {"name":"聚灵玉佩", "slot":"饰品", "attack":5, "defense":5, "desc":"修炼时灵气更加凝聚。"}
]
const SKILLS := [
    {"name":"吐纳诀", "type":"被动", "cost":0, "effect":0.18, "desc":"修炼收益 +18%。"},
    {"name":"青云剑诀", "type":"战斗", "cost":180, "effect":0.30, "desc":"战斗伤害 +30%。"},
    {"name":"龟息术", "type":"寿元", "cost":260, "effect":3.0, "desc":"每次行动额外获得 3 年寿元上限。"},
    {"name":"天衍术", "type":"气运", "cost":420, "effect":8.0, "desc":"探索获得稀有机缘的概率提升。"}
]

var font: Font
var player: Dictionary
var meta := {"comprehension":0, "luck":0, "physique":0}
var fate: Dictionary = {}
var logs: Array[String] = []
var equipped := {"武器":{}, "防具":{}, "饰品":{}}
var owned_equipment: Array = []
var skills: Array = []
var selected_area := 0
var current_enemy: Dictionary = {}
var current_enemy_hp := 0

var status_label: Label
var resource_label: Label
var cultivation_label: Label
var hp_label: Label
var attribute_label: Label
var event_label: Label
var log_label: Label
var fate_label: Label
var scene_text: Label
var center_title: Label
var action_buttons: Array[Button] = []
var modal: Panel

func _ready() -> void:
    randomize()
    font = SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun", "Arial"])
    _new_life(false)
    _build_ui()
    _refresh()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#dce8e3"))
    draw_rect(Rect2(0, 0, size.x, 260), Color("#b7d0d2"))
    draw_rect(Rect2(0, 260, size.x, size.y - 260), Color("#d7dfd0"))
    var mountains = [
        PackedVector2Array([Vector2(-30,390),Vector2(210,110),Vector2(430,390)]),
        PackedVector2Array([Vector2(220,400),Vector2(535,70),Vector2(820,400)]),
        PackedVector2Array([Vector2(650,390),Vector2(980,105),Vector2(1280,390)]),
        PackedVector2Array([Vector2(1050,400),Vector2(1300,135),Vector2(1530,400)])
    ]
    for i in mountains.size():
        draw_colored_polygon(mountains[i], Color(0.28, 0.40, 0.39, 0.12 + i * 0.025))

func _new_life(reincarnate: bool) -> void:
    if reincarnate:
        var gain := {"comprehension":int(player.realm / 2), "luck":int(player.level / 4), "physique":int(player.realm / 3)}
        meta.comprehension += gain.comprehension
        meta.luck += gain.luck
        meta.physique += gain.physique
    var life_no := 1 if not reincarnate else int(player.life_no) + 1
    fate = _roll_fate()
    var comp := 5 + meta.comprehension + int(fate.get("comp",0))
    var luck := 5 + meta.luck + int(fate.get("luck",0))
    var physique := 5 + meta.physique + int(fate.get("physique",0))
    var max_age := 80 + meta.physique * 2 + int(fate.get("age",0))
    player = {"name":"林凡", "life_no":life_no, "age":18, "max_age":max_age, "realm":0, "level":1,
        "cultivation":0, "required":100, "hp":100 + physique*10, "max_hp":100 + physique*10,
        "attack":10+physique, "defense":5+int(physique/2), "comprehension":comp, "luck":luck,
        "physique":physique, "stones":100, "dead":false}
    equipped={"武器":{},"防具":{},"饰品":{}}
    owned_equipment=[]
    skills=["吐纳诀"]
    logs.clear()
    _add_log("第 %d 世开始：命格【%s】。" % [life_no, fate.name])
    if reincarnate:
        _add_log("因果沉淀：永久悟性 +%d、气运 +%d、体质 +%d。" % [int(player.realm/2),int(player.level/4),int(player.realm/3)])

func _roll_fate() -> Dictionary:
    var pool=[
        {"name":"凡骨","desc":"平凡，却足够坚韧。","comp":0,"luck":0,"physique":1,"age":0,"weight":10},
        {"name":"天灵根","desc":"灵气亲和远超常人。","comp":4,"luck":1,"physique":0,"age":0,"weight":5},
        {"name":"天命眷顾","desc":"机缘往往在不经意间降临。","comp":1,"luck":6,"physique":0,"age":0,"weight":4},
        {"name":"不灭体","desc":"肉身强韧，极难倒下。","comp":0,"luck":0,"physique":5,"age":4,"weight":3},
        {"name":"短命相","desc":"寿元薄弱，但悟性惊人。","comp":5,"luck":1,"physique":0,"age":-18,"weight":4}
    ]
    var total:=0
    for f in pool: total+=f.weight
    var roll:=randi_range(1,total)
    for f in pool:
        roll-=f.weight
        if roll<=0:return f.duplicate(true)
    return pool[0]

func _build_ui() -> void:
    queue_redraw()
    var header:=ColorRect.new(); header.color=Color("#173442"); header.position=Vector2.ZERO; header.size=Vector2(size.x,76); add_child(header)
    var title:=_label("寿元将尽",30,Color("#f3ead4")); title.position=Vector2(28,14); title.size=Vector2(190,45); add_child(title)
    status_label=_label("",17,Color("#e8f0e8")); status_label.position=Vector2(220,15); status_label.size=Vector2(800,45); add_child(status_label)
    resource_label=_label("",17,Color("#e8d9a6")); resource_label.position=Vector2(1080,17); resource_label.size=Vector2(330,40); add_child(resource_label)

    var left:=_panel(Vector2(24,96),Vector2(310,610)); add_child(left)
    var lt:=_label("这一世",24,Color("#173442")); lt.position=Vector2(22,18); lt.size=Vector2(250,38); left.add_child(lt)
    fate_label=_label("",16,Color("#5b4931")); fate_label.position=Vector2(22,70); fate_label.size=Vector2(265,125); left.add_child(fate_label)
    cultivation_label=_label("",17,Color("#254c5a")); cultivation_label.position=Vector2(22,210); cultivation_label.size=Vector2(265,55); left.add_child(cultivation_label)
    hp_label=_label("",17,Color("#254c5a")); hp_label.position=Vector2(22,270); hp_label.size=Vector2(265,55); left.add_child(hp_label)
    attribute_label=_label("",15,Color("#30434a")); attribute_label.position=Vector2(22,340); attribute_label.size=Vector2(265,230); left.add_child(attribute_label)

    var center:=_panel(Vector2(354,96),Vector2(680,610)); add_child(center)
    center_title=_label("青云宗 · 后山",22,Color("#173442")); center_title.position=Vector2(25,18); center_title.size=Vector2(500,38); center.add_child(center_title)
    var scene_card:=ColorRect.new(); scene_card.color=Color("#c5d6d0"); scene_card.position=Vector2(25,70); scene_card.size=Vector2(630,225); center.add_child(scene_card)
    scene_text=_label("云海 · 飞瀑 · 古松 · 灵气\n\n一世只有数十年。\n你准备如何走完这一生？",20,Color("#36535a")); scene_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; scene_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; scene_text.position=Vector2(50,90); scene_text.size=Vector2(580,170); center.add_child(scene_text)
    var action_title:=_label("当前行动",19,Color("#173442")); action_title.position=Vector2(25,320); action_title.size=Vector2(200,35); center.add_child(action_title)
    var b1:=_button("修炼 · 1年",Vector2(25,365),Vector2(195,58)); b1.pressed.connect(_cultivate); center.add_child(b1); action_buttons.append(b1)
    var b2:=_button("探索 · 1年",Vector2(242,365),Vector2(195,58)); b2.pressed.connect(_explore); center.add_child(b2); action_buttons.append(b2)
    var b3:=_button("突破",Vector2(459,365),Vector2(196,58)); b3.pressed.connect(_breakthrough); center.add_child(b3); action_buttons.append(b3)
    var eq:=_button("装备",Vector2(25,440),Vector2(130,48)); eq.pressed.connect(_show_equipment); center.add_child(eq)
    var sk:=_button("功法",Vector2(170,440),Vector2(130,48)); sk.pressed.connect(_show_skills); center.add_child(sk)
    var ar:=_button("地图",Vector2(315,440),Vector2(155,48)); ar.pressed.connect(_show_areas); center.add_child(ar)
    var reinc:=_button("轮回",Vector2(485,440),Vector2(170,48)); reinc.pressed.connect(_reincarnate); center.add_child(reinc)
    var save:=_button("保存(F5)",Vector2(25,510),Vector2(130,48)); save.pressed.connect(_save); center.add_child(save)
    var load:=_button("读取(F9)",Vector2(170,510),Vector2(130,48)); load.pressed.connect(_load); center.add_child(load)
    var restart:=_button("重新开局",Vector2(315,510),Vector2(155,48)); restart.pressed.connect(_restart); center.add_child(restart)
    var fate_btn:=_button("命格",Vector2(485,510),Vector2(170,48)); fate_btn.pressed.connect(_show_fate); center.add_child(fate_btn)

    var right:=_panel(Vector2(1056,96),Vector2(360,610)); add_child(right)
    var rt:=_label("命运记录",23,Color("#173442")); rt.position=Vector2(20,18); rt.size=Vector2(300,38); right.add_child(rt)
    event_label=_label("",17,Color("#425455")); event_label.position=Vector2(20,70); event_label.size=Vector2(320,175); right.add_child(event_label)
    var log_title:=_label("近期日志",19,Color("#173442")); log_title.position=Vector2(20,265); log_title.size=Vector2(300,35); right.add_child(log_title)
    log_label=_label("",14,Color("#667272")); log_label.position=Vector2(20,310); log_label.size=Vector2(320,245); right.add_child(log_label)

    var nav:=ColorRect.new(); nav.color=Color("#173442"); nav.position=Vector2(0,730); nav.size=Vector2(size.x,170); add_child(nav)
    var nav_items=["角色","修炼","探索","战斗","装备","功法","命格","轮回"]
    for i in nav_items.size():
        var nb:=_button(nav_items[i],Vector2(35+i*177,775),Vector2(150,54)); add_child(nb)
        match nav_items[i]:
            "探索": nb.pressed.connect(_show_areas)
            "装备": nb.pressed.connect(_show_equipment)
            "功法": nb.pressed.connect(_show_skills)
            "命格": nb.pressed.connect(_show_fate)
            "轮回": nb.pressed.connect(_reincarnate)
            "战斗": nb.pressed.connect(_show_battle_info)
    var footer:=_label("一世轮回，道途无尽",16,Color("#d7dfd7")); footer.position=Vector2(50,850); footer.size=Vector2(300,30); add_child(footer)

func _label(text:String,size_px:int,color:Color)->Label:
    var l:=Label.new(); l.text=text; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l

func _panel(pos:Vector2,panel_size:Vector2)->Panel:
    var p:=Panel.new(); p.position=pos; p.size=panel_size
    var s:=StyleBoxFlat.new(); s.bg_color=Color(0.95,0.94,0.87,0.96); s.border_color=Color("#9caea9"); s.set_border_width_all(2); s.set_corner_radius_all(8); p.add_theme_stylebox_override("panel",s); return p

func _button(text:String,pos:Vector2,button_size:Vector2)->Button:
    var b:=Button.new(); b.text=text; b.position=pos; b.size=button_size; b.add_theme_font_override("font",font); b.add_theme_font_size_override("font_size",15)
    var n:=StyleBoxFlat.new(); n.bg_color=Color("#31576a"); n.set_corner_radius_all(8); var h=n.duplicate(); h.bg_color=Color("#42758a"); b.add_theme_stylebox_override("normal",n); b.add_theme_stylebox_override("hover",h); b.add_theme_color_override("font_color",Color("#f4f0df")); return b

func _refresh()->void:
    var atk:=_attack(); var defense:=_defense()
    status_label.text="%s    %d岁/%d岁    余寿 %d年    %s · %d层" % [player.name,player.age,player.max_age,player.max_age-player.age,REALMS[player.realm],player.level]
    resource_label.text="◆ %d 灵石    ◇ 第 %d 世" % [player.stones,player.life_no]
    cultivation_label.text="修为\n%d / %d" % [player.cultivation,player.required]
    hp_label.text="气血\n%d / %d" % [player.hp,player.max_hp]
    attribute_label.text="攻击      %d\n防御      %d\n悟性      %d\n气运      %d\n体质      %d\n\n装备：%d件\n功法：%s\n\n永久因果\n悟性 +%d   气运 +%d   体质 +%d" % [atk,defense,player.comprehension,player.luck,player.physique,owned_equipment.size(),", ".join(skills),meta.comprehension,meta.luck,meta.physique]
    fate_label.text="命格 · %s\n\n%s\n\n效果：悟性 %+d  气运 %+d  体质 %+d  寿元 %+d" % [fate.name,fate.desc,fate.comp,fate.luck,fate.physique,fate.age]
    log_label.text="\n\n".join(logs)
    for b in action_buttons: b.disabled=player.dead
    if player.dead:
        event_label.text="这一世已经结束。\n\n最终境界：%s · %d层\n\n点击【轮回】继承因果。" % [REALMS[player.realm],player.level]
    else:
        event_label.text="命格【%s】\n\n%s\n\n当前地区：%s" % [fate.name,fate.desc,AREAS[selected_area].name]

func _attack()->int:
    var value:=int(player.attack)
    for e in equipped.values(): value+=int(e.get("attack",0))
    return value

func _defense()->int:
    var value:=int(player.defense)
    for e in equipped.values(): value+=int(e.get("defense",0))
    return value

func _add_log(text:String)->void:
    logs.push_front(text)
    if logs.size()>8: logs.pop_back()
    if is_instance_valid(log_label): log_label.text="\n\n".join(logs)

func _cultivate()->void:
    if player.dead:return
    player.age+=1
    var gain:=int(22.0*(1.0+player.comprehension*0.07))
    if "吐纳诀" in skills: gain=int(gain*1.18)
    player.cultivation+=gain
    player.hp=min(player.max_hp,player.hp+8)
    if "龟息术" in skills: player.max_age+=3
    _add_log("静修一年：修为 +%d。" % gain)
    event_label.text="闭关修炼\n\n灵气汇入经脉。\n\n修为 +%d\n寿元 -1年" % gain
    _check_breakthrough(); _check_death(); _refresh(); _autosave()

func _explore()->void:
    if player.dead:return
    player.age+=1
    var area:=AREAS[selected_area]
    var risk:=float(area.risk)*0.22
    var roll:=randf()+player.luck*0.01
    if roll<risk:
        var ids:Array=area.enemies
        current_enemy=ENEMIES[ids[randi_range(0,ids.size()-1)]]
        _show_battle(current_enemy)
        return
    elif roll<0.75:
        var reward:=randi_range(30,100)+player.luck*3+int(area.reward)
        player.stones+=reward; player.cultivation+=reward
        if randf()<0.12+player.luck*0.005:
            var drop:=EQUIPMENT[randi_range(0,EQUIPMENT.size()-1)].duplicate(true); owned_equipment.append(drop); _add_log("探索获得装备：%s。" % drop.name)
        event_label.text="探索奇遇\n\n发现灵脉与遗迹。\n\n灵石 +%d\n修为 +%d" % [reward,reward]
        _add_log("在%s发现机缘，获得 %d 灵石。" % [area.name,reward])
    else:
        player.max_age+=1; player.age=max(18,player.age-1)
        event_label.text="寿元机缘\n\n灵泉洗练肉身。\n\n寿元上限 +1年"; _add_log("获得长生机缘。")
    _check_breakthrough(); _check_death(); _refresh(); _autosave()

func _show_battle(enemy:Dictionary)->void:
    current_enemy_hp=int(enemy.hp)
    modal=_panel(Vector2(455,145),Vector2(700,510)); modal.z_index=30; add_child(modal)
    var t:=_label("遭遇 · %s" % enemy.name,26,Color("#173442")); t.position=Vector2(25,20); t.size=Vector2(600,40); modal.add_child(t)
    var info:=_label("你的攻击 %d / 防御 %d\n妖物：%d HP / 攻击 %d / 防御 %d" % [_attack(),_defense(),enemy.hp,enemy.attack,enemy.defense],18,Color("#425455")); info.position=Vector2(25,80); info.size=Vector2(620,90); modal.add_child(info)
    var fight:=_button("自动战斗",Vector2(25,205),Vector2(190,58)); fight.pressed.connect(_battle_once); modal.add_child(fight)
    var retreat:=_button("撤退",Vector2(235,205),Vector2(190,58)); retreat.pressed.connect(_retreat_battle); modal.add_child(retreat)
    var note:=_label("战斗胜利可获得灵石、修为与装备。\n战败不会立即结束人生，但会损失大量气血。",16,Color("#667272")); note.position=Vector2(25,300); note.size=Vector2(620,100); modal.add_child(note)

func _battle_once()->void:
    if not is_instance_valid(modal):return
    var enemy:=current_enemy
    var ehp:=current_enemy_hp
    var rounds:=0
    while player.hp>0 and ehp>0 and rounds<30:
        ehp-=max(1,_attack()-int(enemy.defense)+randi_range(-2,5)+(10 if "青云剑诀" in skills else 0))
        if ehp<=0:break
        player.hp-=max(1,int(enemy.attack)-_defense()+randi_range(-2,4))
        rounds+=1
    current_enemy_hp=ehp
    modal.queue_free(); modal=null
    if player.hp>0:
        player.stones+=int(enemy.reward); player.cultivation+=int(enemy.reward*0.6)
        if randf()<0.25:
            var drop:=EQUIPMENT[randi_range(0,EQUIPMENT.size()-1)].duplicate(true); owned_equipment.append(drop); _add_log("战利品：%s。" % drop.name)
        _add_log("击败 %s，获得 %d 灵石。" % [enemy.name,enemy.reward])
        event_label.text="战斗胜利\n\n%s 倒下了。\n\n灵石 +%d" % [enemy.name,enemy.reward]
    else:
        player.hp=0; _add_log("与 %s 激战后重伤。" % enemy.name); event_label.text="战斗失败\n\n你身受重伤。"
        _check_death()
    _refresh(); _autosave()

func _retreat_battle()->void:
    if is_instance_valid(modal): modal.queue_free()
    modal=null; player.hp=max(1,player.hp-10); _add_log("从战场撤退，损失 10 气血。"); _refresh(); _autosave()

func _show_battle_info()->void:
    event_label.text="战斗\n\n探索可能遭遇妖物。\n当前地区：%s\n危险等级：%d\n\n攻击：%d\n防御：%d" % [AREAS[selected_area].name,AREAS[selected_area].risk,_attack(),_defense()]

func _check_breakthrough()->void:
    if player.cultivation>=player.required:_do_breakthrough()

func _breakthrough()->void:
    if player.dead:return
    if player.cultivation<player.required:
        event_label.text="突破失败\n\n还差 %d 点修为。" % (player.required-player.cultivation); _add_log("突破失败：修为不足。"); return
    _do_breakthrough(); _refresh(); _autosave()

func _do_breakthrough()->void:
    player.cultivation-=player.required
    if player.level<12: player.level+=1
    elif player.realm<REALMS.size()-1: player.realm+=1; player.level=1
    player.required=max(100,int(100.0*pow(2.0,player.realm)*player.level*player.level))
    player.max_hp+=30; player.attack+=5; player.defense+=3; player.hp=player.max_hp
    _add_log("突破成功：%s · %d层。" % [REALMS[player.realm],player.level])
    event_label.text="突破成功\n\n%s · %d层\n\n气血、攻击、防御全面提升。" % [REALMS[player.realm],player.level]

func _check_death()->void:
    if player.age>=player.max_age or player.hp<=0:
        player.age=player.max_age; player.dead=true
        _add_log("第 %d 世结束：%s · %d层。" % [player.life_no,REALMS[player.realm],player.level])

func _reincarnate()->void:
    if not player.dead:
        event_label.text="轮回尚未开启\n\n寿元耗尽或战死后，才能进入轮回。"; return
    var old_realm:=player.realm; var old_level:=player.level
    var gain_comp:=int(old_realm/2); var gain_luck:=int(old_level/4); var gain_phys:=int(old_realm/3)
    meta.comprehension+=gain_comp; meta.luck+=gain_luck; meta.physique+=gain_phys
    _new_life(true)
    event_label.text="轮回归来\n\n上一世：%s · %d层\n\n永久悟性 +%d\n永久气运 +%d\n永久体质 +%d" % [REALMS[old_realm],old_level,gain_comp,gain_luck,gain_phys]
    _refresh(); _autosave()

func _show_fate()->void:
    event_label.text="命格 · %s\n\n%s\n\n悟性 %+d\n气运 %+d\n体质 %+d\n寿元 %+d" % [fate.name,fate.desc,fate.comp,fate.luck,fate.physique,fate.age]

func _show_areas()->void:
    modal=_panel(Vector2(450,145),Vector2(720,510)); modal.z_index=30; add_child(modal)
    var t:=_label("选择探索地区",26,Color("#173442")); t.position=Vector2(25,20); t.size=Vector2(600,40); modal.add_child(t)
    for i in AREAS.size():
        var a:=AREAS[i]
        var b:=_button("%s   危险 %d" % [a.name,a.risk],Vector2(25,80+i*80),Vector2(300,58)); b.pressed.connect(func(): _select_area(i)); modal.add_child(b)
        var d:=_label("基础收益：%d灵石\n适合境界：%s" % [a.reward,"炼气-筑基" if i==0 else ("金丹-元婴" if i==1 else "元婴以上")],16,Color("#667272")); d.position=Vector2(350,85+i*80); d.size=Vector2(330,60); modal.add_child(d)

func _select_area(i:int)->void:
    selected_area=i
    if is_instance_valid(modal): modal.queue_free()
    modal=null; _add_log("探索地点切换为：%s。" % AREAS[i].name); _refresh()

func _show_equipment()->void:
    modal=_panel(Vector2(420,130),Vector2(780,550)); modal.z_index=30; add_child(modal)
    var t:=_label("装备",26,Color("#173442")); t.position=Vector2(25,20); t.size=Vector2(600,40); modal.add_child(t)
    var y:=80
    for item in owned_equipment:
        var b:=_button("装备 %s  [%s]" % [item.name,item.slot],Vector2(25,y),Vector2(320,52)); b.pressed.connect(func(): _equip(item)); modal.add_child(b)
        var d:=_label("攻击 +%d  防御 +%d\n%s" % [item.attack,item.defense,item.desc],15,Color("#667272")); d.position=Vector2(370,y+3); d.size=Vector2(360,52); modal.add_child(d); y+=70
    if owned_equipment.is_empty():
        var empty:=_label("目前没有装备。\n探索和战斗都有机会获得装备。",18,Color("#667272")); empty.position=Vector2(25,90); empty.size=Vector2(600,100); modal.add_child(empty)
    var close:=_button("关闭",Vector2(570,465),Vector2(150,50)); close.pressed.connect(func(): modal.queue_free()); modal.add_child(close)

func _equip(item:Dictionary)->void:
    equipped[item.slot]=item.duplicate(true); _add_log("装备 %s。" % item.name); if is_instance_valid(modal): modal.queue_free(); modal=null; _refresh()

func _show_skills()->void:
    modal=_panel(Vector2(420,130),Vector2(780,550)); modal.z_index=30; add_child(modal)
    var t:=_label("功法",26,Color("#173442")); t.position=Vector2(25,20); t.size=Vector2(600,40); modal.add_child(t)
    var y:=80
    for s in SKILLS:
        var learned:=s.name in skills
        var b:=_button(("已修习 · " if learned else "学习 · ")+s.name,Vector2(25,y),Vector2(320,52)); b.disabled=learned; b.pressed.connect(func(): _learn_skill(s)); modal.add_child(b)
        var d:=_label("%s / %s\n%s" % [s.type,("已掌握" if learned else "%d灵石" % s.cost),s.desc],15,Color("#667272")); d.position=Vector2(370,y+2); d.size=Vector2(360,56); modal.add_child(d); y+=78
    var close:=_button("关闭",Vector2(570,465),Vector2(150,50)); close.pressed.connect(func(): modal.queue_free()); modal.add_child(close)

func _learn_skill(skill:Dictionary)->void:
    if player.stones<int(skill.cost):
        event_label.text="灵石不足\n\n还需要 %d 灵石。" % (int(skill.cost)-player.stones); return
    player.stones-=int(skill.cost); skills.append(skill.name); _add_log("领悟功法：%s。" % skill.name); if is_instance_valid(modal): modal.queue_free(); modal=null; _refresh()

func _save()->void:
    var data={"player":player,"meta":meta,"fate":fate,"logs":logs,"equipped":equipped,"owned_equipment":owned_equipment,"skills":skills,"area":selected_area,"time":Time.get_unix_time_from_system()}
    var file:=FileAccess.open("user://shouyuan_save.json",FileAccess.WRITE)
    if file: file.store_string(JSON.stringify(data)); file.close(); event_label.text="保存成功\n\n当前命运已记录。"

func _autosave()->void:
    var data={"player":player,"meta":meta,"fate":fate,"logs":logs,"equipped":equipped,"owned_equipment":owned_equipment,"skills":skills,"area":selected_area,"time":Time.get_unix_time_from_system()}
    var file:=FileAccess.open("user://shouyuan_save.json",FileAccess.WRITE)
    if file: file.store_string(JSON.stringify(data)); file.close()

func _load()->void:
    if not FileAccess.file_exists("user://shouyuan_save.json"):
        event_label.text="暂无存档\n\n先开始这一世。"; return
    var file:=FileAccess.open("user://shouyuan_save.json",FileAccess.READ); var data=JSON.parse_string(file.get_as_text()); file.close()
    if not data is Dictionary:return
    player=data.get("player",player); meta=data.get("meta",meta); fate=data.get("fate",fate); logs=data.get("logs",[]); equipped=data.get("equipped",equipped); owned_equipment=data.get("owned_equipment",[]); skills=data.get("skills",["吐纳诀"]); selected_area=int(data.get("area",0)); event_label.text="读取成功\n\n命运继续。"; _refresh()

func _restart()->void:
    meta={"comprehension":0,"luck":0,"physique":0}; _new_life(false); _refresh(); _autosave(); event_label.text="新的故事开始了。"

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed:
        if event.keycode==KEY_R:_reincarnate()
        elif event.keycode==KEY_F5:_save()
        elif event.keycode==KEY_F9:_load()
