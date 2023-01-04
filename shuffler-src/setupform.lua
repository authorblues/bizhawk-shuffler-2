local module = {}

local NEWLINE = "\r\n"

function module.make_plugin_window(plugins, main_plugin_label)
	local plugin_combo, info_box, enabled_label
	local SETTINGS_X = 370

	local selected_plugin = nil
	local plugin_map = {}

	local SETTINGS_TYPES =
	{
		['boolean'] = {
			make = function(plugin, win, setting, x, y)
				setting.input = forms.checkbox(win, setting.label, x, y)
				if setting.default or setting._value then forms.setproperty(setting.input, "Checked", true) end
				forms.setproperty(setting.input, "Width", 330)

				table.insert(plugin._ui, setting.input)
				return 30
			end,
			getData = function(setting) return forms.ischecked(setting.input) end,
		},
		['romlist'] = {
			make = function(plugin, win, setting, x, y)
				local games_list = get_games_list()
				table.insert(games_list, "")

				setting.input = forms.dropdown(win, games_list, x, y, 200, 20)
				local label = forms.label(win, setting.label, x+205, y+3, 100, 20)
				if setting._value then forms.settext(setting.input, setting._value) end

				table.insert(plugin._ui, setting.input)
				table.insert(plugin._ui, label)
				return 30
			end,
			getData = function(setting) return forms.gettext(setting.input) end,
		},
		['file'] = {
			make = function(plugin, win, setting, x, y)
				local click = function()
					setting._response = forms.openfile(setting.filename,
						setting.directory, setting.filter) or setting._response
					forms.settext(setting.input, setting._response)
				end
				setting.input = forms.button(win, "[ Select File ]", click, x, y, 200, 20)
				if setting._value then
					setting._response = setting._value
					forms.settext(setting.input, setting._response)
				end
				local label = forms.label(win, setting.label, x+205, y+3, 100, 20)

				table.insert(plugin._ui, setting.input)
				table.insert(plugin._ui, label)
				return 30
			end,
			getData = function(setting) return setting._response or nil end,
		},
		['select'] = {
			make = function(plugin, win, setting, x, y)
				setting.input = forms.dropdown(win, setting.options, x, y, 150, 20)
				if setting.default then forms.settext(setting.input, setting.default) end
				if setting._value then forms.settext(setting.input, setting._value) end
				local label = forms.label(win, setting.label, x+155, y+3, 150, 20)

				table.insert(plugin._ui, setting.input)
				table.insert(plugin._ui, label)
				return 30
			end,
			getData = function(setting) return forms.gettext(setting.input) end,
		},
		['text'] = {
			make = function(plugin, win, setting, x, y)
				setting.input = forms.textbox(win, "", 150, 20, nil, x, y)
				if setting.default then forms.settext(setting.input, setting.default) end
				if setting._value then forms.settext(setting.input, setting._value) end
				if setting.password then forms.setproperty(setting.input, "PasswordChar", '*') end
				local label = forms.label(win, setting.label, x+155, y+3, 150, 20)

				table.insert(plugin._ui, setting.input)
				table.insert(plugin._ui, label)
				return 30
			end,
			getData = function(setting) return forms.gettext(setting.input) end,
		},
		['number'] = {
			make = function(plugin, win, setting, x, y)
				setting.input = forms.textbox(win, "", 150, 20, setting.datatype, x, y)
				if setting.default then forms.settext(setting.input, setting.default) end
				if setting._value then forms.settext(setting.input, setting._value) end
				local label = forms.label(win, setting.label, x+155, y+3, 150, 20)

				table.insert(plugin._ui, setting.input)
				table.insert(plugin._ui, label)
				return 30
			end,
			getData = function(setting) return tonumber(forms.gettext(setting.input) or "0") end,
		},
	}

	function setup_plugin_settings(win, x, plugin)
		if plugin == nil then return end
		plugin._ui = {}

		local y = 40
		for _,setting in ipairs(plugin.settings) do
			local meta = SETTINGS_TYPES[setting.type:lower()]
			if meta ~= nil then y = y + meta.make(plugin, win, setting, x, y) end
		end
	end

	local plugin_window = forms.newform(700, 600, "Plugins Setup")

	local plugin_error_text = forms.label(plugin_window, "", SETTINGS_X, 43, 300, 200)
	forms.setproperty(plugin_error_text, "Visible", false)

	function save_plugin_settings()
		for _,plugin in ipairs(plugins) do
			plugin._enabled = forms.ischecked(plugin._ui._enabled)
			if plugin._enabled then
				for _,setting in ipairs(plugin.settings) do
					local meta = SETTINGS_TYPES[setting.type:lower()]
					if meta ~= nil and setting.name ~= nil and meta.getData ~= nil then
						setting._value = meta.getData(setting)
					end
				end
			end
		end

		module.update_plugin_label()

		-- close plugin window if open
		forms.destroy(plugin_window)
	end

	function update_plugins()
		local enabled_list, enabled_count = "", 0
		for _,plugin in ipairs(plugins) do
			local plugin_selected = (forms.gettext(plugin_combo) == plugin.name)
			if plugin_selected then
				selected_plugin = plugin.name
				local text = plugin.name .. NEWLINE
				text = text .. "by " .. (plugin.author or "Unknown") .. NEWLINE .. NEWLINE
				if plugin.description then
					local desc = plugin.description
					desc = desc:gsub('\n[\t ]*', NEWLINE) -- fix newlines and remove line-leading whitespace
					desc = desc:match( "^%s*(.-)%s*$" ) -- remove string-leading and -trailing whitespace
					text = text .. desc
				end
				forms.settext(info_box, text)

				local bad_version = not checkversion(plugin.minversion)
				if bad_version then
					forms.setproperty(plugin._ui._enabled, "Enabled", false)
					forms.setproperty(plugin._ui._enabled, "Checked", false)
					forms.settext(plugin_error_text,
						string.format("This plugin is designed for Bizhawk version %s+\r\nYou are using Bizhawk version %s",
							plugin.minversion or MIN_BIZHAWK_VERSION, client.getversion()))
				end
				forms.setproperty(plugin_error_text, "Visible", bad_version)
			end

			local plugin_enabled = forms.ischecked(plugin._ui._enabled)
			if plugin_enabled then
				enabled_list = enabled_list .. ", " .. plugin.name
				enabled_count = enabled_count + 1
			end
			forms.setproperty(plugin._ui._enabled, "Visible", plugin_selected)
			for _,ui in ipairs(plugin._ui) do
				forms.setproperty(ui, "Visible", plugin_selected and plugin_enabled)
			end
		end

		forms.settext(enabled_label, string.format("Enabled Plugins (%d): %s", enabled_count, enabled_list:sub(3)))
	end

	function correct_enabled_misclick()
		if forms.gettext(plugin_combo) ~= selected_plugin then
			local prev_plugin = plugin_map[selected_plugin]
			local curr_plugin = plugin_map[forms.gettext(plugin_combo)]

			local target_state = forms.ischecked(prev_plugin._ui._enabled)
			forms.setproperty(prev_plugin._ui._enabled, "Checked", not target_state)
			forms.setproperty(curr_plugin._ui._enabled, "Checked", target_state)
		end
		update_plugins()
	end

	local plugin_names = {'[ Choose a Plugin ]'}
	for _,plugin in ipairs(plugins) do
		local name = plugin.name
		table.insert(plugin_names, name)
		plugin_map[name] = plugin

		setup_plugin_settings(plugin_window, SETTINGS_X, plugin)
		plugin._ui._enabled = forms.checkbox(plugin_window, "Enabled", SETTINGS_X, 10)
		forms.setproperty(plugin._ui._enabled, "Visible", false)
		forms.setproperty(plugin._ui._enabled, "Width", 330)
		forms.setproperty(plugin._ui._enabled, "Checked", plugin._enabled)
		forms.addclick(plugin._ui._enabled, correct_enabled_misclick)

		for _,ui in ipairs(plugin._ui) do
			forms.setproperty(ui, "Visible", false)
		end
	end

	plugin_combo = forms.dropdown(plugin_window, plugin_names, 10, 10, 280, 20)
	forms.button(plugin_window, "Select", update_plugins, 300, 10, 60, 22)

	info_box = forms.textbox(plugin_window, "", 350, 450, nil, 10, 40, true, false, "Vertical")
	forms.setproperty(info_box, "ReadOnly", true)

	enabled_label = forms.label(plugin_window, "", 10, 500, 500, 50)
	forms.button(plugin_window, "Save and Close", save_plugin_settings, 520, 530, 150, 20)

	update_plugins()
	return plugin_window
end

function module.initial_setup(callback)
	local setup_window, resume, start_btn
	local seed_text, min_text, max_text
	local mode_combo, hk_complete, plugin_label
	local plugin_window = -1

	local plugins = {}
	for _,filename in ipairs(get_dir_contents(PLUGINS_FOLDER)) do
		-- ignore non-lua files
		if ends_with(filename, '.lua') then
			local pname = filename:sub(1, #filename-4)
			local pmodule = require(PLUGINS_FOLDER .. '.' .. pname)
			pmodule._enabled = false
			pmodule._module = pname
			-- restore plugin data from existing config
			local plugin_data = config.plugins and config.plugins[pname]
			if plugin_data then
				pmodule._enabled = true
				for _,setting in ipairs(pmodule.settings) do
					setting._value = plugin_data.settings[setting.name]
				end
			end
			table.insert(plugins, pmodule)
		end
	end

	local SWAP_MODES_DEFAULT = 'Random Order (Default)'
	local SWAP_MODES = {[SWAP_MODES_DEFAULT] = -1, ['Fixed Order'] = 0}

	-- I believe none of these conflict with default Bizhawk hotkeys
	local HOTKEY_OPTIONS = {
		'Ctrl+Shift+End',
		'Ctrl+Shift+Delete',
		'Ctrl+Shift+D',
		'Alt+Shift+End',
		'Alt+Shift+Delete',
		'Alt+Shift+D',
		'Backslash (above Enter)',
		'RightCtrl',
	}

	function start_handler()
		if not forms.ischecked(resume) then save_new_settings() end
		get_games_list(true) -- force refresh of the games list

		forms.destroy(setup_window)
		callback()
	end

	function save_new_settings()
		config = {}
		config.seed = tonumber(forms.gettext(seed_text) or "0")
		config.nseed = config.seed

		config.auto_shuffle = true
		config.output_timers = true
		local a = tonumber(forms.gettext(min_text) or "15")
		local b = tonumber(forms.gettext(max_text) or "45")
		config.min_swap = math.min(a, b)
		config.max_swap = math.max(a, b)

		config.shuffle_index = SWAP_MODES[forms.gettext(mode_combo)]
		config.hk_complete = (forms.gettext(hk_complete) or 'Ctrl+Shift+End'):match("[^%s]+")
		config.completed_games = {}

		config.plugins = {}
		for _,plugin in ipairs(plugins) do
			if plugin._enabled then
				local plugin_data = { ['state']={}, ['settings']={} }
				for _,setting in ipairs(plugin.settings) do
					if setting.name ~= nil and setting._value ~= nil then
						plugin_data.settings[setting.name] = setting._value
					end
				end
				config.plugins[plugin._module] = plugin_data
			end
		end

		-- internal information for output
		config.frame_count = 0
		config.total_swaps = 0
		config.game_frame_count = {}
		config.game_swaps = {}
	end

	function main_cleanup()
		forms.destroy(plugin_window)
	end

	function random_seed()
		math.randomseed(os.time() + os.clock()*100000)
		return math.random(MAX_INTEGER)
	end

	function module.update_plugin_label()
		local plugin_name
		local count = 0
		for _, plugin in pairs(plugins) do
			if plugin._enabled then
				count = count + 1
				plugin_name = plugin.name
			end
		end
		local text = 'No Plugins Loaded'
		if count == 1 then text = plugin_name end
		if count > 1 then text = count .. ' Plugins Loaded' end
		forms.settext(plugin_label, text)
	end

	local y = 10
	setup_window = forms.newform(340, 230, "Bizhawk Shuffler v2 Setup", main_cleanup)

	seed_text = forms.textbox(setup_window, 0, 100, 20, "UNSIGNED", 10, y)
	forms.label(setup_window, "Seed", 115, y+3, 40, 20)
	forms.settext(seed_text, config.seed or random_seed())

	forms.button(setup_window, "Randomize Seed", function()
		forms.settext(seed_text, random_seed())
	end, 160, y, 150, 20)
	y = y + 30

	min_text = forms.textbox(setup_window, 0, 48, 20, "UNSIGNED", 10, y)
	max_text = forms.textbox(setup_window, 0, 48, 20, "UNSIGNED", 62, y)
	forms.label(setup_window, "Min/Max Swap Time (in seconds)", 115, y+3, 200, 20)
	forms.settext(min_text, config.min_swap or 15)
	forms.settext(max_text, config.max_swap or 45)
	y = y + 30

	local _SWAP_MODES = {}
	for k,v in pairs(SWAP_MODES) do
		table.insert(_SWAP_MODES, k)
	end

	mode_combo = forms.dropdown(setup_window, _SWAP_MODES, 10, y, 150, 20)
	forms.label(setup_window, "Shuffler Swap Order", 165, y+3, 150, 20)
	forms.settext(mode_combo, SWAP_MODES_DEFAULT)
	y = y + 30

	hk_complete = forms.dropdown(setup_window, HOTKEY_OPTIONS, 10, y, 150, 20)
	forms.label(setup_window, "Hotkey: Game Completed", 165, y+3, 150, 20)
	forms.settext(hk_complete, config.hk_complete or 'Ctrl+Shift+End')
	y = y + 30

	forms.button(setup_window, "Setup Plugins", function()
		forms.destroy(plugin_window)
		plugin_window = module.make_plugin_window(plugins, plugin_label)
	end, 10, y, 150, 20)
	plugin_label = forms.label(setup_window, "", 165, y+3, 150, 20)
	module.update_plugin_label()
	y = y + 30

	resume = forms.checkbox(setup_window, "Resuming a session?", 10, y)
	forms.setproperty(resume, "AutoSize", true)
	start_btn = forms.button(setup_window, "Start New Session", start_handler, 160, y, 150, 20)
	y = y + 30

	if config.current_game ~= nil and #get_games_list(true) > 0 then
		forms.setproperty(resume, "Checked", true)
		forms.settext(start_btn, "Resume Previous Session")
	end

	forms.addclick(resume, function()
		if forms.ischecked(resume) then
			forms.settext(start_btn, "Resume Previous Session")
		else
			forms.settext(start_btn, "Start New Session")
		end
	end)

	event.onexit(function()
		forms.destroy(setup_window)
	end)
end

return module
