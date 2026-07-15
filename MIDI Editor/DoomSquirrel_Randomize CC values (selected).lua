-- @description DoomSquirrel_Randomize CC values (selected)
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Randomize CC values. Only affects selected CC values.
--   Useful for adding slight variation to existing values.
--
--   Check USER SETTINGS for configuration options.
--
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--  My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.0
-- @changelog
--   Initial release

----------------------------
--- USER SETTINGS ----------
----------------------------

-- The CC to use. If MSG2 & CHANMSG are nil = use the values determined by last clicked lane.
MSG2 = nil --2 --Only used with CHANMSG = 176

-- VAL_CENTER the center CC value to set (64 is center of value range).
VAL_CENTER = 64

-- VAL_MOD is the amount how much to randomize from the center CC value.
-- Will modulate to both positive and negative directions.
VAL_MOD = 16

-- USE_EXISTING_CC_VALUE determines whether to use the existing CC value.
-- false = use VAL_CENTER
USE_EXISTING_CC_VALUE = true;

----------------------------
--- END OF USER SETTINGS ---
----------------------------

math.randomseed(os.time())

local noteStarts = {}
local prev_val = VAL_CENTER

local editor = reaper.MIDIEditor_GetActive()
local take = reaper.MIDIEditor_GetTake(editor)
local retval, notecnt, ccs, sysext = reaper.MIDI_CountEvts(take) -- Count MIDI notes, ccs

local function Msg(v)
  reaper.ShowConsoleMsg(tostring(v).."\n")
end

function GetRandomCCValue(val_base)
  -- avoid repeating values that are too similar (relative fraction of VAL_MOD)
  local cc_val = prev_val
  while math.abs(cc_val - prev_val) < (VAL_MOD / 5) do
    cc_val = math.random(val_base - (VAL_MOD/2), val_base + (VAL_MOD/2))
  end
  cc_val = cc_val < 1 and 1 or cc_val > 127 and 127 or cc_val -- trim values to the standard range
  prev_val = cc_val -- store prev value
  
  return cc_val
end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)
for ccidx = 0, ccs-1 do
    local retval, ccsel, ccmuted, ppqpos, chanmsg, chan, msg2, msg3 =
        reaper.MIDI_GetCC(take, ccidx)

    if ccsel then
        local val_base = USE_EXISTING_CC_VALUE and msg3 or VAL_CENTER
        local cc_val = GetRandomCCValue(val_base)

        reaper.MIDI_SetCC(
            take,
            ccidx,
            ccsel,
            ccmuted,
            ppqpos,
            chanmsg,
            chan,
            msg2,
            cc_val,
            true
        )
    end
end

reaper.MIDI_Sort(take)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Randomize CC values (selected)", -1)
