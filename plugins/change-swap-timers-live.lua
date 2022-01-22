local plugin = {}

plugin.name = "Change Swap Timers Live"
plugin.author = "SushiKishi"
plugin.settings = { 
	{ name="timerFile", type="file", label="What file to use?" },

}

plugin.description =
[[ NOTE: Using this plugin will render the Minimum and Maximum swap times on the setup window useless, as they are overwritten by the plugin. Make sure the setup file contains the times you want to start with before clicking on Start or Resume Session!

This plugin allows you to use a separate .TXT file to update your minimum and maximum swap timers on the fly. This replicates a (probably unintended) feature of the first Bizhawk Shuffler where you could change these on the fly and they would apply without restarting the entire session. You can use this to offer, say, a donation incentive to speed up your swap timers. You'll need to modify this .TXT file yourself -- any sort of Twitch or chat interaction is beyond the scope of what I'm willing to deal with.

There's a default settings file with the plugin, but the file can go wherever you choose. The format has to be specific, however. In case you lose the default file, the only two lines it contains are:

config.min_swap=1
config.max_swap=3

Adjust your minimum/maximum times, in seconds, accordingly. Any kind of check to make sure you've put valid integers there that won't goof up the works is also beyond the scope of what I'm willing to learn -- I just wanted this feature quickly without having to learn how to code beyond the basics.

Finally -- this directly changes the configuation of your Shuffler settings. This is only worth mentinoing because they won't go back to "default" at the start of a new session -- you'll have to modify the plugin's settings file directly every time you load this plugin if you need to revert them back.

]]

-- called once at the start
-- This makes sure the first game swap of the new/resumed session
-- has the same timers as the plugin's configuation file.
-- Otherwise, it uses the numbers on the Shuffler's set-up screen.
function plugin.on_setup(data, settings)
	local liveTimers = loadfile(settings.timerFile) --load the settings file as set in Plugin config
		if liveTimers ~= nil then -- if it exists / is not empty
		liveTimers() -- execute the code inside -- which updates the config.[VARIABLES]
		liveTimers = nil -- remove the file from memory; I mean, yeah, it's a small file, but no sense in it hanging around
		end -- Ends the If/Then statement
end -- Ends the On_Setup part of the plugin

-- called each time a game/state is saved (before swap)
function plugin.on_game_save(data, settings)
	local liveTimers = loadfile(settings.timerFile) --load the settings file as set in Plugin config
	if liveTimers ~= nil then -- if it exists / is not empty
	liveTimers() -- execute the code inside -- which updates the config.[VARIABLES]
	liveTimers = nil -- remove the file from memory; I mean, yeah, it's a small file, but no sense in it hanging around
	end -- Ends the If/Then statement
end -- Ends the on_game_Save part of the plugin


return plugin
