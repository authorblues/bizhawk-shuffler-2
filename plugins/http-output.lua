local plugin = {}

plugin.name = "HTTP Output"
plugin.author = "VodBox"
plugin.minversion = "2.6.2"
plugin.settings = {{
	name = 'endpoint',
	type = 'text',
	label = 'HTTP Endpoint',
	default = ''
}, {
	name = 'completed_games',
	type = 'boolean',
	label = 'Completed Games',
	default = true
}, {
	name = 'current_game',
	type = 'boolean',
	label = 'Current Game',
	default = true
}, {
	name = 'current_swaps',
	type = 'boolean',
	label = 'Current Swaps',
	default = false
}, {
	name = 'current_time',
	type = 'boolean',
	label = 'Current Time',
	default = false
}, {
	name = 'total_swaps',
	type = 'boolean',
	label = 'Total Swaps',
	default = false
}, {
	name = 'total_time',
	type = 'boolean',
	label = 'Total Time',
	default = false
}}

plugin.description = [[
	Sends information about the current and completed games to an HTTP endpoint for remote tracking.

	NOTE: This script requires BizHawk to be initialized with --url_get and/or a --url_post parameter. This does not have to match the endpoint used when configuring this script. (e.g. "..\EmuHawk.exe --url_get=. --url_post=.")
]]

function plugin.on_complete(data, settings)
	if settings.completed_games then
		local url = settings.endpoint .. '/completed-games'

		local completed = {}
		for _, game in ipairs(config.completed_games) do
			table.insert(completed, strip_ext(game))
		end

		comm.httpPost(url, '["' .. table.concat(completed, '", "') .. '"]')
	end
end

function plugin.on_game_load(data, settings)
	if settings.current_swaps then
		local url = settings.endpoint .. '/current-swaps'
		local new_swaps = (config.game_swaps[config.current_game] or 0) + 1
		comm.httpPost(url, new_swaps)
	end

	if settings.total_swaps then
		local url = settings.endpoint .. '/total-swaps'
		comm.httpPost(url, config.total_swaps)
	end

	if settings.current_game then
		local url = settings.endpoint .. '/current-game'
		comm.httpPost(url, strip_ext(config.current_game))
	end
end

local ptime_total = nil
local ptime_game = nil

function plugin.on_frame(data, settings)
	if settings.current_time then
		local url = settings.endpoint .. '/current-time'
		local cgf = (config.game_frame_count[config.current_game] or 0) + 1

		local time_game = frames_to_time(cgf)
		if time_game ~= ptime_game then
			comm.httpPost(url, frames_to_time(cgf))
			ptime_game = time_game
		end
	end

	if settings.total_time then
		local url = settings.endpoint .. '/total-time'
		local frame_count = (config.frame_count or 0) + 1

		local time_total = frames_to_time(frame_count)
		if time_total ~= ptime_total then
			comm.httpPost(url, frames_to_time(frame_count))
			ptime_total = time_total
		end
	end
end

return plugin
