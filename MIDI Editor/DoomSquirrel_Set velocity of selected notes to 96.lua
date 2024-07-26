-- @description DoomSquirrel_Set velocity of selected notes to 96
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Set velocity of selected notes to 96 **_VELOCITY VALUE_**
--   You can change the velocity to set the notes to by renaming this script.
--   The last number in the script name determines the velocity value.
--
--   Valid velocity values are between 1-127.
--   Anything outside of this will be corrected to the closest valid value.
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   Personal Website http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.1
-- @changelog
--   Updated info

-- Get the name of the script and parse the last word as number (= VELOCITY)
local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local VELOCITY = tonumber(name:match("%d+$"))

local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
local _, notecnt = reaper.MIDI_CountEvts(take)

for i = 0, notecnt + 1 do
  local midi_note, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

  if sel then -- If note is selected
    local VELOCITY = VELOCITY < 1 and 1 or VELOCITY > 127 and 127 or VELOCITY -- Limit values to the standard range
    reaper.MIDI_SetNote(take, i, sel, muted, startppqpos, endppqpos, chan, pitch, VELOCITY)
  end
end

reaper.UpdateArrange()