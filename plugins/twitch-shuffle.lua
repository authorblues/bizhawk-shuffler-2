local plugin = {}

plugin.name = "Twitch Swap"
plugin.author = "dennisrijsdijk/DennisOnTheInternet"
plugin.minversion = "0.0.1"
plugin.settings =
{
	{ name='lookupCooldown', type='number', label='Cooldown between lookups (no previous action)', default=5 },
	{ name='afterActionookupCooldown', type='number', label='Cooldown between lookups, after a swap', default=30 },
	{ name='apitoken', type='text', label='API Token', password=true },
}

plugin.description =
[[
	Uses a custom API and Webhook Callback to receive bits and subscriptions from Twitch and shuffle accordingly
]]

function plugin.on_frame(data, settings)
-- code TBD
end

return plugin
