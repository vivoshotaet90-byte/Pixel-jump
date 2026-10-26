
extends Node2D

const GRAVITY := 1000.0
const SPEED := 320.0
const JUMP_FORCE := -570.0

var player_pos := Vector2(100, 850)
var player_vel := Vector2.ZERO
var platforms: Array[Rect2] = []
var coins: Array[Vector2] = []
var score := 0
var game_over := false
var left_pressed := false
var right_pressed := false
var jump_requested := false

var screen_size := Vector2(720, 1280)
var camera_y := 0.0

var score_label: Label
var message_label: Label
var left_button: Button
var right_button: Button
var jump_button: Button

func _ready() -> void:
    get_viewport().size_changed.connect(_resize_ui)
    _make_level()
    _make_ui()
    queue_redraw()

func _make_level() -> void:
    platforms.clear()
    coins.clear()

    platforms.append(Rect2(0, 950, 260, 35))
    platforms.append(Rect2(340, 830, 170, 30))
    platforms.append(Rect2(110, 700, 170, 30))
    platforms.append(Rect2(400, 570, 180, 30))
    platforms.append(Rect2(160, 440, 170, 30))
    platforms.append(Rect2(430, 310, 180, 30))
    platforms.append(Rect2(170, 180, 180, 30))
    platforms.append(Rect2(0, 50, 220, 30))

    for p in platforms:
        coins.append(Vector2(p.position.x + p.size.x / 2.0, p.position.y - 45))

func _make_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    score_label = Label.new()
    score_label.position = Vector2(25, 25)
    score_label.add_theme_font_size_override("font_size", 32)
    score_label.add_theme_color_override("font_color", Color.WHITE)
    ui.add_child(score_label)

    message_label = Label.new()
    message_label.position = Vector2(90, 120)
    message_label.add_theme_font_size_override("font_size", 32)
    message_label.add_theme_color_override("font_color", Color.WHITE)
    ui.add_child(message_label)

    left_button = _add_button(ui, "◀", Vector2(25, 1100), Vector2(120, 100))
    right_button = _add_button(ui, "▶", Vector2(165, 1100), Vector2(120, 100))
    jump_button = _add_button(ui, "JUMP", Vector2(535, 1080), Vector2(150, 120))

    left_button.button_down.connect(func(): left_pressed = true)
    left_button.button_up.connect(func(): left_pressed = false)
    right_button.button_down.connect(func(): right_pressed = true)
    right_button.button_up.connect(func(): right_pressed = false)
    jump_button.pressed.connect(func(): jump_requested = true)

    _resize_ui()

func _add_button(parent: Node, caption: String, pos: Vector2, size: Vector2) -> Button:
    var b := Button.new()
    b.text = caption
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 28)
    parent.add_child(b)
    return b

func _resize_ui() -> void:
    if not is_instance_valid(left_button):
        return
    var s: Vector2 = get_viewport_rect().size
    left_button.position = Vector2(20, s.y - 125)
    right_button.position = Vector2(155, s.y - 125)
    jump_button.position = Vector2(s.x - 175, s.y - 145)

func _physics_process(delta: float) -> void:
    if game_over:
        if jump_requested:
            score = 0
            player_pos = Vector2(100, 850)
            player_vel = Vector2.ZERO
            camera_y = 0.0
            game_over = false
            _make_level()
            message_label.text = ""
        jump_requested = false
        queue_redraw()
        return

    var direction := 0.0
    if left_pressed:
        direction -= 1.0
    if right_pressed:
        direction += 1.0

    player_vel.x = direction * SPEED
    player_vel.y += GRAVITY * delta

    var old_y := player_pos.y
    player_pos.x += player_vel.x * delta
    player_pos.x = clampf(player_pos.x, 12.0, screen_size.x - 32.0)
    player_pos.y += player_vel.y * delta

    if player_vel.y > 0.0:
        for p in platforms:
            var old_bottom := old_y + 36.0
            var new_bottom := player_pos.y + 36.0
            var overlaps := player_pos.x + 26 > p.position.x and player_pos.x + 6 < p.position.x + p.size.x
            if overlaps and old_bottom <= p.position.y and new_bottom >= p.position.y:
                player_pos.y = p.position.y - 36.0
                player_vel.y = 0.0
                break

    if jump_requested and is_on_platform():
        player_vel.y = JUMP_FORCE
    jump_requested = false

    for i in range(coins.size() - 1, -1, -1):
        if player_pos.distance_to(coins[i]) < 45.0:
            coins.remove_at(i)
            score += 1

    camera_y = minf(camera_y, player_pos.y - 650.0)
    if player_pos.y > camera_y + 1400.0:
        game_over = true
        message_label.text = "Game over!\nНажми JUMP"
    if player_pos.y < 100.0:
        game_over = true
        message_label.text = "ПОБЕДА!\nНажми JUMP"

    score_label.text = "Монеты: " + str(score)
    queue_redraw()

func is_on_platform() -> bool:
    for p in platforms:
        var feet := player_pos.y + 37.0
        var overlap := player_pos.x + 26 > p.position.x and player_pos.x + 6 < p.position.x + p.size.x
        if overlap and absf(feet - p.position.y) < 5.0:
            return true
    return false

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#17243b"))

    for p in platforms:
        var r := Rect2(p.position.x, p.position.y - camera_y, p.size.x, p.size.y)
        draw_rect(r, Color("#40c9a2"))
        draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color("#a1ffe1"))

    for c in coins:
        draw_circle(Vector2(c.x, c.y - camera_y), 13, Color("#ffd447"))
        draw_circle(Vector2(c.x - 4, c.y - camera_y - 4), 4, Color("#fff0a0"))

    var pp := Vector2(player_pos.x, player_pos.y - camera_y)
    draw_rect(Rect2(pp, Vector2(30, 36)), Color("#ff5d73"))
    draw_rect(Rect2(pp + Vector2(5, 8), Vector2(6, 6)), Color.WHITE)
    draw_rect(Rect2(pp + Vector2(19, 8), Vector2(6, 6)), Color.WHITE)
    
