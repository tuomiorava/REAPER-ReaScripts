-- @description DoomSquirrel_DRY / SEND comparison (mute toggle)
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # DRY / SEND comparison (mute toggle)
--   A script for A/B comparing sounds between the DRY track and SEND track(s).
--
--   Has 2 main operation modes (selectable with the OP_MODE User setting):
--     1. Compares between a SEND track **under mouse** and the DRY track
--     2. Compares between **selected** SEND track(s) and the DRY track
--
--   Switches track mute states between:
--     1. mutes DRY & mutes all SEND tracks except under mouse/selected
--     2. unmutes DRY & mutes all SEND tracks
--
--   If the SEND FOLDER is under mouse/selected, does not change the mute state of its child tracks.
--
--   Requires a dedicated DRY track (into which all instrument tracks are
--   routed before going to the master) named in the TRACK_DRY variable,
--   and that all aux send tracks are under a folder track named in FOLDER_SEND variable.
--
--   This script works by muting tracks, so it won't interfere with soloed instrument tracks.
--
--   _See the screenshot for an example of how this script is meant to be used._
--
--   **Default Hotkey:** ALT + The key left of 1
-- @screenshot https://raw.githubusercontent.com/tuomiorava/REAPER-ReaScripts/master/DEMO/DEMO_DoomSquirrel_DRY SEND comparison (mute toggle).gif
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.0
-- @changelog
--   Initial release

----------------------------
--- USER SETTINGS ----------
----------------------------

-- Whether to operate on SELECTED tracks, or the track under the MOUSE
OP_MODE = "MOUSE" -- "SELECTED" or "MOUSE"

-- TRACK_DRY The name of the DRY track
TRACK_DRY = "Audio w/o FX"

-- FOLDER_SEND The name of the folder containing the AUX SEND tracks
FOLDER_SEND = "(Sends)"

----------------------------
--- END OF USER SETTINGS ---
----------------------------

local function Msg(v)
  reaper.ShowConsoleMsg(tostring(v).."\n")
end

-- Is the given track a SEND or SEND FOLDER track
local function isSelectedTrackSend(tr)
  local _, trname = reaper.GetTrackName(tr)

  if (trname == FOLDER_SEND) then return true end

  local ptr = reaper.GetParentTrack(tr)
    if (ptr) then
      local _, ptrname = reaper.GetTrackName(ptr)
      if (ptrname == FOLDER_SEND) then return true end
    end
  return false
end

local muteSw = 1
local seltr = (OP_MODE == "MOUSE") and reaper.GetTrackFromPoint(reaper.GetMousePosition()) or reaper.GetSelectedTrack(0, 0)
if (seltr) then _, selname = reaper.GetTrackName(seltr) end

for i = 0, reaper.CountTracks(0) do
  local tr = reaper.GetTrack(0, i)
  
  if (tr) then
    local _, name = reaper.GetTrackName(tr)
    
    if (name == TRACK_DRY) then -- DRY
      _, mute = reaper.GetTrackUIMute(tr)
      muteSw = (mute and 0 or 1)
      reaper.SetTrackUIMute(tr, muteSw, 0)
      
    else
      if (seltr) then
        if (isSelectedTrackSend(seltr)) then -- Only operate on SEND tracks
          if (OP_MODE == "SELECTED") then  
            if (name == FOLDER_SEND) then -- SEND FOLDER selected
              if (reaper.IsTrackSelected(tr)) then
                reaper.SetTrackUIMute(tr, (muteSw == 1 and 0 or 1), 0)
                break
              end
            end
          elseif (OP_MODE == "MOUSE") then
            if (selname == FOLDER_SEND) then -- SEND FOLDER selected
              reaper.SetTrackUIMute(tr, (muteSw == 1 and 0 or 1), 0)
              break
            end
          end

          local ptr = reaper.GetParentTrack(tr)
    
          if (ptr) then -- Child AUX SEND tracks
            local _, ptrname = reaper.GetTrackName(ptr)
          
            if (ptrname == FOLDER_SEND) then
              reaper.SetTrackUIMute(ptr, (muteSw == 1 and 0 or 1), 0) -- SEND FOLDER mute status to follow selected child track
              
              local is_track_seld = false
              if (OP_MODE == "SELECTED") then 
                is_track_seld = reaper.IsTrackSelected(tr)
              elseif (OP_MODE == "MOUSE") then
                is_track_seld = (selname == name) and true or false
              end

              if (is_track_seld) then
                reaper.SetTrackUIMute(tr, (muteSw == 1 and 0 or 1), 0) -- Selected SEND FOLDER child track
              else
                -- Mute all other SENDs unless the parent track is selected
                if not(selname == FOLDER_SEND) then
                  reaper.SetTrackUIMute(tr, 1, 0)
                end
              end
            else
              break -- All sends are in the beginning of the track list, so can break after them
            end
          end -- Child AUX SEND tracks END
        end
    
      end
    
    end
  end
end