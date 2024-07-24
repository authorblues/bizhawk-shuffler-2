local plugin = {}

plugin.name = "Trigger Swap"
plugin.author = "authorblues"
plugin.settings =
{
	{ name='triggerfile', type='file', label='Trigger File' },
}

plugin.description =
[[
	Trigger a swap when a file is created at a specified path. For compatibility with other tools that might want to trigger a swap.

	Steps:
	1) Create a sample file at the appropriate location. This will be the file that the plugin is looking for to trigger a swap.
	2) Select the file with the file selector on the right -->
	3) Run the shuffler. **The shuffler will delete this file.**

	Do not select a file you don't wish to be deleted! Setup a program to create the file at that same location any time a swap should occur. The plugin will swap when that file exists and delete the file automatically.
]]

function plugin.on_frame(data, settings)
	if settings.triggerfile then
		local fn = loadfile(settings.triggerfile)
		if fn ~= nil then
			os.remove(settings.triggerfile)
			swap_game_delay(1)
		end
	end
end

return plugin
