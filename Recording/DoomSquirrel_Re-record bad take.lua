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
-- @version 1.0
-- @changelog
--   Initial release

local pstate = reaper.GetPlayState()

if (pstate == 5) then
  -- if recording

  -- Transport: Stop (DELETE all recorded media)
  reaper.Main_OnCommand(40668, 0)

  -- Transport: Record
  reaper.Main_OnCommand(1013, 0)
else
  -- if NOT recording

--  -- Take: Delete current take from items
--  reaper.Main_OnCommand(40129, 0)
  -- Take: Delete current take from items (prompt to confirm)
  reaper.Main_OnCommand(40130, 0)

  -- Transport: Record
  reaper.Main_OnCommand(1013, 0)
end