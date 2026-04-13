--[[
hayase-osc.lua
https://github.com/Xurdejl/mpv-config

Custom OSC for mpv inspired by hayase player UI

Based on Samillion/ModernZ and mpv’s osc.lua
License: LGPL v2.1
]]

local assdraw = require "mp.assdraw"
local msg = require "mp.msg"
local opt = require "mp.options"
local utils = require "mp.utils"
mp.set_property("osc", "no")

-- Parameters
-- default user option values
-- do not touch, change them in hayase-osc.conf
local user_opts = {
    idlescreen = true,                     -- show mpv logo when idle
    audioonlyscreen = false,               -- show mpv logo when no video
    osc_on_start = false,                  -- show OSC on start of every file
    osc_on_seek = false,                   -- show OSC when seeking
    keeponpause = true,                    -- disable OSC hide timeout when paused
    hidetimeout = 1000,                    -- time (in ms) before OSC hides if no mouse movement
    fadein = true,                         -- whether to enable fade-in effect
    fadeduration = 200,                    -- fade-out duration (in ms), set to 0 for no fade
    minmousemove = 0,                      -- minimum mouse movement (in pixels) required to show OSC

    title = "${?demuxer-via-network==yes:${media-title}}${?demuxer-via-network==no:${filename/no-ext}}", -- title above seekbar format: "${media-title}" or "${filename}"

    timecurrent = true,                    -- show total time instead of remaining time
    timems = false,                        -- show timecodes with milliseconds

    window_top_bar = "auto",               -- show OSC window top bar: "auto", "yes", or "no" (borderless/fullscreen)
    window_title = false,                  -- show window title in borderless/fullscreen mode

    speed_button = false,                  -- show speed control button
    audio_button = false,                  -- show audio track button (only if more than 1 audio track exists)

    seekrange = true,                      -- show seek range overlay
    seekbarkeyframes = false,              -- use keyframes when dragging the seekbar
    automatickeyframemode = true,          -- automatically set keyframes for the seekbar based on video length
    automatickeyframelimit = 600,          -- videos longer than this (in seconds) will have keyframes on the seekbar
    persistent_progress = false,           -- always show a small progress line at the bottom of the screen
    persistent_buffer = false,             -- show cached buffer status in the persistent progress line

    accent_color = "#FFFFFF",             -- accent color for the progress bar

    visibility = "auto",                   -- only used at init to set visibility_mode(...)
    visibility_modes = "never_auto_always",-- visibility modes to cycle through
    greenandgrumpy = false,                -- disable Santa hat in December
    tick_delay = 1 / 60,                   -- minimum interval between OSC redraws (in seconds)
    tick_delay_follow_display_fps = false, -- use display FPS as the minimum redraw interval

    -- Mouse commands: title
    title_mbtn_left_command = "script-binding stats/display-page-5-toggle",
    title_mbtn_mid_command = "show-text ${path}",
    title_mbtn_right_command = "script-binding select/select-watch-history",

    -- Mouse commands: chapter_title
    chapter_title_mbtn_left_command = "script-binding select/select-chapter",
    chapter_title_mbtn_right_command = "",

    -- Mouse commands: play_pause
    play_pause_mbtn_mid_command = "cycle-values loop-playlist inf no",
    play_pause_mbtn_right_command = "cycle-values loop-file inf no",

    -- Mouse commands: playlist_prev
    playlist_prev_mbtn_left_command = "playlist-prev",
    playlist_prev_mbtn_right_command = "",

    -- Mouse commands: playlist_next
    playlist_next_mbtn_left_command = "playlist-next",
    playlist_next_mbtn_right_command = "",

    -- Mouse commands: vol_ctrl
    vol_ctrl_mbtn_left_command = "no-osd cycle mute",
    vol_ctrl_wheel_down_command = "no-osd add volume -5",
    vol_ctrl_wheel_up_command = "no-osd add volume 5",

    volumebar_wheel_down_command = "osd-msg add volume -5",
    volumebar_wheel_up_command = "osd-msg add volume 5",

    -- Mouse commands: menu
    menu_mbtn_left_command = "script-binding select/menu",

    -- Mouse commands: audio_track
    audio_track_mbtn_left_command = "script-binding select/select-aid",
    audio_track_mbtn_right_command = "set audio no",
    audio_track_wheel_down_command = "cycle audio",
    audio_track_wheel_up_command = "cycle audio down",

    -- Mouse commands: sub_track
    sub_track_mbtn_left_command = "script-binding select/select-sid",
    sub_track_mbtn_mid_command = "cycle sub-visibility",
    sub_track_mbtn_right_command = "set sub no",
    sub_track_wheel_down_command = "cycle sub",
    sub_track_wheel_up_command = "cycle sub down",

    -- Mouse commands: fullscreen
    fullscreen_mbtn_left_command = "cycle fullscreen"
}

local osc_param = {                  -- calculated by osc_init()
    playresy = 0,                    -- canvas size Y
    playresx = 0,                    -- canvas size X
    display_aspect = 1,
    areas = {},
    video_margins = {
        l = 0, r = 0, t = 0, b = 0,  -- left/right/top/bottom
    },
}

local icon_font = "Lucide"

local icons = {
    play = "\238\164\128",
    pause = "\238\164\129",
    replay = "\238\164\130",
    previous = "\238\164\131",
    next = "\238\164\132",
    mute = "\238\164\133",
    volume = {"\238\164\134", "\238\164\135", "\238\164\136", "\238\164\137"},

    menu = "\238\164\143",
    subtitle = "\238\164\144",
    audio = "\238\164\145",
    ontop_on = "\238\164\146",
    ontop_off = "\238\164\147",
    fullscreen = "\238\164\148",
    fullscreen_exit = "\238\164\149",

    window = {
        minimize = "\238\164\150",
        maximize = "\238\164\151",
        unmaximize = "\238\164\152",
        close = "\238\164\153",
    }
}

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local tick_delay = 1 / 60
local window_control_box_width = 150
local is_december = os.date("*t").month == 12

local function osc_color_convert(color)
    return color:sub(6,7) .. color:sub(4,5) ..  color:sub(2,3)
end

local osc_styles

local FONT_SIZE_LG = 24
local FONT_SIZE_MD = 18

local function set_osc_styles()
    osc_styles = {
        titlebar_bg    = "{\\blur80\\bord100\\1c&H0&\\3c&H000000&}",
        bottombar_bg   = "{\\blur80\\bord120\\1c&H0&\\3c&H000000&}",
        hover_bg       = "{\\bord0\\1c&HFAFAFA&}",
        tooltip_bg     = "{\\bord0\\1c&H000000&\\1a&H80&}",

        seekbar_bg     = "{\\bord0\\1c&HD9D9D9&\\1a&H99&}",
        seekbar_fg     = "{\\bord0\\1c&H" .. osc_color_convert(user_opts.accent_color) .. "&}",
        volumebar_bg   = "{\\bord0\\1c&HD9D9D9&\\1a&H99&}",
        volumebar_fg   = "{\\bord0\\1c&H" .. osc_color_convert(user_opts.accent_color) .. "&}",

        window_title   = "{\\bord0\\1c&HFFFFFF&\\fs" .. FONT_SIZE_LG .. "\\q2}",
        title          = "{\\bord0\\1c&HFFFFFF&\\fs" .. FONT_SIZE_LG .. "\\q2}",
        chapter_title  = "{\\bord0\\1c&HD9D9D9&\\1a&H66&\\fs" .. FONT_SIZE_MD .. "}",
        time           = "{\\bord0\\1c&HFFFFFF&\\fs" .. FONT_SIZE_MD .. "}",
        tooltip        = "{\\bord0\\1c&HFFFFFF&\\fs" .. FONT_SIZE_MD .. "}",

        window_control = "{\\bord0\\1c&HFFFFFF&\\fs10\\fn" .. icon_font .. "}",
        buttons        = "{\\bord0\\1c&HFFFFFF&\\fs24\\fn" .. icon_font .. "}",

        thumbnail      = "{\\bord1\\1c&HFFFFFF&\\3c&HFFFFFF&\\3a&HE6&}",
    }
end

-- internal states, do not touch
local state = {
    show_time = nil,                          -- time of last invocation (last mouse move)
    touch_time = nil,                         -- time of last invocation (last touch event)
    touch_points = {},                        -- current touch points
    osc_visible = false,
    ani_start = nil,                          -- time when the animation started
    ani_type = nil,                           -- current type of animation
    animation = nil,                          -- current animation alpha
    mouse_down_counter = 0,                   -- used for softrepeat
    active_element = nil,                     -- nil = none, 0 = background, 1+ = see elements[]
    active_event_source = nil,                -- the "button" that issued the current event
    tc_left_rem = not user_opts.timecurrent,  -- if the left timecode should display current or remaining time
    tc_ms = user_opts.timems,                 -- Should the timecodes display their time with milliseconds
    screen_size_x = nil, screen_size_y = nil, -- last screen-resolution, to detect resolution changes to issue reINITs
    init_req = false,                         -- is a re-init request pending?
    margins_req = false,                      -- is a margins update pending?
    last_mouse_x = nil, last_mouse_y = nil,   -- last mouse position, to detect significant mouse movement
    last_touch_x = -1, last_touch_y = -1,     -- last touch position
    mouse_in_window = false,
    fullscreen = false,
    tick_timer = nil,
    tick_last_time = 0,                       -- when the last tick() was run
    hide_timer = nil,
    demuxer_cache_state = nil,
    idle_active = false,
    audio_track_count = 0,
    sub_track_count = 0,
    playlist_count = 0,
    playlist_pos = 0,
    no_video = false,
    file_loaded = false,
    enabled = true,
    input_enabled = true,
    showhide_enabled = false,
    windowcontrols_buttons = false,
    wc_visible = false,
    border = true,
    window_maximized = false,
    osd = mp.create_osd_overlay("ass-events"),
    logo_osd = mp.create_osd_overlay("ass-events"),
    new_file_flag = false,                  -- flag to detect new file starts
    temp_visibility_mode = nil,             -- store temporary visibility mode state
    chapter_list = {},                      -- sorted by time
    chapter = -1,                           -- current chapter index
    visibility_modes = {},                  -- visibility_modes to cycle through
    mute = false,
    pause = false,
    eof_reached = false,
    volume = 0,
    ontop = false,
    speed = 1,
    file_loop = false,
    slider_pos = 0,
    initial_border = mp.get_property("border"),
    initial_title_bar = mp.get_property("title-bar"),
    playtime_hour_force_init = false,       -- used to force request_init() once
    playing_and_seeking = false,
    persistent_seekbar_element = nil,
    persistent_progress_toggle = user_opts.persistent_progress,
}

local logo_lines = {
    -- White border
    "{\\c&HE5E5E5&\\p6}m 895 10 b 401 10 0 410 0 905 0 1399 401 1800 895 1800 1390 1800 1790 1399 1790 905 1790 410 1390 10 895 10 {\\p0}",
    -- Purple fill
    "{\\c&H682167&\\p6}m 925 42 b 463 42 87 418 87 880 87 1343 463 1718 925 1718 1388 1718 1763 1343 1763 880 1763 418 1388 42 925 42{\\p0}",
    -- Darker fill
    "{\\c&H430142&\\p6}m 1605 828 b 1605 1175 1324 1456 977 1456 631 1456 349 1175 349 828 349 482 631 200 977 200 1324 200 1605 482 1605 828{\\p0}",
    -- White fill
    "{\\c&HDDDBDD&\\p6}m 1296 910 b 1296 1131 1117 1310 897 1310 676 1310 497 1131 497 910 497 689 676 511 897 511 1117 511 1296 689 1296 910{\\p0}",
    -- Triangle
    "{\\c&H691F69&\\p6}m 762 1113 l 762 708 b 881 776 1000 843 1119 911 1000 978 881 1046 762 1113{\\p0}",
}

local santa_hat_lines = {
    -- Pompoms
    "{\\c&HC0C0C0&\\p6}m 500 -323 b 491 -322 481 -318 475 -311 465 -312 456 -319 446 -318 434 -314 427 -304 417 -297 410 -290 404 -282 395 -278 390 -274 387 -267 381 -265 377 -261 379 -254 384 -253 397 -244 409 -232 425 -228 437 -228 446 -218 457 -217 462 -216 466 -213 468 -209 471 -205 477 -203 482 -206 491 -211 499 -217 508 -222 532 -235 556 -249 576 -267 584 -272 584 -284 578 -290 569 -305 550 -312 533 -309 523 -310 515 -316 507 -321 505 -323 503 -323 500 -323{\\p0}",
    "{\\c&HE0E0E0&\\p6}m 315 -260 b 286 -258 259 -240 246 -215 235 -210 222 -215 211 -211 204 -188 177 -176 172 -151 170 -139 163 -128 154 -121 143 -103 141 -81 143 -60 139 -46 125 -34 129 -17 132 -1 134 16 142 30 145 56 161 80 181 96 196 114 210 133 231 144 266 153 303 138 328 115 373 79 401 28 423 -24 446 -73 465 -123 483 -174 487 -199 467 -225 442 -227 421 -232 402 -242 384 -254 364 -259 342 -250 322 -260 320 -260 317 -261 315 -260{\\p0}",
    -- Main cap
    "{\\c&H0000F0&\\p6}m 1151 -523 b 1016 -516 891 -458 769 -406 693 -369 624 -319 561 -262 526 -252 465 -235 479 -187 502 -147 551 -135 588 -111 1115 165 1379 232 1909 761 1926 800 1952 834 1987 858 2020 883 2053 912 2065 952 2088 1000 2146 962 2139 919 2162 836 2156 747 2143 662 2131 615 2116 567 2122 517 2120 410 2090 306 2089 199 2092 147 2071 99 2034 64 1987 5 1928 -41 1869 -86 1777 -157 1712 -256 1629 -337 1578 -389 1521 -436 1461 -476 1407 -509 1343 -507 1284 -515 1240 -519 1195 -521 1151 -523{\\p0}",
    -- Cap shadow
    "{\\c&H0000AA&\\p6}m 1657 248 b 1658 254 1659 261 1660 267 1669 276 1680 284 1689 293 1695 302 1700 311 1707 320 1716 325 1726 330 1735 335 1744 347 1752 360 1761 371 1753 352 1754 331 1753 311 1751 237 1751 163 1751 90 1752 64 1752 37 1767 14 1778 -3 1785 -24 1786 -45 1786 -60 1786 -77 1774 -87 1760 -96 1750 -78 1751 -65 1748 -37 1750 -8 1750 20 1734 78 1715 134 1699 192 1694 211 1689 231 1676 246 1671 251 1661 255 1657 248 m 1909 541 b 1914 542 1922 549 1917 539 1919 520 1921 502 1919 483 1918 458 1917 433 1915 407 1930 373 1942 338 1947 301 1952 270 1954 238 1951 207 1946 214 1947 229 1945 239 1939 278 1936 318 1924 356 1923 362 1913 382 1912 364 1906 301 1904 237 1891 175 1887 150 1892 126 1892 101 1892 68 1893 35 1888 2 1884 -9 1871 -20 1859 -14 1851 -6 1854 9 1854 20 1855 58 1864 95 1873 132 1883 179 1894 225 1899 273 1908 362 1910 451 1909 541{\\p0}",
    -- Brim and tip pompom
    "{\\c&HF8F8F8&\\p6}m 626 -191 b 565 -155 486 -196 428 -151 387 -115 327 -101 304 -47 273 2 267 59 249 113 219 157 217 213 215 265 217 309 260 302 285 283 373 264 465 264 555 257 608 252 655 292 709 287 759 294 816 276 863 298 903 340 972 324 1012 367 1061 394 1125 382 1167 424 1213 462 1268 482 1322 506 1385 546 1427 610 1479 662 1510 690 1534 725 1566 752 1611 796 1664 830 1703 880 1740 918 1747 986 1805 1005 1863 991 1897 932 1916 880 1914 823 1945 777 1961 725 1979 673 1957 622 1938 575 1912 534 1862 515 1836 473 1790 417 1755 351 1697 305 1658 266 1633 216 1593 176 1574 138 1539 116 1497 110 1448 101 1402 77 1371 37 1346 -16 1295 15 1254 6 1211 -27 1170 -62 1121 -86 1072 -104 1027 -128 976 -133 914 -130 851 -137 794 -162 740 -181 679 -168 626 -191 m 2051 917 b 1971 932 1929 1017 1919 1091 1912 1149 1923 1214 1970 1254 2000 1279 2027 1314 2066 1325 2139 1338 2212 1295 2254 1238 2281 1203 2287 1158 2282 1116 2292 1061 2273 1006 2229 970 2206 941 2167 938 2138 918{\\p0}",
}

--
-- Helper functions
--

local function observe_cached(property, callback)
    mp.observe_property(property, "native", function (_, value)
        state[property:gsub("-", "_")] = value
        callback()
    end)
end

local function format_time(seconds)
    if seconds == nil then return "" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    local time_str
    if h > 0 then
        time_str = string.format("%d:%02d:%02d", h, m, s)
    else
        time_str = string.format("%d:%02d", m, s)
    end

    if state.tc_ms then
        local ms = math.floor((seconds % 1) * 1000)
        time_str = time_str .. string.format(".%03d", ms)
    end

    return time_str
end

local function kill_animation()
    state.ani_start = nil
    state.animation = nil
    state.ani_type =  nil
end

local function set_osd(osd, res_x, res_y, text, z)
    if osd.res_x == res_x and
       osd.res_y == res_y and
       osd.data == text then
        return
    end
    osd.res_x = res_x
    osd.res_y = res_y
    osd.data = text
    osd.z = z
    osd:update()
end

local function set_time_styles(timecurrent_changed, timems_changed)
    if timecurrent_changed then
        state.tc_left_rem = not user_opts.timecurrent
    end
    if timems_changed then
        state.tc_ms = user_opts.timems
    end
end

-- scale factor for translating between real and virtual ASS coordinates
local function get_virt_scale_factor()
    local w, h = mp.get_osd_size()
    if w <= 0 or h <= 0 then
        return 0, 0
    end
    return osc_param.playresx / w, osc_param.playresy / h
end

local function recently_touched()
    if state.touch_time == nil then
        return false
    end
    return state.touch_time + 1 >= mp.get_time()
end

-- return mouse position in virtual ASS coordinates (playresx/y)
local function get_virt_mouse_pos()
    if recently_touched() then
        local sx, sy = get_virt_scale_factor()
        return state.last_touch_x * sx, state.last_touch_y * sy
    elseif state.mouse_in_window then
        local sx, sy = get_virt_scale_factor()
        local x, y = mp.get_mouse_pos()
        return x * sx, y * sy
    else
        return -1, -1
    end
end

local function set_virt_mouse_area(x0, y0, x1, y1, name)
    local sx, sy = get_virt_scale_factor()
    mp.set_mouse_area(x0 / sx, y0 / sy, x1 / sx, y1 / sy, name)
end

local function scale_value(x0, x1, y0, y1, val)
    local m = (y1 - y0) / (x1 - x0)
    local b = y0 - (m * x0)
    return (m * val) + b
end

local tooltip_osd = mp.create_osd_overlay and mp.create_osd_overlay("ass-events") or nil
if tooltip_osd then
    tooltip_osd.hidden = true
    tooltip_osd.compute_bounds = true
end

local text_width_cache = {}

local function estimate_text_width(text, style)
    if text == nil then return 0 end
    text = tostring(text)
    if #text == 0 then return 0 end

    -- Replace digits with '0' to ensure width is perfectly stable during playback
    local measure_text = text:gsub("%d", "0")
    local cache_key = measure_text .. (style or "")

    if text_width_cache[cache_key] then
        return text_width_cache[cache_key]
    end

    local width = 0

    if tooltip_osd and tooltip_osd.update then
        tooltip_osd.res_x = osc_param.playresx
        tooltip_osd.res_y = osc_param.playresy
        tooltip_osd.data = (style or "") .. measure_text

        local bounds = tooltip_osd:update()
        if bounds and bounds.x1 and bounds.x0 then
            width = bounds.x1 - bounds.x0
        end
    end

    text_width_cache[cache_key] = width
    return width
end

-- returns hitbox spanning coordinates (top left, bottom right corner)
-- according to alignment
local function get_hitbox_coords(x, y, an, w, h)
    local alignments = {
      [1] = function () return x, y-h, x+w, y end,
      [2] = function () return x-(w/2), y-h, x+(w/2), y end,
      [3] = function () return x-w, y-h, x, y end,

      [4] = function () return x, y-(h/2), x+w, y+(h/2) end,
      [5] = function () return x-(w/2), y-(h/2), x+(w/2), y+(h/2) end,
      [6] = function () return x-w, y-(h/2), x, y+(h/2) end,

      [7] = function () return x, y, x+w, y+h end,
      [8] = function () return x-(w/2), y, x+(w/2), y+h end,
      [9] = function () return x-w, y, x, y+h end,
    }

    return alignments[an]()
end

local function get_element_hitbox(element)
    return element.hitbox.x1, element.hitbox.y1,
        element.hitbox.x2, element.hitbox.y2
end

local function mouse_hit_coords(b_x1, b_y1, b_x2, b_y2)
    local m_x, m_y = get_virt_mouse_pos()
    return (m_x >= b_x1 and m_x <= b_x2 and m_y >= b_y1 and m_y <= b_y2)
end

local function mouse_hit(element)
    return mouse_hit_coords(get_element_hitbox(element))
end

local seekbar_segments_cache = {w = nil, result = {}}

local function get_seekbar_segments(w)
    -- Use cached segments if width hasn't changed
    if seekbar_segments_cache.w == w then
        return seekbar_segments_cache.result
    end

    local duration = mp.get_property_number("duration", 0)
    local chapters = state.chapter_list

    if duration <= 0 or not chapters or #chapters == 0 then
        local result = {{x = 0, w = w, start_p = 0, end_p = 100}}
        seekbar_segments_cache.w = w
        seekbar_segments_cache.result = result
        return result
    end

    local times = {0}
    for _, c in ipairs(chapters) do
        if c.time > 0 and c.time < duration then -- skip chapter at 0:00
            table.insert(times, c.time)
        end
    end
    table.insert(times, duration)

    local gap = 4
    local num_segs = #times - 1
    local total_gap = (num_segs - 1) * gap
    local avail_w = w - total_gap

    local segments = {}
    local current_x = 0
    for i = 1, num_segs do
        local t_start = times[i]
        local t_end = times[i+1]
        local seg_w = ((t_end - t_start) / duration) * avail_w

        table.insert(segments, {
            x = current_x, w = seg_w,
            start_p = (t_start / duration) * 100,
            end_p = (t_end / duration) * 100
        })
        current_x = current_x + seg_w + gap
    end

    seekbar_segments_cache.w = w
    seekbar_segments_cache.result = segments
    return segments
end

local function get_slider_ele_pos_for(element, val)
    if element.name ~= "seekbar" and element.name ~= "persistent_seekbar" then
        local ele_pos = scale_value(element.slider.min.value, element.slider.max.value, element.slider.min.ele_pos, element.slider.max.ele_pos, val)
        return math.min(element.slider.max.ele_pos, math.max(element.slider.min.ele_pos, ele_pos))
    end

    local segments = get_seekbar_segments(element.layout.geometry.w)
    for _, seg in ipairs(segments) do
        if val >= seg.start_p and val <= seg.end_p then
            local ratio = (seg.end_p == seg.start_p) and 0 or (val - seg.start_p) / (seg.end_p - seg.start_p)
            return seg.x + ratio * seg.w
        end
    end
    -- val is before the first segment or past the last
    return val < segments[1].start_p and segments[1].x or (segments[#segments].x + segments[#segments].w)
end

local function get_slider_value_at(element, glob_pos)
    if not element then return 0 end
    if element.name ~= "seekbar" and element.name ~= "persistent_seekbar" then
        local val = scale_value(element.slider.min.glob_pos, element.slider.max.glob_pos, element.slider.min.value, element.slider.max.value, glob_pos)
        return math.min(element.slider.max.value, math.max(element.slider.min.value, val))
    end

    local local_x = glob_pos - element.hitbox.x1
    local segments = get_seekbar_segments(element.layout.geometry.w)

    for i, seg in ipairs(segments) do
        if local_x >= seg.x and local_x <= seg.x + seg.w then
            local ratio = (seg.w == 0) and 0 or (local_x - seg.x) / seg.w
            return seg.start_p + ratio * (seg.end_p - seg.start_p)
        end
        -- Mouse is in the gap between segments: snap to nearest boundary
        if i < #segments and local_x > seg.x + seg.w and local_x < segments[i+1].x then
            return (local_x - (seg.x + seg.w)) < (segments[i+1].x - local_x) and seg.end_p or segments[i+1].start_p
        end
    end
    return local_x < segments[1].x and segments[1].start_p or segments[#segments].end_p
end

local function get_slider_value(element)
    return get_slider_value_at(element, get_virt_mouse_pos())
end

-- multiplies two alpha values
local function mult_alpha(alpha_a, alpha_b)
    return 255 - (255 - alpha_a) * (255 - alpha_b) / 255
end

local function add_area(name, x1, y1, x2, y2)
    -- create area if needed
    if osc_param.areas[name] == nil then
        osc_param.areas[name] = {}
    end
    table.insert(osc_param.areas[name], {x1=x1, y1=y1, x2=x2, y2=y2})
end

local function ass_append_alpha(ass, alpha, modifier, inverse)
    local ar = {}

    for ai, av in ipairs(alpha) do
        av = mult_alpha(av, modifier)
        if state.animation then
            local animpos = state.animation
            if inverse then
                animpos = 255 - animpos
            end
            av = mult_alpha(av, animpos)
        end
        ar[ai] = av
    end

    ass:append(string.format("{\\1a&H%X&\\2a&H%X&\\3a&H%X&\\4a&H%X&}",
               ar[1], ar[2], ar[3], ar[4]))
end

local function get_hidetimeout()
    if user_opts.visibility == "always" then
        return -1 -- disable autohide
    end
    return user_opts.hidetimeout
end

local function get_touchtimeout()
    if state.touch_time == nil then
        return 0
    end
    return state.touch_time + (get_hidetimeout() / 1000) - mp.get_time()
end

local function cache_enabled()
    return state.demuxer_cache_state and #state.demuxer_cache_state["seekable-ranges"] > 0
end

local function update_margins()
    local margins = osc_param.video_margins

    -- Don't use margins if it's visible only temporarily.
    if not state.osc_visible or get_hidetimeout() >= 0 then
        margins = {l = 0, r = 0, t = 0, b = 0}
    end

    mp.set_property_native("user-data/osc/margins", margins)
end

local tick
-- Request that tick() is called (which typically re-renders the OSC).
-- The tick is then either executed immediately, or rate-limited if it was
-- called a small time ago.
local function request_tick()
    if state.tick_timer == nil then
        state.tick_timer = mp.add_timeout(0, tick)
    end

    if not state.tick_timer:is_enabled() then
        local now = mp.get_time()
        local timeout = tick_delay - (now - state.tick_last_time)
        if timeout < 0 then
            timeout = 0
        end
        state.tick_timer.timeout = timeout
        state.tick_timer:resume()
    end
end

local function request_init()
    state.init_req = true
    request_tick()
end

-- Like request_init(), but also request an immediate update
local function request_init_resize()
    request_init()
    -- ensure immediate update
    state.tick_timer:kill()
    state.tick_timer.timeout = 0
    state.tick_timer:resume()
end

local function render_wipe(osd)
    msg.trace("render_wipe()")
    osd.data = "" -- allows set_osd to immediately update on enable
    osd:remove()
end

--
-- Tracklist Management
--

-- updates the OSC internal playlists, should be run each time the track-layout changes
local function update_tracklist(_, track_list)
    state.audio_track_count = 0
    state.sub_track_count = 0
    state.no_video = true

    for _, track in pairs(track_list) do
        if track.type == "audio" then
            state.audio_track_count = state.audio_track_count + 1
        elseif track.type == "sub" then
            state.sub_track_count = state.sub_track_count + 1
        elseif track.type == "video" and track.selected then
            state.no_video = false
        end
    end

    request_init()
end

-- WindowControl helpers
local function window_controls_enabled()
    local val = user_opts.window_top_bar
    if state.fullscreen then
        return false
    end
    if val == "auto" then
        return not state.border or not state.title_bar
    else
        return val ~= "no"
    end
end

--
-- Element Management
--
local elements = {}

-- Helper to draw rounded/flat rectangles
local function draw_rect(ass, x1, y1, x2, y2, r_left, r_right, r)
    local w = x2 - x1
    if w <= 0.05 then return end
    r = r or 0

    local current_r = r
    if w < current_r * 2 then current_r = w / 2 end

    if current_r > 0 and (r_left or r_right) then
        ass:round_rect_cw(x1, y1, x2, y2, current_r)
        -- Overlap flat rectangles to square off the sides we don't want rounded
        if not r_left then ass:rect_cw(x1, y1, x1 + current_r, y2) end
        if not r_right then ass:rect_cw(x2 - current_r, y1, x2, y2) end
    else
        ass:rect_cw(x1, y1, x2, y2)
    end
end

local function prepare_elements()
    -- remove elements without layout or invisible
    local elements2 = {}
    for _, element in pairs(elements) do
        if element.layout ~= nil and element.visible then
            table.insert(elements2, element)
        end
    end
    elements = elements2

    local function elem_compare (a, b)
        return a.layout.layer < b.layout.layer
    end

    table.sort(elements, elem_compare)

    -- Invalidate segment cache (called on init which covers width/chapter changes)
    seekbar_segments_cache.w = nil

    for _,element in pairs(elements) do

        local elem_geo = element.layout.geometry

        -- calculate title and chapter hitbox
        local hitbox_w = elem_geo.w
        if (element.name == "title" or element.name == "chapter_title") and type(element.content) == "function" then
            local text_w = estimate_text_width(element.content(), osc_styles[element.name])

            if text_w > 0 then hitbox_w = math.min(text_w, elem_geo.w) end
        end

        -- Calculate the hitbox
        local b_x1, b_y1, b_x2, b_y2 = get_hitbox_coords(elem_geo.x, elem_geo.y, elem_geo.an, hitbox_w, elem_geo.h)
        element.hitbox = {x1 = b_x1, y1 = b_y1, x2 = b_x2, y2 = b_y2}

        local style_ass = assdraw.ass_new()

        -- prepare static elements
        style_ass:append("{}") -- hack to troll new_event into inserting a \n
        style_ass:new_event()
        style_ass:pos(elem_geo.x, elem_geo.y)
        style_ass:an(elem_geo.an)
        style_ass:append(element.layout.style)

        element.style_ass = style_ass

        local static_ass = assdraw.ass_new()

        if element.type == "box" then
            --draw box
            static_ass:draw_start()
            if element.name == "seekbarbg" then
                local segments = get_seekbar_segments(elem_geo.w)
                local r = element.layout.box.radius
                for i, seg in ipairs(segments) do
                    draw_rect(static_ass, seg.x, 0, seg.x + seg.w, elem_geo.h, (i == 1), (i == #segments), r)
                end
            elseif element.layout.box.hexagon then
                static_ass:hexagon_cw(0, 0, elem_geo.w, elem_geo.h, element.layout.box.radius, 0)
            else
                static_ass:round_rect_cw(0, 0, elem_geo.w, elem_geo.h, element.layout.box.radius)
            end
            static_ass:draw_stop()

        elseif element.type == "slider" then
            --draw static slider parts
            local slider_lo = element.layout.slider
            -- calculate positions of min and max points
            element.slider.min.ele_pos = slider_lo.border
            element.slider.max.ele_pos = elem_geo.w - element.slider.min.ele_pos
            element.slider.min.glob_pos = element.hitbox.x1 + element.slider.min.ele_pos
            element.slider.max.glob_pos = element.hitbox.x1 + element.slider.max.ele_pos

            static_ass:draw_start()
            -- a hack which prepares the whole slider area to allow center placements such like an=5
            static_ass:rect_cw(0, 0, elem_geo.w, elem_geo.h)
            static_ass:rect_ccw(0, 0, elem_geo.w, elem_geo.h)
        end

        element.static_ass = static_ass

        -- if the element is supposed to be disabled,
        -- style it accordingly and kill the eventresponders
        if not element.enabled then
            element.layout.alpha[1] = 215
            if not (element.name == "sub_track" or element.name == "audio_track") then -- keep these to display tooltips
                element.eventresponder = nil
            end
        end

        -- gray out the element if it is toggled off
        if element.off then
            element.layout.alpha[1] = 100
        end
    end
end

--
-- Element Rendering
--

-- returns nil or a chapter element from the native property chapter-list
local function get_chapter(possec)
    local cl = state.chapter_list  -- sorted, get latest before possec, if any

    for n=#cl,1,-1 do
        if possec >= cl[n].time then
            return cl[n]
        end
    end
end

-- Draws seekbar ranges according to user_opts
local function draw_seekbar_ranges(element, elem_ass, override_alpha)
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local seek_ranges = element.slider.seek_ranges_f()
    if not seek_ranges then return end

    elem_ass:draw_stop()
    elem_ass:merge(element.style_ass)
    elem_ass:append(osc_styles.seekbar_bg)
    elem_ass:merge(element.static_ass)

    local radius = slider_lo.radius or 0
    local y1, y2 = slider_lo.gap, elem_geo.h - slider_lo.gap

    local function draw_range(p1, p2, r_left, r_right)
        if p2 > p1 then
            draw_rect(elem_ass, p1, y1, p2, y2, r_left, r_right, radius)
        end
    end

    if element.name ~= "seekbar" and element.name ~= "persistent_seekbar" then
        for _, range in pairs(seek_ranges) do
            local pstart = math.max(0, get_slider_ele_pos_for(element, range["start"]) - slider_lo.gap)
            local pend = math.min(elem_geo.w, get_slider_ele_pos_for(element, range["end"]) + slider_lo.gap)
            draw_range(pstart, pend, (pstart <= element.slider.min.ele_pos + 1), (pend >= element.slider.max.ele_pos - 1))
        end
        return
    end

    local segments = get_seekbar_segments(elem_geo.w)
    for _, range in pairs(seek_ranges) do
        local r_start, r_end = range["start"], range["end"]
        for i, seg in ipairs(segments) do
            if r_end > seg.start_p and r_start < seg.end_p then
                local draw_s, draw_e = math.max(r_start, seg.start_p), math.min(r_end, seg.end_p)
                local s_ratio = (seg.end_p == seg.start_p) and 0 or (draw_s - seg.start_p) / (seg.end_p - seg.start_p)
                local e_ratio = (seg.end_p == seg.start_p) and 1 or (draw_e - seg.start_p) / (seg.end_p - seg.start_p)

                draw_range(seg.x + s_ratio * seg.w, seg.x + e_ratio * seg.w, (draw_s <= seg.start_p and i == 1),
                    (draw_e >= seg.end_p and i == #segments)
                )
            end
        end
    end
end

-- Draw seekbar progress accurately across chapter segments
local function draw_seekbar_progress(element, elem_ass)
    local pos = element.slider.pos_f()
    if not pos then return end

    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local radius = slider_lo.radius or 0
    local y1, y2 = slider_lo.gap, elem_geo.h - slider_lo.gap

    elem_ass:draw_stop()
    elem_ass:merge(element.style_ass)
    elem_ass:append(osc_styles.seekbar_fg)
    elem_ass:merge(element.static_ass)

    if element.name ~= "seekbar" and element.name ~= "persistent_seekbar" then
        local xp = get_slider_ele_pos_for(element, pos)
        local r_right = (elem_geo.w - xp < radius)
        draw_rect(elem_ass, 0, y1, r_right and elem_geo.w or xp, y2, true, r_right, radius)
        return
    end

    local segments = get_seekbar_segments(elem_geo.w)
    for i, seg in ipairs(segments) do
        if pos > seg.start_p then
            local is_partial = (pos < seg.end_p)
            local draw_w = is_partial and ((pos - seg.start_p) / (seg.end_p - seg.start_p)) * seg.w or seg.w
            local r_right = (i == #segments and not is_partial)

            -- Snap final segment to full width if within one radius to prevent rounded corner clipping.
            if i == #segments and is_partial and (seg.w - draw_w < radius) then
                draw_w, r_right = seg.w, true
            end

            if draw_w > 0 then
                draw_rect(elem_ass, seg.x, y1, seg.x + draw_w, y2, (i == 1), r_right, radius)
            end
        end
    end
end

-- Draw semi-transparent hover indicator from current progress to mouse position
local function draw_seekbar_hover(element, elem_ass)
    if not mouse_hit(element) or element.state.mbtnleft then return end

    local pos = element.slider.pos_f()
    if not pos then return end

    local hover_pos = get_slider_value(element)
    if not hover_pos or hover_pos <= pos then return end

    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local radius = slider_lo.radius or 0
    local y1, y2 = slider_lo.gap, elem_geo.h - slider_lo.gap

    elem_ass:draw_stop()
    elem_ass:merge(element.style_ass)
    elem_ass:append(osc_styles.seekbar_bg)
    elem_ass:merge(element.static_ass)

    local segments = get_seekbar_segments(elem_geo.w)
    for i, seg in ipairs(segments) do
        if hover_pos > seg.start_p and pos < seg.end_p then
            local s = math.max(pos, seg.start_p)
            local e = math.min(hover_pos, seg.end_p)
            local s_ratio = (seg.end_p == seg.start_p) and 0 or (s - seg.start_p) / (seg.end_p - seg.start_p)
            local e_ratio = (seg.end_p == seg.start_p) and 1 or (e - seg.start_p) / (seg.end_p - seg.start_p)
            local x1 = seg.x + s_ratio * seg.w
            local x2 = seg.x + e_ratio * seg.w
            if x2 > x1 then
                draw_rect(elem_ass, x1, y1, x2, y2,
                    (s <= seg.start_p and i == 1),
                    (e >= seg.end_p and i == #segments), radius)
            end
        end
    end
end

local function render_elements(master_ass)
    local osd_w = osc_param.osd_w
    local r_w = osc_param.r_w
    local r_h = osc_param.r_h

    local function render_element(n)
        local element = elements[n]

        if element.is_wc then
            if not state.wc_visible then return end
        else
            if not state.osc_visible then return end
        end

        local style_ass = assdraw.ass_new()
        style_ass:merge(element.style_ass)
        ass_append_alpha(style_ass, element.layout.alpha, 0)

        if element.eventresponder and (state.active_element == n) then
            -- run render event functions
            if element.eventresponder.render ~= nil then
                element.eventresponder.render(element)
            end
            if mouse_hit(element) then
                if element.softrepeat and state.mouse_down_counter >= 15
                    and state.mouse_down_counter % 5 == 0 then
                    element.eventresponder[state.active_event_source.."_down"](element)
                end
                state.mouse_down_counter = state.mouse_down_counter + 1
            end
        end

        local elem_ass = assdraw.ass_new()

        -- Hover background box
        if element.type == "button" and element.hover_effect then
            local is_clickable = element.eventresponder and (
                element.eventresponder["mbtn_left_down"] ~= nil or
                element.eventresponder["mbtn_left_up"] ~= nil
            )
            if mouse_hit(element) and is_clickable and element.enabled then
                local hx1, hy1, hx2, hy2 = get_element_hitbox(element)
                local is_held = state.active_element == n and mouse_hit(element)

                elem_ass:append("{}")
                elem_ass:new_event()
                elem_ass:pos(0, 0)
                elem_ass:an(7)

                local bg_color = osc_styles.hover_bg
                local override_color = (is_held and element.held_color) or element.hover_color

                if override_color then
                    bg_color = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(override_color) .. "&}"
                end

                ass_append_alpha(elem_ass, {[1] = element.hover_alpha or 0xCC, [2] = 255, [3] = 255, [4] = 255}, element.layout.alpha[1])
                elem_ass:append(bg_color)

                local pad = element.hover_pad or (element.is_wc and 0 or 12)
                local hover_radius = element.hover_radius or (element.is_wc and 0 or 6)
                local shrink = (is_held and not element.is_wc) and 0.5 or 0

                elem_ass:draw_start()
                elem_ass:round_rect_cw(hx1 - pad + shrink, hy1 - pad + shrink, hx2 + pad - shrink, hy2 + pad - shrink, hover_radius)
                elem_ass:draw_stop()
            end
        end
        elem_ass:merge(style_ass)

        if element.type ~= "button" then
            elem_ass:merge(element.static_ass)
        end

        if element.type == "slider" then
            if element.name ~= "persistent_seekbar" then
                local slider_lo = element.layout.slider
                local elem_geo = element.layout.geometry

                draw_seekbar_ranges(element, elem_ass)
                draw_seekbar_hover(element, elem_ass)
                draw_seekbar_progress(element, elem_ass)

                elem_ass:draw_stop()

                -- add tooltip
                if element.slider.tooltip_f ~= nil and element.enabled then
                    local force_seek_tooltip = element.name == "seekbar"
                        and element.eventresponder["mbtn_left_down"]
                        and element.state.mbtnleft
                        and state.mouse_down_counter > 0
                        and state.playing_and_seeking

                    if mouse_hit(element) or force_seek_tooltip then
                        local slider_pos = get_slider_value(element)
                        local tooltiplabel = element.slider.tooltip_f(slider_pos)
                        local an = slider_lo.tooltip_an
                        local ty = element.hitbox.y1 - 8
                        if an ~= 2 then ty = ty + elem_geo.h / 2 end
                        local tx = get_virt_mouse_pos()

                        local pad_h, pad_v = 4, 4
                        local fs = FONT_SIZE_MD
                        local spacing = 5

                        local tooltip_width = estimate_text_width(tooltiplabel, slider_lo.tooltip_style)

                        local chapter_text = nil
                        local chapter_width = 0

                        if osd_w and r_w > 0 then
                            -- Only attempt to fetch and measure chapter logic if this is the seekbar
                            if element.name == "seekbar" then
                                local dur = mp.get_property_number("duration", 0)
                                if dur > 0 then
                                    local ch = get_chapter(slider_pos * dur / 100)
                                    if ch and ch.title and ch.title ~= "" then
                                        chapter_text = ch.title
                                        chapter_width = estimate_text_width(chapter_text, slider_lo.tooltip_style)
                                    end
                                end
                            end

                            -- Clamping layer ensures horizontal boundaries are strictly respected
                            if slider_lo.adjust_tooltip or (element.thumbnailable and not thumbfast.disabled) then
                                local max_text_width = math.max(tooltip_width, chapter_width)
                                local margin = 10 * r_w
                                local half_width = max_text_width / 2
                                local min_x = margin + half_width
                                local max_x = osc_param.playresx - margin - half_width
                                tx = math.min(max_x, math.max(min_x, tx))
                            end
                        end

                        if element.name == "seekbar" then
                            state.slider_pos = slider_pos
                        end

                        local chapter_tooltip_y = nil

                        if thumbfast.disabled then
                            chapter_tooltip_y = ty - fs - 2 * pad_v - spacing
                        elseif element.thumbnailable and not thumbfast.disabled then
                            if osd_w then
                                local hover_sec = 0
                                local hover_dur = mp.get_property_number("duration")
                                if hover_dur then hover_sec = hover_dur * slider_pos / 100 end
                                local thumb_pad = 2
                                local thumb_margin_x = 18 / r_w
                                local thumb_x = math.min(osd_w - thumbfast.width - thumb_margin_x, math.max(thumb_margin_x, tx / r_w - thumbfast.width / 2))
                                thumb_x = math.floor(thumb_x + 0.5)

                                -- symmetric spacing math
                                local thumb_border_bottom = ty - fs - pad_v - spacing
                                local thumb_image_bottom = thumb_border_bottom - (thumb_pad * r_h)
                                local thumb_image_top = thumb_image_bottom - (thumbfast.height * r_h)
                                local thumb_y = math.floor(thumb_image_top / r_h + 0.5)

                                if state.ani_type == nil then
                                    elem_ass:new_event()
                                    elem_ass:append("{\\rDefault}")
                                    elem_ass:pos(thumb_x * r_w, thumb_image_top)
                                    elem_ass:an(7)
                                    elem_ass:append(osc_styles.thumbnail)
                                    elem_ass:draw_start()
                                    elem_ass:round_rect_cw(-thumb_pad * r_w, -thumb_pad * r_h, (thumbfast.width + thumb_pad) * r_w, (thumbfast.height + thumb_pad) * r_h, 4)
                                    elem_ass:draw_stop()

                                    mp.commandv("script-message-to", "thumbfast", "thumb", hover_sec, thumb_x, thumb_y)
                                end

                                -- force tooltip to be centered on the thumb, even at far left/right of screen
                                tx = (thumb_x + thumbfast.width / 2) * r_w
                                an = 2

                                local thumb_border_top = thumb_image_top - (thumb_pad * r_h)
                                chapter_tooltip_y = thumb_border_top - spacing - pad_v
                            end
                        end

                        -- chapter tooltip
                        if chapter_text and osd_w and r_w > 0 and chapter_tooltip_y then
                            elem_ass:new_event()
                            elem_ass:pos(tx - chapter_width / 2 - pad_h, chapter_tooltip_y - fs - pad_v)
                            elem_ass:an(7)
                            elem_ass:append(osc_styles.tooltip_bg)
                            elem_ass:draw_start()
                            elem_ass:round_rect_cw(0, 0, chapter_width + 2 * pad_h, fs + 2 * pad_v, 4)
                            elem_ass:draw_stop()
                            elem_ass:new_event()
                            elem_ass:pos(tx, chapter_tooltip_y)
                            elem_ass:an(2)
                            elem_ass:append(slider_lo.tooltip_style)
                            ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                            elem_ass:append(chapter_text)
                        end

                        -- tooltip label background box
                        if element.name == "seekbar" then
                            elem_ass:new_event()
                            elem_ass:pos(tx - tooltip_width / 2 - pad_h, ty - fs - pad_v)
                            elem_ass:an(7)
                            elem_ass:append(osc_styles.tooltip_bg)
                            elem_ass:draw_start()
                            elem_ass:round_rect_cw(0, 0, tooltip_width + 2 * pad_h, fs + 2 * pad_v, 4)
                            elem_ass:draw_stop()
                        end

                        -- tooltip label
                        elem_ass:new_event()
                        elem_ass:pos(tx, ty)
                        elem_ass:an(an)
                        elem_ass:append(slider_lo.tooltip_style)
                        ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                        elem_ass:append(tooltiplabel)
                    elseif element.thumbnailable and thumbfast.available then
                        mp.commandv("script-message-to", "thumbfast", "clear")
                    end
                end
            end
        elseif element.type == "button" then
            local buttontext
            if type(element.content) == "function" then
                buttontext = element.content() -- function objects
            elseif element.content ~= nil then
                buttontext = element.content -- text objects
            end

            local maxchars = element.layout.button.maxchars
            if maxchars ~= nil and #buttontext > maxchars then
                local max_ratio = 1.25  -- up to 25% more chars while shrinking
                local limit = math.max(0, math.floor(maxchars * max_ratio) - 3)
                if #buttontext > limit then
                    while (#buttontext > limit) do
                        buttontext = buttontext:gsub(".[\128-\191]*$", "")
                    end
                    buttontext = buttontext .. "..."
                end
                buttontext = string.format("{\\fscx%f}", (maxchars/#buttontext)*100) .. buttontext
            end

            local is_held = state.active_element == n and mouse_hit(element)
            if is_held and not element.hover_effect then
                buttontext = "{\\alpha&H80&}" .. buttontext
            end

            elem_ass:append(buttontext)

            -- add tooltip for button elements
            if element.tooltip_f ~= nil then
                if mouse_hit(element) then
                    local tooltiplabel
                    if element.enabled then
                        if type(element.tooltip_f) == "function" then
                            tooltiplabel = element.tooltip_f()
                        else
                            tooltiplabel = element.tooltip_f
                        end
                    else
                        tooltiplabel = element.nothingavailable
                    end

                    local pad = element.hover_pad or (element.is_wc and 0 or 12)

                    local an = 2
                    local ty = element.hitbox.y1 - pad
                    local tx = (element.hitbox.x1 + element.hitbox.x2) / 2

                    if ty < osc_param.playresy / 2 then
                        ty = element.hitbox.y2 + pad
                        an = 8
                    end

                    if osd_w and r_w > 0 then
                        local tooltip_width = estimate_text_width(tooltiplabel, element.tooltip_style)
                        local margin = 10 * r_w
                        local half_width = tooltip_width / 2

                        local min_x = margin + half_width
                        local max_x = osc_param.playresx - margin - half_width

                        tx = math.min(max_x, math.max(min_x, tx))
                    end

                    elem_ass:new_event()
                    elem_ass:append("{\\rDefault}")
                    elem_ass:pos(tx, ty)
                    elem_ass:an(an)
                    elem_ass:append(element.tooltip_style)
                    elem_ass:append(tooltiplabel)
                end
            end
        end

        master_ass:merge(elem_ass)
    end

    for n = 1, #elements do render_element(n) end
end

local function render_persistent_progress(master_ass)
    local element = state.persistent_seekbar_element
    if not element then return end
    local style_ass = assdraw.ass_new()
    style_ass:merge(element.style_ass)
    if state.animation or not state.osc_visible then
        ass_append_alpha(style_ass, element.layout.alpha, 0, true)

        local elem_ass = assdraw.ass_new()
        elem_ass:merge(style_ass)
        elem_ass:merge(element.static_ass)

        if user_opts.persistent_buffer then
            draw_seekbar_ranges(element, elem_ass)
        end

        draw_seekbar_progress(element, elem_ass)

        elem_ass:draw_stop()
        master_ass:merge(elem_ass)
    end
end

--
-- Initialisation and Layout
--

local function new_element(name, type)
    elements[name] = {}
    elements[name].type = type
    elements[name].name = name

    -- add default stuff
    elements[name].eventresponder = {}
    elements[name].visible = true
    elements[name].enabled = true
    elements[name].softrepeat = false
    elements[name].hover_effect = false
    elements[name].state = {}
    elements[name].is_wc = false

    if type == "slider" then
        elements[name].slider = {min = {value = 0}, max = {value = 100}}
        elements[name].thumbnailable = false
    end

    return elements[name]
end

local function add_layout(name)
    if elements[name] ~= nil then
        -- new layout
        elements[name].layout = {}

        -- set layout defaults
        elements[name].layout.layer = 50
        elements[name].layout.alpha = {[1] = 0, [2] = 255, [3] = 255, [4] = 255}

        if elements[name].type == "button" then
            elements[name].layout.button = {
                maxchars = nil,
            }
        elseif elements[name].type == "slider" then
            -- slider defaults
            elements[name].layout.slider = {
                border = 1,
                gap = 1,
                radius = 0,
                adjust_tooltip = true,
                tooltip_style = "",
                tooltip_an = 2,
                alpha = {[1] = 0, [2] = 255, [3] = 88, [4] = 255},
            }
        elseif elements[name].type == "box" then
            elements[name].layout.box = {radius = 0, hexagon = false}
        end

        return elements[name].layout
    else
        msg.error("Can't add_layout to element '"..name.."', doesn't exist.")
    end
end

local function window_titlebar()
    local geo = {
        x = 0,
        y = 30,
        an = 1,
        w = osc_param.playresx,
        h = 30,
    }

    local controls_w = window_control_box_width
    local controls_x = geo.w - controls_w

    local title_x = geo.x + 15
    local title_w = controls_x - title_x

    local button_y = geo.y - (geo.h / 2)
    local layout

    -- Minimize: 🗕
    layout = add_layout("minimize")
    layout.geometry = { x = controls_x + 25, y = button_y, an = 5, w = 50, h = geo.h }
    layout.style = osc_styles.window_control

    -- Maximize: 🗖 / 🗗
    layout = add_layout("maximize")
    layout.geometry = { x = controls_x + 75, y = button_y, an = 5, w = 50, h = geo.h }
    layout.style = osc_styles.window_control

    -- Close: 🗙
    layout = add_layout("close")
    layout.geometry = { x = controls_x + 125, y = button_y, an = 5, w = 50, h = geo.h }
    layout.style = osc_styles.window_control

    add_area("window-controls", get_hitbox_coords(controls_x, geo.y, geo.an, controls_w, geo.h))

    -- Window title (also shown on progress bar)
    if user_opts.window_title then
        layout = add_layout("window_title")
        layout.geometry = { x = title_x, y = button_y + 14, an = 1, w = title_w, h = geo.h }
        layout.style = string.format("%s{\\clip(%f,%f,%f,%f)}",
            osc_styles.window_title, 0, 0, controls_x, geo.y + geo.h)
    end
end

--
-- hayase-osc Layout
--
-- Default layout
local function layout_default()
    local chapter_index = (state.chapter or -1) >= 0
    local osc_height_offset =
        ((user_opts.title_mbtn_left_command == "" and user_opts.title_mbtn_right_command == "") and 25 or 0) +
        (((user_opts.chapter_title_mbtn_left_command == "" and user_opts.chapter_title_mbtn_right_command == "") or not chapter_index) and 10 or 0)

    local osc_geo = {
        w = osc_param.playresx,
        h = 145 - osc_height_offset
    }

    -- update bottom margin
    osc_param.video_margins.b = math.max(145, 120) / osc_param.playresy

    -- origin of the controllers, left/bottom corner
    local pos_x = 0
    local pos_y = osc_param.playresy

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area("input", get_hitbox_coords(pos_x, pos_y, 1, osc_geo.w, osc_geo.h))

    -- area for show/hide
    add_area("showhide", 0, 0, osc_param.playresx, osc_param.playresy)

    -- fetch values
    local osc_w= osc_geo.w

    -- Controller Background
    local lo, geo

    new_element("bottombar_bg", "box")
    lo = add_layout("bottombar_bg")
    lo.geometry = {x = pos_x, y = pos_y, an = 7, w = osc_w, h = 1}
    lo.style = osc_styles.bottombar_bg
    lo.layer = 10
    lo.alpha[3] = 50

    -- Window bar background
    if window_controls_enabled() then
        new_element("window_bar_alpha_bg", "box")
        lo = add_layout("window_bar_alpha_bg")
        lo.geometry = {x = pos_x, y = -100, an = 7, w = osc_w, h = -1}
        lo.style = osc_styles.titlebar_bg
        lo.layer = 10
        lo.alpha[3] = 0
    end

    -- Alignment
    local ref_x = osc_w / 2
    local ref_y = pos_y

    -- Seekbar
    new_element("seekbarbg", "box")
    lo = add_layout("seekbarbg")
    local seekbar_bg_h = 4
    lo.geometry = {x = ref_x, y = ref_y - 82, an = 5, w = osc_geo.w - 45, h = seekbar_bg_h}
    lo.layer = 13
    lo.style = osc_styles.seekbar_bg
    lo.box.radius = 2
    lo.alpha[1] = 152
    lo.alpha[3] = 128

    lo = add_layout("seekbar")
    local seekbar_h = 18
    lo.geometry = {x = ref_x, y = ref_y - 82, an = 5, w = osc_geo.w - 45, h = seekbar_h}
    lo.layer = 51
    lo.style = osc_styles.seekbar_fg
    lo.slider.gap = (seekbar_h - seekbar_bg_h) / 2.0
    lo.slider.radius = 2
    lo.slider.tooltip_style = osc_styles.tooltip
    lo.slider.tooltip_an = 2

    if user_opts.persistent_progress or state.persistent_progress_toggle then
        lo = add_layout("persistent_seekbar")
        lo.geometry = {x = ref_x, y = ref_y, an = 5, w = osc_geo.w, h = 18}
        lo.style = osc_styles.seekbar_fg
        lo.slider.gap = (seekbar_h - seekbar_bg_h) / 2.0
        lo.slider.tooltip_an = 0
    end

    -- Time codes width calculation
    local dur = mp.get_property_number("duration", 0)
    local playback_time = mp.get_property_number("playback-time", 0)
    local show_hours = (state.tc_left_rem and dur or playback_time) >= 3600
    local show_durhours = dur >= 3600
    local time_codes_width = 90 + (state.tc_ms and 60 or 0) + (state.tc_left_rem and 15 or 0) +
        (show_hours and 20 or 0) + (show_durhours and 20 or 0)

    -- OSC title
    local title_w = (chapter_index and (osc_geo.w - 50) or (osc_geo.w - 50 - time_codes_width))
    if title_w < 0 then title_w = 0 end
    geo = {x = 25, y = ref_y - (chapter_index and 122 or 100), an = 1, w = title_w, h = FONT_SIZE_LG}
    lo = add_layout("title")
    lo.geometry = geo
    lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}", osc_styles.title, geo.x, geo.y - geo.h, geo.x + geo.w, geo.y + geo.h)
    lo.alpha[3] = 0

    -- Chapter title (above seekbar)
    local chapter_geo = {x = 25, y = ref_y - 100, an = 1, w = osc_geo.w / 2, h = FONT_SIZE_MD}
    lo = add_layout("chapter_title")
    lo.geometry = chapter_geo
    lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}", osc_styles.chapter_title, chapter_geo.x, chapter_geo.y - chapter_geo.h, chapter_geo.x + chapter_geo.w, chapter_geo.y + chapter_geo.h)

    -- Time codes
    lo = add_layout("time_codes")
    lo.geometry = {x = osc_geo.w - 25, y = ref_y - 108, an = 6, w = time_codes_width, h = FONT_SIZE_MD}
    lo.style = osc_styles.time

    -- Left side buttons
    local start_x = 50

    lo = add_layout("play_pause")
    lo.geometry = {x = start_x, y = ref_y - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    start_x = start_x + 55

    if elements.playlist_prev.visible then
        lo = add_layout("playlist_prev")
        lo.geometry = {x = start_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 55
    end

    if elements.playlist_next.visible then
        lo = add_layout("playlist_next")
        lo.geometry = {x = start_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 55
    end

    if state.audio_track_count > 0 then
        lo = add_layout("vol_ctrl")
        lo.geometry = {x = start_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 28

        new_element("volumebarbg", "box")
        elements.volumebar.visible = osc_geo.w >= 750
        elements.volumebarbg.visible = elements.volumebar.visible
        if elements.volumebar.visible then
            lo = add_layout("volumebarbg")
            lo.geometry = {x = start_x, y = ref_y - 38, an = 4, w = 95, h = 2}
            lo.layer = 13
            lo.alpha[1] = 128
            lo.style = osc_styles.volumebar_bg
            lo.box.radius = 1

            lo = add_layout("volumebar")
            lo.geometry = {x = start_x, y = ref_y - 38, an = 4, w = 95, h = 8}
            lo.style = osc_styles.volumebar_fg
            lo.slider.gap = 3
            lo.slider.radius = 1
            lo.slider.tooltip_style = osc_styles.tooltip
            lo.slider.tooltip_an = 2
            start_x = start_x + 75
        end
    end

    -- Right side buttons
    local end_x = osc_geo.w - 50

    lo = add_layout("fullscreen")
    lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    end_x = end_x - 55

    elements.tog_ontop.visible = osc_geo.w >= 500
    if elements.tog_ontop.visible then
        lo = add_layout("tog_ontop")
        lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    elements.audio_track.visible = user_opts.audio_button and state.audio_track_count > 1 and osc_geo.w >= 750
    if elements.audio_track.visible then
        lo = add_layout("audio_track")
        lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    elements.sub_track.visible = osc_geo.w >= 600
    if elements.sub_track.visible then
        lo = add_layout("sub_track")
        lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    lo = add_layout("menu")
    lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    end_x = end_x - 55

    if user_opts.speed_button then
        lo = add_layout("speed")
        lo.geometry = {x = end_x, y = ref_y - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end
end


local function osc_visible(visible)
    if state.osc_visible ~= visible then
        state.osc_visible = visible
        update_margins()
    end
    request_tick()
end

local function bind_mouse_buttons(element_name)
    for _, button in ipairs({"mbtn_left", "mbtn_right"}) do
        local command = user_opts[element_name .. "_" .. button .. "_command"]
        if command ~= nil and command ~= "" and command ~= "ignore" then
            elements[element_name].eventresponder[button .. "_up"] = function() mp.command(command) end
        end
    end
    local command = user_opts[element_name .. "_mbtn_mid_command"]
    if command ~= nil and command ~= "" and command ~= "ignore" then
        elements[element_name].eventresponder["mbtn_mid_up"] = function() mp.command(command) end
    end
    for _, button in ipairs({"wheel_up", "wheel_down"}) do
        local command = user_opts[element_name .. "_" .. button .. "_command"]
        if command ~= nil and command ~= "" and command ~= "ignore" then
            elements[element_name].eventresponder[button .. "_press"] = function() mp.command(command) end
        end
    end
end

local function build_cache_seek_ranges()
    if not user_opts.seekrange or not cache_enabled() then return nil end
    local duration = mp.get_property_number("duration")
    if not duration or duration <= 0 then return nil end
    local nranges = {}
    for _, range in ipairs(state.demuxer_cache_state["seekable-ranges"]) do
        nranges[#nranges + 1] = {
            ["start"] = 100 * range["start"] / duration,
            ["end"]   = 100 * range["end"]   / duration,
        }
    end
    return nranges
end

local function setup_canvas()
    local _, display_h, display_aspect = mp.get_osd_size()

    osc_param.playresy = display_h
    if display_aspect > 0 then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect
end

local function create_elements()
    state.active_element = nil
    elements = {}

    local pl_count = state.playlist_count
    local have_pl = state.playlist_pos + 1
    local pl_pos = mp.get_property_number("playlist-pos", 0) + 1

    local ne

    -- Window controls
    -- Close: 🗙
    ne = new_element("close", "button")
    ne.is_wc = true
    ne.hover_effect = true
    ne.hover_color = "#E81123"
    ne.held_color = "#E63A48"
    ne.hover_alpha = 0
    ne.content = icons.window.close
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("quit") end

    -- Minimize: 🗕
    ne = new_element("minimize", "button")
    ne.is_wc = true
    ne.hover_effect = true
    ne.hover_color = "#FFFFFF"
    ne.held_color = "#D9D9D9"
    ne.content = icons.window.minimize
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("cycle", "window-minimized") end

    -- Maximize: 🗖 /🗗
    ne = new_element("maximize", "button")
    ne.is_wc = true
    ne.hover_effect = true
    ne.hover_color = "#FFFFFF"
    ne.held_color = "#D9D9D9"
    ne.content = (state.window_maximized or state.fullscreen) and icons.window.unmaximize or icons.window.maximize
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("cycle", (state.fullscreen and "fullscreen" or "window-maximized")) end

    -- Window Title
    ne = new_element("window_title", "button")
    ne.is_wc = true
    ne.content = function ()
        local title = mp.command_native({"expand-text", mp.get_property("title")})
        title = title:gsub("\n", " ")
        return title ~= "" and mp.command_native({"escape-ass", title}) or "mpv"
    end

    -- OSC title
    ne = new_element("title", "button")
    ne.content = function ()
        local title = mp.command_native({"expand-text", user_opts.title})
        title = title:gsub("\n", " ")
        return title ~= "" and mp.command_native({"escape-ass", title}) or "mpv"
    end
    bind_mouse_buttons("title")

    -- Chapter title (above seekbar)
    ne = new_element("chapter_title", "button")
    ne.visible = (state.chapter or -1) >= 0
    ne.content = function()
        local chapter_index = (state.chapter or -1)
        if chapter_index < 0 then return "" end

        local chapters = state.chapter_list
        local chapter_data = chapters[chapter_index + 1]
        local chapter_title = chapter_data and chapter_data.title ~= "" and chapter_data.title
            or string.format("Chapter: %d/%d", chapter_index + 1, #chapters)

        chapter_title = mp.command_native({"escape-ass", chapter_title})

        return chapter_title
    end
    bind_mouse_buttons("chapter_title")

    -- menu
    ne = new_element("menu", "button")
    ne.hover_effect = true
    ne.content = icons.menu
    bind_mouse_buttons("menu")

    -- playlist buttons
    -- prev
    ne = new_element("playlist_prev", "button")
    ne.hover_effect = true
    ne.visible = pl_pos > 1
    ne.content = icons.previous
    bind_mouse_buttons("playlist_prev")

    --next
    ne = new_element("playlist_next", "button")
    ne.hover_effect = true
    ne.visible = have_pl and (pl_pos < pl_count)
    ne.content = icons.next
    bind_mouse_buttons("playlist_next")

    --play control buttons
    --play_pause
    ne = new_element("play_pause", "button")
    ne.hover_effect = true

    ne.content = function()
        if state.eof_reached then return icons.replay end
        return state.pause and icons.play or icons.pause
    end

    ne.eventresponder["mbtn_left_up"] = function()
        if state.eof_reached then
            mp.commandv("seek", 0, "absolute-percent")
            mp.commandv("set", "pause", "no")
        else
            mp.commandv("cycle", "pause")
        end
    end

    bind_mouse_buttons("play_pause")

    --audio_track
    ne = new_element("audio_track", "button")
    ne.hover_effect = true
    ne.enabled = state.audio_track_count > 0
    ne.off = state.audio_track_count == 0 or not mp.get_property_native("aid")
    ne.content = icons.audio
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltip_f = function ()
        local lang = mp.get_property_native("aid") and (mp.get_property("current-tracks/audio/lang") or "Unknown")
        or "Off"
        return ("Audio (" .. lang .. ")")
    end
    ne.nothingavailable = "No audio tracks"
    bind_mouse_buttons("audio_track")

    --sub_track
    ne = new_element("sub_track", "button")
    ne.hover_effect = true
    ne.enabled = state.sub_track_count > 0
    ne.off = state.sub_track_count == 0 or not mp.get_property_native("sid")
    ne.content = icons.subtitle
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltip_f = function ()
        local lang = mp.get_property_native("sid") and (mp.get_property("current-tracks/sub/lang") or "Unknown")
        or "Off"
        return ("Subtitles (" .. lang .. ")")
    end
    ne.nothingavailable = "No subtitles"
    bind_mouse_buttons("sub_track")

    -- vol_ctrl
    ne = new_element("vol_ctrl", "button")
    ne.hover_effect = true
    ne.enabled = state.audio_track_count > 0
    ne.off = state.audio_track_count == 0
    ne.content = function ()
        local volume = state.volume or 0
        if state.mute then return icons.mute end

        -- index 1 = silent, 2-4 = low to high volume
        local icon_index = math.min(4, math.ceil((volume / 100) * 3) + 1)
        return icons.volume[icon_index]
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltip_f = function ()
        local volume = state.volume or 0
        return string.format("%.0f", math.floor(volume + 0.5))
    end
    bind_mouse_buttons("vol_ctrl")

    --volumebar
    local volume_max_prop = mp.get_property_number("volume-max") or 0
    local volume_max = volume_max_prop > 0 and volume_max_prop or 100
    ne = new_element("volumebar", "slider")
    ne.enabled = state.audio_track_count > 0
    ne.slider = {min = {value = 0}, max = {value = volume_max}}
    ne.slider.seek_ranges_f = function() return nil end
    ne.slider.pos_f = function ()
        return state.volume
    end
    ne.slider.tooltip_f = function (pos) return (state.audio_track_count > 0) and math.floor(pos) or "" end
    ne.eventresponder["mouse_move"] = function (element)
        local pos = get_slider_value(element)
        local setvol = math.floor(pos)
        if element.state.lastseek == nil or element.state.lastseek ~= setvol then
                mp.commandv("osd-msg", "set", "volume", setvol)
                element.state.lastseek = setvol
        end
    end
    ne.eventresponder["mbtn_left_down"] = function (element)
        local pos = get_slider_value(element)
        mp.commandv("osd-msg", "set", "volume", math.floor(pos))
    end
    ne.eventresponder["reset"] = function (element) element.state.lastseek = nil end
    bind_mouse_buttons("volumebar")

    -- fullscreen
    ne = new_element("fullscreen", "button")
    ne.hover_effect = true
    ne.content = function () return state.fullscreen and icons.fullscreen_exit or icons.fullscreen end
    bind_mouse_buttons("fullscreen")

    --tog_ontop
    ne = new_element("tog_ontop", "button")
    ne.hover_effect = true
    ne.content = function () return not state.ontop and icons.ontop_on or icons.ontop_off end
    ne.eventresponder["mbtn_left_up"] = function ()
        local was_ontop = state.ontop
        mp.commandv("cycle", "ontop")
        if state.initial_border == "yes" and state.initial_title_bar == "yes" then
            if not was_ontop then
                mp.commandv("set", "title-bar", "no")
            else
                mp.commandv("set", "title-bar", "yes")
            end
        end
    end

    --speed
    ne = new_element("speed", "button")
    ne.content = function()
        return "x" .. string.format("%g", state.speed or 1)
    end

    local function adjust_speed(delta)
        local new_speed = (state.speed or 1) + delta
        mp.commandv("set", "speed", math.max(0.25, math.min(2, new_speed)))
    end

    ne.eventresponder["mbtn_left_up"] = function() adjust_speed(0.25) end
    ne.eventresponder["mbtn_right_up"] = function() adjust_speed(-0.25) end
    ne.eventresponder["mbtn_mid_up"] = function() mp.set_property("speed", 1) end
    ne.eventresponder["wheel_up_press"] = function() adjust_speed(0.25) end
    ne.eventresponder["wheel_down_press"] = function() adjust_speed(-0.25) end

    --seekbar
    ne = new_element("seekbar", "slider")
    ne.enabled = mp.get_property("percent-pos") ~= nil
    ne.thumbnailable = true
    ne.slider.pos_f = function ()
        if state.eof_reached then return 100 end
        return mp.get_property_number("percent-pos")
    end
    ne.slider.tooltip_f = function (pos)
        local duration = mp.get_property_number("duration")
        if duration and pos then return format_time(duration * (pos / 100)) end
        return ""
    end
    ne.slider.seek_ranges_f = build_cache_seek_ranges

    local function seekbar_pause(element)
        element.state.was_paused = state.pause
        if not state.pause then
            mp.commandv("cycle", "pause")
            state.playing_and_seeking = true
        end
    end

    local function seekbar_unpause(element)
        if state.playing_and_seeking then
            if not element.state.was_paused and not state.eof_reached then
                mp.commandv("cycle", "pause")
            end
            state.playing_and_seeking = false
        end
    end

    ne.eventresponder["mouse_move"] = function (element)
        if not element.state.mbtnleft then return end
        local seekto = get_slider_value(element)
        if element.state.lastseek == nil or element.state.lastseek ~= seekto then
            local flags = "absolute-percent"
            if not user_opts.seekbarkeyframes then
                flags = flags .. "+exact"
            end
            mp.commandv("seek", seekto, flags)
            element.state.lastseek = seekto
        end
    end
    ne.eventresponder["mbtn_left_down"] = function (element)
        element.state.mbtnleft = true
        seekbar_pause(element)
        mp.commandv("seek", get_slider_value(element), "absolute-percent+exact")
    end
    ne.eventresponder["shift+mbtn_left_down"] = function (element)
        element.state.mbtnleft = true
        seekbar_pause(element)
        mp.commandv("seek", get_slider_value(element), "absolute-percent")
    end
    ne.eventresponder["mbtn_left_up"] = function (element)
        element.state.mbtnleft = false
        seekbar_unpause(element)
    end
    ne.eventresponder["mbtn_right_down"] = function (element)
        local dur = mp.get_property_number("duration", 0)
        if not state.chapter_list or dur <= 0 then return end

        local target = (get_slider_value(element) / 100) * dur
        local best_idx, min_diff = 1, math.huge

        for i, c in ipairs(state.chapter_list) do
            local diff = math.abs(target - c.time)
            if diff >= min_diff then break end
            min_diff, best_idx = diff, i
        end

        mp.set_property("chapter", best_idx - 1)
    end
    ne.eventresponder["reset"] = function (element)
        element.state.lastseek = nil
        if element.state.mbtnleft then
            element.state.mbtnleft = false
            seekbar_unpause(element)
        end
    end

    --persistent seekbar
    ne = new_element("persistent_seekbar", "slider")
    ne.enabled = mp.get_property("percent-pos") ~= nil
    ne.slider.pos_f = function ()
        if state.eof_reached then return 100 end
        return mp.get_property_number("percent-pos")
    end
    ne.slider.tooltip_f = function() return "" end
    ne.slider.seek_ranges_f = function()
        if user_opts.persistent_buffer then return build_cache_seek_ranges() end
        return nil
    end

    -- Time codes display
    ne = new_element("time_codes", "button")
    ne.visible = mp.get_property_number("duration", 0) > 0
    ne.content = function()
        local playback_time = mp.get_property_number("playback-time", 0)
        local duration = mp.get_property_number("duration", 0)

        if duration <= 0 then return "--:--" end

        -- Trigger re-layout when crossing the 1-hour mark
        local hour_or_more = playback_time >= 3600
        if hour_or_more ~= state.playtime_hour_force_init then
            request_init()
            state.playtime_hour_force_init = hour_or_more
        end

        if state.tc_left_rem then
            local time_remaining = math.max(0, duration - playback_time)
            return "-" .. format_time(time_remaining) .. " / " .. format_time(duration)
        end

        return format_time(playback_time) .. " / " .. format_time(duration)
    end
    ne.eventresponder["mbtn_left_up"] = function()
        state.tc_left_rem = not state.tc_left_rem
    end
    ne.eventresponder["mbtn_right_up"] = function()
        state.tc_ms = not state.tc_ms
        request_init()
    end
end

local function osc_init()
    msg.debug("osc_init")

    text_width_cache = {}  -- invalidate cache on init (resolution may change)

    setup_canvas()
    create_elements()

    layout_default()

    if window_controls_enabled() then
        window_titlebar()
    end

    state.persistent_seekbar_element = elements["persistent_seekbar"]

    prepare_elements()
    update_margins()
end

local function show_osc()
    -- show when disabled can happen (e.g. mouse_move) due to async/delayed unbinding
    if not state.enabled then return end
    if state.idle_active then return end

    msg.trace("show_osc")
    --remember last time of invocation (mouse move)
    state.show_time = mp.get_time()

    if user_opts.fadeduration <= 0 then
        osc_visible(true)
    elseif user_opts.fadein then
        if not state.osc_visible then
            state.ani_type = "in"
            request_tick()
        end
    else
        osc_visible(true)
        state.ani_type = nil
    end
end

local function hide_osc()
    msg.trace("hide_osc")
    if thumbfast.width ~= 0 and thumbfast.height ~= 0 then
        mp.commandv("script-message-to", "thumbfast", "clear")
    end
    if not state.enabled then
        -- typically hide happens at render() from tick(), but now tick() is
        -- no-op and won't render again to remove the osc, so do that manually.
        state.osc_visible = false
        render_wipe(state.osd)
    elseif user_opts.fadeduration > 0 then
        if state.osc_visible then
            state.ani_type = "out"
            request_tick()
        end
    else
        osc_visible(false)
    end
end

local function mouse_leave()
    if get_hidetimeout() >= 0 and get_touchtimeout() <= 0 then
        hide_osc()
    end

    -- reset mouse position
    state.last_mouse_x, state.last_mouse_y = nil, nil
    state.mouse_in_window = false
end

local function handle_touch(_, touch_points)
    --remember last touch points
    if touch_points then
        state.touch_points = touch_points
        if #touch_points > 0 then
            --remember last time of invocation (touch event)
            state.touch_time = mp.get_time()
            state.last_touch_x = touch_points[1].x
            state.last_touch_y = touch_points[1].y
        end
    end
end

--
-- Event handling
--
local function reset_timeout()
    local now = mp.get_time()
    state.show_time = now
end

local function element_has_action(element, action)
    return element and element.eventresponder and
        element.eventresponder[action]
end

local function process_event(source, what)
    local action = string.format("%s%s", source,
        what and ("_" .. what) or "")

    if what == "down" or what == "press" then
        reset_timeout() -- clicking resets the hideosc timer

        for n = 1, #elements do
            if mouse_hit(elements[n]) and
                elements[n].eventresponder and
                (elements[n].eventresponder[source .. "_up"] or
                    elements[n].eventresponder[action]) then

                if what == "down" then
                    state.active_element = n
                    state.active_event_source = source
                end
                -- fire the down or press event if the element has one
                if element_has_action(elements[n], action) then
                    elements[n].eventresponder[action](elements[n])
                end
            end
        end
    elseif what == "up" then
        if elements[state.active_element] then
            local n = state.active_element

            if n == 0 then
                --click on background (does not work)
            elseif element_has_action(elements[n], action) and
                mouse_hit(elements[n]) then

                elements[n].eventresponder[action](elements[n])
            end

            --reset active element
            if element_has_action(elements[n], "reset") then
                elements[n].eventresponder["reset"](elements[n])
            end
        end
        state.active_element = nil
        state.mouse_down_counter = 0
    elseif source == "mouse_move" then
        state.mouse_in_window = true

        local mouse_x, mouse_y = get_virt_mouse_pos()
        -- init last pos on first mouse_move for comparison below to be valid
        if state.last_mouse_x == nil then
            state.last_mouse_x, state.last_mouse_y = mouse_x, mouse_y
        end

        if user_opts.minmousemove == 0 or
            math.abs(mouse_x - state.last_mouse_x) >= user_opts.minmousemove or
            math.abs(mouse_y - state.last_mouse_y) >= user_opts.minmousemove then
                state.last_mouse_x, state.last_mouse_y = mouse_x, mouse_y
                show_osc()
        end

        local n = state.active_element
        if element_has_action(elements[n], action) then
            elements[n].eventresponder[action](elements[n])
        end
    end

    -- ensure rendering after any (mouse) event - icons could change etc
    request_tick()
end

local function do_enable_keybindings()
    if state.enabled then
        if not state.showhide_enabled then
            mp.enable_key_bindings("showhide", "allow-vo-dragging+allow-hide-cursor")
            mp.enable_key_bindings("showhide_wc", "allow-vo-dragging+allow-hide-cursor")
        end
        state.showhide_enabled = true
    end
end

local function enable_osc(enable)
    state.enabled = enable
    if enable then
        do_enable_keybindings()
    else
        hide_osc() -- acts immediately when state.enabled == false
        if state.showhide_enabled then
            mp.disable_key_bindings("showhide")
            mp.disable_key_bindings("showhide_wc")
        end
        state.showhide_enabled = false
    end
end

local function render()
    msg.trace("rendering")
    local current_screen_size_x, current_screen_size_y = mp.get_osd_size()
    local mouse_x, mouse_y = get_virt_mouse_pos()
    local now = mp.get_time()

    -- check if display changed, if so request reinit
    if state.screen_size_x ~= current_screen_size_x
        or state.screen_size_y ~= current_screen_size_y then

        request_init_resize()

        state.screen_size_x = current_screen_size_x
        state.screen_size_y = current_screen_size_y
    end

    -- init management
    if state.active_element then
        -- mouse is held down on some element - keep ticking and ignore init_req
        -- till it's released, or else the mouse-up (click) will misbehave or
        -- get ignored. that's because osc_init() recreates the osc elements,
        -- but mouse handling depends on the elements staying unmodified
        -- between mouse-down and mouse-up (using the index active_element).
        request_tick()
    elseif state.init_req then
        osc_init()
        state.init_req = false

        -- store initial mouse position
        if (state.last_mouse_x == nil or state.last_mouse_y == nil)
            and not (mouse_x == nil or mouse_y == nil or mouse_x == -1 or mouse_y == -1) then

            state.last_mouse_x, state.last_mouse_y = mouse_x, mouse_y
        end
    end

    -- fade animation
    if state.ani_type ~= nil then
        if state.ani_start == nil then
            state.ani_start = now
        end

        if now < state.ani_start + (user_opts.fadeduration / 1000) then
            if state.ani_type == "in" then --fade in
                osc_visible(true)
                state.animation = scale_value(state.ani_start,
                    (state.ani_start + (user_opts.fadeduration / 1000)),
                    255, 0, now)
            elseif state.ani_type == "out" then --fade out
                state.animation = scale_value(state.ani_start,
                    (state.ani_start + (user_opts.fadeduration / 1000)),
                    0, 255, now)
            end
        else
            if state.ani_type == "out" then
                osc_visible(false)
            end
            kill_animation()
        end
    else
        kill_animation()
    end

    --mouse show/hide area
    for _, cords in pairs(osc_param.areas["showhide"]) do
        set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "showhide")
    end
    if osc_param.areas["showhide_wc"] then
        for _, cords in pairs(osc_param.areas["showhide_wc"]) do
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "showhide_wc")
        end
    else
        set_virt_mouse_area(0, 0, 0, 0, "showhide_wc")
    end
    do_enable_keybindings()

    --mouse input area
    local mouse_over_osc = false

    local function update_area(area_name, visible, enabled_key, enable_fn)
        if not osc_param.areas[area_name] then return end
        for _, cords in ipairs(osc_param.areas[area_name]) do
            if visible then
                set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, area_name)
            end
            if visible ~= state[enabled_key] then
                if visible then enable_fn() else mp.disable_key_bindings(area_name) end
                state[enabled_key] = visible
            end
            if mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2) then
                mouse_over_osc = true
            end
        end
    end

    update_area("input", state.osc_visible, "input_enabled",
        function() mp.enable_key_bindings("input") end)
    update_area("window-controls", state.wc_visible, "windowcontrols_buttons",
        function() mp.enable_key_bindings("window-controls") end)
    update_area("window-controls-title", state.wc_visible, "windowcontrols_title",
        function() mp.enable_key_bindings("window-controls-title", "allow-vo-dragging") end)

    -- autohide
    if state.show_time ~= nil and get_hidetimeout() >= 0 then
        if state.hide_timer then state.hide_timer.timeout = math.huge end
        local timeout = state.show_time + (get_hidetimeout() / 1000) - now
        if timeout <= 0 and get_touchtimeout() <= 0 then
            if state.active_element == nil and not mouse_over_osc then
                hide_osc()
            end
        else
            if not state.hide_timer then
                state.hide_timer = mp.add_timeout(0, tick)
            end
            -- Only update the timer if the new timeout is sooner,
            -- avoiding unnecessary re-arms
            if timeout < state.hide_timer.timeout then
                state.hide_timer.timeout = timeout
                state.hide_timer:kill()
                state.hide_timer:resume()
            end
        end
    end

    -- cache per-frame properties once for the entire render pass
    osc_param.osd_w = mp.get_property_number("osd-width")
    osc_param.r_w, osc_param.r_h = get_virt_scale_factor()

    -- actual rendering
    local ass = assdraw.ass_new()

    -- actual OSC
    if state.osc_visible or state.wc_visible then
        render_elements(ass)
    end

    if user_opts.persistent_progress or state.persistent_progress_toggle then
        render_persistent_progress(ass)
    end

    -- submit
    set_osd(state.osd, osc_param.playresy * osc_param.display_aspect,
            osc_param.playresy, ass.text, 1000)
end

local function render_logo()
    local _, _, display_aspect = mp.get_osd_size()
    if display_aspect == 0 then
        return
    end
    local display_h = 360
    local display_w = display_h * display_aspect
    -- logo is rendered at 2^(6-1) = 32 times resolution with size 1800x1800
    local icon_x, icon_y = (display_w - 1800 / 32) / 2, (display_h - 1800 / 32) / 2
    local line_prefix = ("{\\rDefault\\an7\\1a&H00&\\bord0\\shad0\\pos(%f,%f)}"):format(icon_x,
                                                                                        icon_y)

    local ass = assdraw.ass_new()
    -- mpv logo
    for _, line in ipairs(logo_lines) do
        ass:new_event()
        ass:append(line_prefix .. line)
    end

    -- Santa hat
    if is_december and not user_opts.greenandgrumpy then
        for _, line in ipairs(santa_hat_lines) do
            ass:new_event()
            ass:append(line_prefix .. line)
        end
    end

    if user_opts.idlescreen then
        ass:new_event()
        ass:pos(display_w / 2, icon_y + 65)
        ass:an(8)
        ass:append("Drop files or URLs to play here")
    end
    set_osd(state.logo_osd, display_w, display_h, ass.text, -1000)
end

-- called by mpv on every frame
tick = function()
    if state.margins_req == true then
        update_margins()
        state.margins_req = false
    end

    if not state.enabled then return end

    if state.idle_active then
        -- render idle message
        msg.trace("idle message")
        if user_opts.idlescreen then
            render_logo()
        end

        -- hide main OSC but keep window controls functional
        if state.osc_visible then
            osc_visible(false)
        end
        if window_controls_enabled() then
            state.wc_visible = true
            render()
        else
            render_wipe(state.osd)
            if state.showhide_enabled then
                mp.disable_key_bindings("showhide")
                mp.disable_key_bindings("showhide_wc")
                state.showhide_enabled = false
            end
        end
    else
        if state.no_video and state.file_loaded and user_opts.audioonlyscreen then
            render_logo()
        else
            render_wipe(state.logo_osd)
        end
        -- keep wc_visible in sync with osc_visible during normal playback
        state.wc_visible = state.osc_visible
        -- render the OSC
        render()
    end

    state.tick_last_time = mp.get_time()

    if state.ani_type ~= nil then
        -- allow fade-out animation to continue during idle
        local allow_idle = state.ani_type == "out"
        if (allow_idle or not state.idle_active) and
           (not state.ani_start or
            mp.get_time() < 1 + state.ani_start + user_opts.fadeduration/1000)
        then
            -- animating or starting, or still within 1s past the deadline
            request_tick()
        else
            kill_animation()
        end
    end
end

-- duration is observed for the sole purpose of updating chapter markers
-- positions. live streams with chapters are very rare, and the update is also
-- expensive (with request_init), so it's only observed when we have chapters.
local function on_duration() request_init() end

local duration_watched = false
local function update_duration_watch()
    local want_watch = #state.chapter_list > 0

    if want_watch ~= duration_watched then
        if want_watch then
            mp.observe_property("duration", "native", on_duration)
        else
            mp.unobserve_property(on_duration)
        end
        duration_watched = want_watch
    end
end

local function set_tick_delay(_, display_fps)
    -- may be nil if unavailable or 0 fps is reported
    if not display_fps or not user_opts.tick_delay_follow_display_fps then
        tick_delay = user_opts.tick_delay
        return
    end
    tick_delay = 1 / display_fps
end

mp.register_event("file-loaded", function()
    state.new_file_flag = true
    state.file_loaded = true
    state.no_video = mp.get_property_native("current-tracks/video") == nil
    request_tick()

    if user_opts.automatickeyframemode then
        user_opts.seekbarkeyframes = mp.get_property_number("duration", 0) > user_opts.automatickeyframelimit
    end
    if user_opts.osc_on_start then
        show_osc()
    end
end)
mp.register_event("start-file", request_init)
mp.observe_property("track-list", "native", update_tracklist)
observe_cached("playlist-count", request_init)
observe_cached("playlist-pos", request_init)
observe_cached("chapter-list", function ()
    table.sort(state.chapter_list, function(a, b) return a.time < b.time end)
    update_duration_watch()
    request_init()
end)
mp.register_event("seek", function()
    if state.new_file_flag then
        state.new_file_flag = false
        return
    end
    if user_opts.osc_on_seek then
        show_osc()
    end
end)
mp.observe_property("seeking", "native", function(_, seeking)
    reset_timeout()
end)
observe_cached("fullscreen", function ()
    state.margins_req = true
    request_init_resize()
end)
observe_cached("border", request_init_resize)
observe_cached("title-bar", request_init_resize)
observe_cached("window-maximized", request_init_resize)
observe_cached("idle-active", request_tick)

mp.add_hook("on_unload", 50, function()
    state.file_loaded = false
    request_tick()
end)

mp.observe_property("display-fps", "number", set_tick_delay)
observe_cached("demuxer-cache-state", request_tick)
mp.observe_property("vo-configured", "bool", request_tick)
mp.observe_property("playback-time", "number", request_tick)
mp.observe_property("osd-dimensions", "native", function()
    -- (we could use the value instead of re-querying it all the time, but then
    --  we might have to worry about property update ordering)
    request_init_resize()
end)
mp.observe_property("osd-scale-by-window", "native", request_init_resize)
mp.observe_property("touch-pos", "native", handle_touch)
observe_cached("volume", request_tick)
observe_cached("mute", request_tick)
observe_cached("eof-reached", request_tick)
observe_cached("ontop", request_tick)
observe_cached("speed", request_tick)
observe_cached("chapter", request_tick)
-- ensure compatibility with auto loop scripts
mp.observe_property("loop-file", "bool", function(_, val)
    state.file_loop = (val ~= false)
end)

-- mouse show/hide bindings
mp.set_key_bindings({
    {"mouse_move",              function() process_event("mouse_move", nil) end},
    {"mouse_leave",             mouse_leave},
}, "showhide", "force")
mp.set_key_bindings({
    {"mouse_move",              function() process_event("mouse_move", nil) end},
    {"mouse_leave",             mouse_leave},
}, "showhide_wc", "force")
do_enable_keybindings()

--mouse input bindings
mp.set_key_bindings({
    {"mbtn_left",           function() process_event("mbtn_left", "up") end,
                            function() process_event("mbtn_left", "down")  end},
    {"mbtn_mid",            function() process_event("mbtn_mid", "up") end,
                            function() process_event("mbtn_mid", "down")  end},
    {"mbtn_right",          function() process_event("mbtn_right", "up") end,
                            function() process_event("mbtn_right", "down")  end},
    {"shift+mbtn_right",    function(e) process_event("shift+mbtn_right", "up") end,
                            function(e) process_event("shift+mbtn_right", "down")  end},
    -- alias shift+mbtn_left to mbtn_mid for touchpads
    {"shift+mbtn_left",     function() process_event("mbtn_mid", "up") end,
                            function() process_event("mbtn_mid", "down")  end},
    {"wheel_up",            function() process_event("wheel_up", "press") end},
    {"wheel_down",          function() process_event("wheel_down", "press") end},
    {"mbtn_left_dbl",       "ignore"},
    {"shift+mbtn_left_dbl", "ignore"},
    {"mbtn_right_dbl",      "ignore"},
}, "input", "force")
mp.enable_key_bindings("input")

mp.set_key_bindings({
    {"mbtn_left",           function() process_event("mbtn_left", "up") end,
                            function() process_event("mbtn_left", "down")  end},
}, "window-controls", "force")
mp.enable_key_bindings("window-controls")

local function always_on(val)
    if state.enabled then
        if val then
            show_osc()
        else
            hide_osc()
        end
    end
end

-- mode can be auto/always/never/cycle
-- the modes only affect internal variables and not stored on its own.
local function visibility_mode(mode, no_osd)
    if mode == "cycle" then
        for i, allowed_mode in ipairs(state.visibility_modes) do
            if i == #state.visibility_modes then
                mode = state.visibility_modes[1]
                break
            elseif user_opts.visibility == allowed_mode then
                mode = state.visibility_modes[i + 1]
                break
            end
        end
    end

    if mode == "auto" then
        always_on(false)
        enable_osc(true)
    elseif mode == "always" then
        enable_osc(true)
        always_on(true)
    elseif mode == "never" then
        enable_osc(false)
    else
        msg.warn("Ignoring unknown visibility mode '" .. mode .. "'")
        return
    end

    user_opts.visibility = mode
    mp.set_property_native("user-data/osc/visibility", mode)

    if not no_osd and tonumber(mp.get_property("osd-level")) >= 1 then
        mp.osd_message("OSC visibility: " .. mode)
    end

    -- Reset the input state on a mode change. The input state will be
    -- recalculated on the next render cycle, except in 'never' mode where it
    -- will just stay disabled.
    mp.disable_key_bindings("input")
    mp.disable_key_bindings("window-controls")
    mp.disable_key_bindings("window-controls-title")
    state.input_enabled = false
    state.windowcontrols_buttons = false
    state.windowcontrols_title = false
    state.wc_visible = false

    update_margins()
    request_tick()
end

local function idlescreen_visibility(mode, no_osd)
    if mode == "cycle" then
        mode = user_opts.idlescreen and "no" or "yes"
    end

    user_opts.idlescreen = (mode == "yes")

    mp.set_property_native("user-data/osc/idlescreen", user_opts.idlescreen)

    if not no_osd and tonumber(mp.get_property("osd-level")) >= 1 then
        mp.osd_message("OSC logo visibility: " .. tostring(mode))
    end

    request_tick()
end

observe_cached("pause", function()
    request_tick()

    if user_opts.visibility ~= "never" then
        state.enabled = state.pause
        if state.pause then
            if user_opts.keeponpause then
                -- save mode if a temporary change is needed
                if not state.temp_visibility_mode and user_opts.visibility ~= "always" then
                    state.temp_visibility_mode = user_opts.visibility
                end
                -- force visibility to "always" while paused
                visibility_mode("always", true)
            end
        else
            -- restore mode if it was changed temporarily
            if state.temp_visibility_mode then
                visibility_mode(state.temp_visibility_mode, true)
                state.temp_visibility_mode = nil
            else
                -- respect "always" mode on unpause
                visibility_mode(user_opts.visibility, true)
            end
        end
    end
end)

mp.register_script_message("osc-visibility", visibility_mode)
mp.register_script_message("osc-show", show_osc)
mp.register_script_message("osc-hide", function()
    if user_opts.visibility == "auto" then
        hide_osc()
    end
end)
mp.add_key_binding(nil, "visibility", function() visibility_mode("cycle") end)
mp.add_key_binding(nil, "progress-toggle", function()
    user_opts.persistent_progress = not user_opts.persistent_progress
    state.persistent_progress_toggle = user_opts.persistent_progress
    request_init()
end)
mp.register_script_message("osc-idlescreen", idlescreen_visibility)
mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)

-- validate string type user options
local function validate_user_opts()
    if user_opts.window_top_bar ~= "auto" and
       user_opts.window_top_bar ~= "yes" and
       user_opts.window_top_bar ~= "no" then
          msg.warn("window_top_bar cannot be '" .. user_opts.window_top_bar .. "'. Ignoring.")
          user_opts.window_top_bar = "auto"
    end

    if user_opts.accent_color:find("^#%x%x%x%x%x%x$") == nil then
        msg.warn("'" .. user_opts.accent_color .. "' is not a valid color")
        user_opts.accent_color = "#FFFFFF"
    end

    for str in string.gmatch(user_opts.visibility_modes, "([^_]+)") do
        if str ~= "auto" and str ~= "always" and str ~= "never" then
            msg.warn("Ignoring unknown visibility mode '" .. str .."' in list")
        else
            table.insert(state.visibility_modes, str)
        end
    end
end

-- read options from config and command-line
opt.read_options(user_opts, "hayase-osc", function(changed)
    validate_user_opts()
    set_osc_styles()
    set_time_styles(changed.timecurrent, changed.timems)
    if changed.tick_delay or changed.tick_delay_follow_display_fps then
        set_tick_delay("display_fps", mp.get_property_number("display_fps"))
    end
    request_tick()
    visibility_mode(user_opts.visibility, true)
    update_duration_watch()
    request_init()
end)

validate_user_opts()
set_osc_styles()
set_time_styles(true, true)
set_tick_delay()
visibility_mode(user_opts.visibility, true)
update_duration_watch()

set_virt_mouse_area(0, 0, 0, 0, "input")
set_virt_mouse_area(0, 0, 0, 0, "window-controls")
set_virt_mouse_area(0, 0, 0, 0, "window-controls-title")
