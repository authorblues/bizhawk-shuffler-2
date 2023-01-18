local plugin = {}

plugin.name = "Countdown to Swap"
plugin.author = "authorblues"
plugin.minversion = "2.6.2"
plugin.settings =
{
	{ name='threshold', type='number', label='Threshold (in seconds)', default=3 },
	{ name='fontsize', type='number', datatype='UNSIGNED', label='Font Size', default=12 },
}

plugin.description =
[[
	Provides an on-screen warning when a swap is about to happen. This makes the shuffler slightly easier.
]]

function plugin.on_frame(data, settings)
	local seconds = math.ceil((next_swap_time - config.frame_count) / 60)
	if seconds <= settings.threshold then
		gui.use_surface('client')
		gui.drawText(10, 10, string.format("Swapping in %d...", seconds), 0xFFFFFFFF, 0xFF000000, settings.fontsize or 12)
	end
end

return plugin
