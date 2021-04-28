function setup_form(callback)
	local form, seed_text, min_text, max_text, resume, start_btn, plugin_combo
	local hk_complete

	-- I believe none of these conflict with default hotkeys
	local HOTKEY_OPTIONS = {
		'Ctrl+Shift+End',
		'Ctrl+Shift+Delete',
		'Ctrl+Shift+D',
		'Alt+Shift+End',
		'Alt+Shift+Delete',
		'Alt+Shift+D',
	}

	function start_handler()
		if not forms.ischecked(resume) then
			save_new_settings()
		end

		forms.destroy(form)
		callback()
	end

	function save_new_settings()
		config = {}
		config['seed'] = tonumber(forms.gettext(seed_text) or "0")
		config['nseed'] = config['seed']

		local a = tonumber(forms.gettext(min_text) or "15")
		local b = tonumber(forms.gettext(max_text) or "45")
		config['min_swap'] = math.min(a, b)
		config['max_swap'] = math.max(a, b)

		config['hk_complete'] = forms.gettext(hk_complete) or 'Ctrl+Shift+End'
		config['chosen_plugin'] = forms.gettext(plugin_combo)
		config['plugin_state'] = {}
		config['completed_games'] = {}

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

	form = forms.newform(340, 260, "Bizhawk Shuffler v2 Setup")

	seed_text = forms.textbox(form, 0, 100, 20, "UNSIGNED", 10, 10)
	forms.label(form, "Seed", 115, 13, 40, 20)
	forms.settext(seed_text, config['seed'] or random_seed())
	forms.button(form, "Randomize Seed", randomize_seed, 160, 10, 150, 20)

	min_text = forms.textbox(form, 0, 40, 20, "UNSIGNED", 10, 40)
	forms.label(form, "Minimum Swap Time (in seconds)", 55, 43, 200, 20)
	forms.settext(min_text, config['min_swap'] or 15)

	max_text = forms.textbox(form, 0, 40, 20, "UNSIGNED", 10, 70)
	forms.label(form, "Maximum Swap Time (in seconds)", 55, 73, 200, 20)
	forms.settext(max_text, config['max_swap'] or 45)

	hk_complete = forms.dropdown(form, HOTKEY_OPTIONS, 10, 100, 150, 20)
	forms.label(form, "Hotkey: Game Completed", 165, 103, 150, 20)
	forms.settext(hk_complete, config['hk_complete'] or 'Ctrl+Shift+End')

	forms.label(form, "Resuming a run?", 28, 134, 130, 20)
	resume = forms.checkbox(form, "", 10, 130)
	start_btn = forms.button(form, "Start New Shuffler", start_handler, 160, 130, 150, 20)

	function toggle_resuming()
		if forms.ischecked(resume) then
			forms.settext(start_btn, "Resume Existing Shuffler")
		else
			forms.settext(start_btn, "Start New Shuffler")
		end
	end

	forms.addclick(resume, toggle_resuming)

	plugins_table = get_dir_contents(PLUGINS_FOLDER)
	table_subtract(plugins_table, {'empty.lua'})
	table.insert(plugins_table, '[None]')
	table.insert(plugins_table, '[Use A Different Plugin]')

	plugin_combo = forms.dropdown(form, plugins_table, 10, 160, 150, 20)
	forms.label(form, "Game Plugin", 165, 163, 150, 20)

	forms.label(form, "** Based on the original Bizhawk Shuffler by Brossentia", 10, 193, 300, 20)
end
