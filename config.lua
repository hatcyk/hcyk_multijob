Config = {}

-- Set your preferred language here: 'en', 'cs', 'pl', 'de'
Config.Locale = 'en'

Config.CustomKeybind = GetResourceState("I") ~= "missing"

Config.Command = {
    OpenMenu = "switchjob",
    Keybind = "F6",
    Description = "Open Multijob", -- if you have I, you can use ~HUD_COLOUR_RADAR_ARMOUR~ to color the text
}

return Config
