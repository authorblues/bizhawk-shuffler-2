--[[
	SOLO ZOOTR MULTIWORLD
	Written by authorblues, with significant help from TestRunner

	Create a multiworld randomizer seed and generate roms for all players.
	Put them all in the games/ folder, and the plugin will shuffle like normal,
	sending items between seeds when necessary.

	Special Thanks:
	WizzrobeZC for the initial suggestion
	SpikeVegeta for streaming ZOOTR shuffler and making everybody
		say "it would be cool if they shared items"
	You for reading the source code of a plugin I wrote :^)
--]]

local plugin = {}

plugin.name = "Solo ZOOTR Multiworld"
plugin.settings =
{

}

local rando_context
local coop_context = -1
local player_num = -1

local incoming_player_addr
local incoming_item_addr
local outgoing_key_addr
local outgoing_item_addr
local outgoing_player_addr
local player_names_addr

local save_context = 0x11A5D0
local internal_count_addr = save_context + 0x90

local SCRIPT_PROTOCOL_VERSION = 2

local function get_name(id)
	if player_num == id then
		return 0xC3D3D9DF, 0xDFDFDFDF -- You
	end
	--[[
		return 0xC1D3D6D0, 0xC8000000 -- World255
		return 0xBDC9C9C8, 0xDF000000 -- Seed 255
		return 0xB6CDD2CF, 0xDF000000 -- Link 255
	--]]
	return 0xBDD3D1C9, 0xD3D2C9DF -- Someone
end

local function fill_name(id)
	local name_address = player_names_addr + (id * 8)
	local name1, name2 = get_name(id)
	mainmemory.write_u32_be(name_address + 0, name1)
	mainmemory.write_u32_be(name_address + 4, name2)
end

local function try_fill_names()
	-- fill all the name entries with some data if it hasn't already been done
	if mainmemory.read_u32_be(player_names_addr + player_num * 8) ~= 0xC3D3D9DF then
		for i = 0, 255 do fill_name(i) end
	end
end

local function try_setup(data)
    rando_context = mainmemory.read_u32_be(0x1C6E90 + 0x15D4) - 0x80000000
    if rando_context < 0 then return false end
    coop_context = mainmemory.read_u32_be(rando_context + 0x0000) - 0x80000000
	if coop_context < 0 then return false end

    -- check protocol version
    local rom_protocol_version = mainmemory.read_u32_be(coop_context)
    if rom_protocol_version ~= SCRIPT_PROTOCOL_VERSION then
        print('This ROM is incompatible with this version of the plugin.')
        print('Expected protocol version: '..tostring(SCRIPT_PROTOCOL_VERSION))
        print('ROM protocol version: '..tostring(rom_protocol_version))
    end

	incoming_player_addr  = coop_context + 6
	incoming_item_addr    = coop_context + 8
	outgoing_key_addr     = coop_context + 12
	outgoing_item_addr    = coop_context + 16
	outgoing_player_addr  = coop_context + 18
	player_names_addr     = coop_context + 20

	-- get player num and setup your itemqueue
	player_num = mainmemory.read_u8(coop_context + 4)
	data.itemqueues[player_num] = data.itemqueues[player_num] or {}

    return true
end

function plugin.on_setup(data, settings)
	data.itemqueues = data.itemqueues or {}

	-- this setting is crucially important! without it, loading states will crash
	local warning = 'You must enable "Use Expansion Slot" under Bizhawk\'s N64 menu!'
	for i = 1,5 do print(warning) end
	--gui.pixelText(5, 5, warning)
end

function plugin.on_game_load(data, settings)
end

function plugin.on_frame(data, settings)
	local key, item, player

    -- attempt a setup if not already setup, quit if fails
	if player_num == -1 then
        if not try_setup(data) then return end
    end

	-- attempt to fill names every frame (check to see if it's already done first)
	-- (I wish I didn't have to do this so often, but a soft reset loses the names)
	try_fill_names()

	-- check if an item needs to be sent
	key = mainmemory.read_u32_be(outgoing_key_addr)
	if key ~= 0 then
		item = mainmemory.read_u16_be(outgoing_item_addr)
		player = mainmemory.read_u16_be(outgoing_player_addr)

		data.itemqueues[player] = data.itemqueues[player] or {}
		table.insert(data.itemqueues[player], item)

		mainmemory.write_u32_be(outgoing_key_addr, 0)
		mainmemory.write_u16_be(outgoing_item_addr, 0)
		mainmemory.write_u16_be(outgoing_player_addr, 0)
	end

	-- check if an item needs to be received
	local count = mainmemory.read_u16_be(internal_count_addr)
	item = mainmemory.read_u16_be(incoming_item_addr)
	if item == 0 and #data.itemqueues[player_num] > count then
		item = data.itemqueues[player_num][count+1]
		if item == 0 then
			mainmemory.write_u16_be(internal_count_addr, count+1)
		else
			mainmemory.write_u16_be(incoming_item_addr, item)
			mainmemory.write_u16_be(incoming_player_addr, player_num)
		end
	end

	-- if the internal count suggests items are missing, add filler
	-- the weird check on size here has to do with the fact that the memory location
	-- is stores arbitrary meaningless values on reset (when not in a gameplay mode)
	if #data.itemqueues[player_num] < count and count - #data.itemqueues[player_num] < 3 then
		while #data.itemqueues[player_num] < count do
			table.insert(data.itemqueues[player_num], 0)
		end
	end
end

return plugin
