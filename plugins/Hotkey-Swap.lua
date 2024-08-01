local plugin = {}

plugin.name = "Hotkey Game Swap"
plugin.author = "Aestolia & SaggingRufus"
plugin.settings = {

{name='pressget', type='select', label="Hotkey for Swap", options={"Ctrl+Alt+Insert", "Ctrl+Shift+Insert", "Ctrl+Alt+Shift+Insert", "Alt+Shift+Insert"}},

}

plugin.description =
[[
Uses select hotkey combination to force a the game to change to the next one.

code was canibalized from the authorblues Shuffler.lua
]]

function plugin.on_frame(data, settings)

local press = settings.pressget

		-- calculate input "rises" by subtracting the previously held inputs from the inputs on this frame
		local input_rise = input.get()
		for k,v in pairs(prev_input) do input_rise[k] = nil end
		prev_input = input.get()

		-- mark the game as complete if the hotkey is pressed (and some time buffer)
		if input_rise[press] then swap_game()
		end
end
return plugin