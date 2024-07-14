-- @description DoomSquirrel_Hide & show windows
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Hide & show windows
--   Hides and shows windows. Does this by moving them ouside of the visible screen
--   ViewPort area (below bottom). Some VSTs are slow to open so this is a faster way of
--   getting them out of the way / bringing them back into view.
--
--   Optionally, If any windows are already hidden by this script (below bottom Viewport area),
--   shows all windows. Set with the CHECK_ANY_HIDDEN user setting.
--
--   # Requires
--   Requires JS_ReascriptAPI
--
--   **Default Hotkey:** Ctrl + F11
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

-- Check if any windows are hidden.
-- If any are hidden, shows all windows. Otherwise toggles the hide/show state of all windows
-- WARNING! Setting this to true can slow down the scripts execution significantly
CHECK_ANY_HIDDEN = false;

----------------------------
--- END OF USER SETTINGS ---
----------------------------

local function Msg(v)
  reaper.ShowConsoleMsg(tostring(v).."\n")
end

local isAnyHidden = false

local function titleMatch(hwnd)
  local title = reaper.JS_Window_GetTitle(hwnd)
  -- Limit the titles to match (otherwise "FX: " matches the performance view, for example)
  if ((title:match("FX: Track ") or title:match("FX: Item ") ) ) or
        title:match("VST") or
        title:match("FX: Master Track") or
        title:match("FX: Monitoring")
       then
    return true
  else
    return false
  end
end

local function isWindowHidden(hwnd)
  local _, left, top, right, bottom = reaper.JS_Window_GetRect(hwnd)
  local pos_x, pos_y, screen_w, screen_h = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
  
  if top > screen_h then 
      return true
  else
    return false
  end
end

local function isAnyWindowHidden(list)
  local hidden = false
  
  for address in list:gmatch("[^,]+") do
    local hwnd = reaper.JS_Window_HandleFromAddress(address)
    if titleMatch(hwnd) then
      if isWindowHidden(hwnd) then
        return true
      end
    end
  end
  
  return hidden
end

-- Toggle Window Hide
local function toggleWindowHide(hwnd)
  local _, left, top, right, bottom = reaper.JS_Window_GetRect(hwnd)
  local width = right - left
  local height = math.abs(bottom - top)
  local pos_x, pos_y, screen_w, screen_h = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
  
  -- If any are hidden, show all
  if isAnyHidden then
    if isWindowHidden(hwnd) then
      reaper.JS_Window_SetPosition( hwnd, left, (top - screen_h - height), width, height)
    end
  -- If nothing is hidden, toggle visibility
  else
    if isWindowHidden(hwnd) then
      reaper.JS_Window_SetPosition( hwnd, left, (top - screen_h - height), width, height)
    else
      reaper.JS_Window_SetPosition( hwnd, left, (top + screen_h + height), width, height)
    end
  end
end

local function toggleWindowListHide(list)
  for address in list:gmatch("[^,]+") do
    local hwnd = reaper.JS_Window_HandleFromAddress(address)
    if titleMatch(hwnd) then
      toggleWindowHide(hwnd)
    end
  end
end

-- Check if any windows are hidden?
if CHECK_ANY_HIDDEN then
  local number, list = reaper.JS_Window_ListFind("FX: ", false)
  if number > 0 then
    isAnyHidden = isAnyWindowHidden(list)
    if isAnyHidden == false then
      local number, list = reaper.JS_Window_ListFind("VST", false)
      if number > 0 then
        isAnyHidden = isAnyWindowHidden(list)
      end
    end
  end
end

-- Toggle visibility of FX Windows
local number, list = reaper.JS_Window_ListFind("FX: ", false)
if number > 0 then
    toggleWindowListHide(list)
end

--Toggle visibility of Floating FX Windows
local number, list = reaper.JS_Window_ListFind("VST", false)
if number > 0 then
  toggleWindowListHide(list)
end