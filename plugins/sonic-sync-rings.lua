local plugin = {}

plugin.name = "Sonic Ring Sync"
plugin.author = "authorblues"
plugin.settings = {}

plugin.description =
[[
	This plugin is designed for Sonic 1, 2, and 3 in a shuffle. Ring counts should be synchronized across all three games.
]]

function plugin.on_game_load(data)
	local gamestate = bit.band(mainmemory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		mainmemory.write_s16_be(0xFE20, data['rings'])
		mainmemory.write_s8(0xFE1D, -1) -- triggers an update to the ring counter
	end
end

function plugin.on_frame(data)
	local gamestate = bit.band(mainmemory.readbyte(0xF600), 0x7F)
	if gamestate == 0x0C then
		data['rings'] = mainmemory.read_s16_be(0xFE20)
	end
end

return plugin
