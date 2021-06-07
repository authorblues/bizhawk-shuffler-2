local module = {}

function module.initial_setup(callback)
	local form, seed_text, min_text, max_text, resume, start_btn
	local mode_combo, hk_complete, plugin_combo

	local plugins_table = {'[None]'}
	local plugins_meta = {}

	for _,filename in ipairs(get_dir_contents(PLUGINS_FOLDER)) do
		-- ignore non-lua files
		if ends_with(filename, '.lua') then
			local pname = filename:sub(1, #filename-4)
			local plugin = require(PLUGINS_FOLDER .. '.' .. pname)

			table.insert(plugins_table, plugin.name)
			plugins_meta[plugin.name] = pname
		end
	end

	local SWAP_MODES_DEFAULT = 'Random Order (Default)'
	local SWAP_MODES = {[SWAP_MODES_DEFAULT] = -1, ['Fixed (Alphabetical) Order'] = 0}

	-- I believe none of these conflict with default Bizhawk hotkeys
	local HOTKEY_OPTIONS = {
		'Ctrl+Shift+End',
		'Ctrl+Shift+Delete',
		'Ctrl+Shift+D',
		'Alt+Shift+End',
		'Alt+Shift+Delete',
		'Alt+Shift+D',
	}

	function start_handler()
		local setup = not forms.ischecked(resume)
		if setup then save_new_settings() end
		get_games_list(true) -- force refresh of the games list

		forms.destroy(form)
		plugin_setup(config['plugins'], 1)
	end

	function create_plugin_settings_window(plugin, plist, px)
		if plugin == nil or #(plugin.settings or {}) == 0 then
			return plugin_setup(plist, px+1)
		end

		local form = forms.newform(340, 110 + 30 * #plugin.settings, "Plugin Setup")
		forms.label(form, 'Plugin Setup for ' .. plugin.name, 10, 13, 310, 20)

		local SETTINGS_TYPES =
		{
			['boolean'] = {
				make = function(setting, y)
					setting.input = forms.checkbox(form, setting.label, 10, y)
					forms.setproperty(setting.input, "Width", 330)
				end,
				getData = function(setting) return forms.ischecked(setting.input) end,
			},
			['romlist'] = {
				make = function(setting, y)
					setting.input = forms.dropdown(form, get_games_list(), 10, y, 200, 20)
					forms.label(form, setting.label, 215, y+3, 100, 20)
				end,
				getData = function(setting) return forms.gettext(setting.input) end,
			},
			['file'] = {
				make = function(setting, y)
					local click = function()
						setting._response = forms.openfile(setting.filename,
							setting.directory, setting.filter) or setting._response
						forms.settext(setting.input, setting._response)
					end
					setting.input = forms.button(form, "[ Select File ]", click, 10, y, 200, 20)
					forms.label(form, setting.label, 215, y+3, 100, 20)
				end,
				getData = function(setting) return setting._response or nil end,
			},
			['select'] = {
				make = function(setting, y)
					setting.input = forms.dropdown(form, setting.options, 10, y, 150, 20)
					if setting.default then forms.settext(setting.input, setting.default) end
					forms.label(form, setting.label, 165, y+3, 150, 20)
				end,
				getData = function(setting) return forms.gettext(setting.input) end,
			},
			['text'] = {
				make = function(setting, y)
					setting.input = forms.textbox(form, "", 150, 20, nil, 10, y)
					forms.label(form, setting.label, 165, y+3, 150, 20)
				end,
				getData = function(setting) return forms.gettext(setting.input) end,
			},
			['number'] = {
				make = function(setting, y)
					setting.input = forms.textbox(form, "", 150, 20, setting.datatype, 10, y)
					forms.label(form, setting.label, 165, y+3, 150, 20)
				end,
				getData = function(setting) return tonumber(forms.gettext(setting.input) or "0") end,
			},
			['info'] = {
				make = function(setting, y)
					forms.label(form, setting.text, 10, y+3, 305, 20)
				end,
				getData = function(setting) return false end,
			},
		}

		local y = 40
		for _,setting in ipairs(plugin.settings) do
			local meta = SETTINGS_TYPES[setting.type:lower()]
			if meta ~= nil then meta.make(setting, y); y = y + 30 end
		end

		local next_fn = function()
			for _,setting in ipairs(plugin.settings) do
				local meta = SETTINGS_TYPES[setting.type:lower()]
				if meta ~= nil and setting.name ~= nil then
					config['plugin_settings'][setting.name] = meta.getData(setting)
				end
			end

			forms.destroy(form)
			plugin_setup(plist, px+1)
		end

		local save = forms.button(form, "Save Settings", next_fn, 160, y, 150, 20)
	end

	function plugin_setup(plist, px)
		if px > #plist then return callback() end
		local plugin = require(PLUGINS_FOLDER .. '.' .. plist[px])
		create_plugin_settings_window(plugin, plist, px)
	end

	function save_new_settings()
		config = {}
		config['seed'] = tonumber(forms.gettext(seed_text) or "0")
		config['nseed'] = config['seed']

		local a = tonumber(forms.gettext(min_text) or "15")
		local b = tonumber(forms.gettext(max_text) or "45")
		config['min_swap'] = math.min(a, b)
		config['max_swap'] = math.max(a, b)

		config['shuffle_index'] = SWAP_MODES[forms.gettext(mode_combo)]
		config['hk_complete'] = forms.gettext(hk_complete) or 'Ctrl+Shift+End'
		config['completed_games'] = {}

		config['plugins'] = {}
		config['plugin_settings'] = {}
		config['plugin_state'] = {}

		local selected_plugin = forms.gettext(plugin_combo)
		if selected_plugin ~= '[None]' then
			table.insert(config['plugins'], plugins_meta[selected_plugin])
		end

		-- internal information for output
		config['frame_count'] = 0
		config['total_swaps'] = 0
		config['game_frame_count'] = {}
		config['game_swaps'] = {}
	end

	function random_seed()
		math.randomseed(os.time() + os.clock()*1000)
		for i = 0, 1000 do math.random() end
		return math.random(999999999)
	end

	function randomize_seed()
		forms.settext(seed_text, random_seed())
	end

	form = forms.newform(340, 230, "Bizhawk Shuffler v2 Setup")

	seed_text = forms.textbox(form, 0, 100, 20, "UNSIGNED", 10, 10)
	forms.label(form, "Seed", 115, 13, 40, 20)
	forms.settext(seed_text, config['seed'] or random_seed())
	forms.button(form, "Randomize Seed", randomize_seed, 160, 10, 150, 20)

	min_text = forms.textbox(form, 0, 48, 20, "UNSIGNED", 10, 40)
	max_text = forms.textbox(form, 0, 48, 20, "UNSIGNED", 62, 40)
	forms.label(form, "Min/Max Swap Time (in seconds)", 115, 43, 200, 20)
	forms.settext(min_text, config['min_swap'] or 15)
	forms.settext(max_text, config['max_swap'] or 45)

	local _SWAP_MODES = {}
	for k,v in pairs(SWAP_MODES) do
		table.insert(_SWAP_MODES, k)
	end

	mode_combo = forms.dropdown(form, _SWAP_MODES, 10, 70, 150, 20)
	forms.label(form, "Shuffler Swap Mode", 165, 73, 150, 20)
	forms.settext(mode_combo, SWAP_MODES_DEFAULT)

	hk_complete = forms.dropdown(form, HOTKEY_OPTIONS, 10, 100, 150, 20)
	forms.label(form, "Hotkey: Game Completed", 165, 103, 150, 20)
	forms.settext(hk_complete, config['hk_complete'] or 'Ctrl+Shift+End')

	plugin_combo = forms.dropdown(form, plugins_table, 10, 130, 150, 20)
	forms.label(form, "Game Plugin", 165, 133, 150, 20)

	resume = forms.checkbox(form, "Resuming a run?", 10, 160)
	forms.setproperty(resume, "Width", 150)
	start_btn = forms.button(form, "Start New Shuffler", start_handler, 160, 160, 150, 20)

	function toggle_resuming()
		if forms.ischecked(resume) then
			forms.settext(start_btn, "Resume Existing Shuffler")
		else
			forms.settext(start_btn, "Start New Shuffler")
		end
	end

	forms.addclick(resume, toggle_resuming)
end

return module
