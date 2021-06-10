--[[
	This plugin is designed for Sonic 1, 2, and 3 in a shuffle. This syncs the
	ring count across all three games. They have very similar RAM maps, so the
	addresses were the same for all three games, but if you needed to do different
	things for each game, you could check rom hashes with gameinfo.getromhash()
--]]

local plugin = {}

plugin.name = "Sonic Ring Sync"
plugin.author = "authorblues"
plugin.settings = {}

-- called once at the start
function plugin.on_setup(data)
end

-- called each time a game/state loads
function plugin.on_game_load(data)
	local gamestate = bit.band(mainmemory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		mainmemory.write_s16_be(0xFE20, data['rings'])
		mainmemory.write_s8(0xFE1D, -1) -- triggers an update to the ring counter
	end
end

-- called each frame
function plugin.on_frame(data)
	local gamestate = bit.band(mainmemory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		data['rings'] = mainmemory.read_s16_be(0xFE20)
	end
end

-- called each time a game/state is saved (before swap)
function plugin.on_game_save(data)
	print('saving ' .. tostring(data['rings']) .. ' rings')
end

-- called each time a game is marked complete
function plugin.on_complete(data)
end

return plugin
