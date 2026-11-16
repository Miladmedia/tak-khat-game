extends Control

const CREAM = Color("#ede3d3")
const NAVY = Color("#2c4a6b")
const BRICK = Color("#a0522d")
const GOLD = Color("#d4a657")
const GREY = Color("#6b6b6b")
const FONT = preload("res://assets/Vazir.ttf")

var mode = "menu"
var level = 1
var endless = false
var seconds = 60.0
var pieces = []
var selected = 0
var sway = 0.0
var balance = 0.0
var best = 0
var wins = 0
var tutorial_seen = false
var sound_on = true

var items = ["کتاب", "سبد", "پشتی", "پیت حلب", "پتو", "کارتن"]
var widths = [75, 62, 82, 58, 90, 70]
var color_items = [
    Color("#d4a657"), Color("#a0522d"), Color("#b96a43"),
    Color("#8f9b9b"), Color("#71909b"), Color("#c18b55")
]

func _ready():
    get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    _load()
    if OS.has_feature("android"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    $Music.finished.connect(_restart_music)
    if sound_on:
        $Music.play()
    set_process(true)

func _load():
    var f = FileAccess.open("user://save.json", FileAccess.READ)
    if f == null:
        mode = "tutorial"
        return
    var d = JSON.parse_string(f.get_as_text())
    if typeof(d) == TYPE_DICTIONARY:
        level = clampi(int(d.get("level", 1)), 1, 24)
        best = maxi(0, int(d.get("best", 0)))
        wins = maxi(0, int(d.get("wins", 0)))
        tutorial_seen = bool(d.get("tutorial_seen", false))
        sound_on = bool(d.get("sound_on", true))
        if not tutorial_seen:
            mode = "tutorial"
    else:
        mode = "tutorial"

func _save():
    var f = FileAccess.open("user://save.json", FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify({"level": level, "best": best, "wins": wins, "tutorial_seen": tutorial_seen, "sound_on": sound_on}))

func _draw():
    var w = size.x
    var h = size.y
    draw_rect(Rect2(Vector2.ZERO, size), NAVY)
    # roof and brick wall
    draw_rect(Rect2(0, h * 0.47, w, h * 0.53), Color("#747373"))
    for y in range(int(h * 0.50), int(h), 42):
        for x in range(0, int(w), 72):
            var xx = x + (36 if int(y / 42) % 2 else 0)
            draw_line(Vector2(xx, y), Vector2(xx + 46, y), Color("#8c8580"), 2)
    draw_rect(Rect2(0, h * 0.80, w, h * 0.20), Color("#625f5c"))
    # skyline and cooler
    draw_rect(Rect2(24, h * 0.37, 39, h * 0.12), Color("#394a54"))
    draw_rect(Rect2(34, h * 0.32, 18, h * 0.06), Color("#394a54"))
    draw_line(Vector2(42, h * 0.32), Vector2(42, h * 0.22), GOLD, 3)
    # antenna guide
    var target_y = h * (0.28 if mode == "menu" else 0.37 - max(0, pieces.size() - 1) * 0.045)
    draw_line(Vector2(35, target_y), Vector2(w - 35, target_y), GOLD, 3)
    for x in range(35, int(w - 35), 16):
        draw_circle(Vector2(x, target_y), 2, CREAM)
    if mode == "menu":
        _text("تک‌خط", w / 2, 155, 52, CREAM, true)
        _text("برای رسیدن به یک خط آنتن،", w / 2, 205, 21, CREAM)
        _text("کل خانه را چیدیم. دیگر چه بماند؟", w / 2, 236, 19, CREAM)
        _draw_tower(w / 2, h * 0.47 - 35)
        _button("شروع بازی", h * 0.68, BRICK)
        _button("بی‌پایان", h * 0.77, GOLD)
        _button("راهنما", h * 0.84, Color("#596878"))
        _text("پیشرفت  " + _fa(str(level - 1)) + " / ۲۴", w / 2, h * 0.89, 18, CREAM)
        _sound_button()
    elif mode == "tutorial":
        _text("راهنمای تک‌خط", w / 2, 105, 32, GOLD, true)
        _wrapped_text("وسیله را از پایین انتخاب کن؛ بعد برای حفظ تعادل بکش. پیش از صفر شدن زمان، «چیدن» را بزن و خودت را به خط طلایی برسان.\n\nاین‌جا حتی پتو هم مهندس مخابرات شده!", w / 2, h * 0.37, 22, CREAM)
        _button("بزن بریم", h * 0.72, BRICK)
        _button("بازگشت به منو", h * 0.82, GOLD)
        _sound_button()
    elif mode == "game":
        var header = "بی‌پایان" if endless else "مرحله " + _fa(str(level)) + " از ۲۴"
        _text(header, w / 2, 43, 22, CREAM, true)
        _text("ارتفاع: " + _fa(str(pieces.size())) + " / " + _fa(str(_goal())), w / 2, 78, 17, CREAM)
        draw_rect(Rect2(40, 99, w - 80, 7), Color("#394a54"))
        draw_rect(Rect2(40, 99, (w - 80) * min(1.0, float(pieces.size()) / _goal()), 7), GOLD)
        _draw_tower(w / 2 + sway, h * 0.66)
        # little character
        draw_circle(Vector2(w / 2, h * 0.66 + 24), 13, CREAM)
        draw_line(Vector2(w / 2, h * 0.66 + 36), Vector2(w / 2, h * 0.66 + 65), CREAM, 6)
        draw_line(Vector2(w / 2, h * 0.66 + 45), Vector2(w / 2 + sway * 0.6, h * 0.66 + 15), CREAM, 4)
        draw_circle(Vector2(w / 2 - 4, h * 0.66 + 22), 1.5, NAVY)
        draw_circle(Vector2(w / 2 + 4, h * 0.66 + 22), 1.5, NAVY)
        _text("تعادل را نگه دار. زندگی هم چراغی داشت.", w / 2, h * 0.73, 15, CREAM)
        if endless:
            _text("زمان  " + _fa(str(int(seconds))) + " ثانیه", w / 2, h * 0.78, 16, GOLD)
        else:
            _text("زمان  " + _fa(str(maxi(0, int(seconds)))) + " ثانیه", w / 2, h * 0.78, 16, GOLD)
        var wind = "راست" if int(seconds) % 4 < 2 else "چپ"
        _text("باد از سمت " + wind + " می‌وزد", w / 2, h * 0.82, 14, CREAM)
        # touch target picker strip
        draw_rect(Rect2(12, h * 0.85, w - 24, h * 0.075), Color("#263f5b"))
        var cell = (w - 24) / items.size()
        for i in range(items.size()):
            var x = 12 + i * cell
            draw_rect(Rect2(x + 3, h * 0.858, cell - 6, h * 0.032), color_items[i] if i == selected else Color("#596878"))
            _text(items[i], x + cell / 2, h * 0.895, 12, CREAM)
        _button("چیدن", h * 0.956, BRICK)
    elif mode in ["win", "lose"]:
        _draw_tower(w / 2, h * 0.49)
        if mode == "win":
            _text("وصل شد!", w / 2, 210, 34, GOLD, true)
            _text("دایی جان ۱۲ تصویر فرستاد؛ سه‌تایش تکراری است.", w / 2, 260, 16, CREAM)
        else:
            _text("فرو ریخت!", w / 2, 210, 34, CREAM, true)
            _text("دست‌کم کمرت درد گرفت.", w / 2, 260, 18, CREAM)
        _button("ادامه", h * 0.72, BRICK)
        _button("بازگشت به منو", h * 0.82, GOLD)

func _text(t, x, y, sz, col, bold = false):
    draw_string(FONT, Vector2(x - 220, y + sz * 0.35), t, HORIZONTAL_ALIGNMENT_CENTER, 440, sz, col)

func _wrapped_text(t, x, y, sz, col):
    var paragraphs = t.split("\n")
    var lines = []
    for paragraph in paragraphs:
        var words = paragraph.split(" ")
        var line = ""
        for word in words:
            var candidate = word if line.is_empty() else line + " " + word
            if FONT.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > size.x - 48 and not line.is_empty():
                lines.append(line)
                line = word
            else:
                line = candidate
        lines.append(line)
    for i in range(lines.size()):
        draw_string(FONT, Vector2(24, y + i * (sz * 1.65)), lines[i], HORIZONTAL_ALIGNMENT_CENTER, size.x - 48, sz, col)

func _sound_button():
    var label = "صدا: روشن" if sound_on else "صدا: خاموش"
    _text(label, size.x / 2, size.y * 0.94, 16, GOLD)

func _toggle_sound():
    sound_on = not sound_on
    if sound_on:
        $Music.play()
    else:
        $Music.stop()
    _save()
    queue_redraw()

func _restart_music():
    if sound_on:
        $Music.play()

func _button(t, y, col):
    draw_rect(Rect2(size.x * 0.18, y - 26, size.x * 0.64, 52), col)
    _text(t, size.x / 2, y, 22, CREAM, true)

func _draw_tower(cx, base):
    draw_rect(Rect2(cx - 43, base, 86, 15), BRICK)
    if mode in ["game", "win", "lose"]:
        for i in range(pieces.size()):
            var it = pieces[i]
            var wid = it[1]
            var py = base - 17 - i * 36
            var px = cx + it[2]
            draw_rect(Rect2(px - wid / 2, py - 24, wid, 23), color_items[it[0]])
            draw_rect(Rect2(px - wid / 2, py - 24, wid, 23), Color("#352f2d"), false, 2)
            if it[0] == 0:
                for yy in range(0, 2):
                    draw_line(Vector2(px - wid / 2 + 5, py - 18 + yy * 6), Vector2(px + wid / 2 - 5, py - 18 + yy * 6), CREAM, 1)
            if it[0] == 3:
                _draw_oval(Vector2(px, py - 24), wid / 2 - 4, 4, CREAM)
    else:
        for i in range(3):
            draw_rect(Rect2(cx - 33 + i * 5, base - 28 - i * 30, 66 - i * 6, 19), color_items[i])

func _draw_oval(center, rw, rh, col):
    var pts = PackedVector2Array()
    for i in range(24):
        var a = TAU * i / 24.0
        pts.append(center + Vector2(cos(a) * rw, sin(a) * rh))
    draw_colored_polygon(pts, col)

func _goal():
    if level <= 3:
        return 2
    elif level <= 7:
        return 3
    elif level <= 12:
        return 4
    elif level <= 18:
        return 5
    return 6

func _fa(s):
    var a = "0123456789"
    var b = "۰۱۲۳۴۵۶۷۸۹"
    for i in range(10):
        s = s.replace(a[i], b[i])
    return s

func _start(e = false):
    endless = e
    mode = "game"
    if sound_on and not $Music.playing:
        $Music.play()
    pieces = []
    seconds = 0.0 if endless else 60.0
    sway = 0.0
    balance = 0.0
    selected = 0
    queue_redraw()

func _process(dt):
    if mode != "game":
        return
    if endless:
        seconds += dt
    else:
        seconds -= dt
    sway = sin(Time.get_ticks_msec() / 650.0) * min(15.0, 2.0 + pieces.size() * 1.7)
    balance = clampf(balance + sin(Time.get_ticks_msec() / 710.0) * dt * 0.12, -1.0, 1.0)
    if not endless and seconds <= 0.0:
        _finish(false)
    elif abs(sway) > 14.0 and pieces.size() > 1:
        _finish(false)
    queue_redraw()

func _finish(won):
    mode = "win" if won else "lose"
    if sound_on:
        $Sfx.get_node("Win" if won else "Lose").play()
    if won:
        wins += 1
        if not endless:
            level = mini(24, level + 1)
    best = maxi(best, pieces.size())
    _save()
    queue_redraw()

func _input(e):
    if e is InputEventScreenTouch and e.pressed:
        _tap(e.position)
    elif e is InputEventMouseButton and e.pressed:
        _tap(e.position)
    elif e is InputEventScreenDrag:
        balance = clampf(balance + e.relative.x / 2200.0, -1.0, 1.0)
    elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        balance = clampf(balance + e.relative.x / 5000.0, -1.0, 1.0)

func _tap(p):
    var h = size.y
    var w = size.x
    if mode in ["menu", "tutorial"] and p.y > h * 0.92:
        _toggle_sound()
        return
    if mode == "menu":
        if p.y >= h * 0.62 and p.y < h * 0.74:
            tutorial_seen = true
            _save()
            _start(false)
        elif p.y >= h * 0.74 and p.y < h * 0.81:
            tutorial_seen = true
            _save()
            _start(true)
        elif p.y >= h * 0.81 and p.y < h * 0.87:
            mode = "tutorial"
        queue_redraw()
    elif mode == "tutorial":
        if p.y >= h * 0.68 and p.y < h * 0.77:
            tutorial_seen = true
            _save()
            _start(false)
        elif p.y >= h * 0.78 and p.y < h * 0.87:
            tutorial_seen = true
            mode = "menu"
            _save()
        queue_redraw()
    elif mode == "game":
        var picker_top = h * 0.85
        var picker_bottom = h * 0.925
        var button_top = h * 0.926
        var button_bottom = h * 0.992
        if p.y >= button_top and p.y <= button_bottom:
            var i = selected
            var wid = widths[i]
            pieces.append([i, wid, clampf(balance * 25.0 + randf_range(-5.0, 5.0), -24.0, 24.0)])
            if sound_on: $Sfx/Place.play()
            balance = clampf(balance + randf_range(-0.12, 0.12), -1.0, 1.0)
            if pieces.size() >= _goal():
                _finish(abs(sway) < 12.0)
        elif p.y >= picker_top and p.y < picker_bottom:
            selected = clampi(int((p.x - 12) / ((w - 24) / items.size())), 0, items.size() - 1)
        elif p.y < picker_top:
            balance = clampf((p.x - w / 2.0) / (w / 2.0), -1.0, 1.0)
    elif mode in ["win", "lose"]:
        if p.y >= h * 0.78:
            mode = "menu"
            _save()
        else:
            _start(endless)
    queue_redraw()
