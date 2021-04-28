--[[
	`data` is a table parameter passed to all methods
	this is where you should maintain your plugin's state

	helpful methods:
	- get_current_game() returns a string containing the filename (without path info) of the current loaded rom
	- gameinfo.getromhash() returns a hash of the current loaded file, for validating roms and checking versions
--]]

-- called once at the start
function on_setup(data)
end

-- called each time a game/state loads
function on_game_load(data)
end

-- called each frame
function on_frame(data)
end

-- called each time a game/state is saved (before swap)
function on_game_save(data)
end

-- called each time a game is marked complete
function on_complete(data)
end
