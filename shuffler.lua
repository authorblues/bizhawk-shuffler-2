--[[
	Bizhawk Shuffler 2 by authorblues
	inspired by Brossentia's Bizhawk Shuffler, based on slowbeef's original project
	tested on Bizhawk v2.6.2 - http://tasvideos.org/BizHawk/ReleaseHistory.html
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
STATES_BACKUPS = 3
DEFAULT_CMD_OUTPUT = 'shuffler-src/.cmd-output.txt'

MIN_BIZHAWK_VERSION = "2.6.1"
RECOMMENDED_LUA_CORE = "LuaInterface"
MAX_INTEGER = 99999999

function log_message(msg, quiet)
	if not quiet then print(msg) end

	local handle, err = io.open('message.log', 'a')
	if handle == nil then return end
	handle:write(tostring(msg))
	handle:write('\n')
	handle:close()
end

-- check if folder exists
function path_exists(p)
	local ok, err, code = os.rename(p, p)
	-- code 13 is permission denied, but it's there
	if not ok and code == 13 then return true end
	return ok, err
end

function make_dir(p)
	if path_exists(p .. '/') then return end
	os.execute(string.format('mkdir "%s"', p))
end

-- folders needed for the shuffler to run
make_dir('output-info')
make_dir(GAMES_FOLDER)
make_dir(STATES_FOLDER)

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
				s = s..a..string.format('[%s] = %s,', _dump(k, "", ""), _dump(v, "", ""))..b
			end
			return '{'..b..s..'}'..b
		elseif type(o) == 'number' or type(o) == 'boolean' or o == nil then
			return tostring(o)
		elseif type(o) == 'string' then
			-- %q encloses in double quotes and escapes according to lua rules
			return string.format('%q', o)
		else -- functions, native objects, coroutines
			error(string.format('Unsupported value of type "%s" in config.', type(o)))
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
	local handle, err = io.open(filename, mode or 'w')
	if handle == nil then
		log_message(string.format("Couldn't write to file: %s", filename))
		log_message(err)
		return
	end
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
function get_dir_contents(dir, tmp, force)
	local TEMP_FILE = tmp or DEFAULT_CMD_OUTPUT
	if force ~= false or not path_exists(TEMP_FILE) then
		local cmd = string.format('ls "%s" -type f > %s', dir, TEMP_FILE)
		if PLATFORM == 'WIN' then
			cmd = string.format('dir "%s" /B /A-D > %s', dir, TEMP_FILE)
		end
		os.execute(cmd)
	end

	local file_list = {}
	local fp = io.open(TEMP_FILE, 'r')
	for x in fp:lines() do
		table.insert(file_list, x)
	end
	fp:close()
	return file_list
end

-- types of files to ignore in the games directory
local IGNORED_FILE_EXTS = { '.msu', '.pcm' }

-- get list of games
function get_games_list(force)
	local LIST_FILE = '.games-list.txt'
	local games = get_dir_contents(GAMES_FOLDER, GAMES_FOLDER .. '/' .. LIST_FILE, force or false)
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
		-- ccd/img format?
		elseif ends_with(filename, '.ccd') then
			local primary = filename:sub(1, #filename-4)
			table.insert(toremove, primary .. '.img')
			table.insert(toremove, primary .. '.sub')
		end

		for _,ext in ipairs(IGNORED_FILE_EXTS) do
			if ends_with(filename, ext) then
				table.insert(toremove, filename)
			end
		end
	end

	table_subtract(games, toremove)
	table_subtract(games, { LIST_FILE })
	table_subtract(games, config.completed_games)
	return games
end

-- delete savestates folder
function delete_savestates()
	local cmd = string.format('rm -rf "%s"', STATES_FOLDER)
	if PLATFORM == 'WIN' then
		cmd = string.format('rmdir "%s" /S /Q', STATES_FOLDER)
	end
	os.execute(cmd)
end

function get_savestate_file(game)
	game = game or config.current_game
	if game == nil then error('no game specified for savestate file') end
	return string.format("%s/%s.state", STATES_FOLDER, game)
end

function save_current_game()
	local function overwrite(a, b)
		os.remove(b)
		os.rename(a, b)
	end

	if config.current_game ~= nil then
		local statename = get_savestate_file()
		-- safety backups
		for i = STATES_BACKUPS, 2, -1 do
			overwrite(string.format("%s.bk%d", statename, i-1),
				string.format("%s.bk%d", statename, i))
		end
		overwrite(statename, statename .. '.bk1')
		savestate.save(statename)
	end
end

function file_exists(f)
	local p = io.open(f, 'r')
	if p == nil then return false end
	io.close(p)
	return true
end

-- we don't load the savestate here because (for some unbelievably f***ed up reason),
-- client.openrom() causes the whole script to reload, forcing us to use a convoluted
-- method to determine if this is the initial execution of the script, or a reload
-- caused by openrom(). in any case, loading the savestate here seems to run into
-- a race condition, so we load the savestate at the beginning of the reloaded script
function load_game(g)
	local filename = GAMES_FOLDER .. '/' .. g
	if not file_exists(filename) then return false end
	client.openrom(filename)
	return true
end

function get_next_game()
	local prev = config.current_game or nil
	local all_games = get_games_list()

	-- check to make sure that all of the games correspond to actual
	-- game files that can be opened
	local all_exist = true
	for i,game in ipairs(all_games) do
		all_exist = all_exist and file_exists(GAMES_FOLDER .. '/' .. game)
	end

	-- if any of the games are missing, force a refresh of the game list
	if not all_exist then
		all_games = get_games_list(true)
	end

	-- shuffle_index == -1 represents fully random shuffle order
	if config.shuffle_index < 0 then
		-- remove the currently loaded game and see if there are any other options
		table_subtract(all_games, { prev })
		if #all_games == 0 then return prev end
		return all_games[math.random(#all_games)]
	else
		-- manually select the next one
		if #all_games == 1 then return prev end
		config.shuffle_index = (config.shuffle_index % #all_games) + 1
		return all_games[config.shuffle_index]
	end
end

-- save current game's savestate, backup config, and load new game
function swap_game(next_game)
	-- if a swap has already happened, don't call again
	if not running then return false end

	-- if no game provided, call get_next_game()
	next_game = next_game or get_next_game()

	-- if the game isn't changing, stop here and just update the timer
	-- (you might think we should just disable the timer at this point, but this
	-- allows new games to be added mid-run without the timer being disabled)
	if next_game == config.current_game then
		update_next_swap_time()
		return false
	end

	-- swap_game() is used for the first load, so check if a game is loaded
	if config.current_game ~= nil then
		for _,plugin in ipairs(plugins) do
			if plugin.on_game_save ~= nil then
				local pdata = config.plugins[plugin._module]
				plugin.on_game_save(pdata.state, pdata.settings)
			end
		end
	end

	-- at this point, save the game and update the new "current" game after
	save_current_game()
	config.current_game = next_game
	running = false

	-- mute the sound for a moment to help with the swap
	config.sound = client.GetSoundOn()
	client.SetSoundOn(false)

	-- force another frame to pass to get the mute to take effect
	if emu.getsystemid() ~= "NULL" then emu.frameadvance() end

	-- unique game count, for debug purposes
	config.game_count = 0
	for k,v in pairs(config.game_swaps) do
		config.game_count = config.game_count + 1
	end

	-- save an updated randomizer seed
	config.nseed = math.random(MAX_INTEGER) + config.frame_count
	save_config(config, 'shuffler-src/config.lua')

	-- load the new game WHICH IS JUST GOING TO RESTART THE WHOLE SCRIPT f***
	return load_game(config.current_game)
end

function swap_game_delay(f)
	next_swap_time = config.frame_count + f
end

function update_next_swap_time()
	next_swap_time = math.huge -- infinity
	if config.auto_shuffle then
		swap_game_delay(math.random(config.min_swap * 60, config.max_swap * 60))
	end
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

function checkversion(reqversion)
	-- nil string means no requirements, so of course true
	if reqversion == nil then return true end

	local curr, reqd = {}, {}
	for x in string.gmatch(client.getversion(), "%d+") do
		table.insert(curr, tonumber(x))
	end
	for x in string.gmatch(reqversion, "%d+") do
		table.insert(reqd, tonumber(x))
	end
	while #curr < #reqd do table.insert(curr, 0) end

	for i=1,#reqd do
		if curr[i]<reqd[i] then
			return false
		end
	end
	return true
end

local function check_lua_core()
	if client.get_lua_engine() ~= RECOMMENDED_LUA_CORE then
		log_message(string.format("\n[!] It is recommended to use the %s core (currently using %s)\n" ..
			"Change the Lua core in the Config > Customize > Advanced menu and restart BizHawk",
			RECOMMENDED_LUA_CORE, client.get_lua_engine()))
	end
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
	for i,game in ipairs(config.completed_games) do
		completed = completed .. strip_ext(game) .. '\n'
	end
	write_data('output-info/completed-games.txt', completed)
end

function mark_complete()
	-- mark the game as complete in the config file rather than moving files around
	table.insert(config.completed_games, config.current_game)
	log_message(config.current_game .. ' marked complete')
	for _,plugin in ipairs(plugins) do
		if plugin.on_complete ~= nil then
			local pdata = config.plugins[plugin._module]
			plugin.on_complete(pdata.state, pdata.settings)
		end
	end

	-- update list of completed games in file
	output_completed()

	if #get_games_list() == 0 then
		-- the shuffler is complete!
		running = false
		save_config(config, 'shuffler-src/config.lua')
		log_message('Shuffler complete!')
	else
		swap_game()
	end
end

function cwd()
	local cmd = string.format('pwd > %s', DEFAULT_CMD_OUTPUT)
	if PLATFORM == 'WIN' then
		cmd = string.format('cd > %s', DEFAULT_CMD_OUTPUT)
	end
	os.execute(cmd)

	local fp = io.open(DEFAULT_CMD_OUTPUT, 'r')
	local resp = fp:read("*all")
	fp:close()
	return resp:match( "^%s*(.+)%s*$" )
end

function complete_setup()
	os.remove('message.log')

	if config.plugins ~= nil then
		for pmodpath,pdata in pairs(config.plugins) do
			local pmodule = require(PLUGINS_FOLDER .. '.' .. pmodpath)
			if checkversion(pmodule.minversion) then
				log_message('Plugin loaded: ' .. pmodule.name)
			else
				log_message(string.format('%s requires Bizhawk version %s+', pmodule.name, pmodule.minversion))
				log_message("-- Currently installed version: " .. client.getversion())
				log_message("-- Please update your Bizhawk installation to use this plugin")
				config.plugins[pmodpath] = nil
			end
			if pmodule ~= nil and pmodule.on_setup ~= nil then
				pmodule.on_setup(pdata.state, pdata.settings)
			end
		end
	end

	local games = get_games_list(true) -- force refresh of the games list
	if #games == 0 then
		local sep = '/'
		if PLATFORM == 'WIN' then sep = '\\' end

		log_message('No games found in the expected directory. Were they put somewhere else? ' ..
			'Are they nested inside folders? ROM files should be placed directly in the following directory:')
		if cwd ~= nil then log_message(string.format("Expected: %s%s%s", cwd(), sep, GAMES_FOLDER)) end
		return
	end

	-- these messages will only appear in the message log
	log_message('Platform: ' .. PLATFORM, true)
	log_message('Bizhawk version: ' .. client.getversion(), true)
	for _,game in ipairs(games) do
		log_message('GAME FOUND: ' .. game, true)
	end

	save_config(config, 'shuffler-src/config.lua')
	math.randomseed(config.nseed or config.seed)

	if config.frame_count == 0 then
		log_message('deleting savestates!')
		delete_savestates()
	end

	-- whatever the current state is, update the output file
	output_completed()

	-- if there is already a listed current game, this is a resumed session
	-- otherwise, call swap_game() to setup for the first game load
	if config.current_game ~= nil then
		load_game(config.current_game)
	else swap_game() end
end

check_lua_core()

-- load primary configuration
load_config('shuffler-src/config.lua')

if emu.getsystemid() ~= "NULL" then
	-- THIS CODE RUNS EVERY TIME THE SCRIPT RESTARTS
	-- which is specifically after a call to client.openrom()

	-- I will try to limit the number of comments I write solely to complain about
	-- this design decision, but I make no promises.

	-- load plugin configuration
	if config.plugins ~= nil then
		for pmodpath,pdata in pairs(config.plugins) do
			local pmodule = require(PLUGINS_FOLDER .. '.' .. pmodpath)
			pmodule._module = pmodpath
			if pmodule ~= nil then table.insert(plugins, pmodule) end
		end
	end

	local state = get_savestate_file()
	if file_exists(state) then savestate.load(state) end

	-- update swap counter for this game
	local new_swaps = (config.game_swaps[config.current_game] or 0) + 1
	config.game_swaps[config.current_game] = new_swaps
	write_data('output-info/current-swaps.txt', new_swaps)

	-- update total swap counter
	config.total_swaps = (config.total_swaps or 0) + 1
	write_data('output-info/total-swaps.txt', config.total_swaps)

	-- update game name
	write_data('output-info/current-game.txt', strip_ext(config.current_game))

	-- this code just outright crashes on Bizhawk 2.6.1, go figure
	if checkversion("2.6.2") then
		gui.use_surface('client')
		gui.clearGraphics()
	end

	math.randomseed(config.nseed or config.seed)
	update_next_swap_time()

	for _,plugin in ipairs(plugins) do
		if plugin.on_game_load ~= nil then
			local pdata = config.plugins[plugin._module]
			plugin.on_game_load(pdata.state, pdata.settings)
		end
	end
else
	-- THIS CODE RUNS ONLY ON THE INITIAL SCRIPT SETUP
	client.displaymessages(false)
	if checkversion(MIN_BIZHAWK_VERSION) then
		local setup = require('shuffler-src.setupform')
		setup.initial_setup(complete_setup)
	else
		log_message(string.format("Expected Bizhawk version %s+", MIN_BIZHAWK_VERSION))
		log_message("-- Currently installed version: " .. client.getversion())
		log_message("-- Please update your Bizhawk installation")
	end
end

prev_input = input.get()
frames_since_restart = 0
while true do
	if emu.getsystemid() ~= "NULL" and running then
		-- wait for a frame to pass before turning sound back on
		if frames_since_restart == 1 and config.sound then client.SetSoundOn(true) end

		local frame_count = (config.frame_count or 0) + 1
		config.frame_count = frame_count
		frames_since_restart = frames_since_restart + 1

		-- update the frame count specifically for the active game as well
		local cgf = (config.game_frame_count[config.current_game] or 0) + 1
		config.game_frame_count[config.current_game] = cgf

		-- save time info to files for OBS display
		write_data('output-info/total-time.txt', frames_to_time(frame_count))
		write_data('output-info/current-time.txt', frames_to_time(cgf))

		-- let plugins do operations each frame
		for _,plugin in ipairs(plugins) do
			if plugin.on_frame ~= nil then
				local pdata = config.plugins[plugin._module]
				plugin.on_frame(pdata.state, pdata.settings)
			end
		end

		-- calculate input "rises" by subtracting the previously held inputs from the inputs on this frame
		local input_rise = input.get()
		for k,v in pairs(prev_input) do input_rise[k] = nil end
		prev_input = input.get()

		-- mark the game as complete if the hotkey is pressed (and some time buffer)
		-- the time buffer should hopefully prevent somebody from attempting to
		-- press the hotkey and the game swapping, marking the wrong game complete
		if input_rise[config.hk_complete] and frames_since_restart > math.min(3, config.min_swap/2) * 60 then mark_complete() end

		-- time to swap!
	    if frame_count >= next_swap_time then swap_game() end
	end

	emu.frameadvance()
end
