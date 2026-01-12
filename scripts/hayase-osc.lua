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

-- Parameters
-- default user option values
-- do not touch, change them in hayase-osc.conf
local user_opts = {
    language = "en",                       -- set language
    showwindowed = true,                   -- show OSC when windowed
    showfullscreen = true,                 -- show OSC when fullscreen
    idlescreen = true,                     -- show mpv logo when idle
    osc_on_start = false,                  -- show OSC on start of every file
    osc_on_seek = false,                   -- show OSC when seeking
    keeponpause = true,                    -- disable OSC hide timeout when paused
    hidetimeout = 1000,                    -- time (in ms) before OSC hides if no mouse movement
    fadein = true,                         -- whether to enable fade-in effect
    fadeduration = 200,                    -- fade-out duration (in ms), set to 0 for no fade
    minmousemove = 0,                      -- minimum mouse movement (in pixels) required to show OSC

    scalewindowed = 1,                     -- osc scale factor when windowed
    scalefullscreen = 1,                   -- osc scale factor when fullscreen
    vidscale = "false",                    -- scale osc with the video

    title = "${media-title}",              -- title above seekbar format: "${media-title}" or "${filename}"

    timetotal = true,                      -- show total time instead of remaining time
    timems = false,                        -- show timecodes with milliseconds

    window_top_bar = "auto",               -- show OSC window top bar: "auto", "yes", or "no" (borderless/fullscreen)
    window_title = false,                  -- show window title in borderless/fullscreen mode
    window_controls = true,                -- show window controls (close, minimize, maximize) in borderless/fullscreen
    windowcontrols_title = "${media-title}", -- same as title but for windowcontrols

    raise_subtitles = true,                -- raise subtitles above the OSC when shown
    raise_subtitle_amount = 125,           -- amount by which subtitles are raised when the OSC is shown (in pixels)

    speed_button = false,                  -- show speed control button
    audio_button = false,                  -- show audio track button (only if more than 1 audio track exists)
    cache_info = false,                    -- show cached time information
    cache_info_speed = false,              -- show cache speed per second
    scrollcontrols = true,                 -- allow scrolling when hovering certain OSC elements
    loop_in_pause = true,                  -- enable looping by right-clicking pause

    hover_effect = "glow",                 -- active button hover effects: "glow", "color"; can use multiple separated by commas

    seek_handle_size = 0,                  -- size ratio of the progress bar handle (range: 0 ~ 1)
    seekrange = true,                      -- show seek range overlay
    seekrangealpha = 150,                  -- transparency of the seek range
    livemarkers = true,                    -- update chapter markers on the seekbar when duration changes
    seekbarkeyframes = false,              -- use keyframes when dragging the seekbar
    automatickeyframemode = true,          -- automatically set keyframes for the seekbar based on video length
    automatickeyframelimit = 600,          -- videos longer than this (in seconds) will have keyframes on the seekbar
    persistentprogress = false,            -- always show a small progress line at the bottom of the screen
    persistentprogressheight = 18,         -- height of the persistent progress bar
    persistentbuffer = false,              -- show buffer status on web videos in the persistent progress line

    font_size_lg = 24,                     -- font size for the title (above seekbar)
    font_size_md = 18,                     -- font size of the time codes, tootlips, and chapter title
    buttons_size = 24,                     -- icon size for the play/pause button

    background_color = "#000000",          -- accent color of the OSC and title bar
    title_color = "#FFFFFF",               -- color of the title (above seekbar)
    chapter_title_color = "#D9D9D9",       -- color of the chapter title (above seekbar)
    buttons_color = "#FFFFFF",             -- color of the play/pause button
    seekbarfg_color = "#1D96F5",           -- color of the seekbar progress and handle
    seekbarbg_color = "#D9D9D9",           -- color of the remaining seekbar
    volumebar_match_seek_color = false,      -- match volume bar color with seekbar color
    held_element_color = "#999999",        -- color of the element when held down (pressed)
    hover_effect_color = "#E9F2FA",        -- color of a hovered button when hover_effect includes "color"
    thumbnail_border_color = "#000000",    -- color of the border for thumbnails (with thumbfast)
    thumbnail_border_outline = "#FFFFFF",  -- color of the border outline for thumbnails

    visibility = "auto",                   -- only used at init to set visibility_mode(...)
    visibility_modes = "never_auto_always",-- visibility modes to cycle through
    greenandgrumpy = false,                -- disable Santa hat in December
    tick_delay = 1 / 60,                   -- minimum interval between OSC redraws (in seconds)
    tick_delay_follow_display_fps = false, -- use display FPS as the minimum redraw interval

    -- Mouse commands
    title_mbtn_left_command = "script-binding stats/display-page-5",
    title_mbtn_mid_command = "show-text ${path}",
    title_mbtn_right_command = "script-binding select/select-watch-history; script-message-to hayase-osc osc-hide",

    chapter_title_mbtn_left_command = "script-binding select/select-chapter; script-message-to hayase-osc osc-hide",
    chapter_title_mbtn_mid_command = "",
    chapter_title_mbtn_right_command = "show-text ${chapter-list} 3000",

    play_pause_mbtn_left_command = "cycle pause",
    play_pause_mbtn_mid_command = "cycle-values loop-playlist inf no",
    play_pause_mbtn_right_command = "cycle-values loop-file inf no",

    playlist_prev_mbtn_left_command = "playlist-prev",
    playlist_prev_mbtn_mid_command = "show-text ${playlist} 3000",
    playlist_prev_mbtn_right_command = "script-binding select/select-playlist; script-message-to hayase-osc osc-hide",

    playlist_next_mbtn_left_command = "playlist-next",
    playlist_next_mbtn_mid_command = "show-text ${playlist} 3000",
    playlist_next_mbtn_right_command = "script-binding select/select-playlist; script-message-to hayase-osc osc-hide",

    vol_ctrl_mbtn_left_command = "no-osd cycle mute",
    vol_ctrl_mbtn_mid_command = "",
    vol_ctrl_mbtn_right_command = "script-binding select/select-audio-device; script-message-to hayase-osc osc-hide",
    vol_ctrl_wheel_down_command = "no-osd add volume -5",
    vol_ctrl_wheel_up_command = "no-osd add volume 5",

    menu_mbtn_left_command = "script-binding select/menu; script-message-to osc osc-hide",
    menu_mbtn_mid_command = "",
    menu_mbtn_right_command = "",

    audio_track_mbtn_left_command = "script-binding select/select-aid; script-message-to hayase-osc osc-hide",
    audio_track_mbtn_mid_command = "cycle audio down",
    audio_track_mbtn_right_command = "cycle audio",
    audio_track_wheel_down_command = "cycle audio",
    audio_track_wheel_up_command = "cycle audio down",

    sub_track_mbtn_left_command = "script-binding select/select-sid; script-message-to hayase-osc osc-hide",
    sub_track_mbtn_mid_command = "cycle sub down",
    sub_track_mbtn_right_command = "cycle sub",
    sub_track_wheel_down_command = "cycle sub",
    sub_track_wheel_up_command = "cycle sub down",

    fullscreen_mbtn_left_command = "cycle fullscreen",
    fullscreen_mbtn_mid_command = "",
    fullscreen_mbtn_right_command = "cycle window-maximized",
}

mp.observe_property("osc", "bool", function(name, value) if value == true then mp.set_property("osc", "no") end end)

local osc_param = {                  -- calculated by osc_init()
    playresy = 0,                    -- canvas size Y
    playresx = 0,                    -- canvas size X
    display_aspect = 1,
    unscaled_y = 0,
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

--- localization
local language = {
    ["en"] = {
        idle = "Drop files or URLs here to play",
        na = "Not available",
        video = "Video",
        audio = "Audio",
        subtitle = "Subtitle",
        no_subs = "No subtitles available",
        no_audio = "No audio tracks available",
        playlist = "Playlist",
        no_playlist = "Playlist is empty",
        chapter = "Chapter",
        ontop = "Pin Window",
        ontop_disable = "Unpin Window",
        loop_enable = "Loop",
        loop_disable = "Disable Loop",
        speed_control = "Speed",
        cache = "Cache",
        buffering = "Buffering",
        menu = "Menu",
        replay = "Replay",
        play = "Play",
        pause = "Pause",
        fullscreen_enter = "Fullscreen",
        fullscreen_exit = "Exit fullscreen",
        playlist_next = "Next",
        playlist_prev = "Previous",
    },
}

-- locale JSON file handler
function get_locale_from_json(path)
    local expand_path = mp.command_native({'expand-path', path})

    local file_info = utils.file_info(expand_path)
    if not file_info or not file_info.is_file then
        return nil
    end

    local json_file = io.open(expand_path, 'r')
    if not json_file then
        return nil
    end

    local json = json_file:read('*all')
    json_file:close()

    local json_table, parse_error = utils.parse_json(json)
    if not json_table then
        mp.msg.error("JSON parse error:" .. parse_error)
    end
    return json_table
end

-- load external locales if available
local locale_path = "~~/script-opts/hayase-osc-locale.json"
local external = get_locale_from_json(locale_path)

if external then
    for lang, strings in pairs(external) do
        if type(strings) == "table" then
            language[lang] = strings

            -- fill in missing locales with English defaults
            for key, value in pairs(language["en"]) do
                if strings[key] == nil then
                    strings[key] = value or ""  -- fallback to empty string if key is missing
                end

                -- debug log to verify all keys are populated
                if strings[key] == nil then
                    mp.msg.warn("Locale key '" .. key .. "' is nil in language: " .. lang)
                end
            end
        else
            mp.msg.warn("Locale data for language " .. lang .. " is not in the correct format.")
        end
    end
end

local locale
local function set_osc_locale()
    locale = language[user_opts.language] or language["en"]
    local idle_ass_tags = "{\\fs24\\1c&H0&\\1c&HFFFFFF&}"
    locale.idle = idle_ass_tags .. locale.idle
end

local function contains(list, item)
    local t = type(list) == "table" and list or {}
    if type(list) ~= "table" then
        for str in string.gmatch(list, '([^,]+)') do
            t[#t + 1] = str:match("^%s*(.-)%s*$") -- trim spaces
        end
    end
    for _, v in ipairs(t) do
        if v == item then
            return true
        end
    end
    return false
end

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local tick_delay = 1 / 60
local audio_track_count = 0
local sub_track_count = 0
local window_control_box_width = 150
local layouts = {}
local is_december = os.date("*t").month == 12

local function osc_color_convert(color)
    return color:sub(6,7) .. color:sub(4,5) ..  color:sub(2,3)
end

local osc_styles

local function set_osc_styles()
    local buttons_size = user_opts.buttons_size or 24
    osc_styles = {
        osc_fade_bg = "{\\blur80\\bord120\\1c&H0&\\3c&H" .. osc_color_convert(user_opts.background_color) .. "&}",
        window_fade_bg = "{\\blur80\\bord100\\1c&H0&\\3c&H" .. osc_color_convert(user_opts.background_color) .. "&}",
        window_control = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.buttons_color) .. "&\\3c&H0&\\fs10\\fn" .. icon_font .. "}",
        window_title = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.title_color) .. "&\\3c&H0&\\fs22\\q2}",
        title = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.title_color) .. "&\\3c&H0&\\fs".. user_opts.font_size_lg .."\\q2}",
        chapter_title = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.chapter_title_color) .. "&\\3c&H0&\\fs" .. user_opts.font_size_md .. "}",
        seekbar_bg = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.seekbarbg_color) .. "&}",
        seekbar_fg = "{\\blur1\\bord1\\1c&H" .. osc_color_convert(user_opts.seekbarfg_color) .. "&}",
        thumbnail = "{\\blur0\\bord1\\1c&H" .. osc_color_convert(user_opts.thumbnail_border_color) .. "&\\3c&H" .. osc_color_convert(user_opts.thumbnail_border_outline) .. "&\\3a&HE6&}",
        time = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.title_color) .. "&\\3c&H0&\\fs" .. user_opts.font_size_md .. "}",
        tooltip = "{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H0&\\fs" .. user_opts.font_size_md .. "}",
        volumebar_bg = "{\\blur0\\bord0\\1c&H999999&}",
        volumebar_fg = "{\\blur1\\bord1\\1c&H" .. osc_color_convert(user_opts.buttons_color) .. "&}",
        buttons = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.buttons_color) .. "&\\3c&HFFFFFF&\\fs" .. buttons_size .. "\\fn" .. icon_font .. "}",
        element_down = "{\\1c&H" .. osc_color_convert(user_opts.held_element_color) .. "&}",
        element_hover = "{" .. (contains(user_opts.hover_effect, "color") and "\\1c&H" .. osc_color_convert(user_opts.hover_effect_color) .. "&" or "") .."\\2c&HFFFFFF&" .. "}",
    }
end

-- internal states, do not touch
local state = {
    showtime = nil,                         -- time of last invocation (last mouse move)
    touchtime = nil,                        -- time of last invocation (last touch event)
    touchpoints = {},                       -- current touch points
    osc_visible = false,
    anistart = nil,                         -- time when the animation started
    anitype = nil,                          -- current type of animation
    animation = nil,                        -- current animation alpha
    mouse_down_counter = 0,                 -- used for softrepeat
    active_element = nil,                   -- nil = none, 0 = background, 1+ = see elements[]
    active_event_source = nil,              -- the "button" that issued the current event
    tc_right_rem = not user_opts.timetotal, -- if the right timecode should display total or remaining time
    tc_ms = user_opts.timems,               -- Should the timecodes display their time with milliseconds
    screen_sizeX = nil, screen_sizeY = nil, -- last screen-resolution, to detect resolution changes to issue reINITs
    initREQ = false,                        -- is a re-init request pending?
    marginsREQ = false,                     -- is a margins update pending?
    last_mouseX = nil, last_mouseY = nil,   -- last mouse position, to detect significant mouse movement
    last_touchX = -1, last_touchY = -1,     -- last touch position
    mouse_in_window = false,
    fullscreen = false,
    tick_timer = nil,
    tick_last_time = 0,                     -- when the last tick() was run
    hide_timer = nil,
    cache_state = nil,
    idle = false,
    enabled = true,
    input_enabled = true,
    showhide_enabled = false,
    windowcontrols_buttons = false,
    windowcontrols_title = false,
    dmx_cache = 0,
    border = true,
    maximized = false,
    osd = mp.create_osd_overlay("ass-events"),
    buffering = false,
    new_file_flag = false,                  -- flag to detect new file starts
    temp_visibility_mode = nil,             -- store temporary visibility mode state
    chapter_list = {},                      -- sorted by time
    visibility_modes = {},                  -- visibility_modes to cycle through
    mute = false,
    looping = false,
    sliderpos = 0,
    touchingprogressbar = false,            -- if the mouse is touching the progress bar
    initialborder = mp.get_property("border"),
    playtime_hour_force_init = false,       -- used to force request_init() once
    playtime_nohour_force_init = false,     -- used to force request_init() once
    playing_and_seeking = false,
    persistent_progress_toggle = user_opts.persistentprogress,
    user_subpos = mp.get_property_number("sub-pos") or 100,
    osc_adjusted_subpos = nil
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

local function format_time_custom(seconds, with_ms)
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

    if with_ms then
        local ms = math.floor((seconds % 1) * 1000)
        time_str = time_str .. string.format(".%03d", ms)
    end

    return time_str
end

local function kill_animation()
    state.anistart = nil
    state.animation = nil
    state.anitype =  nil
end

local function set_osd(res_x, res_y, text, z)
    if state.osd.res_x == res_x and
       state.osd.res_y == res_y and
       state.osd.data == text then
        return
    end
    state.osd.res_x = res_x
    state.osd.res_y = res_y
    state.osd.data = text
    state.osd.z = z
    state.osd:update()
end

local function set_time_styles(timetotal_changed, timems_changed)
    if timetotal_changed then
        state.tc_right_rem = not user_opts.timetotal
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
    if state.touchtime == nil then
        return false
    end
    return state.touchtime + 1 >= mp.get_time()
end

-- return mouse position in virtual ASS coordinates (playresx/y)
local function get_virt_mouse_pos()
    if recently_touched() then
        local sx, sy = get_virt_scale_factor()
        return state.last_touchX * sx, state.last_touchY * sy
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

local function get_hitbox_coords_geo(geometry)
    return get_hitbox_coords(geometry.x, geometry.y, geometry.an,
        geometry.w, geometry.h)
end

local function get_element_hitbox(element)
    return element.hitbox.x1, element.hitbox.y1,
        element.hitbox.x2, element.hitbox.y2
end

local function mouse_hit_coords(bX1, bY1, bX2, bY2)
    local mX, mY = get_virt_mouse_pos()
    return (mX >= bX1 and mX <= bX2 and mY >= bY1 and mY <= bY2)
end

local function mouse_hit(element)
    return mouse_hit_coords(get_element_hitbox(element))
end

local function limit_range(min, max, val)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

-- translate value into element coordinates
local function get_slider_ele_pos_for(element, val)
    local ele_pos = scale_value(
        element.slider.min.value, element.slider.max.value,
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        val)

    return limit_range(
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        ele_pos)
end

-- translates global (mouse) coordinates to value
local function get_slider_value_at(element, glob_pos)
    if element then
        local val = scale_value(
            element.slider.min.glob_pos, element.slider.max.glob_pos,
            element.slider.min.value, element.slider.max.value,
            glob_pos)

        return limit_range(
            element.slider.min.value, element.slider.max.value,
            val)
    end
    -- fall back incase of loading errors
    return 0
end

-- get value at current mouse position
local function get_slider_value(element)
    return get_slider_value_at(element, get_virt_mouse_pos())
end

-- multiplies two alpha values, formular can probably be improved
local function mult_alpha(alphaA, alphaB)
    return 255 - (((1-(alphaA/255)) * (1-(alphaB/255))) * 255)
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

    for ai, av in pairs(alpha) do
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

local function ass_draw_cir_cw(ass, x, y, r)
    ass:round_rect_cw(x-r, y-r, x+r, y+r, r)
end

local function ass_draw_rr_h_cw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_cw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_cw(x0, y0, x1, y1, r1, r2)
    end
end

local function get_hidetimeout()
    if user_opts.visibility == "always" then
        return -1 -- disable autohide
    end
    return user_opts.hidetimeout
end

local function get_touchtimeout()
    if state.touchtime == nil then
        return 0
    end
    return state.touchtime + (get_hidetimeout() / 1000) - mp.get_time()
end

local function cache_enabled()
    return state.cache_state and #state.cache_state["seekable-ranges"] > 0
end

local function update_margins()
    local margins = osc_param.video_margins

    -- Don't use margins if it's visible only temporarily.
    if not state.osc_visible or get_hidetimeout() >= 0 or
       (state.fullscreen and not user_opts.showfullscreen) or
       (not state.fullscreen and not user_opts.showwindowed)
    then
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
    state.initREQ = true
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

local function render_wipe()
    msg.trace("render_wipe()")
    state.osd.data = "" -- allows set_osd to immediately update on enable
    state.osd:remove()
end

--
-- Tracklist Management
--

-- updates the OSC internal playlists, should be run each time the track-layout changes
local function update_tracklist()
    audio_track_count, sub_track_count = 0, 0

    for _, track in pairs(mp.get_property_native("track-list")) do
        if track.type == "audio" then
            audio_track_count = audio_track_count + 1
        elseif track.type == "sub" then
            sub_track_count = sub_track_count + 1
        end
    end
end

-- convert slider_pos to volume
local function set_volume(slider_pos)
    return math.floor(slider_pos)
end

-- WindowControl helpers
local function window_controls_enabled()
    local val = user_opts.window_top_bar
    if val == "auto" then
        return not (state.border and state.title_bar) or state.fullscreen
    else
        return val == "yes"
    end
end

--
-- Element Management
--
local elements = {}

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

    for _,element in pairs(elements) do

        local elem_geo = element.layout.geometry

        -- Calculate the hitbox
        local bX1, bY1, bX2, bY2 = get_hitbox_coords_geo(elem_geo)
        element.hitbox = {x1 = bX1, y1 = bY1, x2 = bX2, y2 = bY2}

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
            ass_draw_rr_h_cw(static_ass, 0, 0, elem_geo.w, elem_geo.h,
                             element.layout.box.radius, element.layout.box.hexagon)
            static_ass:draw_stop()

        elseif element.type == "slider" then
            --draw static slider parts
            local slider_lo = element.layout.slider
            -- calculate positions of min and max points
            element.slider.min.ele_pos = user_opts.seek_handle_size > 0 and (user_opts.seek_handle_size * elem_geo.h / 2) or slider_lo.border
            element.slider.max.ele_pos = elem_geo.w - element.slider.min.ele_pos
            element.slider.min.glob_pos = element.hitbox.x1 + element.slider.min.ele_pos
            element.slider.max.glob_pos = element.hitbox.x1 + element.slider.max.ele_pos

            static_ass:draw_start()
            -- a hack which prepares the whole slider area to allow center placements such like an=5
            static_ass:rect_cw(0, 0, elem_geo.w, elem_geo.h)
            static_ass:rect_ccw(0, 0, elem_geo.w, elem_geo.h)
            -- marker nibbles
            if element.slider.markerF ~= nil and slider_lo.gap > 0 then
                local markers = element.slider.markerF()
                for _, marker in pairs(markers) do
                    if marker >= element.slider.min.value and
                    marker <= element.slider.max.value then
                        local s = get_slider_ele_pos_for(element, marker)
                        if slider_lo.gap > 5 then
                            -- top triangle nibble only
                            static_ass:move_to(s - 3, slider_lo.gap - 5)
                            static_ass:line_to(s + 3, slider_lo.gap - 5)
                            static_ass:line_to(s, slider_lo.gap - 1)
                        else
                            -- small 2x1px nibble at top
                            static_ass:rect_cw(s - 1, 0, s + 1, slider_lo.gap)
                        end
                    end
                end
            end
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

-- Draws a handle on the seekbar according to user_opts
-- Returns handle position and radius
local function draw_seekbar_handle(element, elem_ass, override_alpha)
    local pos = element.slider.posF()
    if not pos then
        return 0, 0
    end
    local display_handle = user_opts.seek_handle_size > 0
    local elem_geo = element.layout.geometry

    -- Check if this is the volumebar and set a different handle size for it
    local handle_size = user_opts.seek_handle_size
    if element.name == "volumebar" then
        handle_size = 1
    end

    local rh = display_handle and (handle_size * elem_geo.h / 2) or 0 -- handle radius
    local xp = get_slider_ele_pos_for(element, pos) -- handle position

    if display_handle then
        ass_draw_cir_cw(elem_ass, xp, elem_geo.h / 2, rh)

        return xp, rh
    end
    return xp, 0
end

-- Draws seekbar ranges according to user_opts
local function draw_seekbar_ranges(element, elem_ass, xp, rh, override_alpha)
    local handle = xp and rh
    xp = xp or 0
    rh = rh or 0
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local seekRanges = element.slider.seekRangesF()
    if not seekRanges then
        return
    end
    elem_ass:draw_stop()
    elem_ass:merge(element.style_ass)
    ass_append_alpha(elem_ass, element.layout.alpha, override_alpha or user_opts.seekrangealpha)
    elem_ass:append("{\\1cH&D9D9D9&}")
    elem_ass:merge(element.static_ass)

    local slider_lo = element.layout.slider
    local radius = slider_lo.radius or 0

    for _, range in pairs(seekRanges) do
        local pstart = math.max(0, get_slider_ele_pos_for(element, range["start"]) - slider_lo.gap)
        local pend = math.min(elem_geo.w, get_slider_ele_pos_for(element, range["end"]) + slider_lo.gap)

        if handle and (pstart < xp + rh and pend > xp - rh) then
            if pstart < xp - rh then
                if radius > 0 then
                    elem_ass:round_rect_cw(pstart, slider_lo.gap, xp - rh, elem_geo.h - slider_lo.gap, radius)
                else
                    elem_ass:rect_cw(pstart, slider_lo.gap, xp - rh, elem_geo.h - slider_lo.gap)
                end
            end
            pstart = xp + rh
        end

        if pend > pstart then
            if radius > 0 then
                elem_ass:round_rect_cw(pstart, slider_lo.gap, pend, elem_geo.h - slider_lo.gap, radius)
            else
                elem_ass:rect_cw(pstart, slider_lo.gap, pend, elem_geo.h - slider_lo.gap)
            end
        end
    end
end

-- Draw seekbar progress more accurately
local function draw_seekbar_progress(element, elem_ass)
    local pos = element.slider.posF()
    if not pos then
        return
    end
    local xp = get_slider_ele_pos_for(element, pos)
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local radius = slider_lo.radius or 0
    if radius > 0 then
        elem_ass:round_rect_cw(0, slider_lo.gap, xp, elem_geo.h - slider_lo.gap, radius)
    else
        elem_ass:rect_cw(0, slider_lo.gap, xp, elem_geo.h - slider_lo.gap)
    end
end

local function render_elements(master_ass)
    -- when the slider is dragged or hovered and we have a target chapter name
    -- then we use it instead of the normal title. we calculate it before the
    -- render iterations because the title may be rendered before the slider.
    state.forced_title = nil

    state.touchingprogressbar = false

    for n=1, #elements do
        local element = elements[n]
        local style_ass = assdraw.ass_new()
        style_ass:merge(element.style_ass)
        ass_append_alpha(style_ass, element.layout.alpha, 0)

        if element.eventresponder and (state.active_element == n) then
            -- run render event functions
            if element.eventresponder.render ~= nil then
                element.eventresponder.render(element)
            end
            if mouse_hit(element) then
                -- mouse down styling
                if element.styledown then
                    style_ass:append(osc_styles.element_down)
                end
                if element.softrepeat and state.mouse_down_counter >= 15
                    and state.mouse_down_counter % 5 == 0 then

                    element.eventresponder[state.active_event_source.."_down"](element)
                end
                state.mouse_down_counter = state.mouse_down_counter + 1
            end
        end

        local elem_ass = assdraw.ass_new()
        elem_ass:merge(style_ass)

        if element.type ~= "button" then
            elem_ass:merge(element.static_ass)
        end

        if element.type == "slider" then
            if element.name ~= "persistentseekbar" then
                local slider_lo = element.layout.slider
                local elem_geo = element.layout.geometry
                local s_min = element.slider.min.value
                local s_max = element.slider.max.value

                local xp, rh = draw_seekbar_handle(element, elem_ass) -- handle posistion, handle radius
                draw_seekbar_progress(element, elem_ass)
                draw_seekbar_ranges(element, elem_ass, xp, rh)

                elem_ass:draw_stop()

                -- add tooltip
                if element.slider.tooltipF ~= nil and element.enabled then
                    local force_seek_tooltip = element.name == "seekbar"
                        and element.eventresponder["mbtn_left_down"]
                        and element.state.mbtnleft
                        and state.mouse_down_counter > 0
                        and state.playing_and_seeking
                    if mouse_hit(element) or force_seek_tooltip then
                        local sliderpos = get_slider_value(element)
                        local time_text = element.slider.tooltipF(sliderpos)
                        local an = slider_lo.tooltip_an
                        local ty = element.hitbox.y1
                        if an ~= 2 then ty = ty + elem_geo.h / 2 end
                        local tx = get_virt_mouse_pos()
                        local final_tx = tx

                        local chapter_text = nil
                        if element.name == "seekbar" and state.touchingprogressbar then
                            local dur = mp.get_property_number("duration", 0)
                            if dur > 0 then
                                local ch = get_chapter(sliderpos * dur / 100)
                                if ch and ch.title and ch.title ~= "" then
                                    chapter_text = ch.title
                                end
                            end
                        end

                        if element.name == "seekbar" and thumbfast.disabled then
                            local time_width = string.len(time_text) * (user_opts.font_size_md / 1.8)
                            local chapter_width = chapter_text and string.len(chapter_text) * (user_opts.font_size_md / 1.8) or 0
                            local max_half_width = math.max(time_width, chapter_width) / 2
                            local margin = 5
                            if max_half_width > 0 then
                                final_tx = math.max(max_half_width + margin, final_tx)
                                final_tx = math.min(osc_param.playresx - max_half_width - margin, final_tx)
                            end
                        elseif element.thumbnailable and not thumbfast.disabled then
                            local osd_w = mp.get_property_number("osd-width")
                            local r_w, r_h = get_virt_scale_factor()
                            if osd_w then
                                local hover_sec = mp.get_property_number("duration", 0) * sliderpos / 100
                                local thumbPad = 2
                                local thumbMarginX = 18 / r_w
                                local thumbMarginY = user_opts.font_size_md + thumbPad + 2 / r_h
                                local thumbX = math.min(osd_w - thumbfast.width - thumbMarginX, math.max(thumbMarginX, tx / r_w - thumbfast.width / 2))
                                local thumbY = (ty - thumbMarginY) / r_h - thumbfast.height
                                thumbX = math.floor(thumbX + 0.5)
                                thumbY = math.floor(thumbY + 0.5)

                                if state.anitype == nil then
                                    elem_ass:new_event()
                                    elem_ass:append("{\rDefault}")
                                    elem_ass:pos(thumbX * r_w, ty - thumbMarginY - thumbfast.height * r_h)
                                    elem_ass:an(7)
                                    elem_ass:append(osc_styles.thumbnail)
                                    elem_ass:draw_start()
                                    elem_ass:round_rect_cw(-thumbPad * r_w, -thumbPad * r_h, (thumbfast.width + thumbPad) * r_w, (thumbfast.height + thumbPad) * r_h, 4)
                                    elem_ass:draw_stop()
                                    mp.commandv("script-message-to", "thumbfast", "thumb", hover_sec, thumbX, thumbY)
                                end
                                final_tx = (thumbX + thumbfast.width / 2) * r_w
                                an = 2
                            end
                        elseif slider_lo.adjust_tooltip then
                            if an == 2 then
                                if sliderpos < (s_min + 3) then an = an - 1
                                elseif sliderpos > (s_max - 3) then an = an + 1 end
                            elseif (sliderpos > (s_max+s_min)/2) then
                                an = an + 1; final_tx = final_tx - 5
                            else
                                an = an - 1; final_tx = final_tx + 10
                            end
                        end

                        if element.name == "seekbar" then
                            state.sliderpos = sliderpos
                        end

                        if chapter_text then
                            local titleY
                            if not thumbfast.disabled and element.thumbnailable then
                                local osd_w, osd_h = mp.get_osd_size()
                                local r_w, r_h = get_virt_scale_factor()
                                local thumbMarginY = user_opts.font_size_md + 2 / r_h
                                local thumbY = (ty - thumbMarginY) / r_h - thumbfast.height
                                titleY = thumbY * r_h - user_opts.font_size_md / 2
                            else
                                titleY = ty - (user_opts.font_size_md * 1.3)
                            end
                            elem_ass:new_event()
                            elem_ass:pos(final_tx, titleY)
                            elem_ass:an(an)
                            elem_ass:append(slider_lo.tooltip_style)
                            ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                            elem_ass:append(chapter_text)
                        end

                        elem_ass:new_event()
                        elem_ass:pos(final_tx, ty)
                        elem_ass:an(an)
                        elem_ass:append(slider_lo.tooltip_style)
                        ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                        elem_ass:append(time_text)

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
                buttontext = string.format("{\\fscx%f}",
                    (maxchars/#buttontext)*100) .. buttontext
            end

            -- add hover effects
            local button_lo = element.layout.button
            local is_clickable = element.eventresponder and (
                element.eventresponder["mbtn_left_down"] ~= nil or
                element.eventresponder["mbtn_left_up"] ~= nil
            )
            local hovered = mouse_hit(element) and is_clickable and element.enabled and state.mouse_down_counter == 0
            local hoverstyle = button_lo.hoverstyle
            if hovered and contains(user_opts.hover_effect, "color") then
                elem_ass:append(hoverstyle .. buttontext)
            else
                elem_ass:append(buttontext)
            end

            -- apply blur effect if "glow" is in hover effects
            if hovered and contains(user_opts.hover_effect, "glow") then
                local shadow_ass = assdraw.ass_new()
                shadow_ass:merge(style_ass)
                shadow_ass:append("{\\blur5}" .. hoverstyle .. buttontext)
                elem_ass:merge(shadow_ass)
            end

            -- add tooltip for button elements
            if element.tooltipF ~= nil then
                if mouse_hit(element) then
                    local tooltiplabel
                    if element.enabled then
                        if type(element.tooltipF) == "function" then
                            tooltiplabel = element.tooltipF()
                        else
                            tooltiplabel = element.tooltipF
                        end
                    else
                        tooltiplabel = element.nothingavailable or ""
                    end

                    if tooltiplabel ~= "" and tooltiplabel ~= nil then
                        local tX = element.hitbox.x1 + (element.hitbox.x2 - element.hitbox.x1) / 2 -- center of button
                        local tY, an

                        if element.hitbox.y1 < osc_param.playresy / 2 then
                            -- Button is in top half, show tooltip below
                            tY = element.hitbox.y2 + 5
                            an = 8 -- top-center
                        else
                            -- Button is in bottom half, show tooltip above
                            tY = element.hitbox.y1 - 5
                            an = 2 -- bottom-center
                        end

                        -- Estimate width and check for horizontal overflow
                        local estimated_width = string.len(tooltiplabel) * (user_opts.font_size_md / 1.8)
                        if tX + estimated_width / 2 > osc_param.playresx then
                            an = an + 1 -- 2->3 (bottom-right), 8->9 (top-right)
                            tX = osc_param.playresx - 5 -- Add a small margin
                        elseif tX - estimated_width / 2 < 0 then
                            an = an - 1 -- 2->1 (bottom-left), 8->7 (top-left)
                            tX = 5 -- Add a small margin
                        end

                        elem_ass:new_event()
                        elem_ass:append("{\rDefault}")
                        elem_ass:pos(tX, tY)
                        elem_ass:an(an)
                        elem_ass:append(element.tooltip_style)
                        elem_ass:append(tooltiplabel)
                    end
                end
            end
        end

        master_ass:merge(elem_ass)
    end
end

local function render_persistentprogressbar(master_ass)
    for n=1, #elements do
        local element = elements[n]
        if element.name == "persistentseekbar" then
            local style_ass = assdraw.ass_new()
            style_ass:merge(element.style_ass)
            if state.animation or not state.osc_visible then
                ass_append_alpha(style_ass, element.layout.alpha, 0, true)

                local elem_ass = assdraw.ass_new()
                elem_ass:merge(style_ass)
                if element.type ~= "button" then
                    elem_ass:merge(element.static_ass)
                end

                -- draw pos marker
                draw_seekbar_progress(element, elem_ass)

                if user_opts.persistentbuffer then
                    draw_seekbar_ranges(element, elem_ass, nil, nil)
                end

                elem_ass:draw_stop()
                master_ass:merge(elem_ass)
            end
        end
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
    elements[name].styledown = (type == "button")
    elements[name].state = {}

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
                hoverstyle = osc_styles.element_hover,
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
                hoverstyle = osc_styles.element_hover,
            }
        elseif elements[name].type == "box" then
            elements[name].layout.box = {radius = 0, hexagon = false}
        end

        return elements[name].layout
    else
        msg.error("Can't add_layout to element '"..name.."', doesn't exist.")
    end
end

-- Window Controls
local function window_controls()
    local wc_geo = {
        x = 0,
        y = 30,
        an = 1,
        w = osc_param.playresx,
        h = 30,
    }

    local lo
    local controlbox_w = window_control_box_width
    local titlebox_w = wc_geo.w - controlbox_w

    local controlbox_left = wc_geo.w - controlbox_w
    local titlebox_left = wc_geo.x
    local titlebox_right = wc_geo.w - controlbox_w

    local button_y = wc_geo.y - (wc_geo.h / 2)
    local first_geo = {x = controlbox_left + 36, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local second_geo = {x = controlbox_left + 84, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local third_geo = {x = controlbox_left + 126, y = button_y, an = 5, w = 40, h = wc_geo.h}

    -- Window controls
    if user_opts.window_controls then
        -- Close: 🗙
        lo = add_layout("close")
        lo.geometry = third_geo
        lo.style = osc_styles.window_control
        lo.button.hoverstyle = "{\\c&2311E8&\\3c&H000000&}"

        -- Minimize: 🗕
        lo = add_layout("minimize")
        lo.geometry = first_geo
        lo.style = osc_styles.window_control

        -- Maximize: 🗖 /🗗
        lo = add_layout("maximize")
        lo.geometry = second_geo
        lo.style = osc_styles.window_control

        add_area("window-controls", get_hitbox_coords(controlbox_left, wc_geo.y, wc_geo.an, controlbox_w, wc_geo.h))
    end

    -- Window Title
    if user_opts.window_title then
        lo = add_layout("windowtitle")
        lo.geometry = {x = 15, y = button_y + 14, an = 1, w = titlebox_w, h = wc_geo.h}
        lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}", osc_styles.window_title, titlebox_left, wc_geo.y - wc_geo.h, titlebox_right, wc_geo.y + wc_geo.h)

        add_area("window-controls-title", titlebox_left, 0, titlebox_right, wc_geo.h)
    end
end

--
-- hayase-osc Layout
--
-- Default layout
layouts["default"] = function ()
    local chapter_index = mp.get_property_number("chapter", -1) >= 0
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
    local posX = 0
    local posY = osc_param.playresy

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area("input", get_hitbox_coords(posX, posY, 1, osc_geo.w, osc_geo.h))

    -- area for show/hide
    add_area("showhide", 0, 0, osc_param.playresx, osc_param.playresy)

    -- fetch values
    local osc_w, osc_h = osc_geo.w, osc_geo.h

    -- Controller Background
    local lo, geo

    new_element("osc_fade_bg", "box")
    lo = add_layout("osc_fade_bg")
    lo.geometry = {x = posX, y = posY, an = 7, w = osc_w, h = 1}
    lo.style = osc_styles.osc_fade_bg
    lo.layer = 10
    lo.alpha[3] = 50

    local top_titlebar = window_controls_enabled() and (user_opts.window_title or user_opts.window_controls)

    -- Window bar alpha
    if ((user_opts.window_top_bar == "yes" or not (state.border and state.title_bar)) or state.fullscreen) and top_titlebar then
        new_element("window_bar_alpha_bg", "box")
        lo = add_layout("window_bar_alpha_bg")
        lo.geometry = {x = posX, y = -100, an = 7, w = osc_w, h = -1}
        lo.style = osc_styles.window_fade_bg
        lo.layer = 10
        lo.alpha[3] = 0
    end

    -- Alignment
    local refX = osc_w / 2
    local refY = posY

    -- Seekbar
    new_element("seekbarbg", "box")
    lo = add_layout("seekbarbg")
    local seekbar_bg_h = 4
    lo.geometry = {x = refX, y = refY - 82, an = 5, w = osc_geo.w - 45, h = seekbar_bg_h}
    lo.layer = 13
    lo.style = osc_styles.seekbar_bg
    lo.box.radius = 2
    lo.alpha[1] = 152
    lo.alpha[3] = 128

    lo = add_layout("seekbar")
    local seekbar_h = 18
    lo.geometry = {x = refX, y = refY - 82, an = 5, w = osc_geo.w - 45, h = seekbar_h}
    lo.layer = 51
    lo.style = osc_styles.seekbar_fg
    lo.slider.gap = (seekbar_h - seekbar_bg_h) / 2.0
    lo.slider.radius = 2
    lo.slider.tooltip_style = osc_styles.tooltip
    lo.slider.tooltip_an = 2

    if user_opts.persistentprogress or state.persistent_progress_toggle then
        lo = add_layout("persistentseekbar")
        lo.geometry = {x = refX, y = refY, an = 5, w = osc_geo.w, h = user_opts.persistentprogressheight}
        lo.style = osc_styles.seekbar_fg
        lo.slider.gap = (seekbar_h - seekbar_bg_h) / 2.0
        lo.slider.tooltip_an = 0
    end

    -- Time codes width calculation
    local remsec = mp.get_property_number("playtime-remaining", 0)
    local dur = mp.get_property_number("duration", 0)
    local show_hours = mp.get_property_number("playback-time", 0) >= 3600
    local show_remhours = (state.tc_right_rem and remsec >= 3600) or (not state.tc_right_rem and dur >= 3600)
    local time_codes_width =
        80 + (state.tc_ms and 50 or 0) + (state.tc_right_rem and 15 or 0) + (show_hours and 20 or 0) +
        (show_remhours and 20 or 0)

    -- OSC title
    local title_w = (chapter_index and (osc_geo.w - 50) or (osc_geo.w - 50 - time_codes_width))
    if title_w < 0 then title_w = 0 end
    geo = {x = 25, y = refY - (chapter_index and 122 or 100), an = 1, w = title_w, h = user_opts.font_size_lg}
    lo = add_layout("title")
    lo.geometry = geo
    lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}", osc_styles.title, geo.x, geo.y - geo.h, geo.x + geo.w, geo.y + geo.h)
    lo.alpha[3] = 0

    -- Chapter title (above seekbar)
    local chapter_geo = {x = 25, y = refY - 100, an = 1, w = osc_geo.w / 2, h = user_opts.font_size_md}
    lo = add_layout("chapter_title")
    lo.geometry = chapter_geo
    lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}", osc_styles.chapter_title, chapter_geo.x, chapter_geo.y - chapter_geo.h, chapter_geo.x + chapter_geo.w, chapter_geo.y + chapter_geo.h)

    -- Time codes
    lo = add_layout("time_codes")
    lo.geometry = {x = osc_geo.w - 25, y = refY - 108, an = 6, w = time_codes_width, h = user_opts.font_size_md}
    lo.style = osc_styles.time

    -- Left side buttons
    local start_x = 50

    lo = add_layout("play_pause")
    lo.geometry = {x = start_x, y = refY - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    start_x = start_x + 55

    if elements.playlist_prev.visible then
        lo = add_layout("playlist_prev")
        lo.geometry = {x = start_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 55
    end

    if elements.playlist_next.visible then
        lo = add_layout("playlist_next")
        lo.geometry = {x = start_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 55
    end

    if audio_track_count > 0 then
        lo = add_layout("vol_ctrl")
        lo.geometry = {x = start_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        start_x = start_x + 28

        new_element("volumebarbg", "box")
        elements.volumebar.visible = osc_geo.w >= 750
        elements.volumebarbg.visible = elements.volumebar.visible
        if elements.volumebar.visible then
            lo = add_layout("volumebarbg")
            lo.geometry = {x = start_x, y = refY - 38, an = 4, w = 95, h = 2}
            lo.layer = 13
            lo.alpha[1] = 128
            lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_bg or osc_styles.volumebar_bg
            lo.box.radius = 1

            lo = add_layout("volumebar")
            lo.geometry = {x = start_x, y = refY - 38, an = 4, w = 95, h = 8}
            lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_fg or osc_styles.volumebar_fg
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
    lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    end_x = end_x - 55

    elements.tog_ontop.visible = osc_geo.w >= 500
    if elements.tog_ontop.visible then
        lo = add_layout("tog_ontop")
        lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    elements.audio_track.visible = user_opts.audio_button and audio_track_count > 1 and osc_geo.w >= 750
    if elements.audio_track.visible then
        lo = add_layout("audio_track")
        lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    elements.sub_track.visible = sub_track_count > 0 and osc_geo.w >= 600
    if elements.sub_track.visible then
        lo = add_layout("sub_track")
        lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    lo = add_layout("menu")
    lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
    lo.style = osc_styles.buttons
    end_x = end_x - 55

    if user_opts.speed_button then
        lo = add_layout("speed")
        lo.geometry = {x = end_x, y = refY - 38, an = 5, w = 24, h = 24}
        lo.style = osc_styles.buttons
        end_x = end_x - 55
    end

    elements.cache_info.visible = user_opts.cache_info and osc_geo.w >= 500
    if elements.cache_info.visible then
        lo = add_layout("cache_info")
        lo.geometry = {x = end_x + 7, y = refY - 38, an = 6, w = (user_opts.cache_info_speed and 70 or 45), h = 24}
        lo.style = osc_styles.time
    end
end


local function adjust_subtitles(visible)
    if not mp.get_property_native("sid") then return end

    local scale = state.fullscreen and user_opts.scalefullscreen or user_opts.scalewindowed

    if visible and user_opts.raise_subtitles and state.osc_visible == true then
        local w, h = mp.get_osd_size()
        if h > 0 then
            local raise_factor = user_opts.raise_subtitle_amount

            -- adjust for scale
            if scale > 1 then
                raise_factor = raise_factor * (1 + (scale - 1) * 0.2)
            elseif scale < 1 then
                raise_factor = raise_factor * (0.8 + (scale - 0.5) * 0.5)
            end

            -- raise percentage
            local raise_percent = (raise_factor / osc_param.playresy) * 100

            -- don't adjust if user's sub-pos is higher than the raise factor
            if state.user_subpos >= (100 - raise_percent) then
                local adjusted = math.floor((osc_param.playresy - raise_factor) / osc_param.playresy * 100)
                if adjusted < 0 then adjusted = state.user_subpos end

                state.osc_adjusted_subpos = adjusted
                mp.set_property_number("sub-pos", adjusted)
            else
                state.osc_adjusted_subpos = nil
            end
        end
    elseif user_opts.raise_subtitles then
        -- restore user's original subtitle position
        if state.user_subpos then
            mp.set_property_number("sub-pos", state.user_subpos)
        end
        state.osc_adjusted_subpos = nil
    end
end

local function osc_visible(visible)
    if state.osc_visible ~= visible then
        state.osc_visible = visible
        update_margins()
        adjust_subtitles(true)
    end
    request_tick()
end

local function bind_mouse_buttons(element_name)
    for _, button in pairs({"mbtn_left", "mbtn_mid", "mbtn_right"}) do
        local command = user_opts[element_name .. "_" .. button .. "_command"]

        if command and command ~= "" then
            elements[element_name].eventresponder[button .. "_up"] = function ()
                mp.command(command)
            end
        end
    end

    if user_opts.scrollcontrols then
        for _, button in pairs({"wheel_down", "wheel_up"}) do
            local command = user_opts[element_name .. "_" .. button .. "_command"]

            if command and command ~= "" then
                elements[element_name].eventresponder[button .. "_press"] = function ()
                    mp.command(command)
                end
            end
        end
    end
end

local function osc_init()
    msg.debug("osc_init")

    -- set canvas resolution according to display aspect and scaling setting
    local baseResY = 720
    local _, display_h, display_aspect = mp.get_osd_size()
    local scale

    if state.fullscreen then
        scale = user_opts.scalefullscreen
    else
        scale = user_opts.scalewindowed
    end

    local scale_with_video
    if user_opts.vidscale == "auto" then
        scale_with_video = mp.get_property_native("osd-scale-by-window")
    else
        scale_with_video = user_opts.vidscale == "yes"
    end

    if scale_with_video then
        osc_param.unscaled_y = baseResY
    else
        osc_param.unscaled_y = display_h
    end
    osc_param.playresy = osc_param.unscaled_y / scale
    if display_aspect > 0 then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect

    -- stop seeking with the slider to prevent skipping files
    state.active_element = nil

    elements = {}

    -- some often needed stuff
    local pl_count = mp.get_property_number("playlist-count", 0)
    local have_pl = pl_count > 1
    local pl_pos = mp.get_property_number("playlist-pos", 0) + 1
    local have_ch = mp.get_property_number("chapters", 0) > 0
    local loop = mp.get_property("loop-playlist", "no")

    local audio_offset = (audio_track_count == 0 or not mp.get_property_native("aid")) and 100 or 0
    local sub_offset = (sub_track_count == 0 or not mp.get_property_native("sid")) and 100 or 0
    local playlist_offset = not have_pl and 100 or 0

    local ne

    -- Window controls
    -- Close: 🗙
    ne = new_element("close", "button")
    ne.content = icons.window.close
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("quit") end

    -- Minimize: 🗕
    ne = new_element("minimize", "button")
    ne.content = icons.window.minimize
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("cycle", "window-minimized") end

    -- Maximize: 🗖 /🗗
    ne = new_element("maximize", "button")
    ne.content = (state.maximized or state.fullscreen) and icons.window.unmaximize or icons.window.maximize
    ne.eventresponder["mbtn_left_up"] = function () mp.commandv("cycle", (state.fullscreen and "fullscreen" or "window-maximized")) end

    -- Window Title
    ne = new_element("windowtitle", "button")
    ne.content = function ()
        local title = mp.command_native({"expand-text", user_opts.windowcontrols_title}) or ""
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
    ne.visible = mp.get_property_number("chapter", -1) >= 0
    ne.content = function()
        local chapter_index = mp.get_property_number("chapter", -1)
        if chapter_index < 0 then
            return ""
        end

        local chapters = mp.get_property_native("chapter-list", {})
        local chapter_data = chapters[chapter_index + 1]
        local chapter_title = chapter_data and chapter_data.title ~= "" and chapter_data.title
            or string.format("%s: %d/%d", locale.chapter, chapter_index + 1, #chapters)

        chapter_title = mp.command_native({"escape-ass", chapter_title})

        return chapter_title
    end
    bind_mouse_buttons("chapter_title")

    -- menu
    ne = new_element("menu", "button")
    ne.content = icons.menu
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = locale.menu
    bind_mouse_buttons("menu")

    -- playlist buttons
    -- prev
    ne = new_element("playlist_prev", "button")
    ne.visible = pl_pos > 1
    ne.content = icons.previous
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = locale.playlist_prev
    bind_mouse_buttons("playlist_prev")

    --next
    ne = new_element("playlist_next", "button")
    ne.visible = have_pl and (pl_pos < pl_count)
    ne.content = icons.next
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = locale.playlist_next
    bind_mouse_buttons("playlist_next")

    --play control buttons
    --play_pause
    ne = new_element("play_pause", "button")
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        if mp.get_property("eof-reached") == "yes" then
            return locale.replay
        elseif mp.get_property("pause") == "yes" then
            return locale.play
        else
            return locale.pause
        end
    end
    ne.content = function ()
        if mp.get_property("eof-reached") == "yes" then
            return icons.replay
        elseif mp.get_property("pause") == "yes" then
            return icons.play
        else
            return icons.pause
        end
    end
    ne.eventresponder["mbtn_left_up"] = function ()
        if mp.get_property("eof-reached") == "yes" then
            mp.commandv("seek", 0, "absolute-percent")
            mp.commandv("set", "pause", "no")
        else
            mp.commandv("cycle", "pause")
        end
    end
    ne.eventresponder["mbtn_right_down"] = function ()
        if user_opts.loop_in_pause then
            mp.command("show-text '" .. (state.looping and locale.loop_disable or locale.loop_enable) .. "'")
            state.looping = not state.looping
            mp.set_property_native("loop-file", state.looping)
        end
    end

    update_tracklist()

    --audio_track
    ne = new_element("audio_track", "button")
    ne.enabled = audio_track_count > 0
    ne.off = audio_track_count == 0 or not mp.get_property_native("aid")
    ne.content = icons.audio
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local prop = mp.get_property("current-tracks/audio/title") or mp.get_property("current-tracks/audio/lang") or locale.na
        return (locale.audio .. " " .. mp.get_property_number("aid", "-") .. "/" .. audio_track_count .. " [" .. prop .. "]")
    end
    ne.nothingavailable = locale.no_audio
    bind_mouse_buttons("audio_track")

    --sub_track
    ne = new_element("sub_track", "button")
    ne.enabled = sub_track_count > 0
    ne.off = sub_track_count == 0 or not mp.get_property_native("sid")
    ne.content = icons.subtitle
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local prop = mp.get_property("current-tracks/sub/title") or mp.get_property("current-tracks/sub/lang") or locale.na
        return (locale.subtitle .. " " .. mp.get_property_number("sid", "-") .. "/" .. sub_track_count .. " [" .. prop .. "]")
    end
    ne.nothingavailable = locale.no_subs
    bind_mouse_buttons("sub_track")

    -- vol_ctrl
    ne = new_element("vol_ctrl", "button")
    ne.enabled = audio_track_count > 0
    ne.off = audio_track_count == 0
    ne.content = function ()
        local volume = mp.get_property_number("volume")
        local muted = mp.get_property_native("mute")
        if muted then
            return icons.mute
        end

        if volume == 0 then
            return icons.volume[1]
        else
            local icon_index = math.min(4, math.ceil((volume / 100) * 3) + 1)
            return icons.volume[icon_index]
        end
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local volume = mp.get_property_number("volume", 0) or 0
        -- show only one decimal, if decimals exist
        volume = volume % 1 == 0 and string.format("%.0f", volume) or string.format("%.1f", volume)
        return volume
    end
    bind_mouse_buttons("vol_ctrl")

    --volumebar
    local volume_max = mp.get_property_number("volume-max") > 0 and mp.get_property_number("volume-max") or 100
    ne = new_element("volumebar", "slider")
    ne.enabled = audio_track_count > 0
    ne.slider = {min = {value = 0}, max = {value = volume_max}}
    ne.slider.markerF = function () return {} end
    ne.slider.seekRangesF = function() return nil end
    ne.slider.posF = function ()
        return mp.get_property_number("volume")
    end
    ne.slider.tooltipF = function (pos) return (audio_track_count > 0) and set_volume(pos) or "" end
    ne.eventresponder["mouse_move"] = function (element)
        local pos = get_slider_value(element)
        local setvol = set_volume(pos)
        if element.state.lastseek == nil or element.state.lastseek ~= setvol then
                mp.commandv("osd-msg", "set", "volume", setvol)
                element.state.lastseek = setvol
        end
    end
    ne.eventresponder["mbtn_left_down"] = function (element)
        local pos = get_slider_value(element)
        mp.commandv("osd-msg", "set", "volume", set_volume(pos))
    end
    ne.eventresponder["reset"] = function (element) element.state.lastseek = nil end
    if user_opts.scrollcontrols then
        ne.eventresponder["wheel_down_press"] = function ()
            local command = user_opts["vol_ctrl_wheel_down_command"]
            if command and command ~= "" then mp.command(command) end
        end
        ne.eventresponder["wheel_up_press"] = function ()
            local command = user_opts["vol_ctrl_wheel_up_command"]
            if command and command ~= "" then mp.command(command) end
        end
    end

    -- fullscreen
    ne = new_element("fullscreen", "button")
    ne.content = function () return state.fullscreen and icons.fullscreen_exit or icons.fullscreen end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function () return state.fullscreen and locale.fullscreen_exit or locale.fullscreen_enter end
    bind_mouse_buttons("fullscreen")

    --tog_ontop
    ne = new_element("tog_ontop", "button")
    ne.content = function () return mp.get_property("ontop") == "no" and icons.ontop_on or icons.ontop_off end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function () return mp.get_property("ontop") == "no" and locale.ontop or locale.ontop_disable end
    ne.eventresponder["mbtn_left_up"] = function ()
        mp.commandv("cycle", "ontop")
        if state.initialborder == "yes" then
            if mp.get_property("ontop") == "yes" then
                mp.commandv("set", "border", "no")
            else
                mp.commandv("set", "border", "yes")
            end
        end
    end
    ne.eventresponder["mbtn_right_up"] = function ()
        mp.commandv("cycle", "ontop")
        if mp.get_property("border") == "no" then
            mp.commandv("set", "border", "yes")
        end
    end

    --speed
    ne = new_element("speed", "button")
    ne.content = function ()
        return "x" .. string.format("%g", mp.get_property_number("speed", 1))
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = locale.speed_control
    ne.eventresponder["mbtn_left_up"] = function ()
        mp.commandv("set", "speed", math.min(2, mp.get_property_number("speed") + 0.25))
    end
    ne.eventresponder["mbtn_right_up"] = function ()
        mp.commandv("set", "speed", math.max(0.25, mp.get_property_number("speed") - 0.25))
    end
    if user_opts.scrollcontrols then
        ne.eventresponder["wheel_up_press"] = function ()
            mp.commandv("set", "speed", math.min(2, mp.get_property_number("speed") + 0.25))
        end
        ne.eventresponder["wheel_down_press"] = function ()
            mp.commandv("set", "speed", math.max(0.25, mp.get_property_number("speed") - 0.25))
        end
    end

    -- cache info
    ne = new_element("cache_info", "button")
    ne.content = function ()
        if not cache_enabled() then return "" end
        local dmx_cache = state.cache_state["cache-duration"]
        local thresh = math.min(state.dmx_cache * 0.05, 5)  -- 5% or 5s
        if dmx_cache and math.abs(dmx_cache - state.dmx_cache) >= thresh then
            state.dmx_cache = dmx_cache
        else
            dmx_cache = state.dmx_cache
        end
        local min = math.floor(dmx_cache / 60)
        local sec = math.floor(dmx_cache % 60) -- don't round e.g. 59.9 to 60
        local cache_time = (min > 0 and string.format("%sm%02.0fs", min, sec) or string.format("%3.0fs", sec))

        local dmx_speed = state.cache_state["raw-input-rate"] or 0
        local cache_speed = utils.format_bytes_humanized(dmx_speed)
        local number, unit = cache_speed:match("([%d%.]+)%s*(%S+)")
        local cache_info = state.buffering and locale.buffering .. ": " .. mp.get_property("cache-buffering-state") .. "%" or cache_time
        local cache_info_speed = string.format("%8s %4s/s", number, unit)

        return user_opts.cache_info_speed and cache_info .. "\\N" .. cache_info_speed or cache_info
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = (user_opts.tooltip_hints and cache_enabled()) and locale.cache or ""
    ne.eventresponder["mbtn_left_up"] = function() mp.command("script-binding stats/display-page-3") end

    --seekbar
    ne = new_element("seekbar", "slider")
    ne.enabled = mp.get_property("percent-pos") ~= nil
    ne.thumbnailable = true
    state.slider_element = ne.enabled and ne or nil  -- used for forced_title
    ne.slider.markerF = function ()
        local duration = mp.get_property_number("duration")
        if duration ~= nil then
            local chapters = mp.get_property_native("chapter-list", {})
            local markers = {}
            for n = 1, #chapters do
                markers[n] = (chapters[n].time / duration * 100)
            end
            return markers
        else
            return {}
        end
    end
    ne.slider.posF = function ()
        if mp.get_property_bool("eof-reached") then return 100 end
        return mp.get_property_number("percent-pos")
    end
            ne.slider.tooltipF = function (pos)
        state.touchingprogressbar = true
        local duration = mp.get_property_number("duration")
        if duration ~= nil and pos ~= nil then
            local possec = duration * (pos / 100)
            return format_time_custom(possec)
        else
            return ""
        end
    end
    ne.slider.seekRangesF = function()
        if not user_opts.seekrange or not cache_enabled() then
            return nil
        end
        local duration = mp.get_property_number("duration")
        if duration == nil or duration <= 0 then
            return nil
        end
        local nranges = {}
        for _, range in pairs(state.cache_state["seekable-ranges"]) do
            nranges[#nranges + 1] = {
                ["start"] = 100 * range["start"] / duration,
                ["end"] = 100 * range["end"] / duration,
            }
        end
        return nranges
    end
    ne.eventresponder["mouse_move"] = function (element)
        if not element.state.mbtnleft then return end -- allow drag for mbtnleft only!
        -- mouse move events may pile up during seeking and may still get
        -- sent when the user is done seeking, so we need to throw away
        -- identical seeks
        state.playing_and_seeking = true
        if mp.get_property("pause") == "no" then
            mp.commandv("cycle", "pause")
        end
        local seekto = get_slider_value(element)
        if element.state.lastseek == nil or
          element.state.lastseek ~= seekto then
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
        mp.commandv("seek", get_slider_value(element), "absolute-percent+exact")
    end
    ne.eventresponder["shift+mbtn_left_down"] = function (element)
        element.state.mbtnleft = true
        mp.commandv("seek", get_slider_value(element), "absolute-percent")
    end
    ne.eventresponder["mbtn_left_up"] = function (element)
        element.state.mbtnleft = false
    end
    ne.eventresponder["mbtn_right_down"] = function (element)
        local chapter
        local pos = get_slider_value(element)
        local diff = math.huge

        for i, marker in ipairs(element.slider.markerF()) do
            if math.abs(pos - marker) < diff then
                diff = math.abs(pos - marker)
                chapter = i
            end
        end

        if chapter then
            mp.set_property("chapter", chapter - 1)
        end
    end
    ne.eventresponder["reset"] = function (element)
        element.state.lastseek = nil
        if state.playing_and_seeking then
            if mp.get_property("eof-reached") == "no" then
                mp.commandv("cycle", "pause")
            end
            state.playing_and_seeking = false
        end
    end
    if user_opts.scrollcontrols then
        ne.eventresponder["wheel_up_press"] = function () mp.commandv("seek", 10) end
        ne.eventresponder["wheel_down_press"] = function () mp.commandv("seek", -10) end
    end

    --persistent seekbar
    ne = new_element("persistentseekbar", "slider")
    ne.enabled = mp.get_property("percent-pos") ~= nil
    state.slider_element = ne.enabled and ne or nil  -- used for forced_title
    ne.slider.markerF = function () return {} end
    ne.slider.posF = function ()
        if mp.get_property_bool("eof-reached") then return 100 end
        return mp.get_property_number("percent-pos")
    end
    ne.slider.tooltipF = function() return "" end
    ne.slider.seekRangesF = function()
        if user_opts.persistentbuffer then
            if not user_opts.seekrange then
                return nil
            end
            local cache_state = state.cache_state
            if not cache_state then
                return nil
            end
            local duration = mp.get_property_number("duration")
            if duration == nil or duration <= 0 then
                return nil
            end
            local ranges = cache_state["seekable-ranges"]
            if #ranges == 0 then
                return nil
            end
            local nranges = {}
            for _, range in pairs(ranges) do
                nranges[#nranges + 1] = {
                    ["start"] = 100 * range["start"] / duration,
                    ["end"] = 100 * range["end"] / duration,
                }
            end
            return nranges
        end
        return nil
    end

    -- Helper function to format time
        local function format_time(seconds)
        return format_time_custom(seconds, state.tc_ms)
    end

    -- Time codes display
    local tc_visible_offset = audio_offset + sub_offset + playlist_offset
    ne = new_element("time_codes", "button")
    ne.visible = mp.get_property_number("duration", 0) > 0
    ne.content = function()
        local playback_time = mp.get_property_number("playback-time", 0)

        -- call request_init() only when needed to update time code width
        if playback_time then
            local hour_or_more = playback_time >= 3600
            if hour_or_more ~= state.playtime_hour_force_init then
                request_init()
                state.playtime_hour_force_init = hour_or_more
                state.playtime_nohour_force_init = not hour_or_more
            end
        end

        local duration = mp.get_property_number("duration", 0)
        if duration <= 0 then return "--:--" end

        local playtime_remaining = state.tc_right_rem and
            mp.get_property_number("playtime-remaining", 0) or duration

        local prefix = state.tc_right_rem and "-" or ""

        return format_time(playback_time) .. " / " .. prefix .. format_time(playtime_remaining)
    end
    ne.eventresponder["mbtn_left_up"] = function()
        state.tc_right_rem = not state.tc_right_rem
    end
    ne.eventresponder["mbtn_right_up"] = function()
        state.tc_ms = not state.tc_ms
        request_init()
    end

    -- load layout
    layouts["default"]()

    -- load window controls
    if window_controls_enabled() then
        window_controls()
    end

    --do something with the elements
    prepare_elements()
    update_margins()
end

local function show_osc()
    -- show when disabled can happen (e.g. mouse_move) due to async/delayed unbinding
    if not state.enabled then return end

    msg.trace("show_osc")
    --remember last time of invocation (mouse move)
    state.showtime = mp.get_time()

    if user_opts.fadeduration <= 0 then
        osc_visible(true)
    elseif user_opts.fadein then
        if not state.osc_visible then
            state.anitype = "in"
            request_tick()
        end
    else
        osc_visible(true)
        state.anitype = nil
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
        adjust_subtitles(false)
        render_wipe()
    elseif user_opts.fadeduration > 0 then
        if state.osc_visible then
            state.anitype = "out"
            request_tick()
        end
    else
        osc_visible(false)
    end
end

local function pause_state(_, enabled)
    state.paused = enabled
    request_tick()
end

local function cache_state(_, st)
    state.cache_state = st
    request_tick()
end

local function mouse_leave()
    state.touchtime = nil

    if get_hidetimeout() >= 0 and get_touchtimeout() <= 0 then
        local elapsed_time = mp.get_time() - state.showtime

        if elapsed_time >= (get_hidetimeout() / 1000) then
            hide_osc()
        end
    end

    -- reset mouse position
    state.last_mouseX, state.last_mouseY = nil, nil
    state.mouse_in_window = false
end

local function handle_touch(_, touchpoints)
    --remember last touch points
    if touchpoints then
        state.touchpoints = touchpoints
        if #touchpoints > 0 then
            --remember last time of invocation (touch event)
            state.touchtime = mp.get_time()
            state.last_touchX = touchpoints[1].x
            state.last_touchY = touchpoints[1].y
        end
    end
end

--
-- Event handling
--
local function reset_timeout()
    state.showtime = mp.get_time()
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

        local mouseX, mouseY = get_virt_mouse_pos()
        if user_opts.minmousemove == 0 or
            ((state.last_mouseX ~= nil and state.last_mouseY ~= nil) and
                ((math.abs(mouseX - state.last_mouseX) >= user_opts.minmousemove)
                    or (math.abs(mouseY - state.last_mouseY) >= user_opts.minmousemove)
                )
            ) then
                show_osc()
        end
        state.last_mouseX, state.last_mouseY = mouseX, mouseY

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
    local current_screen_sizeX, current_screen_sizeY = mp.get_osd_size()
    local mouseX, mouseY = get_virt_mouse_pos()
    local now = mp.get_time()

    -- check if display changed, if so request reinit
    if state.screen_sizeX ~= current_screen_sizeX
        or state.screen_sizeY ~= current_screen_sizeY then

        request_init_resize()

        state.screen_sizeX = current_screen_sizeX
        state.screen_sizeY = current_screen_sizeY
    end

    -- init management
    if state.active_element then
        -- mouse is held down on some element - keep ticking and ignore initReq
        -- till it's released, or else the mouse-up (click) will misbehave or
        -- get ignored. that's because osc_init() recreates the osc elements,
        -- but mouse handling depends on the elements staying unmodified
        -- between mouse-down and mouse-up (using the index active_element).
        request_tick()
    elseif state.initREQ then
        osc_init()
        state.initREQ = false

        -- store initial mouse position
        if (state.last_mouseX == nil or state.last_mouseY == nil)
            and not (mouseX == nil or mouseY == nil) then

            state.last_mouseX, state.last_mouseY = mouseX, mouseY
        end
    end

    -- fade animation
    if state.anitype ~= nil then
        if state.anistart == nil then
            state.anistart = now
        end

        if now < state.anistart + (user_opts.fadeduration / 1000) then
            if state.anitype == "in" then --fade in
                osc_visible(true)
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration / 1000)),
                    255, 0, now)
            elseif state.anitype == "out" then --fade out
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration / 1000)),
                    0, 255, now)
            end
        else
            if state.anitype == "out" then
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

    for _,cords in ipairs(osc_param.areas["input"]) do
        if state.osc_visible then -- activate only when OSC is actually visible
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "input")
        end
        if state.osc_visible ~= state.input_enabled then
            if state.osc_visible then
                mp.enable_key_bindings("input")
            else
                mp.disable_key_bindings("input")
            end
            state.input_enabled = state.osc_visible
        end

        if mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2) then
            mouse_over_osc = true
        end
    end

    if osc_param.areas["window-controls"] then
        for _,cords in ipairs(osc_param.areas["window-controls"]) do
            if state.osc_visible then -- activate only when OSC is actually visible
                set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "window-controls")
                mp.enable_key_bindings("window-controls")
            else
                mp.disable_key_bindings("window-controls")
            end

            if mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2) then
                mouse_over_osc = true
            end
        end
    end

    if osc_param.areas["window-controls-title"] then
        for _,cords in ipairs(osc_param.areas["window-controls-title"]) do
            if state.osc_visible then -- activate only when OSC is actually visible
                set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "window-controls-title")
            end
            if state.osc_visible ~= state.windowcontrols_title then
                if state.osc_visible then
                    mp.enable_key_bindings("window-controls-title", "allow-vo-dragging")
                else
                    mp.disable_key_bindings("window-controls-title")
                end
                state.windowcontrols_title = state.osc_visible
            end

            if mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2) then
                mouse_over_osc = true
            end
        end
    end

    -- autohide
    if state.showtime ~= nil and get_hidetimeout() >= 0 then
        local timeout = state.showtime + (get_hidetimeout() / 1000) - now
        if timeout <= 0 and get_touchtimeout() <= 0 then
            if state.active_element == nil and not mouse_over_osc then
                hide_osc()
            end
        else
            -- the timer is only used to recheck the state and to possibly run
            -- the code above again
            if not state.hide_timer then
                state.hide_timer = mp.add_timeout(0, tick)
            end
            state.hide_timer.timeout = timeout
            -- re-arm
            state.hide_timer:kill()
            state.hide_timer:resume()
        end
    end

    -- actual rendering
    local ass = assdraw.ass_new()

    -- actual OSC
    if state.osc_visible then
        render_elements(ass)
    end

    if user_opts.persistentprogress or state.persistent_progress_toggle then
        render_persistentprogressbar(ass)
    end

    -- submit
    set_osd(osc_param.playresy * osc_param.display_aspect,
            osc_param.playresy, ass.text, 1000)
end

-- called by mpv on every frame
tick = function()
    if state.marginsREQ == true then
        update_margins()
        state.marginsREQ = false
    end

    if not state.enabled then return end

    if state.idle then
        -- render idle message
        msg.trace("idle message")
        local _, _, display_aspect = mp.get_osd_size()
        if display_aspect == 0 then
            return
        end
        local display_h = 360
        local display_w = display_h * display_aspect
        -- logo is rendered at 2^(6-1) = 32 times resolution with size 1800x1800
        local icon_x, icon_y = (display_w - 1800 / 32) / 2, 140
        local line_prefix = ("{\\rDefault\\an7\\1a&H00&\\bord0\\shad0\\pos(%f,%f)}"):format(icon_x, icon_y)

        local ass = assdraw.ass_new()
        -- mpv logo
        if user_opts.idlescreen then
            for _, line in ipairs(logo_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end

        -- Santa hat
        if is_december and user_opts.idlescreen and not user_opts.greenandgrumpy then
            for _, line in ipairs(santa_hat_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end

        if user_opts.idlescreen then
            ass:new_event()
            ass:pos(display_w / 2, icon_y + 65)
            ass:an(8)
            ass:append(locale.idle)
        end
        set_osd(display_w, display_h, ass.text, -1000)

        if state.showhide_enabled then
            mp.disable_key_bindings("showhide")
            mp.disable_key_bindings("showhide_wc")
            state.showhide_enabled = false
        end
    elseif (state.fullscreen and user_opts.showfullscreen)
        or (not state.fullscreen and user_opts.showwindowed) then

        -- render the OSC
        render()
    else
        -- Flush OSD
        render_wipe()
    end

    state.tick_last_time = mp.get_time()

    if state.anitype ~= nil then
        -- state.anistart can be nil - animation should now start, or it can
        -- be a timestamp when it started. state.idle has no animation.
        if not state.idle and
           (not state.anistart or
            mp.get_time() < 1 + state.anistart + user_opts.fadeduration/1000)
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
-- expensive (with request_init), so it's only observed when we have chapters
-- and the user didn't disable the livemarkers option (update_duration_watch).
local function on_duration() request_init() end

local duration_watched = false
local function update_duration_watch()
    local want_watch = user_opts.livemarkers and
                       (mp.get_property_number("chapters", 0) or 0) > 0 and
                       true or false  -- ensure it's a boolean

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
    if user_opts.automatickeyframemode then
       if mp.get_property_number("duration", 0) > user_opts.automatickeyframelimit then
            user_opts.seekbarkeyframes = true
       else
            user_opts.seekbarkeyframes = false
       end
    end
    if user_opts.osc_on_start then
        show_osc()
    end
end)
mp.register_event("start-file", request_init)
mp.observe_property("track-list", "native", request_init)
mp.observe_property("playlist-count", "native", request_init)
mp.observe_property("playlist-pos", "native", request_init)
mp.observe_property("chapter-list", "native", function(_, list)
    list = list or {}  -- safety, shouldn't return nil
    table.sort(list, function(a, b) return a.time < b.time end)
    state.chapter_list = list
    update_duration_watch()
    request_init()
end)
local function show_osc_on_seek_event()
    show_osc()
end
mp.observe_property("seeking", "native", function(_, seeking)
    reset_timeout()

    if state.new_file_flag then
        state.new_file_flag = false
        return
    end

    if seeking and user_opts.osc_on_seek then
        show_osc()
    end
end)
mp.observe_property("fullscreen", "bool", function(_, val)
    state.fullscreen = val
    state.marginsREQ = true
    adjust_subtitles(state.osc_visible)
    request_init_resize()
end)
mp.observe_property("border", "bool", function(_, val)
    state.border = val
    request_init_resize()
end)
mp.observe_property("title-bar", "bool", function(_, val)
    state.title_bar = val
    request_init_resize()
end)
mp.observe_property("window-maximized", "bool", function(_, val)
    state.maximized = val
    request_init_resize()
end)
mp.observe_property("idle-active", "bool", function(_, val)
    state.idle = val
    request_tick()
end)
mp.observe_property("display-fps", "number", set_tick_delay)
mp.observe_property("demuxer-cache-state", "native", cache_state)
mp.observe_property("vo-configured", "bool", request_tick)
mp.observe_property("playback-time", "number", request_tick)
mp.observe_property("osd-dimensions", "native", function()
    -- (we could use the value instead of re-querying it all the time, but then
    --  we might have to worry about property update ordering)
    request_init_resize()
    adjust_subtitles(state.osc_visible)
end)
mp.observe_property("osd-scale-by-window", "native", request_init_resize)
mp.observe_property("touch-pos", "native", handle_touch)
mp.observe_property("mute", "bool", function(_, val)
    state.mute = val
    request_tick()
end)
mp.observe_property("paused-for-cache", "bool", function(_, val) state.buffering = val end)
-- ensure compatibility with auto looping scripts (eg: a script that sets videos under 2 seconds to loop by default)
mp.observe_property("loop-file", "bool", function(_, val)
    if (val == nil) then
        state.looping = true
    else
        state.looping = false
    end
end)
mp.observe_property("sub-pos", "native", function(_, value)
    if value == nil then return end

    if state.osc_adjusted_subpos == nil or value ~= state.osc_adjusted_subpos then
        state.user_subpos = value
    end
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
    state.input_enabled = false

    update_margins()
    request_tick()
end

local function idlescreen_visibility(mode, no_osd)
    if mode == "cycle" then
        if user_opts.idlescreen then
            mode = "no"
        else
            mode = "yes"
        end
    end

    if mode == "yes" then
        user_opts.idlescreen = true
    else
        user_opts.idlescreen = false
    end

    mp.set_property_native("user-data/osc/idlescreen", user_opts.idlescreen)

    if not no_osd and tonumber(mp.get_property("osd-level")) >= 1 then
        mp.osd_message("OSC logo visibility: " .. tostring(mode))
    end

    request_tick()
end

mp.observe_property("pause", "bool", function(name, enabled)
    pause_state(name, enabled)

    if user_opts.visibility ~= "never" then
        state.enabled = enabled
        if enabled then
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
        osc_visible(false)
    end
end)
mp.add_key_binding(nil, "visibility", function() visibility_mode("cycle") end)
mp.add_key_binding(nil, "progress-toggle", function()
    user_opts.persistentprogress = not user_opts.persistentprogress
    state.persistent_progress_toggle = user_opts.persistentprogress
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

    if user_opts.seek_handle_size < 0 then
        msg.warn("seek_handle_size must be 0 or higher. Setting it to 0 (minimum).")
        user_opts.seek_handle_size = 0
    end

    if not language[user_opts.language] then
       msg.warn("language '" .. user_opts.language .. "' not found. Ignoring.")
       user_opts.language = "en"
       if not language["en"] then
          msg.warn("ERROR: can't find the default 'en' language or the one set by user_opts.")
       end
    end

    local colors = {
        user_opts.background_color, user_opts.seekbarfg_color, user_opts.seekbarbg_color,
        user_opts.title_color, user_opts.playpause_color, user_opts.held_element_color,
        user_opts.thumbnail_border_color, user_opts.chapter_title_color, user_opts.hover_effect_color,
        user_opts.thumbnail_border_outline
    }

    for _, color in pairs(colors) do
        if color:find("^#%x%x%x%x%x%x$") == nil then
            msg.warn("'" .. color .. "' is not a valid color")
        end
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
    set_osc_locale()
    set_osc_styles()
    set_time_styles(changed.timetotal, changed.timems)
    if changed.tick_delay or changed.tick_delay_follow_display_fps then
        set_tick_delay("display_fps", mp.get_property_number("display_fps"))
    end
    request_tick()
    visibility_mode(user_opts.visibility, true)
    update_duration_watch()
    request_init()
end)

validate_user_opts()
set_osc_locale()
set_osc_styles()
set_time_styles(true, true)
set_tick_delay("display_fps", mp.get_property_number("display_fps"))
visibility_mode(user_opts.visibility, true)
update_duration_watch()

set_virt_mouse_area(0, 0, 0, 0, "input")
set_virt_mouse_area(0, 0, 0, 0, "window-controls")
set_virt_mouse_area(0, 0, 0, 0, "window-controls-title")
