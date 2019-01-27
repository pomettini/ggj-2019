pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- states
menu = 0
tutorial = 1
game = 2
gameover = 3
credits = 4
gamestate = menu
-- gameplay globals
posts = {}
tutorial_posts = {}
safe_stickers = {}
dirty_stickers = {}
score = 0
countdown = 1
-- animation globals
falling_hearts = {}
menu_lock = false
-- game animation globals
swipe_direction = 0
is_animating_feed = false
is_animating_swipe = false
posts_y_offset = 0
posts_x_offset = 0
is_camera_shaking = false
camera_shake_cooldown = 0
music_is_playing = false
music_speed = 1
-- const globals
database = {}
text_y_offset = -2
camera_shake_intensity = 5
camera_shake_duration = 0.5
countdown_speed = 0.0015
profile_pics = 8
post_pics = 4
blinking_speed = 2
enable_music = true

function load_database()
    database = {}
    -- first row, second row, third row, is not porn
    insert_post("donna calda", "a 2 km", "da te", false)
    insert_post("vendesi", "soprammobili", "usati", true)
    insert_post("clicca qui", "per il", "ca**o", false)
    insert_post("passata di", "pomodoro", "tre per due", true)
    insert_post("vendo", "la droga", "", false)
    insert_post("qui foto", "di gattini", "", true)
    insert_post("qui foto", "di", "cagnolini", true)
    insert_post("biscotti", "in offerta", "", true)
    insert_post("sito", "bellissimo", "sui memini", true)
    insert_post("guardate che", "belle le", "mie tette", false)
    insert_post("nuovissimi", "giochi per", "playstation", true)
    insert_post("altri", "memini", "divertenti", true)
    insert_post("qui battute", "sui coder", "", true)
    -- insert_post("game of", "thrones", "streaming", true)
    insert_post("leggi", "hentai", "online", false)
    insert_post("nuovo modo", "allungamento", "del pene", false)
    insert_post("visite", "gratuite", "urologo", true)
    insert_post("nuova dieta", "di kylie", "jenner", true)
    insert_post("qui kim", "kardashian", "nuda", false)
    insert_post("jason momoa", "leaked", "photo", false)
end

function load_tutorial_posts()
    insert_tutorial_post("sei rob, il", "nuovo moderatore", "di tambler")
    insert_tutorial_post("il tuo lavoro e'", "eliminiare i", "contenuti espliciti")
    insert_tutorial_post("premi la freccia", "a destra per", "approvare il post")
    insert_tutorial_post("premi la freccia", "a sinistra per", "eliminare il post")
    insert_tutorial_post("se sbagli sarai", "licenziato!!!", "")
end

function load_stickers()
    safe_stickers = {}
    add(safe_stickers, 2)
    add(safe_stickers, 3)
    add(safe_stickers, 6)
    add(safe_stickers, 10)
    add(safe_stickers, 11)
    add(safe_stickers, 13)
    add(safe_stickers, 14)
    add(safe_stickers, 15)
    dirty_stickers = {}
    add(dirty_stickers, 1)
    -- add(dirty_stickers, 4) <- shit, ambibuos
    add(dirty_stickers, 5)
    add(dirty_stickers, 7)
    add(dirty_stickers, 8)
    add(dirty_stickers, 9)
    add(dirty_stickers, 12)
end

-- start init stuff

function insert_post(first, second, third, valid)
    local post = {}
    post.first_row = first
    post.second_row = second
    post.third_row = third
    post.is_valid = valid
    post.profile_id = get_random_profile_pic()
    post.pic_id = get_random_post_pic()
    add_sticker(post)
    add_sprite_variations(post)
    -- the big tit is very rare
    if not post.is_valid then
        post.show_big_tit = flr(rnd(50)) == 1
    end
    add(database, post)
end

function insert_tutorial_post(first, second, third)
    local post = {}
    post.first_row = first
    post.second_row = second
    post.third_row = third
    post.is_valid = valid
    add(tutorial_posts, post)
end

function generate_posts()
    for x = 1, 4 do
        add(posts, database[get_random_post_id()])
    end
end

-- end init stuff

function pop_and_push_post()
    -- i need to pop post after the animation finishes
    posts[1] = posts[2]
    posts[2] = posts[3]
    posts[3] = posts[4]
    posts[4] = database[get_random_post_id()]
end

function pop_and_push_tutorial()
    -- i need to pop post after the animation finishes
    tutorial_posts[1] = tutorial_posts[2]
    tutorial_posts[2] = tutorial_posts[3]
    tutorial_posts[3] = tutorial_posts[4]
    tutorial_posts[4] = tutorial_posts[5]
    tutorial_posts[5] = nil
end

function get_random_post_id()
    return flr(rnd(#database)) + 1
end

function get_random_profile_pic()
    return flr(rnd(profile_pics)) + 1
end

function get_random_post_pic()
    return flr(rnd(post_pics)) + 1
end

function process_buttons()
    if not is_animating_swipe and not menu_lock then
        -- left arrow key
        if btnp(0) then
            swipe_direction = -1
            is_animating_swipe = true
            sfx_correct()
            menu_lock = true
        end
        -- right arrow key
        if btnp(1) then
            swipe_direction = 1
            is_animating_swipe = true
            sfx_correct()
            menu_lock = true
        end
    else
        menu_lock = false
    end
end

function process_feed_animation()
    if is_animating_feed then
        posts_y_offset -= 10
    end

    if posts_y_offset <= -40 then
        -- here is where the animation ends
        is_animating_feed = false
        post_animation_ended()
        posts_x_offset = 0
        posts_y_offset = 0
    end
end

function process_swipe_animation(direction)
    if is_animating_swipe then
        posts_x_offset += 16 * swipe_direction
    end

    if posts_x_offset <= -160 or posts_x_offset >= 160 then
        is_animating_feed = true
        is_animating_swipe = false
    end
end

function do_camera_shake()
    camera_shake_cooldown = camera_shake_duration
end

function decrease_countdown()
    if not is_animating_swipe then
        countdown -= countdown_speed * (score + 1)
    end
end

function post_animation_ended()
    if gamestate == tutorial then
        pop_and_push_tutorial()
    end
    if gamestate == game then
        evaluate_content(posts[1])
        pop_and_push_post()
    end
end

function evaluate_content(post)
    if post.is_valid and swipe_direction == 1 
    or not post.is_valid and swipe_direction == -1 then
        score += 1
        countdown = 1
    else
        -- do_camera_shake()
        countdown = 0
        sfx_wrong()
    end
end

function evaluate_gameover()
    if countdown <= 0 then
        change_state(gameover)
    end
end

function change_state(new_state)
    menu_lock = true
    gamestate = new_state

    if new_state == game then
        reset_game_state()
        start_game_music()
    end
end

function reset_game_state()
    load_database()
    generate_posts()
    score = 0
    countdown = 1
    swipe_direction = 0
    is_animating_feed = false
    is_animating_swipe = false
    posts_y_offset = 0
    posts_x_offset = 0
end

function add_sticker(post)
    post.sticker_x = rnd(24)
    post.sticker_y = rnd(24)
    if post.is_valid then
        post.sticker_id = get_safe_sticker()
    else
        post.sticker_id = get_dirty_sticker()
    end
end

function add_sprite_variations(post)
    post.flip_x = rnd(2) > 1
end

function get_safe_sticker()
    return safe_stickers[flr(rnd(#safe_stickers)) + 1]
end

function get_dirty_sticker()
    return dirty_stickers[flr(rnd(#dirty_stickers)) + 1]
end

-- start game draw stuff

function draw_background()
    rectfill(0, 0, 128, 128, 1)
end

function draw_bar()
    rectfill(0, 0, 128, 16, 1)
    line(0, 16, 128, 16, 12)
    -- search bar
    rectfill(12, 4, 116, 12, 0)
    print("cerca su tambler", 14, 6, 7)
end

function draw_post(x_offset, y_offset, post)
    -- post bg
    rectfill(
        32 + x_offset, 
        8 + y_offset, 
        120 + x_offset, 
        40 + y_offset, 
        7)
    -- profile pic
    -- rectfill(
    --     8 + x_offset, 
    --     8 + y_offset, 
    --     24 + x_offset, 
    --     24 + y_offset, 
    --     0)
    draw_profile_pic(
        post.profile_id,
        8 + x_offset,
        8 + y_offset)
    -- image
    rectfill(
        32 + x_offset,
        8 + y_offset, 
        64 + x_offset, 
        40 + y_offset, 
        0)
    if not post.show_big_tit then
        draw_post_pic(
            post,
            32 + x_offset,
            8 + y_offset)
        -- draw sticker
        draw_sticker(post, 32 + x_offset, 8 + y_offset)
    else
        draw_big_tit(
            post,
            32 + x_offset,
            8 + y_offset)
    end
    -- text
    print(
        post.first_row, 
        72 + x_offset, 
        16 + y_offset + text_y_offset)
    print(
        post.second_row, 
        72 + x_offset, 
        24 + y_offset + text_y_offset)
    print(
        post.third_row, 
        72 + x_offset, 
        32 + y_offset + text_y_offset)
end

function draw_posts()
    local y_offset = posts_y_offset + 16
    local x_offset = posts_x_offset
    -- max 11 char for row
    -- horrible code must refactor
    draw_post(x_offset, 0 + y_offset, posts[1])
    draw_post(0, 40 + y_offset, posts[2])
    draw_post(0, 80 + y_offset, posts[3])
    draw_post(0, 120 + y_offset, posts[4])
end

function draw_debug_stuff()
    -- print(posts[0].first_row, 0, 0, 7)
    -- print(posts_x_offset, 0, 0, 7)
    -- print(flr(rnd(#database)), 0, 0, 7)
    -- print(posts[1].flip_x, 0, 0, 7)
end

function draw_camera_shake()
    if camera_shake_cooldown > 0 then
        camera(
            rnd(camera_shake_intensity) - (camera_shake_intensity / 2), 
            rnd(camera_shake_intensity) - (camera_shake_intensity / 2))
        -- change_colors()
        camera_shake_cooldown -= 0.1
    else
        camera()
        -- pal()
    end
end

function change_colors()
    for i = 0, 16 do
        pal(i, rnd(16))
    end
end

function draw_countdown_bar()
    local height = 12
    rectfill(0, 128 - height, 128, 128, 0)
    rectfill(0, 128 - height, 128 * countdown, 128, 7)
    line(0, 128 - height, 128, 128 - height, 0)
end

function draw_sticker(post, offset_x, offset_y)
    spr(
        post.sticker_id, 
        post.sticker_x + offset_x, 
        post.sticker_y + offset_y)
end

-- end game draw stuff

-- start other update stuff

function process_menu_screen()
    if btnp(1) and not menu_lock then
        change_state(tutorial)
    elseif btnp(0) and not menu_lock then
        change_state(credits)
    else
        menu_lock = false
    end
end

function process_tutorial_input()
    if btnp(1) and not menu_lock then
        change_state(game)
    else
        menu_lock = false
    end
end

function process_gameover_screen()
    if btnp(2) and not menu_lock then
        reset_game_state()
        change_state(game)
    else
        menu_lock = false
    end
end

function process_credits_screen()
    if btnp(1) and not menu_lock then
        change_state(menu)
    else
        menu_lock = false
    end
end

function evaluate_end_tutorial()
    if tutorial_posts[1] == nil then
        change_state(game)
    end
end

-- end other update stuff

-- start other draw stuff

function draw_menu_screen()
    rectfill(0, 0, 128, 128, 12)
    falling_hearts_draw()
    sspr(0, 96, 128, 32, 0, 27)
    -- subtitle
    credits_text = "(pulisci l'internet)"
    print(credits_text, h_center(credits_text), 63, 7)
    -- start text
    blinking_text_centered("premi freccia dx per iniziare", 80)
    -- credits text
    credits_text = "premi freccia sx per i credits"
    print(credits_text, h_center(credits_text), 94, 5)
end

function draw_tutorial_screen()
    rectfill(0, 0, 128, 128, 0)
    print("tutorial", 60, 60, 7)
    print("premi freccia dx per continuare", 15, 80, 7)
end

function draw_gameover_screen()
    local y_offset = -4
    rectfill(0, 0, 128, 128, 1)
    draw_text_wave("  game over  ", 26 + y_offset)
    draw_text_center("sei stato cacciato!", 52 + y_offset)
    draw_text_center("il tuo punteggio e': "..score, 78 + y_offset)
    blinking_text_centered("premi freccia su per riprovare", 104 + y_offset)
end

function draw_credits_screen()
    local y_offset = 2
    rectfill(0, 0, 128, 128, 12)
    falling_hearts_draw()
    draw_text_wave(" tambler the game ", 14 + y_offset)
    draw_text_center("a pierettini production", 36 + y_offset)
    draw_text_center("art: piera falcone", 54 + y_offset)
    draw_text_center("code: giorgio pomettini", 72 + y_offset)
    draw_text_center("music: tecla zorzi", 90 + y_offset)
    blinking_text_centered("premi freccia dx per continuare", 108 + y_offset)
end

function draw_text_wave(text, y)
    for i = 0, #text do
		wave_amount = 3
        char_offset = i * (120 / #text)
        char_y = y + (sin(time() + (i / #text))) * wave_amount
        print(sub(text, i, i), char_offset, char_y, 7)
    end
end

function draw_text_center(text, y)
    print(text, h_center(text), y, 7)
end

function h_center(text)
    return 64 - #text * 2
end

function draw_tutorial_post(x_offset, y_offset, post)
    -- post bg
    rectfill(
        32 + x_offset, 
        8 + y_offset, 
        120 + x_offset, 
        40 + y_offset, 
        7)
    -- profile pic
    -- rectfill(
    --     8 + x_offset, 
    --     8 + y_offset, 
    --     24 + x_offset, 
    --     24 + y_offset, 
    --     0)
    draw_profile_pic(
        5, 
        8 + x_offset, 
        8 + y_offset)
    -- text
    print(
        post.first_row, 
        40 + x_offset, 
        16 + y_offset + text_y_offset, 0)
    print(
        post.second_row, 
        40 + x_offset, 
        24 + y_offset + text_y_offset, 0)
    print(
        post.third_row, 
        40 + x_offset, 
        32 + y_offset + text_y_offset, 0)
end

function draw_tutorial_posts()
    local y_offset = posts_y_offset + 16
    local x_offset = posts_x_offset
    -- horrible code must refactor
    -- very horrible!!!
    if tutorial_posts[1] != nil then
        draw_tutorial_post(
            x_offset, 
            0 + y_offset, 
            tutorial_posts[1])
    end
    for i = 2, #tutorial_posts + 1 do
        if tutorial_posts[i] != nil then
            draw_tutorial_post(
                0, 
                (40 * (i - 1)) + y_offset, 
                tutorial_posts[i])
        end
    end
end

function draw_profile_pic(id, x, y)
    -- rendering bug?
    sspr(id * 16, 15, 16, 16, x, y)
end

function draw_post_pic(post, x, y)
    sspr(post.pic_id * 32, 32, 32, 32, x, y, 32, 32, post.flip_x)
end

function draw_big_tit(post, x, y)
    sspr(0, 64, 32, 32, x, y, 32, 32, post.flip_x)
end

function blinking_text_centered(text, y)
    if (time() * blinking_speed) % 2 > 1 then
        print(text, h_center(text), y, 7)
    else
        print(text, h_center(text), y, 5)
    end
end

function falling_hearts_init()
    falling_hearts = {}
    for i = 1, 20 do
        heart = {}
        heart.x = rnd(128)
        heart.y = rnd(128) - 128
        heart.speed = 1 + rnd(1)
        add(falling_hearts, heart)
    end
end

function falling_hearts_draw()
    for i = 1, 20 do
        falling_hearts[i].y += falling_hearts[i].speed
        print("♥", falling_hearts[i].x, falling_hearts[i].y, 8)
        if (falling_hearts[i].y > 128) then
            falling_hearts[i].y = 0
        end
    end
end

-- end other draw stuff

-- start music/sfx stuff

function start_menu_music()
    if enable_music then
        music(10)
    end
end

function start_game_music()
    if enable_music then
        if not music_is_playing then
            music(0)
            music_is_playing = true
        end
    end
end

function sfx_correct()
    sfx(38)
end

function sfx_wrong()
    sfx(39)
end

-- end music/sfx stuff

function _init()
    load_stickers()
    load_database()
    generate_posts()
    load_tutorial_posts()
    start_menu_music()
    falling_hearts_init()
end

function _update()
    if gamestate == menu then
        process_menu_screen()
    end
    if gamestate == tutorial then
        process_buttons()
        process_feed_animation()
        process_swipe_animation()
        evaluate_end_tutorial()
    end
    if gamestate == game then
        process_buttons()
        process_feed_animation()
        process_swipe_animation()
        decrease_countdown()
        evaluate_gameover()
    end
    if gamestate == gameover then
        process_gameover_screen()
    end
    if gamestate == credits then
        process_credits_screen()
    end
end

function _draw()
    if gamestate == menu then
        draw_menu_screen()
    end
    if gamestate == tutorial then
        draw_background()
        draw_tutorial_posts()
        blinking_text_centered("premi freccia dx per avanzare", 9)
    end
    if gamestate == game then
        draw_background()
        draw_posts()
        draw_bar()
        draw_camera_shake()
        draw_countdown_bar()
        draw_debug_stuff()
    end
    if gamestate == gameover then
        draw_gameover_screen()
        draw_camera_shake()
    end
    if gamestate == credits then
        draw_credits_screen()
    end
end
__gfx__
00000000000000000400004000ccc00000050000000ee00000000000f000000f00066000000000000000000000666000000000000088880000000000000aaa00
0000000000ffff00042004e00ccc0c0000044000000ee00008800880ff0000ff0006600000444400000440000666660000eeee00882882880088820000aaaaa0
007007000ffffff004424ee00ccc0c0000445000000ff00077888888fff00fff000440000444444000444400066666600eeeeee0889aa9880888882200aa0a00
000770000ffeeff004444440aacccc0000554400000ff00078888888ffffffff000440000445544004404020666666660eeffee08828828888778ff200affff0
000770000ffeeff0204404400ccccccc04444440000ff000e8888888ffffffff000440000445544044722227000000000eeffee000888800887080f200afff40
007007000ffffff0404404440ccc1cc004445550000ff0000e888880ffffffff000440000444444044444442c00c00c00eeeeee00000b00088888822077777f0
0000000000ffff0024e4444000ccc100555544440ff44ff000888800fef00fef0440044000444400002990000000000000eeee000b30b0b088888822aacccc19
00000000000000000204420000a00a00444444440ff00ff000088000fff00fff0440044000000000004422000c00c00c0000000000b3b3008088082200c00110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee004440000003333333333333333009aaaaaaaa9990000000000000000000000000bbb000000000000050500000000000000550555000000055005500000
00e66e444000000033333b33333b33b30aaa999aaaaaaaa0000005000055000000000bb3b3bb00000000505555050000005550058857775000005bb55bb50000
0e664444444444003b33333333333333aaa99aaaaa9a99a0000054555544500000006bbbbbbb6000000055555555000005777558885575500005b777777b5000
0e644444555554403333333333333333aaaa9aa9a9aa9aa000005449994450000006b3b3b3b3b600000555555555500005777758558858850005770770775000
0e44555455555440330000333300003399a99affffaaaaaa0005999999945000bbbbbbbbbbbbbb00005555555555550005777758858855850005770770775000
0e45555fff7744443300003b33000033aaaafffffffaa9aa005759999999450033b333bbb333bbb00055ffffffff550005777775575585850055755555575500
0e45577777cc77443300003333000033aaa9a0fff0a9999a0059997599944500003707b0b707bb33005f00ffff00f500577777777775885505bb5bbbbbb5bb50
ee44f77cc7cc7f043300003333000033a99aa0fff0aa999a0599999999694450000bbbbbbbbbbb00005ffffffffff500577777777777557505b5bbbbbbbb5b50
eee4477cc777ff003333330000333333aa9af4fff4faa9aa05655999967794500000bb000bbbb000055555555555555055777777777777555b5bbb0bb0bbb5b5
0ee44f7775f5ff003b33b300003b33330a9aaffffffaaaaa057566677777945000000bbbbbbb00005f57075ff57075f557770777777077755b5bbbbbbbbbb5b5
e00f4fffff5fff003333300000003b330aaaaffffffaaa0005765556777794500000000bbbb000005f55555ff55555f55577077777707755575bbbbbbbbbb575
e00ff67775ffff0033b300000000333300aaffffffff000005677667776945000000005f44f50000055ffffffffff5505777777007777775575bbbbbbbbbb575
000ffee77ffff000333300000000b333000ffffff7f0000000567777769450000004b55f44f55000005fff0ff0fff5000577777777777750055bbbbbbbbbb550
0000ffe66fff000033330000000033330000fff777f0000000055555555500000000405f00f5b000005ffff00ffff50005777777777777500005bbbbbbbb5000
00000ffffff0000033b300333300333b00000fffff00000000000000000000000000405f44f500000005ffffffff5000005577777777550000005bbbbbb50000
000000eeee0000003333003333003333000000000000000000000000000000000000000000000000000055555555000000005555555500000000055555500000
999999999999aaaaaa99999999999999cccccccccccccccccccccccccccccccc1111111111111111111111111111111199494994994949999994949ccccccccc
9999999aaaaaaaaaaaaa999999999999ccccccccccc00000c0000ccccccccccc1111111111111111111111111111111194994994999499994999499ccccccccc
999999aaaaaaa00aaaaaa99999999999ccccccccc0000055a550000ccccccccc1111111111111111111111111111111149999499994949994994949ccccccccc
99999aaaaaaaaa0aaaaaaa9a99999999cccccccc0000055aaa550000cccccccc1111111111133311111111111111111199499499449994999949994ccccccccc
999aaaaaa00aaa0aaaaaaaaaaa999999ccccccc0000055aaaaa550000ccccccc111111111111333111111111111111114949994cccc99949ccc9999fffffffcc
99aaaaa000aaaaaaaaaaaaaaaaa99999cccccc000055aaaa8aaaa5500ccccccc1111111333311333cc1c111111111111499999cc11cc911cc1cc499fffffffff
99a0aaa00aaaaaaaaa00aaaaaaaa9999cccccc00005aaa88888aaa5000cccccc11111333333311b33c1cc1c11111ccc194999cc1001c1c1c111c499fffffffff
99a0aaaa0eaaaaaee00eaaaaaaaa9999cccccc0005aaaaa888aaaaa500cccccc1111ccc33bbbb1bb3cccccccc111cccc94994c10000ccc1c111c994fffffffff
99aaaaaaeeeeeeeeeeeeea0aaaaa9999ccccc00005aaaaa8a8aaaaa5000ccccc111ccccccc3bbb3bbc33333cccc1cccc94949c10000cc1c1c1cc9495555fffff
99aaaaaaeeeeeeeeeeeeea00aaaa0999ccccc00005aaaaaaaaaaaaa5000ccccc1c1cccc33333bbbbb3333333cccccccc99499c10000c1c11ccc949255555ffff
999a00aaeeeeeeeeeeeeeaaaaaa00999ccccc00000ffffffaffffff5000ccccc1cccc333bbbbbbbbb33333333ccccccc94949c100001c1c1999492a25555ffef
9990aa00eeeeeeeeeeeeeeaaaaa09999ccccc00000fffffffffffff0000ccccccccc333333bbbbbbbbbbcccccccccccce9e94c10066c1c119994b92555fffeff
99a00aeeeeeeeeeeeeeeeeaaaaaaa999cccc000000fff000f000fff00000ccccccc33333cccc33bbbbbbb37cccccccc70e929c10666cccc199bab95fffffefff
99aa00e0eeeeeee00000eeaaaaaaa999cccc005000fff07fff70fff00000cccc7cc33ccccc3333bbbb333377cc7cc7c7e9e92c16666cccc1999b9ffffff55eff
9aaa000e00eeeeeecee00ea0aa0aa099ccc0050000fff00fff00fff00000cccc77c3ccccc3333fbb3bb33337777c77c7fffffb555bb5fcc1ffffffffff5555ff
99aaa0eccc0eeecccc0ceea0aa000099ccc000000ffffffffffffff000000ccc7777c7c733337fbb33bb333777737777ffffb5bb555bffc1fffffffff555555f
99aa0a0000ceeee0000ceea00aa00999cc0000000ffffffffffffff000000ccc7777777733337fbb33bb733777737777fffb55555bb5ffffffffffffffffffff
99aa0ae0eeeeeeeee00eee00aaa00999cc000000ffffff88888fffff000000cc777777733337ffbb33b7777337733777ff55bb5bb55fffffffffffffffffffff
99aa0aeeeeeeeeeeeeeeee0aaa00a999cc000000fffffff888ffffff000000cc777777733377fbb33377733333b33377f5bb55555bbfffffffffffffffffffff
99a0aaeeeeeeeeeeeeeeee00aa009999cc000000ffffffffffffffff000000ccccccccc333ccfbc333cccccc33bb33cc555555bbbb5fffffffffffffffffffff
9990aaeeeeeee0eeeeeee000aa000999cc0050000ffffffffffffff0000500ccccccccc33ccffcc333c333bbb3bb33bc5555555555ffffffffffffffffffffff
9999aaeeee000e0eeeee00000aa00999cc055000000ffffffffff0000005500ccccccccc3ccffcc33c33333bbb3b3bbc55555555555555555555555555555555
9999900eeeeeeeeeeeee000d00009999c00500000000aaffffaa000000005500cccccccccccffcc33ccc3333bbbb3bbc55555555555555555555555555555555
9999900eee808808eeeee0dd000999990000000000000aaaaaa0000000000000cc666c6c6cffccc3cccccc333bbbbb3355555555555555555555555555555555
9999900ee8077700eeeee00d0099999900000000088888888888888880000000ccccccccccffccccccccbbbbbbbbb33355555555555555555555555555555555
99999a0eee08800eeee0000009999999c00fff8555ffffffffffff5558fff00cccccccccccffcccccccbb3333fbbbbbc55555555555555555555555555555555
99999900eee088eeeee0000009999999ccfff85aaa5ffff55ffff5aaa58fffccccccccccccffccccccc3333cffbbbbb355555555555555555555555555555555
999999a0eeeeeeeee0000ccc09999999cff0085aaaa5ff5aa5ff5aaaa5800ffc6cccccccccffcccccc3333cffbbbbcbb55555ffff55555555555555555555555
9999999a0eeeeeee00000ccc99999999cff08885aaaa55aaaa55aaaa58880ffc666c6cc66ff66ccc66333cffbb3bbc3bffffffffffffffffffffffffffffffff
9999999900eeee00000ee0ccc9999999fff0888555aaaaaaaaaaaa5558880fff666666666ff666666633cffbb33bbcc3ffffffffffffffffffffffffffffffff
999999999000000000eeecccc9999999ff08888880055aa55aa55008888880ffcccccccccffccccccc3cffbbc33bccc3ffffffffffffffffffffffffffffffff
90000000000000000eeeeccccc999999ff0888888880055555500888888880ffcccccccccffccccccccffcccc33bccc3ffffffffffffffffffffffffffffffff
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000fffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000fffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000fffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000fffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffffffffffffffefffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fffffffffffffeeeffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ffffffffffffeeeffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000fffffffffffffefffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000fffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000fffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000fffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000ffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000ffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000fffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccc777777777ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccc777777777ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccc777777777ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccc777777777ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccc777777777ccccccccccccccccccccccccccccccccccccccc
cccc7777cccccccccccccccccccccccccccccccccccccccccccccccccccccc000777777ccccccccc000077777ccccccccccccccccccccccccccccccccccccccc
cccc7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccccccccccccc77777ccccccccccccccccccccccccccccccccccccccc
c7777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccccccccccccc77777ccccccccccccccccccccccccccccccccccccccc
c7777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccccccccccccc77777ccccccccccccccccccccccccccccccccccccccc
77777777777777ccc77777777777ccccccc77777cc777777ccc7777777ccccccc777777ccccccccccccc77777cccccccccccccccccccccccc77777cccccccccc
77777777777777ccc77777777777ccccccc77777cc777777cc77777777ccccccc777777ccccccccccccc77777cccccccccccccccccccccccc77777cccccccccc
77777777777777cc77777777777777ccccc7777777777777777777777777ccccc777777ccccccccccccc77777ccccccccc777777777cccccc77777cccccccccc
77777777777777cc77777777777777ccccc7777777777777777777777777ccccc7777777777777cccccc77777cccccccc77777777777ccccc77777cc7777cccc
77777777777777cc77777777777777ccccc7777777777777777777777777ccccc77777777777777ccccc77777ccccccc7777777777777cccc77777777777cccc
00777777000000cc77777000077777ccccc7777777777777777777777777ccccc7777777777777777ccc77777ccccccc7777777777777cccc77777777777cccc
cc777777cccccccc77777cccc77777ccccc777777777777777777777777777ccc7777777777777777ccc77777cccccc777777777777777ccc77777777777cccc
cc777777cccccccc00000cccc77777ccccc777770000007777700000777777ccc7777770000007777ccc77777cccccc777777777777777ccc77777077770cccc
cc777777ccccccccccccccccc77777ccccc77777cccccc77777ccccc777777ccc777777cccccc7777ccc77777cccccc777777ccccc7777ccc77777077700cccc
cc777777cccccccc77777777777777ccccc77777cccccc77777ccccc777777ccc777777cccccc7777ccc77777cccccc777777000007777ccc77777c000cccccc
cc777777cccccccc77777777777777ccccc77777cccccc77777ccccc777777ccc777777cccccc7777ccc77777cccccc777777777777777ccc77777cccccccccc
cc777777777ccccc77777cccc77777ccccc77777cccccc77777ccccc777777ccc777777cccccc7777ccc77777cccccc777777777777777ccc77777cccccccccc
cc777777777ccccc77777cccc77777ccccc77777cccccc77777ccccc777777ccc777777cccccc7777ccc77777cccccc777777777777777ccc77777cccccccccc
cc777777777ccccc77777cccc77777ccccc77777cccccc77777ccccc777777ccc7777777777777777ccc777777777cc777777cccccccccccc77777ccccc77777
cc777777777ccccc77777000077777ccccc77777cccccc77777ccccc777777ccc7777777777777777ccc777777777cc777777cccccccccccc77777ccccc77777
cc777777777ccccc0777777777777777c777777777cc777777777cc77777777cc7777777777777777ccc777777777cc777777777777777c777777777ccc77777
cc007777777cccccc777777777777777c777777777cc777777777cc77777777cc7777777777777700ccc777777777cc777777777777777c777777777ccc77777
cccc7777777cccccc777777777777777c777777777cc777777777cc77777777cc77777777777777ccccc777777777cc007777777777777c777777777ccc77777
cccc0000000cccccc000000000000000c000000000cc000000000cc00000000cc00000000000000ccccc000000000ccc00000000000000c00000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01140000210400000000000210400000021040000002104021040000002004000000250400000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000c63300000000000c6330c6330000000000000000c63000000000000c6330c63300000000000c6000c63000000000000c6330c6330000000000000000c63000000000000c6330c633000000000000000
011400001905000000000001905019000190500000019050190500000017040000001c0500000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000000000000000000000000000000001e0601c0401904017040190401e0601c0401904017040190401e0601c0401904017040190401e0601c040190001e0001c0001900017000190001e0001c00000000
0014000000000000001e0501e0501e050000001e050000001e050000001e05020050200502205022050230502305023050230500000000000000001b0501b0501c0501c0501c050000001e0501e0500000000000
001400001e0501e050000001c0501c0501c0501c0001b0501b0501b0500000019050190500000017050000001b0501b0501b0501b0501c0501c0301c0501b0501905019000190001905000000190500000019050
001400001704000000170401704000000170401704000000160400000016040160401604000000000001604014040140400000014040000001404000000000001204000000120401204000000120401204000000
00140000170400000017040150400000015040000001404014040200000c000150400000000000000000000014040000001404014040140400000014040140402105000000000002105000000210500000021050
001400002105000000200502000025050200000000000000190000000000000000000000000000000000000000000000000000000000000000000000000000002104000000000002104000000210400000021040
00140000190500000017050000001c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001905000000000001905000000190500000019050
011400002105000000200502000025050200000000000000190000000000000000000000000000000000000000000000000000000000000000000000000000001e04000000000001e040000001e040000001e040
001400000c63300000000000c6330c6330000000000000000c63000000000000c6330c63300000000000c6000c63000000000000c6330c6330000000000000000c63000000000000c6330c633000000000000000
00140000190500000017050000001c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001905000000000001905000000190500000019050
001400000000000000000000000000000000001e0601c0401904017040190401e0601c0401904017040190401e0601c0401904017040190401e0601c040190002100021052210522105221000210501c00021050
001400002105000000210500000021050000002105021050210502105020000200002000220050200002005020050200502005000000000000000000000000002100021052210522105221000210502100021050
001400001a050000001a050000001a050000001a05000000150500000015050000001505000000150500000010050000001005000000100500000010050000001e050000001e050000001e050000001e05000000
0014000021030000002103000000210300000021030000001c030000001c030000001c030000001c030000001c030000001c030000001c030000001c030000001904000000000001904000000190400000019040
001400002105000000210500000021050000002105021050210502105023050230502105020050200002005020050200502005000000000000000000000000002100021050210502105021000210502100021050
001400001a050000001a050000001a050000001a0500000015050000001505000000150500000015050000001905000000190500000019050000001905000000210500000021000210501e000210501e00021050
0014000021050000002105000000210502105020000000002105021050210502105020050200501c0501c05020050200502005020050200502005021050200501e05000000000001e050000001e050000001e050
0014000000000000000000000000000000000000000000000000000000000000000000000000001e0601c0401904017040190401e0601c0401904017040190401e0601c0401904017040190401e0601c04000000
0113000028040270402804029040280402404026040280402904028040290402b0402904026040240402604028040260402804029040280402404023040240402604226042280402804026040260402604226042
0013000018550000000000000000185500000021550000001855000000000001a55000000000001f55000000235500000000000245501a5501a5501a5501a5501a5500000023552235521f552235521f5521f552
011300000c0530000000000000000c6430000000000000003f3350c05300000000000c6430000000000000000c0530000000000000000c6430000000000000000c0530000000000000000c05300000000003f335
011300001005500000000000000010055000000e055000001105500000000001305500000000000c0550000010055000000000011055130551305513055130550e0550000010055100550e0550c0550e05510055
0113000023030220302303018030230301f03021030230302403023030240302603024030210301f0302103023030210302303024030230301f030230301f0302103221032230322303221032210322103221032
011300000c0433f225246050c04324645246050c0430c0430c043246453f2250c043246450000024605246050c04300000000000c043246453f2250c003246050c043000003f2253f22524645246452464524645
011300001353013530135301353013530135301353013530155301553015530155301553015530155301553013530135301353013530135301353013530135301053010530105301053010530105301053013530
001300001f5500000000000000001f550000001e550000002155000000000002355000000000001c550000001f550000000000021550235501f5501a5501a5501f55000000000000000000000000000000000000
011300001c5501c5500c5001c5501c5500c5031c5501c550000001f5501f550000001e5501e5501e5501e5501c5501c550000001c5501c550000001c5501c550000001f5501f5500000023552235522355223552
01130000175501755017500175501755017500175501755000000175501755000000175501755017550175501755017550000001755017550000001755017550000001755017550000001a5521a5521a5521a552
011300000c0433f2253f2250c04324645000000c0430c0430c043246453f2250c04324645000003f225246450c043000003f2250c043246453f22524645000000c043000003f2253f22524645246452464524645
011300001c0501d0501c0501b0501c0501d0501c0501b0001c050210501c050180501c050210501f0501d0001f0501f0501f05021050210501d0501d0501d0501f0501f0501f0501f05000000000000000000000
011300002404024040240402404024040240402b0402b0402d0402d0402d0402d04000000000002b0402b0402f0402f04024040240402f0402f0402d0402d0402b0402b0402b0402b0402b0422b0422b0422b042
011200002404024040240402404024040240002b0402b0402d0402d0402d0402d0402d040240402f040240402f0402d0402f040240402f0402d0402b040240402b0402d0402b0402d0402b0402b0422b0422b042
0013000018030180301803018030180300000018030180300000000000180301803018030180300000000000180301803018030180301803000000000001c0001c0301c0301c0301c03000000000000000000000
001300001005500000000000000010055000000e055000001105500000000001305500000000000c0550000010055000000000011055130551305513055130550e0550000010055100550e0550c0050e00510005
0101000005320063200732006320083200e3200c320133201132017320153200532008320163200b320203202a3201432019320263201f32023320263202032025320223203032029320273202e3202132033320
010100003f32038320313202c32026320343201f320353201c32032320243201c320163202c3201e3200a3200932026320233201b3200732014320113200f3200d32014320123201132006320053200b32000020
__music__
01 01020315
00 01020315
00 0702054b
00 08020644
00 09020a04
00 0b0c0d0e
00 1002110f
00 10021112
00 1002110f
02 10021114
01 1618191c
00 161b191a
00 161b191a
00 411b191d
00 171b191d
00 1e201f1b
00 1e201f1b
00 181b4344
02 181b4344

