--[[
	for all methods:
    `data` is a table to maintain state between swaps
    `gamename` is a string containing the filename (without path info) of the rom
--]]

-- called once at the start
function on_setup(data)
end

-- called each time a game/state loads
function on_game_load(gamename, data)
end

-- called each frame
function on_frame(gamename, data)
end

-- called each time a game/state is saved (before swap)
function on_game_save(gamename, data)
end

-- called each time a game is marked complete
function on_complete(gamename, data)
end
