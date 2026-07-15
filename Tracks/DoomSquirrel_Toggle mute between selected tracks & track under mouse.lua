-- @description DoomSquirrel_Toggle mute between selected tracks & track under mouse
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Toggle mute between selected tracks & track under mouse
--   Switches track mute states between the selected track(s) and the track under mouse.
--   Ensures that the selected track and the track under the mouse do not have
--   the same mute state - so that you can toggle which one you're hearing.
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--  My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.0
-- @changelog
--   Initial release

local muteSw = 1
local mousetr = reaper.GetTrackFromPoint(reaper.GetMousePosition())

if (mousetr) then
  _, mute = reaper.GetTrackUIMute(mousetr)
  muteSw = (mute and 0 or 1)
  reaper.SetTrackUIMute(mousetr, muteSw, 0)
end

for i = 0, reaper.CountTracks(0) do
  local tr = reaper.GetTrack(0, i)
  
  if (tr) then
    if (reaper.IsTrackSelected(tr)) then
      reaper.SetTrackUIMute(tr, (muteSw == 1 and 0 or 1), 0)
    end
  end
end

