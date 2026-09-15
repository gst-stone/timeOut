extends Node

# 《寿元将尽》V2 视觉主题：以 1.png 为设计基准的东方修仙墨色 UI。
# 通过统一的 StyleBox/字体/色阶，让现有玩法保持不变，同时降低“程序化 UI”观感。

const INK := Color("#173442")
const INK_SOFT := Color("#425455")
const PAPER := Color("#eee9dc")
const PAPER_LIGHT := Color("#f7f3e8")
const PAPER_DARK := Color("#d8d0bf")
const TEAL := Color("#31576a")
const TEAL_HOVER := Color("#42758a")
const EARTH := Color("#6b5740")
const EARTH_HOVER := Color("#856d50")
const RED := Color("#9b4b45")

static func panel_style(radius := 10, border := 1) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = PAPER
    s.border_color = Color("#a89f8b")
    s.set_border_width_all(border)
    s.set_corner_radius_all(radius)
    s.shadow_color = Color(0.05, 0.08, 0.08, 0.12)
    s.shadow_size = 8
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 14
    s.content_margin_bottom = 14
    return s

static func button_style(bg: Color, radius := 7) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(radius)
    s.border_color = Color(1, 1, 1, 0.10)
    s.set_border_width_all(1)
    s.shadow_color = Color(0, 0, 0, 0.14)
    s.shadow_size = 4
    return s

static func apply_button(button: Button, primary := true) -> void:
    var bg := TEAL if primary else EARTH
    var hover := TEAL_HOVER if primary else EARTH_HOVER
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", PAPER_LIGHT)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", button_style(bg))
    button.add_theme_stylebox_override("hover", button_style(hover))
    button.add_theme_stylebox_override("pressed", button_style(INK))
    button.add_theme_stylebox_override("disabled", button_style(Color("#a7aaa2")))

static func apply_panel(panel: Control) -> void:
    panel.add_theme_stylebox_override("panel", panel_style())

static func apply_label(label: Label, size := 16, color := INK_SOFT) -> void:
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
