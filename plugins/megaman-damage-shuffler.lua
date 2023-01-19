local plugin = {}

plugin.name = "Megaman Damage Shuffler"
plugin.author = "authorblues, kalimag"
plugin.settings =
{
	-- enable this feature to have health and lives synchronized across games
	--{ name='healthsync', type='boolean', label='Synchronize Health/Lives' },
}

plugin.description =
[[
	Automatically swaps games any time Megaman takes damage. Checks hashes of different rom versions, so if you use a version of the rom that isn't recognized, nothing special will happen in that game (no swap on hit).

	Thanks to kalimag for adding support for all the weird games. Extreme0 for adding Megaman ZX & ZX Advent. Thanks to Smight and ZandraVandra for the initial ideas.

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
	- Mega Man Game Gear
	- Mega Man Battle Network 1-3 GBA
	- Mega Man Legends/64
	- Mega Man Zero 1-4 GBA
	- Mega Man ZX (USA/PAL/JP)
	- Mega Man ZX Advent (USA/PAL/JP)
	- Rockman & Forte WonderSwan
	- Rockman EXE WS
	- Rockman Battle & Fighters
	- Mega Man Soccer
	- Mega Man Battle & Chase
	- Super Adventure Rockman PSX
	- Mega Man: The Power Battle & The Power Fighters (Arcade)

	Bootlegs:
	- Zook Hero Z (aka Rockman DX6) GBC
	- Zook Hero 2 (aka Rockman X3) GBC
	- Zook Man ZX4 (aka Rockman & Crystal) GBA
	- Thunder Blast Man (aka Rocman X) GBC
	- Rocman X NES (NesHawk only)
	- Rockman 8 GB / Rockman X4 GBC
]]

local NO_MATCH = 'NONE'

local prevdata
local swap_scheduled
local shouldSwap

-- optionally load BizHawk 2.9 compat helper to get rid of bit operator warnings
local bit = bit
if compare_version("2.9") >= 0 then
	local success, migration_helpers = pcall(require, "migration_helpers")
	bit = success and migration_helpers.EmuHawk_pre_2_9_bit and migration_helpers.EmuHawk_pre_2_9_bit() or bit
end

-- update value in prevdata and return whether the value has changed, new value, and old value
-- value is only considered changed if it wasn't nil before
local function update_prev(key, value)
	local prev_value = prevdata[key]
	prevdata[key] = value
	local changed = prev_value ~= nil and value ~= prev_value
	return changed, value, prev_value
end

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

local function mmlegends(gamemeta)
	local mainfunc = generic_swap(gamemeta)
	return function(data)
		local shield = gamemeta.shield()
		local prevsh = data.prevsh

		data.prevsh = shield
		if shield == 0 then return false end
		return mainfunc(data) or (prevsh == 0)
	end
end

local function mmx6_swap(gamemeta)
	return function()
		-- check the damage counter used for the stats screen. not incremented by acid rain damage
		_, damage, prev_damage = update_prev('damage', gamemeta.getdamage())
		return prev_damage ~= nil and damage > prev_damage
	end
end

local function mmzero_swap(gamemeta)
	return function()
		local iframes_changed, iframes = update_prev('iframes', gamemeta.get_iframes() > 0)
		local state_changed, state = update_prev('state', gamemeta.get_state())
		return (iframes_changed and iframes) or
			   (state_changed and gamemeta.hit_states[state])
	end
end

local function battle_and_chase_swap(gamemeta)
	local player_addr = gamemeta.player_addr
	local hit_states = {
		[0] = nil, -- in menus, before race start
		[1] = false, -- normal race state
		[2] = true, -- spun out
		[3] = false, -- 180 turn? unknown use
		[4] = nil, -- after race finish
		[5] = false, -- Roll's spin jump
		[6] = false, -- bad start
		[7] = true, -- Duo's special attack
		[8] = true, -- Sky High Wing, not used by CPUs?
		[9] = true, -- falling into hole
		[10] = true, -- blown up/launched into air
	}
	return function()
		local state_changed, state = update_prev('state', memory.read_u8(player_addr + 0x2, "MainRAM"))
		local is_hit_state = hit_states[state]
		if is_hit_state == nil then return false end -- not actively racing or garbage data

		local dizzy_changed, dizzy = update_prev('dizzy', memory.read_u8(player_addr + 0xD4, "MainRAM") > 0)
		local frozen_changed, frozen = update_prev('frozen', memory.read_s16_le(player_addr + 0xFC, "MainRAM") > 0)
		local shuriken_changed, shuriken = update_prev('shuriken', memory.read_s16_le(player_addr + 0xFE, "MainRAM") > 0)
		local flags = memory.read_u8(player_addr + 0xC7, "MainRAM")
		local lightning_changed, lightning = update_prev('lightning', bit.check(flags, 5))
		--local wheel_damage_changed, wheel_damage = update_prev('wheel_damage',  memory.read_s16_le(player_addr + 0x106, "MainRAM") ~= 0) -- Blade Tires, not used by CPUs?

		return (state_changed and is_hit_state) or
		       (dizzy_changed and dizzy) or
		       (frozen_changed and frozen) or
		       (shuriken_changed and shuriken) or
		       (lightning_changed and lightning),
			   20
	end
end

local function super_adventure_rockman_swap(gamemeta)
	return function()
		local scene_hp_changed, scene_hp, prev_scene_hp = update_prev('scene_hp', gamemeta.get_scene_hp())
		local battle_hp_changed, battle_hp, prev_battle_hp = update_prev('battle_hp', gamemeta.get_battle_hp())
		return (scene_hp_changed and scene_hp < prev_scene_hp and gamemeta.is_scene()) or
		       (battle_hp_changed and battle_hp < prev_battle_hp and gamemeta.is_battle())
	end
end

local gamedata = {
	['mm1nes']={ -- Mega Man NES
		gethp=function() return memory.read_u8(0x006A, "RAM") end,
		getlc=function() return memory.read_u8(0x00A6, "RAM") end,
		maxhp=function() return 28 end,
	},
	['mm2nes']={ -- Mega Man 2 NES
		gethp=function() return memory.read_u8(0x06C0, "RAM") end,
		getlc=function() return memory.read_u8(0x00A8, "RAM") end,
		maxhp=function() return 28 end,
	},
	['mm3nes']={ -- Mega Man 3 NES
		gethp=function() return bit.band(memory.read_u8(0x00A2, "RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x00AE, "RAM") end,
		maxhp=function() return 28 end,
	},
	['mm4nes']={ -- Mega Man 4 NES
		gethp=function() return bit.band(memory.read_u8(0x00B0, "RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x00A1, "RAM") end,
		maxhp=function() return 28 end,
	},
	['mm5nes']={ -- Mega Man 5 NES
		gethp=function() return bit.band(memory.read_u8(0x00B0, "RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x00BF, "RAM") end,
		maxhp=function() return 28 end,
	},
	['mm6nes']={ -- Mega Man 6 NES
		gethp=function() return memory.read_u8(0x03E5, "RAM") end,
		getlc=function() return memory.read_u8(0x00A9, "RAM") end,
		maxhp=function() return 27 end,
	},
	['mm7snes']={ -- Mega Man 7 SNES
		gethp=function() return memory.read_u8(0x0C2E, "WRAM") end,
		getlc=function() return memory.read_s8(0x0B81, "WRAM") end,
		maxhp=function() return 28 end,
	},
	['mm8psx']={ -- Mega Man 8 PSX
		gethp=function() return memory.read_u8(0x15E283, "MainRAM") end,
		getlc=function() return memory.read_u8(0x1C3370, "MainRAM") end,
		maxhp=function() return 40 end,
	},
	['mmwwgen']={ -- Mega Man Wily Wars GEN
		gethp=function() return memory.read_u8(0xA3FE, "68K RAM") end,
		getlc=function() return memory.read_u8(0xCB39, "68K RAM") end,
		maxhp=function() return 28 end,
	},
	['rm&f']={ -- Rockman & Forte SNES
		gethp=function() return memory.read_u8(0x0C2F, "WRAM") end,
		getlc=function() return memory.read_s8(0x0B7E, "WRAM") end,
		maxhp=function() return 28 end,
	},
	['mmx1']={ -- Mega Man X SNES
		gethp=function() return bit.band(memory.read_u8(0x0BCF, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x1F80, "WRAM") end,
		maxhp=function() return memory.read_u8(0x1F9A, "WRAM") end,
	},
	['mmx2']={ -- Mega Man X2 SNES
		gethp=function() return bit.band(memory.read_u8(0x09FF, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x1FB3, "WRAM") end,
		maxhp=function() return memory.read_u8(0x1FD1, "WRAM") end,
	},
	['mmx3snes-us']={ -- Mega Man X3 SNES
		gethp=function() return bit.band(memory.read_u8(0x09FF, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x1FB4, "WRAM") end,
		maxhp=function() return memory.read_u8(0x1FD2, "WRAM") end,
	},
	['mmx3snes-eu']={ -- Mega Man X3 SNES
		gethp=function() return bit.band(memory.read_u8(0x09FF, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x1FB4, "WRAM") end,
		maxhp=function() return memory.read_u8(0x1FD2, "WRAM") end,
	},
	['mmx3snes-zp-4.4']={ -- Mega Man X3 SNES + Zero Project 4.4
		func=function()
			return function()
				local action_changed, action = update_prev('action', memory.read_u8(0x09DA, "WRAM"))
				local ride_armor_iframes_changed, ride_armor_iframes = update_prev('ride_armor_iframes', memory.read_s8(0x0CEE, "WRAM") > 0)
				return (action_changed and (action == 12 or action == 14)) or -- hit or death
				       (ride_armor_iframes_changed and ride_armor_iframes)
			end
		end,
	},
	['mmx3psx-eu']={ -- Mega Man X3 PSX PAL
		gethp=function() return bit.band(memory.read_u8(0x0D9091, "MainRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x0D8743, "MainRAM") end,
		maxhp=function() return memory.read_u8(0x0D8761, "MainRAM") end,
	},
	['mmx3psx-jp']={ -- Mega Man X3 PSX NTSC-J
		gethp=function() return bit.band(memory.read_u8(0x0D8A45, "MainRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x0D80F7, "MainRAM") end,
		maxhp=function() return memory.read_u8(0x0D8115, "MainRAM") end,
	},
	['mmx4psx-us']={ -- Mega Man X4 PSX
		gethp=function() return bit.band(memory.read_u8(0x141924, "MainRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x172204, "MainRAM") end,
		maxhp=function() return memory.read_u8(0x172206, "MainRAM") end,
	},
	['mmx5psx-us']={ -- Mega Man X5 PSX
		gethp=function() return bit.band(memory.read_u8(0x09A0FC, "MainRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x0D1C45, "MainRAM") end,
		maxhp=function() return memory.read_u8(0x0D1C47, "MainRAM") end,
		gmode=function() return memory.read_u8(0x09A0FC, "MainRAM") ~= 0 or memory.read_u8(0x0942BE, "MainRAM") ~= 0 end,
	},
	['mmx6psx-eu']={ -- Mega Man X6 PSX PAL
		getdamage=function() return memory.read_u32_le(0x0CCFB0, "MainRAM") end,
		func=mmx6_swap,
	},
	['mmx6psx-us']={ -- Mega Man X6 PSX NTSC-U
		getdamage=function() return memory.read_u32_le(0x0CCF68, "MainRAM") end,
		func=mmx6_swap,
	},
	['mmx6psx-jp']={ -- Mega Man X6 PSX NTSC-J
		getdamage=function() return memory.read_u32_le(0x0CE628, "MainRAM") end,
		func=mmx6_swap,
	},
	['mm1gb']={ -- Mega Man I GB
		gethp=function() return memory.read_u8(0x1FA3, "WRAM") end,
		getlc=function() return memory.read_s8(0x0108, "WRAM") end,
		maxhp=function() return 152 end,
	},
	['mm2gb']={ -- Mega Man II GB
		gethp=function() return memory.read_u8(0x0FD0, "WRAM") end,
		getlc=function() return memory.read_s8(0x0FE8, "WRAM") end,
		maxhp=function() return 152 end,
	},
	['mm3gb']={ -- Mega Man III GB
		gethp=function() return memory.read_u8(0x1E9C, "WRAM") end,
		getlc=function() return memory.read_s8(0x1D08, "WRAM") end,
		maxhp=function() return 152 end,
	},
	['mm4gb']={ -- Mega Man IV GB
		gethp=function() return memory.read_u8(0x1EAE, "WRAM") end,
		getlc=function() return memory.read_s8(0x1F34, "WRAM") end,
		maxhp=function() return 152 end,
	},
	['mm5gb']={ -- Mega Man V GB
		gethp=function() return memory.read_u8(0x1E9E, "WRAM") end,
		getlc=function() return memory.read_s8(0x1F34, "WRAM") end,
		maxhp=function() return 152 end,
	},
	['mmx1gbc']={ -- Mega Man Xtreme GBC
		gethp=function() return bit.band(memory.read_u8(0x0ADC, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x1365, "WRAM") end,
		maxhp=function() return memory.read_u8(0x1384, "WRAM") end,
	},
	['mmx2gbc']={ -- Mega Man Xtreme 2 GBC
		gethp=function() return bit.band(memory.read_u8(0x0121, "WRAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x0065, "WRAM") end,
		maxhp=function() return memory.read_u8(0x0084, "WRAM") end,
	},
	['mmgg']={ -- Mega Man Game Gear
		gethp=function() return memory.read_u8(0x0268, "Main RAM") end,
		getlc=function() return memory.read_u8(0x026A, "Main RAM") end,
		maxhp=function() return 252 end,
	},
	['mmbn1']={ -- Mega Man Battle Network GBA
		gethp=function() return memory.read_u16_le(0x0066D0, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_le(0x00022C, "EWRAM") end,
		gmode=function() return memory.read_u8(0x004CDC, "EWRAM") ~= 0x00 end
	},
	['mmbn2']={ -- Mega Man Battle Network 2 GBA
		gethp=function() return memory.read_u16_le(0x008A94, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_le(0x000DE2, "EWRAM") end, -- unsure
		gmode=function() return memory.read_u8(0x00C220, "EWRAM") ~= 0x00 end
	},
	['mmbn3-us']={ -- Mega Man Battle Network 3 GBA (Blue & White)
		gethp=function() return memory.read_u16_le(0x037294, "EWRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_u16_le(0x0018A2, "EWRAM") end,
		gmode=function() return memory.read_u8(0x019006, "EWRAM") ~= 0x01 end
	},
	['mmlegends-n64']={ -- Mega Man 64
		func=mmlegends,
		gethp=function() return memory.read_s16_be(0x204A1E, "RDRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_s16_be(0x204A60, "RDRAM") end,
		minhp=-40,
		shield=function() return memory.read_u8(0x1BC66D, "RDRAM") end,
	},
	['mmlegends-psx']={ -- Mega Man Legends PSX
		func=mmlegends,
		gethp=function() return memory.read_s16_be(0x0B521E, "MainRAM") end,
		getlc=function() return 0 end,
		maxhp=function() return memory.read_s16_be(0x0B5260, "MainRAM") end,
		minhp=-40,
		shield=function() return memory.read_u8(0x0BBD85, "MainRAM") end,
	},
	['mmzero1']={
		func=mmzero_swap,
		get_iframes=function() return memory.read_u8(0x02B634, 'EWRAM') end,
		get_state=function() return memory.read_u8(0x02B5AD, 'EWRAM') end,
		hit_states={[6]=true,},
	},
	['mmzero2']={
		func=mmzero_swap,
		get_iframes=function() return memory.read_u8(0x037D84, 'EWRAM') end,
		get_state=function() return memory.read_u8(0x037CFD, 'EWRAM') end,
		hit_states={[7]=true,},
	},
	['mmzero3']={
		func=mmzero_swap,
		get_iframes=function() return memory.read_u8(0x038034, 'EWRAM') end,
		get_state=function() return memory.read_u8(0x037FAD, 'EWRAM') end,
		hit_states={[4]=true,},
	},
	['mmzero3-jp']={
		func=mmzero_swap,
		get_iframes=function() return memory.read_u8(0x037CF4, 'EWRAM') end,
		get_state=function() return memory.read_u8(0x037C6D, 'EWRAM') end,
		hit_states={[4]=true,},
	},
	['mmzero4']={
		func=mmzero_swap,
		get_iframes=function() return memory.read_u8(0x036694, 'EWRAM') end,
		get_state=function() return memory.read_u8(0x03660D, 'EWRAM') end,
		hit_states={[4]=true,},
	},
	['mmzx']={ -- Mega Man ZX
		gethp=function() return bit.band(memory.read_u8(0x14FBB2, "Main RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x14FC6C, "Main RAM") end,
		maxhp=function() return memory.read_u8(0x14FBB4, "Main RAM") end,
	},
	['mmzx-jp']={ -- Mega Man ZX NSTC-J
		gethp=function() return bit.band(memory.read_u8(0x14F7B2, "Main RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x14F86C, "Main RAM") end,
		maxhp=function() return memory.read_u8(0x14F7B4, "Main RAM") end,
	},
	['mmzx-eu']={ -- Mega Man ZX PAL
		gethp=function() return bit.band(memory.read_u8(0x151DBA, "Main RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x151E74, "Main RAM") end,
		maxhp=function() return memory.read_u8(0x151DBC, "Main RAM") end,
	},
	['mmzxadv']={ -- Mega Man ZX - Advent NSTC & NSTC-J
		gethp=function() return bit.band(memory.read_u8(0x169D1A, "Main RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x169DE4, "Main RAM") end,
		maxhp=function() return memory.read_u8(0x169D1C, "Main RAM") end,
	},
	['mmzxadv-eu']={ -- Mega Man ZX - Advent PAL
		gethp=function() return bit.band(memory.read_u8(0x155D66, "Main RAM"), 0x7F) end,
		getlc=function() return memory.read_u8(0x155E30, "Main RAM") end,
		maxhp=function() return memory.read_u8(0x155D68, "Main RAM") end,
	},
	['rm&fws']={ -- Rockman & Forte: Mirai Kara no Chousensha (WonderSwan)
		func=function()
			return function() -- hp and life counter change in very inconvenient ways, generic_swap doesn't work well here
				local hit_anim_changed, hit_anim = update_prev('hit_anim', memory.read_u16_le(0x03CE, "RAM") == 0x66F9)
				local hp_changed, hp, prev_hp = update_prev('hp', memory.read_u8(0x03B6, "RAM"))
				return (hit_anim_changed and hit_anim) or --happens on pretty much everything including pits and spikes
				       (hp_changed and hp < prev_hp and (hp > 0 or hit_anim)) -- slime damage and repeated hits while still in anim.
			end
		end,
	},
	['mmsoccer']={ -- Megaman's Soccer SNES
		func=function()
			local function get_controlled_player() return memory.read_u16_le(0x195A, "WRAM") end
			local function is_player_valid(player_addr)
				return player_addr >= 0x1000 and player_addr < 0x1800 and (player_addr % 0x80) == 0
			end
			local function get_player_state(player_addr)
				return is_player_valid(player_addr) and memory.read_u16_le(player_addr + 0x22, "WRAM") or nil
			end
			local function is_hit_state(state, only_special)
				return (state == 0x7 and not only_special) or -- tackle knockdown
				       (state ~= nil and state >= 0x48 and state <= 0x59) or state == 0x5C -- special shot effects
			end
			local function get_opponent_score(left_addr, right_addr)
				local player_side_flags = memory.read_u16_le(0x0088, "WRAM") -- game swaps team data in memory after half-time
				if bit.check(player_side_flags, 0) then return memory.read_u8(right_addr, "WRAM") end
				if bit.check(player_side_flags, 4) then return memory.read_u8(left_addr, "WRAM") end
			end

			return function()
				local player_changed, player = update_prev('player', get_controlled_player())
				local state_changed, state = update_prev('state', get_player_state(player))
				local _, opp_score, prev_opp_score = update_prev('opp_score', get_opponent_score(0xABC, 0xADC))
				local _, tie_score, prev_tie_score = update_prev('tie_score', get_opponent_score(0x94C, 0x094E))

				-- swap if currently controlled character is tackled or hit by special shot
				if not player_changed and state_changed and is_hit_state(state) then return true, 8 end
				-- swap if opponent scores, unless we (probably) already swapped because we got hit by a special shot
				if prev_opp_score and opp_score == prev_opp_score + 1 and not is_hit_state(state, true)
				   then return true end
				-- swap if opponent scores in tiebreaker
				if prev_tie_score and tie_score == prev_tie_score + 1 then return true end

				return false
			end
		end,
	},
	['mmb&c-eu'] = { -- Megaman - Battle & Chase (Europe)
		func=battle_and_chase_swap,
		player_addr=0x135234,
	},
	['mmb&c-jp-1.0'] = { -- Rockman - Battle & Chase (Japan) (v1.0)
		func=battle_and_chase_swap,
		player_addr=0x13A414,
	},
	['mmb&c-jp-1.1'] = { -- Rockman - Battle & Chase (Japan) (v1.1)
		func=battle_and_chase_swap,
		player_addr=0x13A310,
	},
	['rockman-battle-and-fighters'] = { -- Rockman Battle & Fighters (Neo Geo Pocket)
		func=function()
			return function(data)
				if memory.read_u8(0x0110, "RAM") == 1 then -- Power Battle
					local _, hp, prev_hp = update_prev('hp', memory.read_u16_le(0x023A, "RAM"))
					return prev_hp and hp < prev_hp
				elseif memory.read_u8(0x0107, "RAM") == 1 then -- Power Fighters
					local _, hp, prev_hp = update_prev('hp', memory.read_u16_le(0x02C2, "RAM"))
					return prev_hp and hp < prev_hp
				else
					data.hp = nil
					return false
				end
			end
		end
	},
	['rockman-exe-ws'] = {
		func=function()
			return function()
				local hit_changed, hit = update_prev('hit', bit.check(memory.read_u8(0x0BDF, "RAM"), 4))
				return (hit_changed and hit)
			end
		end
	},
	['mm-power-battle-fighters'] = { -- Mega Man: The Power Battle / Mega Man 2: The Power Fighters (Arcade)
		func=function()
			return function()
				local hp_changed, hp, prev_hp = update_prev('hp', memory.read_u16_be(0xFF8350, "m68000 : System Bus"))
				local timer = memory.read_u16_be(0xFF8118, "m68000 : System Bus")
				return (timer ~= 0 and hp_changed and hp < prev_hp)
			end
		end
	},
	['super-adventure-rockman-psx-disc1'] = {
		get_scene_hp = function() return memory.read_s16_le(0x1BBBBC, "MainRAM") end,
		get_battle_hp = function() return memory.read_s16_le(0x0C8AE0, "MainRAM") end,
		is_battle = function() return memory.read_u8(0x0C8B48, "MainRAM") == 1 end,
		is_scene = function() return memory.read_u8(0x0C8C30, "MainRAM") == 1 end,
		func=super_adventure_rockman_swap,
	},
	['super-adventure-rockman-psx-disc2'] = {
		get_scene_hp = function() return memory.read_s16_le(0x1D0DF0, "MainRAM") end,
		get_battle_hp = function() return memory.read_s16_le(0x0DCEA4, "MainRAM") end,
		is_battle = function() return memory.read_u8(0x0DCF0C, "MainRAM") == 1 end,
		is_scene = function() return memory.read_u8(0x0DCFF4, "MainRAM") == 1 end,
		func=super_adventure_rockman_swap,
	},
	['super-adventure-rockman-psx-disc3'] = {
		get_scene_hp = function() return memory.read_s16_le(0x1C287C, "MainRAM") end,
		get_battle_hp = function() return memory.read_s16_le(0x0CCA6C, "MainRAM") end,
		is_scene = function() return memory.read_u8(0x0CCBBC, "MainRAM") == 1 end,
		is_battle = function() return memory.read_u8(0x0CCAD4, "MainRAM") == 1 end,
		func=super_adventure_rockman_swap,
	},
	['zook-hero'] = {
		gethp=function() return memory.read_u8(0x52, "HRAM") end,
		getlc=function() return memory.read_u8(0x60, "HRAM") end,
		maxhp=function() return 20 end,
	},
	['zook-man-zx4'] = {
		gethp=function() return memory.read_u8(0x1638, "IWRAM") end,
		getlc=function() return memory.read_u8(0x1634, "IWRAM") end,
		maxhp=function() return 11 end,
	},
	['rockman-and-crystal'] = {
		gethp=function() return memory.read_u8(0x163C, "IWRAM") end,
		getlc=function() return memory.read_u8(0x1638, "IWRAM") end,
		maxhp=function() return 11 end,
	},
	['rocman-x-gb'] = {
		gethp=function() return memory.read_u8(0x025B, "WRAM") end,
		getlc=function() return memory.read_u8(0x5F, "HRAM") end,
		maxhp=function() return 8 end,
	},
	['rocman-x-nes'] = {
		func=function()
			local hit_states = {
				[8] = true, -- hit
				[9] = true, -- ko
				[14] = true, -- continue prompt
			}
			return function()
				local hit_changed, hit = update_prev("hit_changed", hit_states[memory.read_u8(0x56, "RAM")] or false)
				local game_over_changed, game_over = update_prev("game_over", memory.read_u16_le(0x5C0, "RAM") == 0xD6D4)
				return (hit_changed and hit) or
				       (game_over_changed and game_over and not hit)
			end
		end
	},
	['rockman-8-gb'] = {
		gethp=function() return memory.read_u8(0x027C, "WRAM") end,
		getlc=function() return memory.read_u8(0x025E, "WRAM") end,
		maxhp=function() return 8 end,
	},
}

local backupchecks = {
}

local function get_game_tag()
	-- try to just match the rom hash first
	local tag = get_tag_from_hash_db(gameinfo.getromhash(), 'plugins/megaman-hashes.dat')
	if tag ~= nil and gamedata[tag] ~= nil then return tag end

	-- check to see if any of the rom name samples match
	local name = gameinfo.getromname()
	for _,check in pairs(backupchecks) do
		if check.test() then return check.tag end
	end

	return nil
end

function plugin.on_setup(data, settings)
	data.tags = data.tags or {}
end

function plugin.on_game_load(data, settings)
	prevdata = {}
	swap_scheduled = false
	shouldSwap = function() return false end

	local tag = data.tags[gameinfo.getromhash()] or get_game_tag()
	data.tags[gameinfo.getromhash()] = tag or NO_MATCH

	-- first time through with a bad match, tag will be nil
	-- can use this to print a debug message only the first time
	if tag ~= nil and tag ~= NO_MATCH then
		log_message('game match: ' .. tag)
		local gamemeta = gamedata[tag]
		local func = gamemeta.func or generic_swap
		shouldSwap = func(gamemeta)
	elseif tag == nil then
		log_message(string.format('unrecognized? %s (%s)',
			gameinfo.getromname(), gameinfo.getromhash()))
	end
end

function plugin.on_frame(data, settings)
	-- run the check method for each individual game
	if swap_scheduled then return end

	local schedule_swap, delay = shouldSwap(prevdata)
	if schedule_swap and frames_since_restart > 10 then
		swap_game_delay(delay or 3)
		swap_scheduled = true
	end
end

return plugin
