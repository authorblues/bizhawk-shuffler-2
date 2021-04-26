--[[
	This plugin is designed for Sonic 1, 2, and 3 in a shuffle. This syncs the
	ring count across all three games. They have very similar RAM maps, so the
	addresses were the same for all three games, but if you needed to do different
	things for each game, you could check rom hashes with gameinfo.getromhash()
--]]

-- called once at the start
function on_setup(data)
end

-- called each time a game/state loads
function on_game_load(data)
	memory.usememorydomain("68K RAM")
	local gamestate = bit.band(memory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		memory.write_s16_be(0xFE20, data['rings'])
		memory.write_s8(0xFE1D, -1) -- triggers an update to the ring counter
	end
end

-- called each frame
function on_frame(data)
	memory.usememorydomain("68K RAM")
	local gamestate = bit.band(memory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		data['rings'] = memory.read_s16_be(0xFE20)
	end
end

-- called each time a game/state is saved (before swap)
function on_game_save(data)
	print('saving ' .. tostring(data['rings']) .. ' rings')
end

-- called each time a game is marked complete
function on_complete(data)
end
