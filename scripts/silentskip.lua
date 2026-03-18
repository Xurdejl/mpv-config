--[[
    silentskip.lua
    Skip to next silence with chapter aware skip.
    License: MIT

    Based on skiptosilence.lua (github.com/detuur/mpv-scripts)
    Chapter matching adapted from chapterskip.lua (github.com/po5/chapterskip)
    Fork by: xurdejl
--]]

local mp = require "mp"
local msg = require "mp.msg"

local categories = {
    prologue = "^[Pp]rologue/^[Ii]ntro",
    opening = "^OP/ OP$/^[Oo]pening/[Oo]pening$/^Intro%s*Start/オープニング$/^片头$/片头开始$",
    ending = "^ED/ ED$/^[Ee]nding/[Ee]nding$/エンディング$",
    credits = "^[Cc]redits/[Cc]redits$",
    preview = "[Pp]review$",
}

local options = {
    skip_keybind = "Tab",      -- Keybind to trigger skip
    silence_audio_level = -40, -- Audio level (dB) considered as silence
    silence_duration = 0.65,   -- Duration (seconds) of silence needed to trigger skip
    min_skip_lead = 5,         -- Seconds after skip start before silence is accepted
    max_skip_duration = 90,    -- Seconds before giving up and aborting silence scan
}

local state = {
    skip_active = false,
    initial_skip_time = 0,
    original = {},
    timer = nil,
}

local handle_silence_detection

local function window_is_large()
    return mp.get_property_native("fullscreen")
        or mp.get_property_native("window-maximized")
end

local function lock_window_size()
    if window_is_large() then return end
    local w = mp.get_property_native("osd-width")
    local h = mp.get_property_native("osd-height")
    if w and h then
        mp.set_property_native("geometry", string.format("%dx%d", w, h))
    end
end

local function unlock_window_size()
    mp.set_property("geometry", "")
end

local function save_state()
    state.original.sub = mp.get_property_bool("sub-visibility")
    state.original.secondary_sub = mp.get_property_bool("secondary-sub-visibility")
    state.original.force_window = mp.get_property("force-window")
    state.original.vid = mp.get_property("vid")
    state.original.mute = mp.get_property_native("mute")
    state.original.pause = mp.get_property_native("pause")
    state.original.speed = mp.get_property_native("speed")
end

local function restore_state(timepos)
    timepos = timepos or state.initial_skip_time

    mp.set_property("vid", state.original.vid)
    mp.set_property("force-window", state.original.force_window)
    mp.set_property_bool("mute", state.original.mute)
    mp.set_property("speed", state.original.speed)
    mp.set_property_bool("sub-visibility", state.original.sub)
    mp.set_property_bool("secondary-sub-visibility", state.original.secondary_sub)
    mp.set_property_bool("pause", state.original.pause)

    mp.unobserve_property(handle_silence_detection)
    mp.command("no-osd af remove @skiptosilence")

    local duration = mp.get_property_number("duration") or 0
    if timepos >= 0 and timepos <= duration then
        mp.set_property_number("time-pos", timepos)
    end

    if state.timer then
        state.timer:kill()
        state.timer = nil
    end

    state.skip_active = false
end

local function apply_skip_settings()
    mp.set_property_bool("sub-visibility", false)
    mp.set_property_bool("secondary-sub-visibility", false)
    mp.set_property("force-window", "yes")
    mp.set_property("vid", "no")
    mp.set_property_bool("pause", false)
    mp.set_property("speed", 100)

    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise="
        .. options.silence_audio_level
        .. "dB:d=" .. options.silence_duration .. "]"
    )

    mp.observe_property("af-metadata/skiptosilence", "string", handle_silence_detection)
end

local function chapter_title_matches(title)
    if not title then return false end
    for _, patterns in pairs(categories) do
        for pattern in patterns:gmatch("([^/]+)") do
            if title:find(pattern) then return true end
        end
    end
    return false
end

local function find_chapter_skip_target(current_time)
    local chapter_list = mp.get_property_native("chapter-list")
    if not chapter_list or #chapter_list == 0 then return nil end

    local n = #chapter_list
    local duration = mp.get_property_number("duration") or 0

    local function chapter_end(i)
        return chapter_list[i + 1] and chapter_list[i + 1].time or duration
    end

    for i = 1, n do
        local cstart = chapter_list[i].time
        local cend = chapter_end(i)
        -- Only match the chapter the user is currently inside.
        if current_time >= cstart and current_time < cend then
            if chapter_title_matches(chapter_list[i].title) then
                local last = i
                while last < n and chapter_title_matches(chapter_list[last + 1].title) do
                    last = last + 1
                end
                local target = chapter_end(last)
                msg.info(string.format("Chapter skip: '%s' [%.2fs -> %.2fs]",
                    chapter_list[i].title, chapter_list[i].time, target))
                return target
            end
            return nil
        end
    end
    return nil
end

handle_silence_detection = function(_, value)
    if not state.skip_active then return end
    if not value or value == "{}" then return end

    local timecode = tonumber(value:match("%d+%.?%d+"))
    if not timecode then return end

    if timecode < state.initial_skip_time + options.min_skip_lead then return end

    restore_state(timecode)
end

local function handle_pause_change(_, value)
    if value and state.skip_active then
        restore_state(state.initial_skip_time)
    end
end

local function trigger_silence_skip()
    if state.skip_active then return end

    local current_time = mp.get_property_number("time-pos") or 0
    local duration = mp.get_property_number("duration") or 0

    -- Do nothing if we're already at (or past) the last second.
    if duration > 0 and math.floor(current_time) >= math.floor(duration) - 1 then
        return
    end

    -- Chapter match: instant seek, no silence detection required.
    local target = find_chapter_skip_target(current_time)
    if target then
        mp.set_property_number("time-pos", target)
        return
    end

    -- If less time remains than the max scan window, just jump to 1s before
    -- the end so the file finishes naturally without triggering a scan.
    if duration > 0 and (duration - current_time) < options.max_skip_duration then
        mp.set_property_number("time-pos", duration - 1)
        return
    end

    -- Start silence-detection fast-forward.
    state.initial_skip_time = current_time
    state.skip_active = true

    lock_window_size()
    save_state()
    apply_skip_settings()

    state.timer = mp.add_periodic_timer(0.05, function()
        if not state.skip_active then return end
        local pos = mp.get_property_number("time-pos")
        if pos and (pos - state.initial_skip_time) >= options.max_skip_duration then
            restore_state(pos)
        end
    end)
end

local function on_end_file()
    if state.skip_active then
        restore_state(nil)
    end
    unlock_window_size()
end

local function on_file_loaded()
    if state.skip_active then
        restore_state(nil)
    end
    unlock_window_size()
end

mp.register_event("end-file", on_end_file)
mp.register_event("file-loaded", on_file_loaded)
mp.observe_property("pause", "bool", handle_pause_change)
mp.add_key_binding(options.skip_keybind, "silence-skip", trigger_silence_skip)
