-- @description DoomSquirrel_Reset vertical zoom (TCP)
-- @author DoomSquirrel
-- @license GPL v3
-- @about
--   # Reset TCP vertical zoom
--   Reset vertical zoom of the TCP to the amount specified in the ZOOM_LEVEL variable
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--   My music = http://iki.fi/atolonen
-- @donation 
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A
-- @version 1.2
-- @changelog
--   Now uses command: 40110 (Action: "View: Toggle track zoom to minimum height") for zooming out.

----------------------------
--- USER SETTINGS ----------
----------------------------

ZOOM_LEVEL = 4; -- How many times to zoom in.

----------------------------
--- END OF USER SETTINGS ---
----------------------------

-- Zoom all the way out vertically
reaper.Main_OnCommand(40110, 0); -- Action: "View: Toggle track zoom to minimum height"

-- Zoom back in vertically
for i = 0, ZOOM_LEVEL-1 do
  reaper.Main_OnCommand(40111, 0); -- Action: "zoom in vertically"
end