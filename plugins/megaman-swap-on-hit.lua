--[[
	This plugin is designed for Megaman 1-6 NES. The game swaps any time
	Megaman takes damage. Checks SHA-1 hashes of different rom versions, so if
	you use a version of the rom that isn't recognized, nothing special will
	happen in that game (no swap on hit). This means other games can be mixed in
--]]

_gamemeta = {
	[1]={ type='hit', addr=0x0055 },
	[2]={ type='hit', addr=0x004B },
	[6]={ type='hit', addr=0x00A2 },

	[3]={ type='hp', addr=0x00A2 },
	[4]={ type='hp', addr=0x00B0 },
	[5]={ type='hp', addr=0x00B0 },
}

-- non NTSC-U versions marked, same RAM maps?
_rominfo = {
	-- Mega Man 1 rom hashes
	['F0CC04FBEBB2552687309DA9AF94750F7161D722'] = 1,
	['2F88381557339A14C20428455F6991C1EB902C99'] = 1,
	['0FE255649359ECE8CB64B6F24ACAF09F17AF746C'] = 1, --PAL
	['5914D409EA027A96C2BB58F5136C5E7E9B2E8300'] = 1, --JPN
	-- Mega Man 2 rom hashes
	['6B5B9235C3F630486ED8F07A133B044EAA2E22B2'] = 2,
	['2290D8D839A303219E9327EA1451C5EEA430F53D'] = 2,
	['FB51875D1FF4B0DEEE97E967E6434FF514F3C2F2'] = 2, --JPN
	-- Mega Man 3 rom hashes
	['53197445E137E47A73FD4876B87E288ED0FED5C6'] = 3,
	['0728DB6B8AABF7E525D930A05929CAA1891588D0'] = 3,
	['E82C532DE36C6A5DEAF08C6248AEA434C4D8A85A'] = 3, --JPN
	-- Mega Man 4 rom hashes
	['2AE9A049DAFC8C7577584B4B9256F7EF8932B29C'] = 4,
	['0FA8D2DADFB6E1DD9DE737A02CE0BFA1CD5FF65D'] = 4,
	['C33C6FA5B0A5B010AF6B38CBD22252A595500A5A'] = 4, --JPN
	-- Mega Man 5 rom hashes
	['1748E9B6ECFF0C01DD14ECC7A48575E74F88B778'] = 5,
	['0FC06CE52BBB65F6019E2FA3553A9C1FC60CC201'] = 5, --JPN
	-- Mega Man 6 rom hashes
	['32774F6A0982534272679AC424C4191F1BE5F689'] = 6,
	['316BEA6B2AEF7E5ECDE995EAB4AD99DB78F85C34'] = 6, --JPN
}

-- called once at the start
function on_setup(data)
end

-- called each time a game/state loads
function on_game_load(data)
	local whichgame = _rominfo[gameinfo.getromhash()]
	local meta = _gamemeta[whichgame]

	-- get initial value for this address
	meta.prev = mainmemory.readbyte(meta.addr)
end

-- called each frame
function on_frame(data)
	local whichgame = _rominfo[gameinfo.getromhash()]
	local meta = _gamemeta[whichgame]
	local curr = mainmemory.readbyte(meta.addr)

	-- these games have a hitstun countdown that rests at 0 and jumps
	-- any time a hit is taken or a death happens
	if meta.type == 'hit' then
		if meta.prev == 0 and curr > 0 then
			swap_game()
		end
	-- these games were harder to find a reliable hitstun/i-frame counter, so
	-- simply checking if HP goes down
	elseif meta.type == 'hp' then
		-- MM5 stores xFF here for about 5f when the game boots up for no reason
		if curr < meta.prev and meta.prev ~= 0xFF then
			swap_game()
		end
	end

	-- update previous value for next frame
	meta.prev = curr
end

-- called each time a game/state is saved (before swap)
function on_game_save(data)
end

-- called each time a game is marked complete
function on_complete(data)
end
