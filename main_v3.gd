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
var font_title: Font
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
var fate_chip: Label
var extra_label: Label
var area_info_label: Label
var break_info_label: Label
var equip_info_label: Label
var skill_info_label: Label
var nav_info_label: Label
var cultivation_bar: ProgressBar
var hp_bar: ProgressBar
var scene_text: Label
var center_title: Label
var action_buttons: Array[Button] = []
var modal: Panel

const AVATAR_SHADER_CODE := "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tif (distance(UV, vec2(0.5)) > 0.5) discard;\n\tCOLOR = c;\n}"

func _ready() -> void:
	randomize()
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun", "Arial"])
	font_title = font
	if ResourceLoader.exists("res://assets/fonts/LXGWWenKai-Regular.ttf"):
		font = load("res://assets/fonts/LXGWWenKai-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/MaShanZheng-Regular.ttf"):
		font_title = load("res://assets/fonts/MaShanZheng-Regular.ttf")
	var ink := get_node_or_null("InkWorldStage")
	if ink and ResourceLoader.exists("res://assets/bg_ink_landscape.png"):
		ink.overlay_only = true
	_new_life(false)
	_build_ui()
	_refresh()

func _draw() -> void:
	# 背景交给 InkWorldStage 绘制整幅水墨山水，这里保持透明，
	# 让 UI 以半透明宣纸卡片浮于山水之上。
	pass

func _new_life(reincarnate: bool) -> void:
	if reincarnate:
		var gain := {"comprehension":int(player.realm / 2), "luck":int(player.level / 4), "physique":int(player.realm / 3)}
		meta.comprehension += gain.comprehension
		meta.luck += gain.luck
		meta.physique += gain.physique
	var life_no := 1 if not reincarnate else int(player.life_no) + 1
	fate = _roll_fate()
	var comp = 5 + meta.comprehension + int(fate.get("comp",0))
	var luck = 5 + meta.luck + int(fate.get("luck",0))
	var physique = 5 + meta.physique + int(fate.get("physique",0))
	var max_age = 80 + meta.physique * 2 + int(fate.get("age",0))
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
	# ── 背景大图：手绘水墨山水（InkWorldStage 降级为动态云雾叠加层）──
	if ResourceLoader.exists("res://assets/bg_ink_landscape.png"):
		var bg:=TextureRect.new(); bg.texture=load("res://assets/bg_ink_landscape.png"); bg.position=Vector2.ZERO; bg.size=size
		bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; bg.z_index=-6
		add_child(bg)
	# ── 顶栏：悬浮墨玉长条（头像 / 姓名 / 状态 / 灵石 / 设置）──
	var top:=_ink_bar(Vector2(16,12),Vector2(1408,58),0.84,28); add_child(top)
	var avatar:=Panel.new(); avatar.position=Vector2(34,9); avatar.size=Vector2(40,40)
	var av_s:=StyleBoxFlat.new(); av_s.bg_color=Color("#31576a"); av_s.set_corner_radius_all(20); av_s.border_color=Color(Color("#f3ead4"),0.45); av_s.set_border_width_all(2)
	avatar.add_theme_stylebox_override("panel",av_s); top.add_child(avatar)
	if ResourceLoader.exists("res://assets/avatar_linfan.png"):
		var av_img:=TextureRect.new(); av_img.texture=load("res://assets/avatar_linfan.png")
		av_img.position=Vector2(4,4); av_img.size=Vector2(32,32)
		av_img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; av_img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		av_img.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var sh:=Shader.new(); sh.code=AVATAR_SHADER_CODE
		var mat:=ShaderMaterial.new(); mat.shader=sh; av_img.material=mat
		avatar.add_child(av_img)
	else:
		var av_char:=_label("林",17,Color("#f3ead4")); av_char.position=Vector2.ZERO; av_char.size=Vector2(40,40); av_char.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; av_char.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; avatar.add_child(av_char)
	var name_label:=_label("林凡",19,Color("#f3ead4")); name_label.position=Vector2(88,15); name_label.size=Vector2(66,28); name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; top.add_child(name_label)
	status_label=_label("",16,Color("#dfe8e4")); status_label.position=Vector2(162,15); status_label.size=Vector2(660,28); status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; top.add_child(status_label)
	resource_label=_label("",16,Color("#e8d9a6")); resource_label.position=Vector2(950,15); resource_label.size=Vector2(350,28); resource_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; resource_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; top.add_child(resource_label)
	var settings:=_button("设 置",Vector2(1314,9),Vector2(84,40)); settings.pressed.connect(_show_settings); top.add_child(settings)

	# ── 左：角色属性宣纸卡（修为/气血条 + 属性 + 命格 + 永久因果）──
	var left:=_panel(Vector2(16,84),Vector2(300,532)); add_child(left)
	var lt:=_title_label("角色属性",20,Color("#173442")); lt.position=Vector2(20,12); lt.size=Vector2(220,32); left.add_child(lt)
	cultivation_label=_label("",15,Color("#254c5a")); cultivation_label.position=Vector2(20,52); cultivation_label.size=Vector2(260,24); left.add_child(cultivation_label)
	cultivation_bar=_bar(Vector2(20,82),Vector2(260,12),Color("#31576a")); left.add_child(cultivation_bar)
	hp_label=_label("",15,Color("#254c5a")); hp_label.position=Vector2(20,102); hp_label.size=Vector2(260,24); left.add_child(hp_label)
	hp_bar=_bar(Vector2(20,132),Vector2(260,12),Color("#9b4b45")); left.add_child(hp_bar)
	attribute_label=_label("",15,Color("#30434a")); attribute_label.position=Vector2(20,158); attribute_label.size=Vector2(260,148); left.add_child(attribute_label)
	fate_label=_label("",14,Color("#5b4931")); fate_label.position=Vector2(20,312); fate_label.size=Vector2(260,118); left.add_child(fate_label)
	extra_label=_label("",13,Color("#667272")); extra_label.position=Vector2(20,436); extra_label.size=Vector2(260,80); left.add_child(extra_label)

	# ── 中：开放式山水主景（无面板遮挡），宗门徽记 + 漂浮事件文字 + 主行动 ──
	var chip:=_ink_bar(Vector2(346,92),Vector2(208,46),0.78,12); add_child(chip)
	center_title=_title_label("青云宗 · 后山",19,Color("#f3ead4")); center_title.position=Vector2(14,8); center_title.size=Vector2(184,30); center_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; chip.add_child(center_title)
	fate_chip=_label("",14,Color("#f7f3e8")); fate_chip.position=Vector2(352,148); fate_chip.size=Vector2(340,24); _shadow(fate_chip); add_child(fate_chip)
	scene_text=_label("云海 · 飞瀑 · 古松 · 灵气\n一世只有数十年，你准备如何走完这一生？",20,Color("#f7f3e8")); scene_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; scene_text.position=Vector2(420,176); scene_text.size=Vector2(600,104); _shadow(scene_text); add_child(scene_text)
	var b1:=_button("修炼 · 1年",Vector2(455,560),Vector2(170,54)); b1.pressed.connect(_cultivate); add_child(b1); action_buttons.append(b1)
	var b2:=_button("探索 · 1年",Vector2(635,560),Vector2(170,54)); b2.pressed.connect(_explore); add_child(b2); action_buttons.append(b2)
	var b3:=_button("突　破",Vector2(815,560),Vector2(170,54)); b3.pressed.connect(_breakthrough); add_child(b3); action_buttons.append(b3)

	# ── 右：当前事件 + 近期日志 ──
	var right:=_panel(Vector2(1116,84),Vector2(308,270)); add_child(right)
	var rt:=_title_label("当前事件",18,Color("#173442")); rt.position=Vector2(18,12); rt.size=Vector2(240,30); right.add_child(rt)
	if ResourceLoader.exists("res://assets/event_ink_spring.png"):
		var ev_img:=TextureRect.new(); ev_img.texture=load("res://assets/event_ink_spring.png")
		ev_img.position=Vector2(18,44); ev_img.size=Vector2(272,92)
		ev_img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; ev_img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ev_img.mouse_filter=Control.MOUSE_FILTER_IGNORE; right.add_child(ev_img)
		event_label=_label("",15,Color("#425455")); event_label.position=Vector2(18,142); event_label.size=Vector2(272,112); right.add_child(event_label)
	else:
		event_label=_label("",15,Color("#425455")); event_label.position=Vector2(18,50); event_label.size=Vector2(272,204); right.add_child(event_label)
	var right2:=_panel(Vector2(1116,370),Vector2(308,246)); add_child(right2)
	var log_title:=_title_label("近期日志",18,Color("#173442")); log_title.position=Vector2(18,12); log_title.size=Vector2(240,30); right2.add_child(log_title)
	log_label=_label("",13,Color("#667272")); log_label.position=Vector2(18,48); log_label.size=Vector2(272,188); right2.add_child(log_label)

	# ── 底部行动卡：修炼 / 探索 / 突破 / 装备 / 功法 / 系统 ──
	var card_defs: Array[String] = ["修炼","探索","突破","装备","功法","系统"]
	for i in card_defs.size():
		var cp:=_panel(Vector2(36+i*230,624),Vector2(218,148)); add_child(cp)
		var ct:=_title_label(card_defs[i],17,Color("#173442")); ct.position=Vector2(16,10); ct.size=Vector2(180,28); cp.add_child(ct)
		var info:=_label("",13,Color("#667272")); info.position=Vector2(16,40); info.size=Vector2(186,46); cp.add_child(info)
		match card_defs[i]:
			"修炼":
				info.text="静修一年，吐纳灵气。"
				var cb:=_button("修炼 · 1年",Vector2(16,92),Vector2(186,44)); cb.pressed.connect(_cultivate); cp.add_child(cb); action_buttons.append(cb)
			"探索":
				area_info_label=info
				var eb:=_button("探索 · 1年",Vector2(16,92),Vector2(186,44)); eb.pressed.connect(_explore); cp.add_child(eb); action_buttons.append(eb)
			"突破":
				break_info_label=info
				var bb:=_button("突　破",Vector2(16,92),Vector2(186,44)); bb.pressed.connect(_breakthrough); cp.add_child(bb); action_buttons.append(bb)
			"装备":
				equip_info_label=info
				var qb:=_button("装　备",Vector2(16,92),Vector2(186,44)); qb.pressed.connect(_show_equipment); cp.add_child(qb)
			"功法":
				skill_info_label=info
				var gb:=_button("功　法",Vector2(16,92),Vector2(186,44)); gb.pressed.connect(_show_skills); cp.add_child(gb)
			"系统":
				info.text="因果长存，随时归来。"
				var sv:=_button("保存",Vector2(16,92),Vector2(57,44)); sv.pressed.connect(_save); cp.add_child(sv)
				var ld:=_button("读取",Vector2(77,92),Vector2(57,44)); ld.pressed.connect(_load); cp.add_child(ld)
				var rs:=_button("重开",Vector2(138,92),Vector2(64,44)); rs.pressed.connect(_restart); cp.add_child(rs)

	# ── 底部导航：墨玉浮条 + 下一世 ──
	var nav:=_ink_bar(Vector2(16,786),Vector2(1408,100),0.88,24); add_child(nav)
	var nav_items: Array[String] = ["角色","修炼","探索","战斗","装备","功法","命格","轮回"]
	var logo:=_title_label("寿元将尽",24,Color("#f3ead4")); logo.position=Vector2(28,8); logo.size=Vector2(200,40); logo.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; nav.add_child(logo)
	var footer:=_label("一世轮回，道途无尽",12,Color("#9fb4b8")); footer.position=Vector2(30,52); footer.size=Vector2(200,24); nav.add_child(footer)
	var nav_x := 236
	for i in nav_items.size():
		var nb:=_button(nav_items[i],Vector2(nav_x+i*109,12),Vector2(100,46)); nav.add_child(nb)
		match nav_items[i]:
			"修炼": nb.pressed.connect(_cultivate)
			"探索": nb.pressed.connect(_show_areas)
			"战斗": nb.pressed.connect(_show_battle_info)
			"装备": nb.pressed.connect(_show_equipment)
			"功法": nb.pressed.connect(_show_skills)
			"命格": nb.pressed.connect(_show_fate)
			"轮回": nb.pressed.connect(_reincarnate)
	nav_info_label=_label("",14,Color("#e8d9a6")); nav_info_label.position=Vector2(1112,17); nav_info_label.size=Vector2(130,36); nav_info_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; nav.add_child(nav_info_label)
	var next_life:=_button("下一世 ▶",Vector2(1250,12),Vector2(154,46)); next_life.pressed.connect(_reincarnate); nav.add_child(next_life)

func _label(text:String,size_px:int,color:Color)->Label:
	var l:=Label.new(); l.text=text; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l

func _title_label(text:String,size_px:int,color:Color)->Label:
	# 标题/徽记用书法字体，正文用文楷。
	var l:=_label(text,size_px,color); l.add_theme_font_override("font",font_title); return l

func _panel(pos:Vector2,panel_size:Vector2)->Panel:
	var p:=Panel.new(); p.position=pos; p.size=panel_size
	var s:=StyleBoxFlat.new(); s.bg_color=Color(0.96,0.94,0.88,0.92); s.border_color=Color("#a89f8b"); s.set_border_width_all(1); s.set_corner_radius_all(12)
	s.shadow_color=Color(0.05,0.10,0.10,0.18); s.shadow_size=10; s.shadow_offset=Vector2(0,4)
	p.add_theme_stylebox_override("panel",s); return p

func _ink_bar(pos:Vector2,bar_size:Vector2,alpha:float,radius:int)->Panel:
	var p:=Panel.new(); p.position=pos; p.size=bar_size
	var s:=StyleBoxFlat.new(); s.bg_color=Color(Color("#1c3644"),alpha); s.set_corner_radius_all(radius)
	s.border_color=Color(Color("#3d5a66"),0.6); s.set_border_width_all(1)
	s.shadow_color=Color(0.05,0.10,0.10,0.25); s.shadow_size=8; s.shadow_offset=Vector2(0,3)
	p.add_theme_stylebox_override("panel",s); return p

func _bar(pos:Vector2,bar_size:Vector2,fill:Color)->ProgressBar:
	var pb:=ProgressBar.new(); pb.position=pos; pb.size=bar_size; pb.show_percentage=false
	var bg:=StyleBoxFlat.new(); bg.bg_color=Color(0.10,0.20,0.22,0.18); bg.set_corner_radius_all(6)
	var fg:=StyleBoxFlat.new(); fg.bg_color=fill; fg.set_corner_radius_all(6)
	pb.add_theme_stylebox_override("background",bg); pb.add_theme_stylebox_override("fill",fg)
	return pb

func _shadow(l:Label)->void:
	l.add_theme_color_override("font_shadow_color",Color(0.07,0.16,0.20,0.6))
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",2)

func _button(text:String,pos:Vector2,button_size:Vector2)->Button:
	var b:=Button.new(); b.text=text; b.position=pos; b.size=button_size; b.add_theme_font_override("font",font); b.add_theme_font_size_override("font_size",15)
	var n:=StyleBoxFlat.new(); n.bg_color=Color("#31576a"); n.set_corner_radius_all(9); n.border_color=Color(1,1,1,0.10); n.set_border_width_all(1)
	var h:=StyleBoxFlat.new(); h.bg_color=Color("#42758a"); h.set_corner_radius_all(9); h.border_color=Color(1,1,1,0.14); h.set_border_width_all(1)
	var pr:=StyleBoxFlat.new(); pr.bg_color=Color("#173442"); pr.set_corner_radius_all(9)
	var dis:=StyleBoxFlat.new(); dis.bg_color=Color("#a7aaa2"); dis.set_corner_radius_all(9)
	b.add_theme_stylebox_override("normal",n); b.add_theme_stylebox_override("hover",h)
	b.add_theme_stylebox_override("pressed",pr); b.add_theme_stylebox_override("disabled",dis)
	b.add_theme_color_override("font_color",Color("#f4f0df")); b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_color_override("font_pressed_color",Color("#d8d0bf")); b.add_theme_color_override("font_disabled_color",Color("#e8e6dd"))
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	return b

func _refresh()->void:
	var atk:=_attack(); var defense:=_defense()
	status_label.text="%d岁 / %d岁    余寿 %d年    %s · %d层" % [player.age,player.max_age,player.max_age-player.age,REALMS[player.realm],player.level]
	resource_label.text="◆ %d 灵石    第 %d 世" % [player.stones,player.life_no]
	cultivation_label.text="修为　%d / %d" % [player.cultivation,player.required]
	cultivation_bar.max_value=player.required; cultivation_bar.value=player.cultivation
	hp_label.text="气血　%d / %d" % [player.hp,player.max_hp]
	hp_bar.max_value=player.max_hp; hp_bar.value=player.hp
	attribute_label.text="攻击　%d\n防御　%d\n悟性　%d\n气运　%d\n体质　%d\n装备　%d 件 · 功法 %s" % [atk,defense,player.comprehension,player.luck,player.physique,owned_equipment.size(),", ".join(skills)]
	fate_label.text="命格 · %s\n%s\n\n效果：悟性 %+d  气运 %+d  体质 %+d  寿元 %+d" % [fate.name,fate.desc,fate.comp,fate.luck,fate.physique,fate.age]
	fate_chip.text="命格 · %s　|　外门弟子" % fate.name
	extra_label.text="永久因果\n悟性 +%d　气运 +%d　体质 +%d" % [meta.comprehension,meta.luck,meta.physique]
	log_label.text="\n".join(logs)
	equip_info_label.text="已装备 %d 件 · 背包 %d 件" % [equipped_usage(),owned_equipment.size()]
	skill_info_label.text="已修习 %d 门" % skills.size()
	area_info_label.text="%s · 危险 %d" % [AREAS[selected_area].name,AREAS[selected_area].risk]
	break_info_label.text=("轮回后可突破" if player.dead else ("✦ 修为已满，可突破！" if player.cultivation>=player.required else "还差 %d 点修为" % (player.required-player.cultivation)))
	nav_info_label.text="第 %d 世 · 因果 %d" % [player.life_no,meta.comprehension+meta.luck+meta.physique]
	for b in action_buttons: b.disabled=player.dead
	if player.dead:
		event_label.text="这一世已经结束。\n\n最终境界：%s · %d层\n\n点击【轮回】继承因果。" % [REALMS[player.realm],player.level]
	else:
		event_label.text="命格【%s】\n\n%s\n\n当前地区：%s" % [fate.name,fate.desc,AREAS[selected_area].name]

func equipped_usage()->int:
	var n:=0
	for e in equipped.values():
		if not e.is_empty(): n+=1
	return n

func _show_settings()->void:
	modal=_panel(Vector2(560,240),Vector2(320,330)); modal.z_index=30; add_child(modal)
	var t:=_label("设置",22,Color("#173442")); t.position=Vector2(20,16); t.size=Vector2(200,34); modal.add_child(t)
	var b1:=_button("保存进度 (F5)",Vector2(24,70),Vector2(272,50)); b1.pressed.connect(_save); modal.add_child(b1)
	var b2:=_button("读取进度 (F9)",Vector2(24,132),Vector2(272,50)); b2.pressed.connect(_load); modal.add_child(b2)
	var b3:=_button("重新开局",Vector2(24,194),Vector2(272,50)); b3.pressed.connect(_restart); modal.add_child(b3)
	var cl:=_button("关闭",Vector2(24,256),Vector2(272,50)); cl.pressed.connect(func(): modal.queue_free()); modal.add_child(cl)

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
	var area = AREAS[selected_area]
	var risk := float(area.risk)*0.22
	var roll = randf()+player.luck*0.01
	if roll<risk:
		var ids:Array=area.enemies
		current_enemy=ENEMIES[ids[randi_range(0,ids.size()-1)]]
		_show_battle(current_enemy)
		return
	elif roll<0.75:
		var reward = randi_range(30,100)+player.luck*3+int(area.reward)
		player.stones+=reward; player.cultivation+=reward
		if randf()<0.12+player.luck*0.005:
			var drop = EQUIPMENT[randi_range(0,EQUIPMENT.size()-1)].duplicate(true); owned_equipment.append(drop); _add_log("探索获得装备：%s。" % drop.name)
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
			var drop = EQUIPMENT[randi_range(0,EQUIPMENT.size()-1)].duplicate(true); owned_equipment.append(drop); _add_log("战利品：%s。" % drop.name)
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
	var old_realm = player.realm; var old_level = player.level
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
		var a = AREAS[i]
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
		var learned = s.name in skills
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
