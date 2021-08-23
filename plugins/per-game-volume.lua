local MIN_VOLUME = 0
local MAX_VOLUME = 100

local plugin = {}
plugin.name = "Per-Game Volume"
plugin.author = "kalimag"
plugin.settings = {
	{ name='default_volume', type='number', datatype='UNSIGNED', label='Default Volume (0-100)', default=MAX_VOLUME },
}
plugin.description =
[[
	Remembers BizHawk's volume setting for each game separately and restores it when swapping back to the game.

	Bind Volume Up/Volume Down in the BizHawk hotkey menu to use this plugin effectively.
]]



local function sanitize_volume(volume)
	if type(volume) ~= 'number' then return nil end
	return math.floor(math.max(math.min(volume, MAX_VOLUME), MIN_VOLUME))
end

local function get_volume()
	return sanitize_volume(client.getconfig().SoundVolume)
end

local function set_volume(volume)
	volume = sanitize_volume(volume)
	if volume then
		client.getconfig().SoundVolume = volume
	end
end

function plugin.on_setup(data, settings)
	settings.default_volume = sanitize_volume(settings.default_volume) or MAX_VOLUME
end

function plugin.on_game_load(data, settings)
	set_volume(data[config.current_game] or settings.default_volume)
end

function plugin.on_game_save(data, settings)
	data[config.current_game] = get_volume()
end

return plugin