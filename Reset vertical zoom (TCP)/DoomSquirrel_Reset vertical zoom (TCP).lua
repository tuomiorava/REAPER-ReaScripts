-- @description DoomSquirrel_Reset vertical zoom (TCP)
-- @author DoomSquirrel
-- @version 1.0
-- @license GPL v3
-- @about
--   # Reset TCP vertical zoom
--   Reset vertical zoom of the TCP to the amount specified in the ZOOM_LEVEL variable
-- @repository
--   https://github.com/tuomiorava/REAPER-ReaScripts
-- @links
--  My music = http://iki.fi/atolonen
-- @donation 
--   Donate via PayPal https://www.paypal.com/donate/?hosted_button_id=2BEA2GHZMAW9A

-- @changelog
--   v1.0 (2024-06-20)
--   Initial release

----------------------------
--- USER SETTINGS ----------
----------------------------

ZOOM_LEVEL = 4; -- How many times to zoom in.
MAX_ZOOM_OUT_LEVEL = 40; -- High enough to zoom all the way out (current Reaper max is 40)

----------------------------
--- END OF USER SETTINGS ---
----------------------------

-- Zoom all the way out vertically
for i = 0, MAX_ZOOM_OUT_LEVEL-1 do
  reaper.Main_OnCommand(40112, 0); -- Action: "zoom out vertically"
end

-- Zoom back in vertically
for i = 0, ZOOM_LEVEL-1 do
  reaper.Main_OnCommand(40111, 0); -- Action: "zoom in vertically"
end