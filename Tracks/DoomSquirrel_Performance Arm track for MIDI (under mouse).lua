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
-- @version 1.5
-- @changelog
--   Better Scrolling (options to scroll track to view or scroll track to top in TCP / left in MCP)

----------------------------
--- USER SETTINGS ----------
----------------------------

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

local mousetr = reaper.GetTrackFromPoint(reaper.GetMousePosition())
if (mousetr) then
  _, mouseTrName = reaper.GetTrackName(mousetr)
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



function performanceArmTrack()
  local mcctx = reaper.BR_GetMouseCursorContext()
  local trCount = reaper.CountTracks(0)

  for i = 0, trCount do
    local tr = reaper.GetTrack(0, i)

    if (tr) then
      local _, trName = reaper.GetTrackName(tr)

      if (trName == mouseTrName) then
        reaper.SetTrackUIRecArm(tr, 1, 0)
        reaper.SetTrackUIInputMonitor(tr, RECMON_ACTIVE, 0)

        -- Set input if it wasn't already MIDI
        local i_RecInputVal = reaper.GetMediaTrackInfo_Value(tr, 'I_RECINPUT')
        if (i_RecInputVal < 4096) then
          reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', RECINPUT_ACTIVE )
        end

        if (TCP_SCROLL_TRACK_TO_VIEW and (TCP_ALWAYS_SCROLL_TO_TOP or not tcp_isTrackInView(tr)) and mcctx == "mcp") then
          tcp_scrollTrackToView(tr, TCP_ALWAYS_SCROLL_TO_TOP)
        end
        if (MCP_SCROLL_TRACK_TO_VIEW and (MCP_ALWAYS_SCROLL_TO_LEFT or not mcp_isTrackInView(tr)) and (mcctx == "tcp" or mcctx == "arrange")) then
          reaper.SetMixerScroll(tr)
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

reaper.Undo_BeginBlock()
performanceArmTrack()
reaper.Undo_EndBlock("Performance Arm track for MIDI (under mouse)", -1)