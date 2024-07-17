-- @description DoomSquirrel_Open item in MIDI Editor with default zoom level
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Open item in MIDI Editor with default zoom level
--   Opens the selected media item in the MIDI Editor with a default zoom level.
--
--   Has 2 main operation modes (selectable with the OP_MODE User setting):
--     1. Zoom to a DEFAULT level
--     2. Zoom to show all CONTENT of the media item
--
--   If the selected media item is not MIDI, runs a command defined in the
--   NON_MIDI_ITEM_ACTION User setting
--   (default: "40009" -- Action: "Show media Item/take properties...").
--   You can change this command to whatever you like.
--
--   If you want to use this as the default behaviour when double clicking a media item,
--   set it in the Preferences:
--   _**Options > Preferences > Mouse Modifiers > Media Item > double click > Default Action >
--   Action list... > DoomSquirrel_Open item in midi editor with default zoom level.lua**_
--
--   **Default Hotkey:** Alt + Shift + M
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   My music = http://iki.fi/atolonen
-- @donation
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.1
-- @changelog
--   + Added NON_MIDI_ITEM_ACTION

----------------------------
--- USER SETTINGS ----------
----------------------------

-- Whether to zoom to content (show all item midi notes vertically) or use default
OP_MODE = "" -- "CONTENT" or ""

DEFAULT_ZOOM_LEVEL = 10; -- The default zoom level (how many times to zoom in after zooming all the way out)
MAX_ZOOM_OUT = 96; -- The amount to zoom out, before zooming in (96 is the current Reaper maximum to zoom all the way out)

NON_MIDI_ITEM_ACTION = "40009"; -- Action: "Show media Item/take properties..."

----------------------------
--- END OF USER SETTINGS ---
----------------------------

local item = reaper.GetSelectedMediaItem(0, 0)
local take = reaper.GetActiveTake(item)

if (reaper.TakeIsMIDI(take)) then
  reaper.Main_OnCommand(40153, 0); -- Action: "Open in built-in MIDI editor"

  local editor = reaper.MIDIEditor_GetActive()
  reaper.MIDIEditor_OnCommand(editor, 40468); -- Action: MIDI Editor "Zoom to one loop iteration"

  if (OP_MODE == "CONTENT") then
    reaper.MIDIEditor_OnCommand(editor, 40466); -- Action: MIDI Editor "Zoom to content"
  else
    -- Zoom all the way out vertically
    for i = 0, MAX_ZOOM_OUT-1 do
      reaper.MIDIEditor_OnCommand(editor, 40112, 0); -- Action: MIDI Editor "zoom out vertically"
    end

    -- Zoom back in vertically
    for i = 0, DEFAULT_ZOOM_LEVEL-1 do
      reaper.MIDIEditor_OnCommand(editor, 40111, 0); -- Action: MIDI Editor "zoom in vertically"
    end
  end
else
  reaper.Main_OnCommand(NON_MIDI_ITEM_ACTION, 0);
end