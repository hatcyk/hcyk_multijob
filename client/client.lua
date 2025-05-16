-- client.lua
local ESX = exports["es_extended"]:getSharedObject()
local Config = require 'config'
local langModule = require 'lang'
local Lang = langModule.Lang
local _L = langModule._L
local isMenuOpen = false

AddEventHandler('esx:onPlayerDeath', function()
  if isMenuOpen then
      CloseMultiJobMenu()
  end
end)

function OpenMultiJobMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    SendNUIMessage({
        action = 'setVisible',
        data = true
    })
    SetNuiFocus(true, true)
    
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end

function CloseMultiJobMenu()
    if not isMenuOpen then return end
    
    isMenuOpen = false
    SendNUIMessage({
        action = 'setVisible',
        data = false
    })
    SetNuiFocus(false, false)
    
    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end

RegisterCommand(Config.Command.OpenMenu, function()
    OpenMultiJobMenu()
end, false)

if Config.CustomKeybind then
    exports['I']:RegisterKeyMap(Config.Command.OpenMenu, Config.Command.Description, Config.Command.Keybind)
else 
    RegisterKeyMapping(Config.Command.OpenMenu, Config.Command.Description, 'keyboard', Config.Command.Keybind)
end


RegisterNUICallback('getJobs', function(data, cb)
    ESX.TriggerServerCallback('hcyk_multijob:getJobs', function(response)
        cb(response)
    end)
end)

RegisterNUICallback('switchJob', function(data, cb)
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    ESX.TriggerServerCallback('hcyk_multijob:switchJob', function(response)
        if response.success then
            PlaySoundFrontend(-1, "MEDAL_UP", "HUD_MINI_GAME_SOUNDSET", false)
        else
            PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        end
        cb(response)
    end, data)
end)

RegisterNUICallback('removeJob', function(data, cb)
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    ESX.TriggerServerCallback('hcyk_multijob:removeJob', function(response)
        if response.success then
            PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", false)
        else
            PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        end
        cb(response)
    end, data)
end)

RegisterNUICallback('showNotification', function(data, cb)
    local message = data.message or ''
    local type = data.type or 'info'
    local title = _L('notify_title')
    local libType = 'inform'
    if type == 'success' then
        libType = 'success'
    elseif type == 'error' then
        libType = 'error'
    elseif type == 'warning' then
        libType = 'warning'
    end
    lib.notify({
        title = title,
        description = message,
        type = libType
    })
    cb({})
end)

RegisterNUICallback('hideUI', function(_, cb)
    CloseMultiJobMenu()
    cb({})
end)

-- Add new event handler for server notifications
RegisterNetEvent('hcyk_multijob:showNotification')
AddEventHandler('hcyk_multijob:showNotification', function(data)
    local message = data.message or ''
    local type = data.type or 'info'
    local title = _L('notify_title')
    local libType = 'inform'
    if type == 'success' then
        libType = 'success'
    elseif type == 'error' then
        libType = 'error'
    elseif type == 'warning' then
        libType = 'warning'
    end
    lib.notify({
        title = title,
        description = message,
        type = libType
    })
end)

RegisterNetEvent('hcyk_multijob:jobChanged')
AddEventHandler('hcyk_multijob:jobChanged', function()
    if isMenuOpen then
        ESX.TriggerServerCallback('hcyk_multijob:getJobs', function(response)
            if response.success then
                SendNUIMessage({
                    action = 'updateJobs',
                    jobs = response.jobs
                })
            end
        end)
    end
end)