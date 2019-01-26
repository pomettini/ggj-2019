pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- states
menu = 0
tutorial = 1
game = 2
gameover = 3
gamestate = menu
-- gameplay globals
posts = {}
tutorial_posts = {}
score = 0
countdown = 1
-- animation globals
menu_lock = false
-- game animation globals
swipe_direction = 0
is_animating_feed = false
is_animating_swipe = false
posts_y_offset = 0
posts_x_offset = 0
is_camera_shaking = false
camera_shake_cooldown = 0
-- const globals
database = {}
text_y_offset = -2
camera_shake_intensity = 5
camera_shake_duration = 0.5
countdown_speed = 0.002
profile_pics = 8
post_pics = 4

function load_database()
    -- first row, second row, third row, is not porn
    insert_post("ciao", "micio", "mao", true)
    insert_post("donna calda", "cerca te", "clicca qui", false)
    insert_post("i bless the", "rain down", "in africa", true)
    insert_post("tette", "culo", "pipolo", false)
    insert_post("roberto", "chirone", "jek", true)
    insert_post("safe", "safe", "safe", true)
    insert_post("sex", "sex", "sex", false)
end

function load_tutorial_posts()
    insert_tutorial_post("sei rob, il", "nuovo moderatore", "di tambler")
    insert_tutorial_post("il tuo lavoro e'", "eliminiare i", "contenuti espliciti")
    insert_tutorial_post("premi la freccia", "a destra per", "approvare il post")
    insert_tutorial_post("premi la freccia", "a sinistra per", "eliminare il post")
    insert_tutorial_post("se sbagli sarai", "licenziato!!!", "")
end

function insert_post(first, second, third, valid)
    local post = {}
    post.first_row = first
    post.second_row = second
    post.third_row = third
    post.is_valid = valid
    post.profile_id = get_random_profile_pic()
    post.post_pic_id = get_random_post_pic()
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
        end
        -- right arrow key
        if btnp(1) then
            swipe_direction = 1
            is_animating_swipe = true
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
        countdown = 0
    end
end

function evaluate_gameover()
    if countdown <= 0 then
        gamestate = gameover
    end
end

function change_state(new_state)
    menu_lock = true
    gamestate = new_state

    if new_state == game then
        reset_game_state()
    end
end

function reset_game_state()
    generate_posts()
    score = 0
    countdown = 1
    swipe_direction = 0
    is_animating_feed = false
    is_animating_swipe = false
    posts_y_offset = 0
    posts_x_offset = 0
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

function draw_post(x_offset, y_offset, first_row, second_row, third_row, profile_id, post_pic_id)
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
        profile_id,
        8 + x_offset,
        8 + y_offset)
    -- image
    rectfill(
        32 + x_offset,
        8 + y_offset, 
        64 + x_offset, 
        40 + y_offset, 
        0)
    draw_post_pic(
        post_pic_id,
        32 + x_offset,
        8 + y_offset
    )
    -- text
    print(
        first_row, 
        72 + x_offset, 
        16 + y_offset + text_y_offset)
    print(
        second_row, 
        72 + x_offset, 
        24 + y_offset + text_y_offset)
    print(
        third_row, 
        72 + x_offset, 
        32 + y_offset + text_y_offset)
end

function draw_posts()
    local y_offset = posts_y_offset + 16
    local x_offset = posts_x_offset
    -- max 11 char for row
    -- horrible code must refactor
    draw_post(x_offset, 0 + y_offset, posts[1].first_row, posts[1].second_row, posts[1].third_row, posts[1].profile_id, posts[1].post_pic_id)
    draw_post(0, 40 + y_offset, posts[2].first_row, posts[2].second_row, posts[2].third_row, posts[2].profile_id, posts[2].post_pic_id)
    draw_post(0, 80 + y_offset, posts[3].first_row, posts[3].second_row, posts[3].third_row, posts[3].profile_id, posts[3].post_pic_id)
    draw_post(0, 120 + y_offset, posts[4].first_row, posts[4].second_row, posts[4].third_row, posts[4].profile_id, posts[4].post_pic_id)
end

function draw_debug_stuff()
    -- print(posts[0].first_row, 0, 0, 7)
    -- print(posts_x_offset, 0, 0, 7)
    -- print(flr(rnd(#database)), 0, 0, 7)
    -- print(tutorial_posts[1], 0, 0, 7)
end

function draw_camera_shake()
    if camera_shake_cooldown > 0 then
        camera(
            rnd(camera_shake_intensity) - (camera_shake_intensity / 2), 
            rnd(camera_shake_intensity) - (camera_shake_intensity / 2))
        camera_shake_cooldown -= 0.1
    else
        camera()
    end
end

function draw_countdown_bar()
    rectfill(0, 112, 128, 128, 0)
    rectfill(0, 112, 128 * countdown, 128, 7)
    line(0, 112, 128, 112, 0)
end

-- end game draw stuff

-- start other update stuff

function process_menu_screen()
    if btnp(1) and not menu_lock then
        change_state(tutorial)
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
    if btnp(1) and not menu_lock then
        reset_game_state()
        change_state(game)
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
    rectfill(0, 0, 128, 128, 0)
    print("menu", 60, 60, 7)
    print("premi destra per iniziare", 20, 80, 7)
end

function draw_tutorial_screen()
    rectfill(0, 0, 128, 128, 0)
    print("tutorial", 60, 60, 7)
    print("premi destra per continuare", 15, 80, 7)
end

function draw_gameover_screen()
    local y_offset = -4
    rectfill(0, 0, 128, 128, 1)
    draw_text_wave("  game over  ", 26 + y_offset)
    draw_text_center("sei stato cacciato!", 52 + y_offset)
    draw_text_center("il tuo punteggio e': "..score, 78 + y_offset)
    draw_text_center("premi destra per riprovare", 104 + y_offset)
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
    print(text, h_center(text), y)
end

function h_center(text)
    return 64 - #text * 2
end

function draw_tutorial_post(x_offset, y_offset, first_row, second_row, third_row)
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
        first_row, 
        40 + x_offset, 
        16 + y_offset + text_y_offset, 0)
    print(
        second_row, 
        40 + x_offset, 
        24 + y_offset + text_y_offset, 0)
    print(
        third_row, 
        40 + x_offset, 
        32 + y_offset + text_y_offset, 0)
end

function draw_tutorial_posts()
    local y_offset = posts_y_offset + 32
    local x_offset = posts_x_offset
    -- horrible code must refactor
    -- very horrible!!!
    if tutorial_posts[1] != nil then
        draw_tutorial_post(
            x_offset, 
            0 + y_offset, 
            tutorial_posts[1].first_row, 
            tutorial_posts[1].second_row, 
            tutorial_posts[1].third_row)
    end
    for i = 2, #tutorial_posts + 1 do
        if tutorial_posts[i] != nil then
            draw_tutorial_post(
                0, 
                (40 * (i - 1)) + y_offset, 
                tutorial_posts[i].first_row, 
                tutorial_posts[i].second_row, 
                tutorial_posts[i].third_row)
        end
    end
end

function draw_profile_pic(id, x, y)
    sspr(id * 16, 16, 16, 16, x, y)
end

function draw_post_pic(id, x, y)
    sspr(id * 32, 32, 32, 32, x, y)
end

-- end other draw stuff

function _init()
    load_database()
    generate_posts()
    load_tutorial_posts()
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
end

function _draw()
    if gamestate == menu then
        draw_menu_screen()
        -- draw_profile_pic(1, 10, 10)
    end
    if gamestate == tutorial then
        draw_background()
        draw_tutorial_posts()
        draw_debug_stuff()
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
