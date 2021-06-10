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
plugin.author = "authorblues"

-- this setting is crucially important! without it, loading states will crash
local EXPANSION_WARNING = 'Enable "Use Expansion Slot" under Bizhawk\'s N64 menu!'
plugin.settings =
{
	-- some people prefer to see the world name I guess
	{ name='othernames', type='select', label='Show Other Names As',
		options={'Someone', 'Link #', 'World #'}, default='Someone' },
	{ name='swapbutton', type='boolean', label='Force Game Swap on P2 L Button?' },

	-- add an info block for the required settings
	{ type='info', text=EXPANSION_WARNING, }
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

-- first 4 bytes are written big-endian
-- second 4 bytes are written little-endian :^)
local NAME_FUNCTIONS = {
	['Someone'] = function(id)
		if player_num == id then
			return 0xC3D3D9DF, 0xDFDFDFDF -- You
		end
		return 0xBDD3D1C9, 0xDFC9D2D3 -- Someone
	end,
	['Link #'] = function(id)
		if player_num == id then
			return 0xC3D3D9DF, 0xDFDFDFDF -- You
		end

		local b = 0xDFDFDFDF
		while id > 0 do
			b = b * 256 + (id % 10)
			id = math.floor(id / 10)
		end
		return 0xB6CDD2CF, b * 256 + 0xDF -- Link 255
	end,
	['World #'] = function(id)
		if player_num == id then
			return 0xC3D3D9DF, 0xDFDFDFDF -- You
		end

		local b = 0xDFDFDFDF
		while id > 0 do
			b = b * 256 + (id % 10)
			id = math.floor(id / 10)
		end
		if b < 256 * 256 then b = b * 256 + 0xDF end
		return 0xC1D3D6D0, b * 256 + 0xC8 -- World 255
	end,
}

local get_name = nil

local function fill_name(id)
	local name_address = player_names_addr + (id * 8)
	local name1, name2 = get_name(id)
	mainmemory.write_u32_be(name_address + 0, name1) --be
	mainmemory.write_u32_le(name_address + 4, name2) --le
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

local function is_normal_gameplay()
	local state_logo = mainmemory.read_u32_be(0x11F200)
	local state_main = mainmemory.read_s8(0x11B92F)
	local state_menu = mainmemory.read_s8(0x1D8DD5)
	return state_logo ~= 0x802C5880 and state_logo ~= 0x00000000 and
		state_main ~= 1 and state_main ~= 2 and state_menu == 0
end

function plugin.on_setup(data, settings)
	data.itemqueues = data.itemqueues or {}
	for i = 1,10 do print(EXPANSION_WARNING) end
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
	get_name = NAME_FUNCTIONS[settings.othernames]
	try_fill_names()

	if is_normal_gameplay() then
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
		while #data.itemqueues[player_num] < count do
			print('internal count too high? adding a filler item')
			table.insert(data.itemqueues[player_num], 0)
		end
	end

	if settings.swapbutton then
		local currL = joypad.get(2).L
		if not data.prevL and currL then swap_game() end
		data.prevL = currL
	end
end

return plugin
