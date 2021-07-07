local plugin = {}

plugin.name = ""
plugin.author = ""
plugin.settings = {}

plugin.description =
[[
]]

-- called once at the start
function plugin.on_setup(data, settings)
end

-- called each time a game/state loads
function plugin.on_game_load(data, settings)
end

-- called each frame
function plugin.on_frame(data, settings)
end

-- called each time a game/state is saved (before swap)
function plugin.on_game_save(data, settings)
end

-- called each time a game is marked complete
function plugin.on_complete(data, settings)
end

return plugin
