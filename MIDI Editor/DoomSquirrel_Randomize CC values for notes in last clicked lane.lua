-- @description DoomSquirrel_Randomize CC values for notes in last clicked lane
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Randomize CC values for notes in last clicked lane
--   Inserts/updates CC events with randomized values for notes in the last
--   clicked cc lane. Useful for adding slight variation to existing values.
--
--   Check USER SETTINGS for configuration options.
--
--   _See the screenshot for an example of how this script is meant to be used._
-- @screenshot https://raw.githubusercontent.com/tuomiorava/REAPER-ReaScripts/master/DEMO/DEMO_DoomSquirrel_Randomize CC values for notes in last clicked lane.gif
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

-- Select CHANMSG 176 to use normal CC values with CC Id defined in MSG2.
-- 176 = Control change (use MSG2 to give the CC Id)
-- 224 = Pitch bend
-- 208 = Channel aftertouch
-- 160 = Poly aftertouch
CHANMSG = nil --176

-- VAL_CENTER the center CC value to set (64 is center of value range).
VAL_CENTER = 64

-- VAL_MOD is the amount how much to randomize from the center CC value.
-- Will modulate to both positive and negative directions.
VAL_MOD = 16

-- USE_EXISTING_CC_VALUE determines whether to use the existing CC value.
-- false = use VAL_CENTER
USE_EXISTING_CC_VALUE = true;

-- NOTE_START_TOLERANCE How close to allow notes to be together when determining separate note starts
NOTE_START_TOLERANCE = 25

-- OVERWRITE_EXISTING_CC overwrite existing CC values that correspond to a note start.
OVERWRITE_EXISTING_CC = true

-- DELETE_NON_NOTE_CC delete all CC events that don't correspond to a note start.
DELETE_NON_NOTE_CC = true

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

-- Determine MSG2 & CHANMSG based on clicked lane
if CHANMSG == nil and MSG2 == nil then
  CHANMSG = 176
  MSG2 = 2
  
  local targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
--  Msg("targetLane:" .. targetLane)
  
  if targetLane == -1 then
      reaper.MB("Click on a CC lane to randomize its CC event values.", "ERROR", 0)
      return
  end
  
  -- Determine special values
--  if targetLane == -1 then targetLane = 0x200 end -- Nothing clicked = assume Bank/Program Select
--  if targetLane == 512 then CHANMSG = 224 end -- Velocity
  if targetLane == 513 then CHANMSG = 224 end -- Pitch Bend
  MSG2 = targetLane
end

if MSG2 == 512 then -- CC Events -  Velocity (Special case)
  for i = 0, notecnt-1 do -- Loop NOTES
    local midi_note, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    local val_base = VAL_CENTER
    
    if USE_EXISTING_CC_VALUE then
      val_base = vel > -1 and vel or VAL_CENTER
    end
    
    local cc_val = GetRandomCCValue(val_base)
    
    reaper.MIDI_SetNote(take, i, sel, muted, startppqpos, endppqpos, chan, pitch, cc_val)
  end

else -- CC Events -  Normal

  if DELETE_NON_NOTE_CC == true then -- CC = Delete all CC events that don't correspond to a note start.
    for ccidx = ccs-1, 0, -1 do
      cc_item, ccsel, ccmuted, ccstart, ccchanmsg, ccchan, ccmsg2, ccmsg3 = reaper.MIDI_GetCC(take, ccidx)
      local oktodel = true
      
      if (ccchanmsg == CHANMSG) then
        for i = 0, notecnt-1 do
          local midi_note, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
          if (math.abs(ccstart - startppqpos) < NOTE_START_TOLERANCE) then
            oktodel = false
            break
          end
        end
      else
         oktodel = false
      end
      
      if oktodel then
        reaper.MIDI_DeleteCC(take, ccidx)
      end
    end
  end -- END Delete CCs
  
  for i = 0, notecnt-1 do -- Gather all unique NOTE STARTS (and idx as values). This is to avoid adding multiple CC events too close to one note start.
    local midi_note, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    noteStarts[startppqpos] = i
  end -- END gather unique NOTE STARTS
  
  --for i = 0, notecnt-1 do -- Loop NOTES
  for k,i in pairs(noteStarts) do -- Loop gathered NOTE STARTS
    local midi_note, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    local val_base = VAL_CENTER
    
    local iscc = -1
    
    for ccidx = 0, ccs-1 do -- seek CC corresponding to note start
      cc_item, ccsel, ccmuted, ccstart, ccchanmsg, ccchan, ccmsg2, ccmsg3 = reaper.MIDI_GetCC(take, ccidx)
  
      if (ccchanmsg == CHANMSG) and (cc_item == true) and (math.abs(ccstart - startppqpos) < NOTE_START_TOLERANCE) then
  --      Msg("CC match: " .. ccidx .. " = " .. ccstart .. " / " .. startppqpos .. ", " .. ccchanmsg .. "/" .. CHANMSG .. " - " .. ccmsg2 .. "/" .. MSG2)
        
        iscc = ccidx
        if USE_EXISTING_CC_VALUE then
          val_base = ccmsg3 > -1 and ccmsg3 or VAL_CENTER
        end
        break
      end    
    end -- END seek CC corresponding to note start
    
    local cc_val = GetRandomCCValue(val_base)
    
    -- Update or insert CC
    if iscc > -1 then
      cc_item, ccsel, ccmuted, ccstart, ccchanmsg, ccchan, ccmsg2, ccmsg3 = reaper.MIDI_GetCC(take, iscc)
      if OVERWRITE_EXISTING_CC == true then
        --reaper.MIDI_SetCC(take, iscc, ccsel, ccmuted, ccstart, CHANMSG, ccchan, MSG2, cc_val, true)
        reaper.MIDI_SetCC(take, iscc, ccsel, ccmuted, ccstart, ccchanmsg, ccchan, ccmsg2, cc_val, true)
      end
    else
      reaper.MIDI_InsertCC(take, sel, muted, startppqpos, CHANMSG, chan, MSG2, cc_val)
    end
    
  end -- End loop NOTES / NOTE STARTS
  
end

reaper.UpdateArrange()