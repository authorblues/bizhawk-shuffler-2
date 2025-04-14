local plugin = {}

plugin.name = "Modifiable Swap Timers"
plugin.author = "SushiKishi"
plugin.settings = { 
	{ name="minTimerFile", type="file", label="<--Min Swap Time File" },
	{ name="maxTimerFile", type="file", label="<--Max Swap Time File" }

}

plugin.description =
[[ This plugin allows you to control the minimum and maximum swap timers by modifying text files on your computer. This can be used in conjuction with, for example, a Twitch bot that updates the file when viewers redeem a chat reward. It's up to you to make sure your data is valid. If your values get 'swapped' somehow (your min is higher than your max), the plugin will swap them. If the plugin can't understand the files, it will stop the shuffler and put an error message in the Lua console.

Something to note when using this plugin that seems obvious, but might sneak by you on initial use:
This plugin overrides the minimum and maximum timer settings in the plugin's configuration screen. The values there are ignored entirely (and directly overwritten) by this plugin.
If you have to reset these values to a default number, for example at the start of your stream, you have to modify the *text files*, not the *config screen,* at the start of every session.

]]


function modifiable_swap_timers(minTimerFile, maxTimerFile, bootUp)

	local minFile = io.open(minTimerFile, "r") --load the min value, as set in Plugin config
	local maxFile = io.open(maxTimerFile, "r") --load the max value, as set in Plugin config

	--Start processing data if both files were found.
	if minFile ~= nil and maxFile ~= nil then 

		local minContents = minFile:read()
		local maxContents = maxFile:read()
		local min = tonumber(minContents)
		local max = tonumber(maxContents)
		
		-- update the min/max only if both are numbers. Otherwise, do nothin'
		if type(min) == "number" and type(max) =="number" then 

			min = math.floor(min + 0.5)
			max = math.floor(max + 0.5)

			--check they're input in the right order...
			if min > max then min, max = max, min end
			
			config.min_swap=min
			config.max_swap=max

		--one or both files did not contain numbers.
		else

			local errorMsg = "\n(" .. os.date("%H:%M:%S") .. ") :: The Modifiable Swap Timers plugin ran into an error reading your files.\nYour timer files could not be processed by the plugin.\nYour minimum time file contained: " .. tostring(minContents) .. "\nYour maximum time file contained: " .. tostring(maxContents) .. "\n"
		
		if bootUp then
			
			errorMsg = "\nThe Shuffler was stopped on start-up due to an error." .. errorMsg
			error(errorMsg)
			
		else
			mstDisplayMsgFrames = 300
			print(errorMsg)
		end
			

		end
		--End updating min/max

	--one or both files were not found.
	else
		local errorMsg = "\n(" .. os.date("%H:%M:%S") .. ") :: The Modifiable Swap Timers plugin ran into an error loading your files.\nThe files you selected in the plugin's settings could not be found.\nMinimum timer file location: " .. tostring(minTimerFile) .. "\nMaximum timer file location: " .. tostring(maxTimerFile) .. "\n"
		
		if bootUp then
			
			errorMsg = "\nThe Shuffler was stopped on start-up due to an error." .. errorMsg
			error(errorMsg)
			
		else
			mstDisplayMsgFrames = 300
			print(errorMsg)
		end
		
	end
	--end processing data
	

end --end main plugin function


--This function is called once at the start of the session; if the plugin isn't called here, the first swap uses the "configuration screen" values.
function plugin.on_setup(data, settings)

	--initialize some variables
	mstDisplayMsgFrames = 0
	
	--check both files were set in settings, then run the plugin

	if settings.minTimerFile ~= nil and settings.maxTimerFile ~= nil then modifiable_swap_timers(settings.minTimerFile, settings.maxTimerFile, true)
	else
		error("\n()" .. os.date("%H:%M:%S") .. ")  The Modifiable Swap Timer plugin ran into an error on initial load, and stopped the Shuffler from starting.\nPlease double-check the plugin's settings page and make sure both files are set.")
		
	end

end -- Ends the On_Setup part of the plugin


--This is called every time the shuffler makes a save state, right before a swap.
function plugin.on_game_save(data, settings)
	
	--check both files were set in settings, then run the plugin
	if settings.minTimerFile ~= nil and settings.maxTimerFile ~= nil then modifiable_swap_timers(settings.minTimerFile, settings.maxTimerFile, false)
	
	else
		print("\n" .. os.date("%H:%M:%S") .. " -- Somehow, the settings for the Modifiable Swap Timers plugin were erased mid-session.\nThis plugin doesn't delete files; the error must have been caused by another plugin or interaction.\nIf you are using a stream bot to manage the files for this plugin, check its settings.")

	end

end -- Ends the on_game_Save part of the plugin

--executes every frame. Only needed to display error messages.
function plugin.on_frame(data, settings)
	
	if mstDisplayMsgFrames > 0 then --display error
		
		mstDisplayMsgFrames = mstDisplayMsgFrames - 1

		gui.use_surface('client')
		gui.drawText((client.screenwidth() / 2), 25, string.format("Modifiable Swap Timer Error. See Lua Console."), 0xFFCCCCFF, 0xFF000000, 14, nil, nil, "center", nil)
	
	end --end error display

end --end on_frame plugin

return plugin
