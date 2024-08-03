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
--   for example: _Numeric Keys 1-9_ or _Function Keys F1-F12_.
--   Then, when you press the hotkey, it **_Performance Arms_** a track based on the sequential order of those tracks,
--   and **_un-Performance Arms_** other tracks.
--
--   Optionally, checks which tracks contain an instrument, and if the name of the track contains a string when
--   determining which tracks are allowed to be **_Performance Armed_**.
--
--   ## Examples:
--   - If **_CHECK_INSTR = false_** and **_TRACK_NAME_Q = nil_**,
--     pressing keys 1-9 will **_Performance Arm_** the track whose order number corresponds to the pressed key.
--     It won't matter if any tracks contain instruments, or what the track names are.
--   - If **_CHECK_INSTR = true_** and **_TRACK_NAME_Q = nil_**.
--     If you have 4 tracks, with tracks 2 & 4 containing instruments.
--     Pressing 1 will **_Performance Arm_** track 2, and pressing 2 will **_Performance Arm_** track 4.
--     It won't matter what the track names are.
--   - If **_CHECK_INSTR = false_** and **_TRACK_NAME_Q = "perf"_**.
--     If you have tracks 2 & 3 named "Instrument 1-perf" and "Instrument 2-perf" respectively.
--     Pressing 1 will **_Performance Arm_** track 2, and pressing 2 will **_Performance Arm_** track 3.
--     It won't matter if any tracks contain instruments.
--   - If **_CHECK_INSTR = true_** and **_TRACK_NAME_Q = "perf"_**.
--     If you have 4 tracks, with tracks 2, 3 & 4 containing instruments,
--     and with tracks 3 & 4 named "Instrument 1-perf" and "Instrument 2-perf" respectively.
--     Pressing 1 will **_Performance Arm_** track 3, and pressing 2 will **_Performance Arm_** track 4.
--
--   You can set this script to **_Performance Arm_** a specific track by having it's **_SELECTED_IDX (idx)_**
--   and/or **_TRACK_NAME_Q (trq)_** in the script's file name.
--   For Example, naming the script: _DoomSquirrel_Performance Arm track for MIDI (sequential) idx2 trq-perf.lua_ will
--   **_Performance Arm_** the second track (that has an instrument, if **_CHECK_INSTR = true_**)
--   and whose name contains **_-perf_**. This is useful for making multiple copies of this script,
--   assigning each to specific track **_idx_** and **_trq_** matches, and setting the hotkeys for each script to be a different MIDI note.
--
--   Check USER SETTINGS for configuration options.
--
--   For advanced modification of this script, you can customize the accepted key ranges in the **_getIdxByKey()_** function.
--   Virtual-Key Codes reference: https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
--
--   **Default Hotkey:** Numeric Keys 1-9 / Function Keys F1-F12
-- @screenshot https://raw.githubusercontent.com/tuomiorava/REAPER-ReaScripts/master/DEMO/DEMO_DoomSquirrel_Performance Arm track for MIDI (sequential).gif
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 2.4
-- @changelog
--   Added functionality to get SELECTED_IDX (idx) and TRACK_NAME_Q (trq) from file name

----------------------------
--- USER SETTINGS ----------
----------------------------

-- The selected track idx (order number amongst all instrument tracks)
-- If nil, gets the idx from the file name / pressed hotkey
SELECTED_IDX = nil

-- Check if the track contains instrument(s)
-- If false, don't require the track to have instrument(s)
CHECK_INSTR = true

-- The track name qualifier (this should appear somewhere in the track name)
-- If nil (and not specified in the file name), don't check if track name contains this
-- If nil, try to get it from the file name.
TRACK_NAME_Q = nil -- Default = "perf".

-- The input to set when Performance Arming a track
RECINPUT_ACTIVE = 4096+0x7E0 -- Default = 4096+0x7E0: MIDI Keyboard: All Channels
-- The input to set when un-Performance Arming previously active track
RECINPUT_DEFAULT = nil -- Default = nil, 0: Input:Mono / In 1

-- The record monitoring to set when Performance Arming a track
RECMON_ACTIVE = 1 -- Default = 1: On

-- Whether to scroll the Performance Armed track into view
TCP_SCROLL_TRACK_TO_VIEW = true -- For Track Control Panel
TCP_ALWAYS_SCROLL_TO_TOP = false -- If true, always scrolls the Performance Armed track to the top of the arrange view. If false: only scrolls when the track is out of view
MCP_SCROLL_TRACK_TO_VIEW = true -- For Mixer Control Panel
MCP_ALWAYS_SCROLL_TO_LEFT = false -- If true, always scrolls the Performance Armed track to the left of the mixer view. If false: only scrolls when the track is out of view

----------------------------
--- END OF USER SETTINGS ---
----------------------------

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

function getClientWidth(hwnd)
  local _, l, t, r, b = reaper.JS_Window_GetClientRect(hwnd)
  return r-l
end

function getClientHeight(hwnd)
  local _, l, t, r, b = reaper.JS_Window_GetClientRect(hwnd)
  return b-t
end

function tcp_isTrackInView(track)
  local arrangeHWND = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8)
  local arrange_height = getClientHeight(arrangeHWND)
  local track_tcpy = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
  local track_wndh = reaper.GetMediaTrackInfo_Value(track, "I_WNDH")

  if (track_tcpy > 0 and (track_tcpy + track_wndh < arrange_height)) then
    return true
  else
    return false
  end
end

function mcp_isTrackInView(track)
  local mixerHWND, _ = reaper.BR_Win32_GetMixerHwnd()
  if (not mixerHWND) then
    return false
  end

  -- Deduct Master track width from available mixer width
  mtr_mcpw = 0
  local mtrvis = reaper.GetMasterTrackVisibility()

  if (mtrvis ~= 2) then
    mtr_mcpw = reaper.GetMediaTrackInfo_Value(reaper.GetMasterTrack(0), "I_MCPW")
  end

  local track_mcpx = reaper.GetMediaTrackInfo_Value(track, "I_MCPX")
  local track_mcpw = reaper.GetMediaTrackInfo_Value(track, "I_MCPW")
  local mixer_width = getClientWidth(mixerHWND)

  if (track_mcpx > 0 and (track_mcpx + track_mcpw < (mixer_width - mtr_mcpw))) then
    return true
  else
    return false
  end
end

function tcp_scrollTrackToView(track, scrollToTop)
  reaper.PreventUIRefresh(1)

  local arrangeHWND = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8)
  local _, scroll_pos = reaper.JS_Window_GetScrollInfo(arrangeHWND, "v")
  local track_tcpy = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")

  if (scrollToTop) then
    -- Scroll track to top
    reaper.JS_Window_SetScrollPos(arrangeHWND, "v", scroll_pos + track_tcpy)
  else
    -- scroll track to view (To bottom, if below bottom. To top, if above top)
    local track_wndh = reaper.GetMediaTrackInfo_Value(track, "I_WNDH")
    local arrange_height = getClientHeight(arrangeHWND)

    if (track_tcpy + track_wndh >= arrange_height) then
      reaper.JS_Window_SetScrollPos(arrangeHWND, "v", scroll_pos + track_tcpy + track_wndh - arrange_height)
    else
      reaper.JS_Window_SetScrollPos(arrangeHWND, "v", scroll_pos + track_tcpy)
    end
  end

  reaper.PreventUIRefresh(-1)
end

function getParamsFromFileName()
  -- Get the name of the script
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

  for token in string.gmatch(name, "[^%s]+") do
    if (token:find("idx") ~= nil) then
      -- Get SELECTED_IDX from file name ONLY if it has not been specified in USER SETTINGS
      if (not SELECTED_IDX) then
        SELECTED_IDX = tonumber(string.sub(token, 4))
      end
    elseif (token:find("trq") ~= nil) then
      -- Get TRACK_NAME_Q from file name ONLY if it has not been specified in USER SETTINGS
      if (not TRACK_NAME_Q) then
        TRACK_NAME_Q = string.sub(token, 4)
      end
      -- When getting TRACK_NAME_Q from file name, set SELECTED_IDX to 1 if it is not already set
      if (not SELECTED_IDX) then
        SELECTED_IDX = 1
      end
    end
  end
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
      local _, trName = reaper.GetTrackName(tr)
      local hasInst = false

      -- Whether to check if the track has instruments
      if (CHECK_INSTR) then
        hasInst = HasInstrument(tr)
      else
        hasInst = true;
      end

      if (hasInst and (not TRACK_NAME_Q or string.find(trName, TRACK_NAME_Q))) then
        tr_match_i = tr_match_i + 1
      end

      if (hasInst and tr_match_i == selIdx and (not TRACK_NAME_Q or string.find(trName, TRACK_NAME_Q))) then
        local i_RecArmVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM')
        local i_RecMonVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECMON')
        if (i_RecArmVal == 1 and (i_RecMonVal == 1 or i_RecMonVal == 2)) then
          doUnPerformanceArmTrack(tr)
        else
          unPerformanceArmTracks()
          doPerformanceArmTrack(tr)
        end

        return
      end
    end
  end
end

function doPerformanceArmTrack(track)
  reaper.SetTrackUIRecArm(track, 1, 0)
  reaper.SetTrackUIInputMonitor(track, RECMON_ACTIVE, 0)

  -- Set input if it wasn't already MIDI
  local i_RecInputVal = reaper.GetMediaTrackInfo_Value(track, 'I_RECINPUT')
  if (i_RecInputVal < 4096) then
    reaper.SetMediaTrackInfo_Value(track, 'I_RECINPUT', RECINPUT_ACTIVE )
  end

  if (TCP_SCROLL_TRACK_TO_VIEW and (TCP_ALWAYS_SCROLL_TO_TOP or not tcp_isTrackInView(track))) then
    tcp_scrollTrackToView(track, TCP_ALWAYS_SCROLL_TO_TOP)
  end
  if (MCP_SCROLL_TRACK_TO_VIEW and (MCP_ALWAYS_SCROLL_TO_LEFT or not mcp_isTrackInView(track))) then
    reaper.SetMixerScroll(track)
  end
end

function unPerformanceArmTracks()
  --reaper.ClearAllRecArmed()

  local trCount = reaper.CountTracks(0)

  for i = 0, trCount do
    local tr = reaper.GetTrack(0, i)

    if (tr) then
      doUnPerformanceArmTrack(tr)
    end
  end
end

function doUnPerformanceArmTrack(track)
  local i_RecArmVal = reaper.GetMediaTrackInfo_Value(track, 'I_RECARM')
  local i_RecMonVal = reaper.GetMediaTrackInfo_Value(track, 'I_RECMON')

  if (i_RecArmVal == 1) then
    -- If track was Performance Armed (and wasn't MIDI), and RECINPUT_DEFAULT is set
    -- set input to default
    local i_RecInputVal = reaper.GetMediaTrackInfo_Value(track, 'I_RECINPUT')
    if (RECINPUT_DEFAULT and i_RecInputVal < 4096
      and (i_RecMonVal == 1 or i_RecMonVal == 2)) then
      reaper.SetMediaTrackInfo_Value(track, 'I_RECINPUT', RECINPUT_DEFAULT)
    end

    reaper.SetTrackUIRecArm(track, 0, 0)
    reaper.SetTrackUIInputMonitor(track, 0, 0)
  end
end

reaper.Undo_BeginBlock()
-- Get params from file name, if not set in USER SETTINGS
if (not SELECTED_IDX and not TRACK_NAME_Q) then
    getParamsFromFileName()
end
-- Get param from pressed hotkey, if not already set
if (not SELECTED_IDX) then
  getIdxByKey()
end

performanceArmTrack(SELECTED_IDX)
reaper.Undo_EndBlock("Performance Arm track for MIDI (sequential)", -1)