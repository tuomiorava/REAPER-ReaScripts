-- @description DoomSquirrel_Toggle mute between selected tracks & track under mouse
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Adjusts the volume of track(s)
--   
--   You can set this script to **_adjust volume_** of specific track(s) by having it's 
--   **_TRACK_NAME_Q (trq)_** and/or **_VOL_ADJUST (vol)_** in the script's file name.
--   For Example, naming the script: _DoomSquirrel_Track volume  trq-voltrack vol0.5 .lua_ will
--   **_adjust volume_** of the track(s) whose name contains **_-voltrack_** by the value of 0.5.
--   This is useful for making multiple copies of this script, assigning each to specific
--   track **_trq_** matches and volume values.
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

-- Whether to operate on tracks matching NAME, SELECTED tracks, or the track under the MOUSE
OP_MODE = "MOUSE" -- "NAME", "SELECTED" or "MOUSE"

-- The track name qualifier (this should appear somewhere in the track name)
-- If nil, try to get it from the file name.
-- If this is set, OP_MODE will always be "NAME"
TRACK_NAME_Q = nil -- Default = "MASTER".

-- How much to adjust the volume
VOL_ADJUST = nil -- Default = "0.1".

----------------------------
--- END OF USER SETTINGS ---
----------------------------

function getParamsFromFileName()
  -- Get the name of the script
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

  for token in string.gmatch(name, "[^%s]+") do
    if (token:find("trq") ~= nil) then
      -- Get TRACK_NAME_Q from file name ONLY if it has not been specified in USER SETTINGS
      if (not TRACK_NAME_Q) then
        TRACK_NAME_Q = string.sub(token, 4)
      end
    elseif (token:find("vol") ~= nil) then
      -- Get VOL_ADJUST from file name ONLY if it has not been specified in USER SETTINGS
      if (not VOL_ADJUST) then
        VOL_ADJUST = tonumber(string.sub(token, 4))
      end
    end
  end
end

function doAdjustVolume(track)
  ok, vol, pan = reaper.GetTrackUIVolPan(track, 0, 0)
  local volAdj = vol+(VOL_ADJUST)

  if (volAdj < 0) then
    volAdj = 0 -- Avoid going under 0.0
  elseif (volAdj > 0.91 and volAdj < 1.09) then
    volAdj = 1 -- Snap to 1.0
  end

  reaper.SetMediaTrackInfo_Value(track, "D_VOL", volAdj)
end

function adjustVolume()
  if (not OP_MODE and TRACK_NAME_Q) then
    OP_MODE = "NAME"
  end

  if (OP_MODE == "MOUSE") then
    local mousetr = reaper.GetTrackFromPoint(reaper.GetMousePosition())

    if (mousetr) then
      doAdjustVolume(mousetr)
      local _, trName = reaper.GetTrackName(mousetr)
      TRACK_NAME_Q = trName
    end
  elseif (OP_MODE == "SELECTED") then
    local mastertr = reaper.GetMasterTrack(0)

    if (mastertr) then
      if (reaper.IsTrackSelected(mastertr)) then
        doAdjustVolume(mastertr)
        TRACK_NAME_Q = "MASTER"
      else
        for i = 0, reaper.CountTracks(0) do
          local tr = reaper.GetTrack(0, i)
          
          if (tr) then
            if (reaper.IsTrackSelected(tr)) then
              doAdjustVolume(tr)
              local _, trName = reaper.GetTrackName(tr)
              TRACK_NAME_Q = trName
            end
          end
        end
      end
    end
  elseif (OP_MODE == "NAME") then
    if (TRACK_NAME_Q == "MASTER") then
      local mastertr = reaper.GetMasterTrack(0)
      doAdjustVolume(mastertr)
    else
      for i = 0, reaper.CountTracks(0) do
        local tr = reaper.GetTrack(0, i)
        
        if (tr) then
          local _, trName = reaper.GetTrackName(tr)
          if (TRACK_NAME_Q and string.find(trName, TRACK_NAME_Q)) then
            doAdjustVolume(tr)
          end
        end
      end
    end
  end
end

reaper.Undo_BeginBlock()
-- Get params from file name, if not set in USER SETTINGS
if (not TRACK_NAME_Q or not VOL_ADJUST) then
    getParamsFromFileName()
end

adjustVolume()
reaper.Undo_EndBlock("Adjust track volume" .. " " .. OP_MODE .. (TRACK_NAME_Q and " \"" .. TRACK_NAME_Q .. "\""or "") .. (VOL_ADJUST and ", vol: " .. VOL_ADJUST or ""), -1)
