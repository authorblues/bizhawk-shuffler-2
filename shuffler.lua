--[[
	Bizhawk Shuffler 2 by authorblues
	inspired by Brossentia's Bizhawk Shuffler, based on slowbeef's original project
	tested on Bizhawk v2.6.1 - http://tasvideos.org/BizHawk/ReleaseHistory.html
	released under MIT License
--]]

config = {}
next_swap_time = 0
running = true
plugins = {}

-- determine operating system for the purpose of commands
_PLATFORMS = {['dll'] = 'WIN', ['so'] = 'LINUX', ['dylib'] = 'MAC'}
PLATFORM = _PLATFORMS[package.cpath:match("%p[\\|/]?%p(%a+)")]

PLUGINS_FOLDER = 'plugins'
GAMES_FOLDER = 'games'
STATES_FOLDER = GAMES_FOLDER .. '/.savestates'

-- folders needed for the shuffler to run
os.execute('mkdir output-info')
os.execute('mkdir "' .. GAMES_FOLDER .. '"')
os.execute('mkdir "' .. STATES_FOLDER .. '"')

-- loads primary config file
function load_config(f)
	local fn = loadfile(f)
	if fn ~= nil then fn() end
	return fn ~= nil
end

-- dump lua object
function dump(o)
	function _dump(o, a, b)
		if type(o) == 'table' then
			local s = ''
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s..a..'['..k..'] = '.._dump(v, '', '')..','..b
			end
			return '{'..b..s..'}'..b
		elseif type(o) == 'string' then
			return '"' .. o .. '"'
		else
			return tostring(o)
		end
	end

	return _dump(o, "\t", "\n")
end

-- saves primary config file
function save_config(config, f)
	write_data(f, 'config=\n'..dump(config))
end

-- output data to files (for OBS support)
function write_data(filename, data, mode)
	local handle = io.open(filename, mode or 'w')
	handle:write(data)
	handle:close()
end

function table_subtract(t2, t1)
	local t = {}
	for i = 1, #t1 do
		t[t1[i]] = true
	end
	for i = #t2, 1, -1 do
		if t[t2[i]] then
			table.remove(t2, i)
		end
	end
end

-- returns a table containing all files in a given directory
function get_dir_contents(dir)
	local TEMP_FILE = 'shuffler-src/.file-list.txt'
	local cmd = 'ls ' .. dir .. ' > ' .. TEMP_FILE
	if PLATFORM == 'WIN' then
		cmd = 'dir ' .. dir .. ' /B > ' .. TEMP_FILE
	end
	os.execute(cmd)

	local file_list = {}
	local fp = io.open(TEMP_FILE, 'r')
	for x in fp:lines() do
		table.insert(file_list, x)
	end
	fp:close()
	return file_list
end

-- get list of games
function get_games_list()
	local games = get_dir_contents(GAMES_FOLDER)
	local toremove = {}

	-- find .cue files and remove the associated bin/iso
	for _,filename in ipairs(games) do
		if ends_with(filename, '.cue') then
			-- open the cue file, oh god here we go...
			fp = io.open(GAMES_FOLDER .. '/' .. filename, 'r')
			for line in fp:lines() do
				-- look for the line that starts with FILE and remove the rest of the stuff
				if starts_with(line, "FILE") and ends_with(line, "BINARY") then
					table.insert(toremove, line:sub(7, -9))
				end
			end
			fp:close()
		end
	end

	table_subtract(games, toremove)
	table_subtract(games, { 'plugin.lua', '.savestates' })
	table_subtract(games, config['completed_games'])
	return games
end

-- delete savestates folder
function delete_savestates()
	local cmd = 'rm -rf "' .. STATES_FOLDER .. '"'
	if PLATFORM == 'WIN' then
		cmd = 'rmdir "' .. STATES_FOLDER .. '" /S /Q'
	end
	os.execute(cmd)
end

function get_current_game()
	return config['current_game'] or nil
end

function save_current_game()
	local g = get_current_game()
	if g ~= nil then
		savestate.save(STATES_FOLDER .. '/' .. g .. '.state')
	end
end

function file_exists(f)
	local p = io.open(f, 'r')
	if p == nil then return false end
	io.close(p)
	return true
end

-- we don't load the savestate here because (for some unbelievably f***ed up reason),
-- client.openrom() causes the whole script to reload, forcing us to use userdata
-- storage to determine if this is the initial execution of the script, or a reload
-- caused by openrom(). in any case, loading the savestate here seems to run into
-- a race condition, so we load the savestate at the beginning of the reloaded script
function load_game(g)
	client.openrom(GAMES_FOLDER .. '/' .. g)
end

function get_next_game()
	local prev = config['current_game'] or nil
	local all_games = get_games_list()

	-- remove the currently loaded game and see if there are any other options
	table_subtract(all_games, { prev })
	if #all_games == 0 then return prev end
	return all_games[math.random(#all_games)]
end

-- save current game's savestate, backup config, and load new game
function swap_game()
	-- if a swap has already happened, don't call again
	if not running then return false end

	-- if the game isn't changing, stop here and just update the timer
	-- (you might think we should just disable the timer at this point, but this
	-- allows new games to be added mid-run without the timer being disabled)
	local next_game = get_next_game()
	if next_game == get_current_game() then
		update_next_swap_time()
		return false
	end

	-- swap_game() is used for the first load, so check if a game is loaded
	if get_current_game() ~= nil then
		for _,plugin in ipairs(plugins) do
			if plugin.on_game_save ~= nil then
				plugin.on_game_save(config['plugin_state'], config['plugin_settings'])
			end
		end
	end

	-- at this point, save the game and update the new "current" game after
	save_current_game()
	config['current_game'] = next_game
	running = false

	-- save an updated randomizer seed
	config['nseed'] = math.random(9999999999)
	save_config(config, 'shuffler-src/config.lua')

	-- mute the sound for a moment to help with the swap
	config['sound'] = client.GetSoundOn()
	client.SetSoundOn(false)

	-- load the new game WHICH IS JUST GOING TO RESTART THE WHOLE SCRIPT f***
	load_game(get_current_game())
	return true
end

function swap_game_delay(f)
	next_swap_time = config['frame_count'] + f
end

function update_next_swap_time()
	swap_game_delay(math.random(config['min_swap'] * 60, config['max_swap'] * 60))
end

function starts_with(a, b)
	return a:sub(1, #b) == b
end

function ends_with(a, b)
	return a:sub(-#b) == b
end

function strip_ext(filename)
	local ndx = filename:find("\.[^\.]*$")
	return filename:sub(1, ndx-1)
end

-- this is going to be an APPROXIMATION and is not a substitute for an actual
-- timer. games do not run at a consistent or exact 60 fps, so this method is
-- provided purely for entertainment purposes
function frames_to_time(f)
	local sec = math.floor(f   / 60)
	local min = math.floor(sec / 60)
	local hrs = math.floor(min / 60)
	return string.format('%02d:%02d:%02d', hrs, min%60, sec%60)
end

function output_completed()
	completed = ""
	for i,game in ipairs(config['completed_games']) do
		completed = completed .. strip_ext(game) .. '\n'
	end
	write_data('output-info/completed-games.txt', completed)
end

function mark_complete()
	-- mark the game as complete in the config file rather than moving files around
	table.insert(config['completed_games'], get_current_game())
	print(get_current_game() .. ' marked complete')
	for _,plugin in ipairs(plugins) do
		if plugin.on_complete ~= nil then
			plugin.on_complete(config['plugin_state'], config['plugin_settings'])
		end
	end

	-- update list of completed games in file
	output_completed()

	if #get_games_list() == 0 then
		-- the shuffler is complete!
		running = false
		save_config(config, 'shuffler-src/config.lua')
		print('Shuffler complete!')
	else
		swap_game()
	end
end

function complete_setup()
	if config['plugins'] ~= nil then
		for _,pmodpath in ipairs(config['plugins']) do
			local pmodule = require(PLUGINS_FOLDER .. '.' .. pmodpath)
			print('Plugin loaded: ' .. pmodule.name)
			if pmodule ~= nil and pmodule.on_setup ~= nil then
				pmodule.on_setup(config['plugin_state'], config['plugin_settings'])
			end
		end
	end

	save_config(config, 'shuffler-src/config.lua')
	math.randomseed(config['nseed'])

	if config['frame_count'] == 0 then
		print('deleting savestates!')
		delete_savestates()
	end

	-- whatever the current state is, update the output file
	output_completed()

	-- load first game
	swap_game()
end

-- load primary configuration
load_config('shuffler-src/config.lua')

if emu.getsystemid() ~= "NULL" then
	-- THIS CODE RUNS EVERY TIME THE SCRIPT RESTARTS
	-- which is specifically after a call to client.openrom()

	-- I will try to limit the number of comments I write solely to complain about
	-- this design decision, but I make no promises.

	-- load plugin configuration
	if config['plugins'] ~= nil then
		for _,pmodpath in ipairs(config['plugins']) do
			local pmodule = require(PLUGINS_FOLDER .. '.' .. pmodpath)
			if pmodule ~= nil then table.insert(plugins, pmodule) end
		end
	end

	local state = STATES_FOLDER .. '/' .. get_current_game() .. '.state'
	if file_exists(state) then
		savestate.load(state)
	end

	-- update swap counter for this game
	local new_swaps = (config['game_swaps'][get_current_game()] or 0) + 1
	config['game_swaps'][get_current_game()] = new_swaps
	write_data('output-info/current-swaps.txt', new_swaps)

	-- update total swap counter
	config['total_swaps'] = (config['total_swaps'] or 0) + 1
	write_data('output-info/total-swaps.txt', config['total_swaps'])

	-- update game name
	write_data('output-info/current-game.txt', strip_ext(get_current_game()))

	update_next_swap_time()
	client.SetSoundOn(config['sound'] or true)
	for _,plugin in ipairs(plugins) do
		if plugin.on_game_load ~= nil then
			plugin.on_game_load(config['plugin_state'], config['plugin_settings'])
		end
	end
else
	-- THIS CODE RUNS ONLY ON THE INITIAL SCRIPT SETUP
	client.displaymessages(false)
	local setup = require('shuffler-src.setupform')
	setup.initial_setup(complete_setup)
end

prev_input = input.get()
frames_since_restart = 0
while true do
	if emu.getsystemid() ~= "NULL" and running then
		local frame_count = (config['frame_count'] or 0) + 1
		config['frame_count'] = frame_count
		frames_since_restart = frames_since_restart + 1

		-- update the frame count specifically for the active game as well
		local cgf = (config['game_frame_count'][get_current_game()] or 0) + 1
		config['game_frame_count'][get_current_game()] = cgf

		-- save time info to files for OBS display
		write_data('output-info/total-time.txt', frames_to_time(frame_count))
		write_data('output-info/current-time.txt', frames_to_time(cgf))

		-- let plugins do operations each frame
		for _,plugin in ipairs(plugins) do
			if plugin.on_frame ~= nil then
				plugin.on_frame(config['plugin_state'], config['plugin_settings'])
			end
		end

		-- calculate input "rises" by subtracting the previously held inputs from the inputs on this frame
		local input_rise = input.get()
		for k,v in pairs(prev_input) do input_rise[k] = nil end
		prev_input = input.get()

		-- mark the game as complete if the hotkey is pressed (and some time buffer)
		-- the time buffer should hopefully prevent somebody from attempting to
		-- press the hotkey and the game swapping, marking the wrong game complete
		if input_rise[config['hk_complete']] and frames_since_restart > math.min(3, config['min_swap']/2) * 60 then mark_complete() end

		-- time to swap!
		if frame_count >= next_swap_time then swap_game() end
	end

	emu.frameadvance()
end
