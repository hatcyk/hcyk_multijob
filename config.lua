Config = {}

-- Set your preferred language here: 'en', 'cs', 'pl', 'de', 'ru', 'fr', 'es'
Config.Locale = 'cs'

-- Enable or disable debug mode (true = on, false = off)
Config.DebugMode = false

Config.CustomKeybind = GetResourceState("I") ~= "missing"

Config.Command = {
    OpenMenu = "switchjob",
    Keybind = "F6",
    Description = "Open Multijob", -- if you have I, you can use ~HUD_COLOUR_RADAR_ARMOUR~ to color the text
}

Config.EnableDiscordLogs = true -- Enable or disable Discord logging (true = on, false = off)
-- Replace your webhook in server.lua
Config.DiscordWebhookUsername = "Hcyk - MultiJob" -- Replace with your username
Config.DiscordWebhookLogo = "https://i.ibb.co/8DCKZ4r2/logo-hcyk-dev.png" -- Replace with your avatar URL
Config.Logs = {
    RemoveJob = true,
    SwitchJob = true,
    AddJob    = true,
}

return Config