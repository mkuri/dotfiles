-- Bind f to maximize the window instead of entering macOS native fullscreen,
-- which moves mpv to its own Space. A script binding applies under any
-- --input-conf, so the yazi image opener picks it up too. Double-click still
-- toggles fullscreen.
mp.add_key_binding("f", "maximize-window", function()
  mp.command("cycle window-maximized")
end)
