-- @description DoomSquirrel_Performance Arm track for MIDI (under mouse)
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Performance Arm track for MIDI (under mouse)
--   **Performance Arm** means:
--   - Arms the selected track for recording, sets its monitoring, and sets its input.
--   - Unsets record arming, monitoring (and optionally sets the input to default) for the previously Performance Armed track(s).
--
--   Check USER SETTINGS for configuration options.
--
--   **Default Hotkey:** Ctrl + Shift + R
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

----------------------------
--- END OF USER SETTINGS ---
----------------------------

local mousetr = reaper.GetTrackFromPoint(reaper.GetMousePosition())
if (mousetr) then
  _, mouseTrName = reaper.GetTrackName(mousetr)
end

function performanceArmTrack()
  local trCount = reaper.CountTracks(0)

  for i = 0, trCount do
    local tr = reaper.GetTrack(0, i)

    if (tr) then
      local _, trName = reaper.GetTrackName(tr)

      if (trName == mouseTrName) then
        reaper.SetTrackUIRecArm(tr, 1, 0)
        reaper.SetTrackUIInputMonitor(tr, 2, 0)

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

performanceArmTrack()