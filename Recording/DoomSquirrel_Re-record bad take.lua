-- @description DoomSquirrel_Re-record bad take
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Re-record bad take
--   Deletes last recording & re-records. This script is meant for quick re-recording of a take with just one hotkey.
--
--   ### Does 2 different things, depending on the play state:
--   #### If recording:
--   - Stops recording, deletes the recorded media, starts recording again.
--   #### If NOT recording:
--   - Deletes current take from item, starts recording again.
--
--   **Default Hotkey:** Backspace / F12
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   Personal Website http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.1
-- @changelog
--   Better handling of take deletion confirmation when not recording. Doesn't start recording, if previous take was not deleted. Improve retake behavior when playing by deleting active take, stopping playback, and starting recording.

local pstate = reaper.GetPlayState()

local playing   = (pstate & 1) ~= 0
local recording = (pstate & 4) ~= 0

if recording then
    -- Stop and delete recording
    reaper.Main_OnCommand(40668, 0)

    reaper.defer(function()
        reaper.Main_OnCommand(1013, 0)
    end)

elseif playing then
    -- Delete current take
    reaper.Main_OnCommand(40129, 0)

    -- Stop playback
    reaper.Main_OnCommand(1016, 0)

    -- Start recording
    reaper.defer(function()
        reaper.Main_OnCommand(1013, 0)
    end)

else
    local ret = reaper.ShowMessageBox(
        "Delete the current take and start recording?",
        "Confirm",
        4 -- Yes/No
    )

    if ret == 6 then
        reaper.Main_OnCommand(40129, 0)
        reaper.Main_OnCommand(1013, 0)
    end
end
