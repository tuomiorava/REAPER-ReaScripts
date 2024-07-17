-- @description DoomSquirrel_Performance Arm track for MIDI (sequential)
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Performance Arm track for MIDI (sequential)
--   **Performance Arm** means:
--   - Arms the selected track for recording, sets its monitoring, and sets its input.
--   - Unsets record arming, monitoring (and optionally sets the input to default) for the previously Performance Armed track(s).
--
--   The intended use for this action is to assign sequential hotkey ranges to it,
--   for example: _Numeric Keys 1-0_ or _Function Keys F1-F12_.
--   Then, when you press the hotkey, it **_Performance Arms_** a track containing an instrument
--   based on the sequential order of those tracks, disregarding other tracks.
--
--   So, if you have 4 tracks, with tracks 2 & 4 containing instruments,
--   pressing 1 will Performance Arm track 2, and pressing 2 will Performance Arm track 4.
--
--   Check USER SETTINGS for configuration options.
--
--   For advanced modification of this script, you can customize the accepted key ranges in the **_getIdxByKey()_** function.
--   Virtual-Key Codes reference: https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
--
--   **Default Hotkey:** Numeric Keys 1-0 / Function Keys F1-F12
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.2
-- @changelog
--   Updated packaging documentation

----------------------------
--- USER SETTINGS ----------
----------------------------

-- The input to set when Performance Arming a track
RECINPUT_ACTIVE = 4096+0x7E0 -- Default = 4096+0x7E0: MIDI Keyboard: All Channels
-- The input to set when un-Performance Arming previously active track
RECINPUT_DEFAULT = nil -- Default = nil, 0: Input:Mono / In 1

-- The record monitoring to set when Performance Arming a track
RECMON_ACTIVE = 1 -- Default = 1: On

-- The selected track idx (order number amongst all instrument tracks)
SELECTED_IDX = nil -- When nil, gets the idx from the pressed hotkey

----------------------------
--- END OF USER SETTINGS ---
----------------------------

local function Msg(v)
  reaper.ShowConsoleMsg(tostring(v).."\n")
end

function IsInstrument(track, fx)
  local fx_instr = reaper.TrackFX_GetInstrument(track)
  return fx_instr >= fx
end

function HasInstrument(track)
 for tr_i = 1, reaper.TrackFX_GetCount(track) do
    local retval, buf = reaper.TrackFX_GetFXName(track, tr_i-1, '' )
    if IsInstrument(track, tr_i-1) or buf:match('Reaticulate') then
      return true
    end
  end

  return false
end

function getIdxByKey()
-- Note: Shortcut scope must be set to Normal or keys will not be detected!
  local state = reaper.JS_VKeys_GetState(0)
  for i = 48, 255 do
    if state:byte(i) == 1 then
      if (i ~= 91) then -- Disregard Win key
        -- Numeric keys
        if (i > 47 and i < 58) then
          SELECTED_IDX = i-48
          break
        end
        -- Numeric keypad keys
        if (i > 95 and i < 106) then
          SELECTED_IDX = i-96
          break
        end
        -- Function keys
        if (i > 111 and i < 136) then
          SELECTED_IDX = i-111
          break
        end
      end
    end
  end
end

function performanceArmTrack(selIdx)
  local tr_match_i = 0
  local trCount = reaper.CountTracks(0)

  if (not selIdx or selIdx < 1 or selIdx > trCount) then
    return
  end

  for i = 0, trCount do
    local tr = reaper.GetTrack(0, i)

    if (tr) then
      local hasInst = HasInstrument(tr)

      if (hasInst) then
        tr_match_i = tr_match_i + 1
      end

      if (hasInst and tr_match_i == selIdx) then
        reaper.SetTrackUIRecArm(tr, 1, 0)
        reaper.SetTrackUIInputMonitor(tr, RECMON_ACTIVE, 0)

        -- Set input if it wasn't already MIDI
        local i_RecInputVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECINPUT')
        if (i_RecInputVal < 4096) then
          reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', RECINPUT_ACTIVE )
        end
      else
        local i_RecArmVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM')
        local i_RecMonVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECMON')

        if (i_RecArmVal == 1) then
          -- If track was Performance Armed (and wasn't MIDI), and RECINPUT_DEFAULT is set
          -- set input to default
          local i_RecInputVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECINPUT')
          if (RECINPUT_DEFAULT and i_RecInputVal < 4096
            and (i_RecMonVal == 1 or i_RecMonVal == 2)) then
            reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', RECINPUT_DEFAULT)
          end

          reaper.SetTrackUIRecArm(tr, 0, 0)
          reaper.SetTrackUIInputMonitor(tr, 0, 0)
        end
      end
    end
  end
end

if (not SELECTED_IDX) then
  getIdxByKey()
end

performanceArmTrack(SELECTED_IDX)