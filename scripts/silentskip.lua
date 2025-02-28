-- silentskip.lua
--
-- Forked from skiptosilence.lua (github.com/dyphire/mpv-config)
-- Original authors: detuur, microraptor, Eisa01, dyphire
-- License: MIT
--
-- Fork by: xurdejl

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

--Configuration
local options = {
    -- Audio detection settings
    silence_audio_level = -40,         -- Audio level in dB that is considered silence
    silence_duration = 0.65,           -- Duration in seconds needed to detect silence
    ignore_silence_duration = 5,       -- Ignore silences in first X seconds from start position
    
    -- Skip duration limits
    min_skip_duration = 0,             -- Minimum skip duration (0 = no minimum)
    max_skip_duration = 120,           -- Maximum skip duration (0 = no maximum)
    
    -- User experience
    keybind_twice_cancel_skip = true,  -- Cancel skip by pressing keybind twice
    force_mute_on_skip = false,        -- Mute audio during skip
    osd_duration = 2500,               -- OSD message duration in ms
    osd_msg = false,                   -- Show OSD messages
    skip_feedback_on_success = true,   -- Show feedback message on successful skip
    silence_skip_keybind = "Tab",      -- Keybind to trigger skip to silence
}

-- State Variables
local state = {
    skip_active = false,
    initial_skip_time = 0,
    original = {
        speed = 1,
        pause = false,
        mute = false,
        sub = nil,
        secondary_sub = nil,
        vid = nil,
        window = nil
    },
    timer = nil
}

--Helper Functions
local function show_message(text, duration)
    if not text then return end
    duration = duration or options.osd_duration
    
    if options.osd_msg then 
        mp.commandv("show-text", text, duration) 
    end
    msg.info(text)
end

local function save_state()
    state.original.sub = mp.get_property("sub-visibility")
    state.original.secondary_sub = mp.get_property("secondary-sub-visibility")
    state.original.window = mp.get_property("force-window")
    state.original.vid = mp.get_property("vid")
    state.original.mute = mp.get_property_native("mute")
    state.original.pause = mp.get_property_native("pause")
    state.original.speed = mp.get_property_native("speed")
end

local function apply_skip_settings()
    mp.set_property("sub-visibility", "no")
    mp.set_property("secondary-sub-visibility", "no")
    mp.set_property("force-window", "yes")
    mp.set_property("vid", "no")
    
    if options.force_mute_on_skip then
        mp.set_property_bool("mute", true)
    end
    
    mp.set_property_bool("pause", false)
    mp.set_property("speed", 100)
    
    -- Setup the silencedetect filter
    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
        options.silence_audio_level .. "dB:d=" .. options.silence_duration .. "]"
    )
    
    mp.observe_property("af-metadata/skiptosilence", "string", handle_silence_detection)
end

local function restore_state(timepos, use_saved_pause_state)
    if not timepos then 
        timepos = mp.get_property_number("time-pos") or state.initial_skip_time
    end
    
    local pause_state = use_saved_pause_state and state.original.pause or false
    
    -- Restore all properties
    mp.set_property("vid", state.original.vid)
    mp.set_property("force-window", state.original.window)
    mp.set_property_bool("mute", state.original.mute)
    mp.set_property("speed", state.original.speed)
    mp.set_property("sub-visibility", state.original.sub)
    mp.set_property("secondary-sub-visibility", state.original.secondary_sub)
    
    -- Clean up filter and observers
    mp.unobserve_property(handle_silence_detection)
    mp.command("no-osd af remove @skiptosilence")
    
    mp.set_property_bool("pause", pause_state)
    
    -- Ensure time-pos is valid before setting
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

local function check_duration_limits(current_time)
    if not state.skip_active then return false end
    
    current_time = current_time or mp.get_property_number("time-pos") or 0
    local skip_duration = current_time - state.initial_skip_time
    
    -- Check minimum skip duration
    if options.min_skip_duration > 0 and skip_duration <= options.min_skip_duration then
        restore_state(state.initial_skip_time)
        show_message('Skip cancelled: Silence less than minimum duration')
        return true
    end
    
    -- Check maximum skip duration
    if options.max_skip_duration > 0 and skip_duration >= options.max_skip_duration then
        restore_state(state.initial_skip_time)
        show_message('Skip cancelled: Maximum skip duration reached')
        return true
    end
    
    return false
end

-- Main Functions
function trigger_silence_skip()
    -- If already skipping and double press cancels, restore and exit
    if state.skip_active and options.keybind_twice_cancel_skip then 
        restore_state(state.initial_skip_time)
        show_message('Skip cancelled by user')
        return 
    end
    
    state.initial_skip_time = mp.get_property_number("time-pos") or 0
    local duration = mp.get_property_number('duration') or 0
    
    -- Don't start skip if at the end of the file
    if duration > 0 and math.floor(state.initial_skip_time) >= math.floor(duration) - 1 then
        show_message('Cannot skip: Already at end of file')
        return
    end
    
    local is_fullscreen = mp.get_property_native("fullscreen")
    if not is_fullscreen then
        local width = mp.get_property_native("osd-width")
        local height = mp.get_property_native("osd-height")
        if width and height then
            mp.set_property_native("geometry", ("%dx%d"):format(width, height))
        end
    end
    
    save_state()
    
    apply_skip_settings()
    
    state.skip_active = true
    
    state.timer = mp.add_periodic_timer(0.5, function()
        if not state.skip_active then return end
        
        local video_time = mp.get_property_number("time-pos")
        if not video_time then return end
        
        check_duration_limits(video_time)
    end)
    
    show_message('Skipping to next silence...')
end

function handle_silence_detection(name, value)
    if not state.skip_active then return end
    if not value or value == "{}" then return end
    
    local timecode = tonumber(string.match(value, "%d+%.?%d+"))
    if not timecode then return end
    
    if timecode < state.initial_skip_time + options.ignore_silence_duration then
        return
    end
    
    if check_duration_limits(timecode) then return end
    
    restore_state(timecode)
    
    if options.skip_feedback_on_success then
        mp.add_timeout(0.05, function() 
            show_message('Skipped to silence 🕒 ' .. mp.get_property_osd("time-pos"))
        end)
    end
end

function handle_end_of_file(name, val)
    if val and state.skip_active then
        show_message('Skip cancelled: End of file reached')
        restore_state(state.initial_skip_time)
    end
end

function handle_pause_change(name, value)
    if value and state.skip_active then
        show_message('Skip cancelled: Playback paused')
        restore_state(state.initial_skip_time, true)
    end
end

function reset_on_file_load()
    local is_fullscreen = mp.get_property_native("fullscreen")
    if not is_fullscreen then
        mp.set_property("geometry", "")
    end

    if state.skip_active then
        show_message('Skip cancelled: New file loaded')
        restore_state(0)
    end
end

-- Event Registration
mp.register_event('file-loaded', reset_on_file_load)

mp.observe_property('pause', 'bool', handle_pause_change)

mp.observe_property('eof-reached', 'bool', handle_end_of_file)

mp.add_key_binding(options.silence_skip_keybind, "silence-skip", trigger_silence_skip)
