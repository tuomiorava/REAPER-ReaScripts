-- @description DoomSquirrel_Zoom MIDI editor at mouse position to measures 16
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Zoom MIDI editor at mouse position to measures **_MEASURE VALUE_**
--   You can change the measure value by renaming this script.
--   The last number in the script name determines the measure value.
--
--   Adapted from a [script by juliansader](https://raw.githubusercontent.com/ReaTeam/ReaScripts/master/MIDI%20Editor/js_Zoom%20MIDI%20editor%20to%205%20measures%20at%20mouse%20position.lua).
--   All credit to him. I only added the option to set measures value via the script name.
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   Personal Website http://iki.fi/atolonen
-- @version 1.1
-- @changelog
--   Updated info

-- Get the name of the script and parse the last word as number (= MEASURES)
local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local MEASURES = tonumber(name:match("%d+$"))

-- Is SWS installed?
if not reaper.APIExists("BR_GetMouseCursorContext") then
    reaper.MB("This script requires the SWS/S&M extension, which adds all kinds of nifty features to REAPER.\n\nThe extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return
end

-- Is there an active MIDI editor?
editor = reaper.MIDIEditor_GetActive()
if editor == nil then return end

-- Checks OK, so start undo block
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

-- Store any pre-existing loop range
loopStart, loopEnd = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)

-- Is the mouse in the MIDI editor, or in the arrange view?
window, segment, details = reaper.BR_GetMouseCursorContext()

-- If the mouse is over a part of the interface that has position (arrange view, ruler or MIDI editor "notes" or "cc" area),
--    scroll to mouse position.  Otherwise, scroll to current edit position.
-- AFAIK it is not possible to get the mouse time position directly, without using the edit cursor
if window == "midi_editor" and segment ~= "unknown" then -- Is in MIDI editor?
    reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
elseif window == "arrange" or window == "ruler" then -- Is in arrange?
    reaper.Main_OnCommandEx(40513, -1, 0) -- Move edit cursor to mouse cursor (obey snapping)
-- else
--  don't move edit cursor, so will scroll to current edit cursor
end
mouseTimePos = reaper.GetCursorPositionEx(0)
beats, measures = reaper.TimeMap2_timeToBeats(0, mouseTimePos)

-- Zoom!
zoomStart = reaper.TimeMap2_beatsToTime(0, 0, measures-math.floor(MEASURES/2))
zoomEnd   = reaper.TimeMap2_beatsToTime(0, 0, measures+math.ceil(MEASURES/2))
reaper.GetSet_LoopTimeRange2(0, true, true, zoomStart, zoomEnd, false)
reaper.MIDIEditor_OnCommand(editor, 40726) -- Zoom to project loop selection

-- Reset the pre-existing loop range
reaper.GetSet_LoopTimeRange2(0, true, true, loopStart, loopEnd, false)

reaper.PreventUIRefresh(-1)
reaper.UpdateTimeline()
reaper.Undo_EndBlock2(0, "Zoom MIDI editor at mouse position to measures " .. MEASURES, -1)