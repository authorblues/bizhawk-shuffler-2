local plugin = {}

plugin.name = "Megaman Damage Shuffler"
plugin.author = "authorblues"
plugin.settings =
{
	-- enable this feature to have health and lives synchronized across games
	--{ name='healthsync', type='boolean', label='Synchronize Health/Lives' },
}

plugin.description =
[[
	Automatically swaps games any time Megaman takes damage. Checks hashes of different rom versions, so if you use a version of the rom that isn't recognized, nothing special will happen in that game (no swap on hit).

	Supports:
	- Mega Man 1-6 NES
	- Mega Man 7 SNES
	- Mega Man 8 PSX
	- Mega Man X 1-3 SNES
	- Mega Man X3 PSX (PAL & NTSC-J)
	- Mega Man X 4-6 PSX
	- Mega Man Xtreme 1 & 2 GBC
	- Rockman & Forte SNES
	- Mega Man I-V GB
	- Mega Man Wily Wars GEN
	- Mega Man Battle Network 1-3 GBA
	- Mega Man Legends/64
	- Mega Man Soccer (credit: kalimag)
]]

local prevdata = {}

local shouldSwap = function() return false end

local function generic_swap(gamemeta)
	return function(data)
		-- if a method is provided and we are not in normal gameplay, don't ever swap
		if gamemeta.gmode and not gamemeta.gmode() then
			return false
		end

		local currhp = gamemeta.gethp()
		local currlc = gamemeta.getlc()

		local maxhp = gamemeta.maxhp()
		local minhp = gamemeta.minhp or 0

		-- health must be within an acceptable range to count
		-- ON ACCOUNT OF ALL THE GARBAGE VALUES BEING STORED IN THESE ADDRESSES
		if currhp < minhp or currhp > maxhp then
			return false
		end

		-- retrieve previous health and lives before backup
		local prevhp = data.prevhp
		local prevlc = data.prevlc

		data.prevhp = currhp
		data.prevlc = currlc

		-- this delay ensures that when the game ticks away health for the end of a level,
		-- we can catch its purpose and hopefully not swap, since this isnt damage related
		if data.hpcountdown ~= nil and data.hpcountdown > 0 then
			data.hpcountdown = data.hpcountdown - 1
			if data.hpcountdown == 0 and currhp > minhp then
				return true
			end
		end

		-- if the health goes to 0, we will rely on the life count to tell us whether to swap
		if prevhp ~= nil and currhp < prevhp then
			data.hpcountdown = gamemeta.delay or 3
		end

		-- check to see if the life count went down
		if prevlc ~= nil and currlc < prevlc then
			return true
		end

		return false
	end
end

function mmlegends(gamemeta)
	local mainfunc = generic_swap(gamemeta)
	return function(data)
		local shield = gamemeta.shield()
		local prevsh = data.prevsh

		data.prevsh = shield
		if shield == 0 then return false end
		return mainfunc(data) or (prevsh == 0)
	end
end

local gamedata = {
	['mm1nes']={ -- Mega Man NES
		gethp=function() return mainmemory.read_u8(0x006A) end,
		getlc=function() return mainmemory.read_u8(0x00A6) end,
		maxhp=function() return 28 end,
	},
	['mm2nes']={ -- Mega Man 2 NES
		gethp=function() return mainmemory.read_u8(0x06C0) end,
		getlc=function() return mainmemory.read_u8(0x00A8) end,
		maxhp=function() return 28 end,
	},
	['mm3nes']={ -- Mega Man 3 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00A2), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00AE) end,
		maxhp=function() return 28 end,
	},
	['mm4nes']={ -- Mega Man 4 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00B0), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00A1) end,
		maxhp=function() return 28 end,
	},
	['mm5nes']={ -- Mega Man 5 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00B0), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00BF) end,
		maxhp=function() return 28 end,
	},
	['mm6nes']={ -- Mega Man 6 NES
		gethp=function() return mainmemory.read_u8(0x03E5) end,
		getlc=function() return mainmemory.read_u8(0x00A9) end,
		maxhp=function() return 27 end,
	},
	['mm7snes']={ -- Mega Man 7 SNES
		gethp=function() return mainmemory.read_u8(0x0C2E) end,
		getlc=function() return mainmemory.read_s8(0x0B81) end,
		maxhp=function() return 28 end,
	},
	['mm8psx']={ -- Mega Man 8 PSX
		gethp=function() return mainmemory.read_u8(0x15E283) end,
		getlc=function() return mainmemory.read_u8(0x1C3370) end,
		maxhp=function() return 40 end,
	},
	['mmwwgen']={ -- Mega Man Wily Wars GEN
		gethp=function() return mainmemory.read_u8(0xA3FE) end,
		getlc=function() return mainmemory.read_u8(0xCB39) end,
		maxhp=function() return 28 end,
	},
	['rm&f']={ -- Rockman & Forte SNES
		gethp=function() return mainmemory.read_u8(0x0C2F) end,
		getlc=function() return mainmemory.read_s8(0x0B7E) end,
		maxhp=function() return 28 end,
	},
	['mmx1']={ -- Mega Man X SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x0BCF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1F80) end,
		maxhp=function() return mainmemory.read_u8(0x1F9A) end,
	},
	['mmx2']={ -- Mega Man X2 SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x09FF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1FB3) end,
		maxhp=function() return mainmemory.read_u8(0x1FD1) end,
	},
	['mmx3snes-us']={ -- Mega Man X3 SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x09FF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1FB4) end,
		maxhp=function() return mainmemory.read_u8(0x1FD2) end,
	},
	['mmx3snes-eu']={ -- Mega Man X3 SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x09FF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1FB4) end,
		maxhp=function() return mainmemory.read_u8(0x1FD2) end,
	},
	['mmx3psx-eu']={ -- Mega Man X3 PSX PAL
		gethp=function() return bit.band(mainmemory.read_u8(0x0D9091), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0D8743) end,
		maxhp=function() return mainmemory.read_u8(0x0D8761) end,
	},
	['mmx3psx-jp']={ -- Mega Man X3 PSX NTSC-J
		gethp=function() return bit.band(mainmemory.read_u8(0x0D8A45), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0D80F7) end,
		maxhp=function() return mainmemory.read_u8(0x0D8115) end,
	},
	['mmx4psx-us']={ -- Mega Man X4 PSX
		gethp=function() return bit.band(mainmemory.read_u8(0x141924), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x172204) end,
		maxhp=function() return mainmemory.read_u8(0x172206) end,
	},
	['mmx5psx-us']={ -- Mega Man X5 PSX
		gethp=function() return bit.band(mainmemory.read_u8(0x09A0FC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0D1C45) end,
		maxhp=function() return mainmemory.read_u8(0x0D1C47) end,
	},
	['mmx6psx-us']={ -- Mega Man X6 PSX NTSC-U
		gethp=function() return bit.band(mainmemory.read_u8(0x0970FC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0CCF09) end,
		maxhp=function() return mainmemory.read_u8(0x0CCF2B) end,
	},
	['mmx6psx-jp']={ -- Mega Man X6 PSX NTSC-J
		gethp=function() return bit.band(mainmemory.read_u8(0x0987BC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0CE5C9) end,
		maxhp=function() return mainmemory.read_u8(0x0CE5EB) end,
	},
	['mm1gb']={ -- Mega Man I GB
		gethp=function() return mainmemory.read_u8(0x1FA3) end,
		getlc=function() return mainmemory.read_s8(0x0108) end,
		maxhp=function() return 152 end,
	},
	['mm2gb']={ -- Mega Man II GB
		gethp=function() return mainmemory.read_u8(0x0FD0) end,
		getlc=function() return mainmemory.read_s8(0x0FE8) end,
		maxhp=function() return 152 end,
	},
	['mm3gb']={ -- Mega Man III GB
		gethp=function() return mainmemory.read_u8(0x1E9C) end,
		getlc=function() return mainmemory.read_s8(0x1D08) end,
		maxhp=function() return 152 end,
	},
	['mm4gb']={ -- Mega Man IV GB
		gethp=function() return mainmemory.read_u8(0x1EAE) end,
		getlc=function() return mainmemory.read_s8(0x1F34) end,
		maxhp=function() return 152 end,
	},
	['mm5gb']={ -- Mega Man V GB
		gethp=function() return mainmemory.read_u8(0x1E9E) end,
		getlc=function() return mainmemory.read_s8(0x1F34) end,
		maxhp=function() return 152 end,
	},
	['mmx1gbc']={ -- Mega Man Xtreme GBC
		gethp=function() return bit.band(mainmemory.read_u8(0x0ADC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1365) end,
		maxhp=function() return mainmemory.read_u8(0x1384) end,
	},
	['mmx2gbc']={ -- Mega Man Xtreme 2 GBC
		gethp=function() return bit.band(mainmemory.read_u8(0x0121), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0065) end,
		maxhp=function() return mainmemory.read_u8(0x0084) end,
	},
	['mmbn1']={ -- Mega Man Battle Network GBA
		gethp=function() return memory.read_u16_be(0x0066D0, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_be(0x00022C, "EWRAM") end,
		gmode=function() return memory.read_u8(0x0033A5, "EWRAM") ~= 0x00 end
	},
	['mmbn2']={ -- Mega Man Battle Network 2 GBA
		gethp=function() return memory.read_u16_be(0x008A94, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_be(0x000DE2, "EWRAM") end, -- unsure
		gmode=function() return memory.read_u8(0x00C220, "EWRAM") ~= 0x00 end
	},
	['mmbn3-us']={ -- Mega Man Battle Network 3 GBA (Blue & White)
		gethp=function() return memory.read_u16_be(0x037294, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_be(0x0018A2, "EWRAM") end,
		gmode=function() return memory.read_u8(0x019006, "EWRAM") ~= 0x01 end
	},
	['mmlegends-n64']={ -- Mega Man 64
		gethp=function() return mainmemory.read_s16_be(0x204A1E) end,
		getlc=function() return 0 end,
		maxhp=function() return mainmemory.read_s16_be(0x204A60) end,
		minhp=-40,
		shield=function() return mainmemory.read_u8(0x1BC66D) end,
		func=mmlegends,
	},
	['mmlegends-psx']={ -- Mega Man Legends PSX
		gethp=function() return mainmemory.read_s16_be(0x0B521E) end,
		getlc=function() return 0 end,
		maxhp=function() return mainmemory.read_s16_be(0x0B5260) end,
		minhp=-40,
		shield=function() return mainmemory.read_u8(0x0BBD85) end,
		func=mmlegends,
	},
	['mmsoccer']={ -- Megaman's Soccer SNES
		get_controlled_player = function() return mainmemory.read_u16_le(0x195A) end,
		get_player_state = function(player_addr) return mainmemory.read_u16_le(player_addr + 0x22) end,
		is_player_valid = function(player_addr) return player_addr >= 0x1000 and player_addr < 0x1800 and (player_addr % 0x80) == 0 end,
		get_opponent_score = function()
			local player_side_flags = mainmemory.read_u16_le(0x0088) -- game swaps team data in memory after half-time
			if bit.check(player_side_flags, 0) then return mainmemory.read_u8(0x0ADC) end -- if player 1 is on left side, return right side score
			if bit.check(player_side_flags, 4) then return mainmemory.read_u8(0x0ABC) end -- if player 1 is on right side, return left side score
		end,
		is_hit_state = function(state, only_special)
			return (state == 0x7 and not only_special) or -- tackle knockdown
				   (state ~= nil and state >= 0x48 and state <= 0x59) or state == 0x5C -- special shot effects
		end,
		func = function(gamemeta)
			return function(data)
				local prev_player = data.player
				local prev_state = data.state
				local prev_opponent_score = data.opponent_score or -math.huge

				local player = gamemeta.get_controlled_player()
				local state = nil
				if gamemeta.is_player_valid(player) then
					state = gamemeta.get_player_state(player)
				end
				local opponent_score = gamemeta.get_opponent_score()

				data.player = player
				data.state = state
				data.opponent_score = opponent_score

				-- swap if currently controlled character is tackled or hit by special shot
				if player == prev_player and state ~= prev_state and gamemeta.is_hit_state(state) then return true end
				-- swap if opponent scores, unless we (probably) already swapped because we got hit by a special shot
				if opponent_score == prev_opponent_score + 1 and not gamemeta.is_hit_state(state, true) then return true end
				return false
			end
		end,
	},
}

local function get_tag_from_hash(target)
	local fp = io.open('plugins/megaman-hashes.dat', 'r')
	for x in fp:lines() do
		local hash, tag = x:match("([0-9A-Fa-f]*)%s+([^ ]*)")
		if hash == target then return tag end
	end
	fp:close()
	return nil
end

local backupchecks = {
	{ tag='mmx4psx-us', name='Mega Man X4' },
	{ tag='mmx4psx-jp', name='Rockman X4' },
	{ tag='mmx5psx-us', name='Mega Man X5' },
	{ tag='mmx5psx-jp', name='Rockman X5' },
	{ tag='mmx6psx-us', name='Mega Man X6' },
	{ tag='mmx6psx-jp', name='Rockman X6' },
}

local function get_game_data()
	-- try to just match the rom hash first
	local tag = get_tag_from_hash(gameinfo.getromhash())
	if tag ~= nil and gamedata[tag] ~= nil then return gamedata[tag] end

	-- check to see if any of the rom name samples match
	local name = gameinfo.getromname()
	for _,check in pairs(backupchecks) do
		if check.name ~= nil and string.find(name, check.name) and gamedata[tag] ~= nil then
			return gamedata[tag]
		end
	end

	return nil
end

function plugin.on_game_load(data, settings)
	local gamemeta = get_game_data()
	if gamemeta ~= nil then
		local func = gamemeta.func or generic_swap
		shouldSwap = func(gamemeta)
	end
end

function plugin.on_frame(data, settings)
	-- run the check method for each individual game
	if shouldSwap(prevdata) and frames_since_restart > 10 then
		swap_game_delay(3)
	end
end

return plugin
