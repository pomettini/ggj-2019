pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- globals
text_y_offset = -2

function draw_post(y_offset, first_row, second_row, third_row)
    -- post bg
    rectfill(32, 8 + y_offset, 120, 40 + y_offset, 7)
    -- profile pic
    rectfill(8, 8 + y_offset, 24, 24 + y_offset, 0)
    -- image
    rectfill(32, 8 + y_offset, 64, 40 + y_offset, 0)
    -- text
    print(first_row, 72, 16 + y_offset + text_y_offset)
    print(second_row, 72, 24 + y_offset + text_y_offset)
    print(third_row, 72, 32 + y_offset + text_y_offset)
end

function draw_posts()
    -- max 11 char for row
    draw_post(0, "donna calda", "cerca te", "clicca qui")
    draw_post(40, "donna calda", "cerca te", "clicca qui")
    draw_post(80, "donna calda", "cerca te", "clicca qui")
end

function draw_background()
    rectfill(0, 0, 128, 128, 1)
end

function _update()

end

function _draw()
    draw_background()
    draw_posts()
end