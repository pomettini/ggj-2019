pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- gameplay globals
posts = {}
score = 0
countdown = 1
-- animation globals
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

function load_database()
    -- first row, second row, third row, is not porn
    insert_post("ciao", "micio", "mao", true)
    insert_post("donna calda", "cerca te", "clicca qui", false)
    insert_post("i bless the", "rain down", "in africa", true)
    insert_post("tette", "culo", "pipolo", false)
    insert_post("roberto", "chirone", "jek", false)
    insert_post("b", "b", "b", false)
    insert_post("c", "c", "c", false)
    insert_post("d", "d", "d", false)
end

function insert_post(first, second, third, valid)
    local post = {}
    post.first_row = first
    post.second_row = second
    post.third_row = third
    post.is_valid = valid
    add(database, post)
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

function get_random_post_id()
    return flr(rnd(#database)) + 1
end

function process_buttons()
    if is_animating_swipe == false then
        if btnp(5) then
            swipe_direction = -1
            is_animating_swipe = true
        end
        if btnp(4) then
            swipe_direction = 1
            is_animating_swipe = true
        end
    end
end

function process_feed_animation()
    if is_animating_feed then
        posts_y_offset -= 10
    end

    if posts_y_offset <= -40 then
        -- here is where the animation ends
        is_animating_feed = false
        pop_and_push_post()
        posts_x_offset = 0
        posts_y_offset = 0
    end
end

function process_swipe_animation(direction)
    if is_animating_swipe then
        posts_x_offset -= 16 * swipe_direction
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
    countdown -= 0.01
end

-- start draw stuff

function draw_background()
    rectfill(0, 0, 128, 128, 1)
end

function draw_bar()
    rectfill(0, 0, 128, 16, 1)
    line(0, 16, 128, 16, 12)
    -- search bar
    rectfill(12, 4, 96, 12, 0)
    print("cerca su tumblr", 14, 6, 7)
end

function draw_post(x_offset, y_offset, first_row, second_row, third_row)
    -- post bg
    rectfill(
        32 + x_offset, 
        8 + y_offset, 
        120 + x_offset, 
        40 + y_offset, 
        7)
    -- profile pic
    rectfill(
        8 + x_offset, 
        8 + y_offset, 
        24 + x_offset, 
        24 + y_offset, 
        0)
    -- image
    rectfill(
        32 + x_offset,
        8 + y_offset, 
        64 + x_offset, 
        40 + y_offset, 
        0)
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
    draw_post(x_offset, 0 + y_offset, posts[1].first_row, posts[1].second_row, posts[1].third_row)
    draw_post(0, 40 + y_offset, posts[2].first_row, posts[2].second_row, posts[2].third_row)
    draw_post(0, 80 + y_offset, posts[3].first_row, posts[3].second_row, posts[3].third_row)
    draw_post(0, 120 + y_offset, posts[4].first_row, posts[4].second_row, posts[4].third_row)
end

function draw_debug_stuff()
    -- print(posts[0].first_row, 0, 0, 7)
    -- print(posts_x_offset, 0, 0, 7)
    -- print(flr(rnd(#database)), 0, 0, 7)
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

-- end draw stuff

function _init()
    load_database()
    generate_posts()
end

function _update()
    process_buttons()
    process_feed_animation()
    process_swipe_animation()
    decrease_countdown()
end

function _draw()
    draw_background()
    draw_posts()
    draw_bar()
    draw_debug_stuff()
    draw_camera_shake()
    draw_countdown_bar()
end