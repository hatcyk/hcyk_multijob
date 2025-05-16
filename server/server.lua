local Config = require 'config'
local langModule = require 'lang'
local Lang = langModule.Lang
local _L = langModule._L
local ESX = exports["es_extended"]:getSharedObject()

local webhook = 'discord_webhook_here' -- Replace with your actual webhook URL

-- Discord logging function
local function sendDiscordLog(message)
  if not Config.EnableDiscordLogs then return end
  -- Build embed payload
  local data = {
    username   = Config.DiscordWebhookUsername,
    avatar_url = Config.DiscordWebhookLogo,
    embeds     = {{
      title       = "Multijob Log",
      description = message,
      color       = 0x6c5ce7,
      timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }}
  }
  PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

local function debugPrint(...)
  if not Config.DebugMode then return end
  local args = { ... }
  local appendStr = ''
  for _, v in ipairs(args) do
    appendStr = appendStr .. ' ' .. tostring(v)
  end
  local msgTemplate = '^3[hcyk_multijob:server]^0%s'
  local finalMsg = msgTemplate:format(appendStr)
  print(finalMsg)
end

local function countJobs(identifier)
    local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM hcyk_multijob WHERE identifier = ?', {identifier})
    return result
end

local function getJobLabel(jobName)
    local result = MySQL.Sync.fetchAll('SELECT label FROM jobs WHERE name = ?', {jobName})
    return result[1] and result[1].label or jobName
end

local function getGradeLabel(jobName, grade)
    local result = MySQL.Sync.fetchAll('SELECT label FROM job_grades WHERE job_name = ? AND grade = ?', {jobName, grade})
    return result[1] and result[1].label or _L('unknown')
end

local function getPlayerJobs(identifier)
    if not identifier then 
        debugPrint("getPlayerJobs called with nil identifier")
        return {} 
    end
    
    debugPrint("Getting jobs for identifier: " .. identifier)
    local result = MySQL.Sync.fetchAll('SELECT * FROM hcyk_multijob WHERE identifier = ?', {identifier})
    local jobs = {}
    
    for _, jobData in ipairs(result) do
        debugPrint("Found job: " .. jobData.job .. " (grade: " .. jobData.grade .. ", removable: " ..tostring(jobData.removable).. ")")
        table.insert(jobs, {
            job = jobData.job,
            label = getJobLabel(jobData.job),
            grade = jobData.grade,
            grade_label = getGradeLabel(jobData.job, jobData.grade),
            removable = jobData.removable
        })
    end
    
    debugPrint("Total jobs found: " .. #jobs)
    return jobs
end

local function getActiveJob(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    
    return xPlayer.getJob().name
end

local function hasJob(identifier, jobName)
    local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    return result > 0
end

local function saveJob(identifier, jobName, grade, removable)
    if not identifier or not jobName then return false, _L('invalid_data') end
    
    if hasJob(identifier, jobName) then
        MySQL.Sync.execute('UPDATE hcyk_multijob SET grade = ?, removable = ? WHERE identifier = ? AND job = ?',
            {grade, removable, identifier, jobName})
        return true
    else
        local jobCount = countJobs(identifier)
        if jobCount >= (Config.MaxJobs or 3) then
            return false, _L('no_free_slot')
        end
        
        MySQL.Sync.execute('INSERT INTO hcyk_multijob (identifier, job, grade, removable) VALUES (?, ?, ?, ?)',
            {identifier, jobName, grade, removable})
        if Config.Logs.AddJob then
            sendDiscordLog(('Player %s added job %s (grade %d)'):format(identifier, jobName, grade))
        end
        return true
    end
end

local function removeJob(identifier, jobName)
    if not identifier or not jobName then return false end
    
    MySQL.Sync.execute('DELETE FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    return true
end

ESX.RegisterServerCallback('hcyk_multijob:getJobs', function(source, cb)
    debugPrint("getJobs callback called for source: " .. source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        debugPrint("Player not found for source: " .. source)
        cb({success = false, message = _L('player_not_found')})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    debugPrint("Getting jobs for identifier: " .. identifier)
    local jobs = getPlayerJobs(identifier)
    local activeJob = getActiveJob(source)
    debugPrint("Active job: " .. (activeJob or "none"))
    
    for i, job in ipairs(jobs) do
        jobs[i].active = job.job == activeJob
        debugPrint("Job " .. i .. ": " .. job.job .. " (removable: " .. tostring(job.removable) .. ")")
    end
    
    cb({success = true, jobs = jobs})
    debugPrint("Jobs sent to client: " .. #jobs)
end)

ESX.RegisterServerCallback('hcyk_multijob:switchJob', function(source, cb, data)
    debugPrint("switchJob callback called for source: " .. source .. " to job: " .. (data.job or "unknown"))
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        debugPrint("Player not found for source: " .. source)
        cb({success = false, message = _L('player_not_found')})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local jobName = data.job
    debugPrint("Switching job for identifier: " .. identifier .. " to job: " .. jobName)
    
    if not hasJob(identifier, jobName) then
        debugPrint("Job not saved in database: " .. jobName)
        cb({success = false, message = _L('job_not_saved')})
        return
    end
    
    local result = MySQL.Sync.fetchAll('SELECT grade FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    
    if not result or #result == 0 then
        debugPrint("Job data not found in database")
        cb({success = false, message = _L('job_data_not_found')})
        return
    end
    
    local grade = result[1].grade
    debugPrint("Job grade found: " .. grade)
    
    local currentJob = xPlayer.getJob()
    debugPrint("Current job: " .. currentJob.name .. " grade: " .. currentJob.grade)
    
    if not hasJob(identifier, currentJob.name) and countJobs(identifier) < 3 then
        debugPrint("Saving current job before switching")
        saveJob(identifier, currentJob.name, currentJob.grade, 1)
    end
    
    xPlayer.setJob(jobName, grade)
    if Config.Logs.SwitchJob then
        sendDiscordLog(('Player %s switched to job %s (grade %d)'):format(identifier, jobName, grade))
    end
    TriggerClientEvent('hcyk_multijob:jobChanged', source)
    
    cb({success = true, message = _L('job_switched')})
end)

ESX.RegisterServerCallback('hcyk_multijob:removeJob', function(source, cb, data)
    debugPrint("removeJob callback called for source: " .. source .. " job: " .. (data.job or "unknown"))
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        debugPrint("Player not found for source: " .. source)
        cb({success = false, message = _L('player_not_found')})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local jobName = data.job
    debugPrint("Removing job for identifier: " .. identifier .. " job: " .. jobName)
    
    if not hasJob(identifier, jobName) then
        debugPrint("Job not saved in database: " .. jobName)
        cb({success = false, message = _L('job_not_saved')})
        return
    end
    
    local result = MySQL.Sync.fetchAll('SELECT removable FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    debugPrint("Job removable check - result: " .. json.encode(result))
    
    if not result or #result == 0 or result[1].removable == 0 then
        cb({success = false, message = _L('cannot_remove')})
        return
    end
    
    if xPlayer.getJob().name == jobName then
        xPlayer.setJob('unemployed', 0)
        TriggerClientEvent('hcyk_multijob:jobChanged', source)
    end
    removeJob(identifier, jobName)
    if Config.Logs.RemoveJob then
        sendDiscordLog(('Player %s removed job %s'):format(identifier, jobName))
    end
    cb({success = true, message = _L('job_removed')})
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(source, job, lastJob)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    
    -- Save previous job if player has space
    if lastJob and lastJob.name ~= 'unemployed' then
        local success, message = saveJob(identifier, lastJob.name, lastJob.grade, 1)
        if not success and message then
            TriggerClientEvent('hcyk_multijob:showNotification', source, {
                message = message,
                type = 'error'
            })
        end
    end
      -- Save current job
    if job and job.name ~= 'unemployed' then
        local success, message = saveJob(identifier, job.name, job.grade, 1)
        if not success and message then
            TriggerClientEvent('hcyk_multijob:showNotification', source, {
                message = _L('no_job_slot'),
                type = 'error'
            })
        end
    end
    
    TriggerClientEvent('hcyk_multijob:jobChanged', source)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local currentJob = xPlayer.getJob()
    
    if currentJob and currentJob.name ~= 'unemployed' then
        saveJob(identifier, currentJob.name, currentJob.grade, 1)
    end
end)

ESX.RegisterServerCallback('hcyk_multijob:checkJobSlot', function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        cb({success = false, message = _L('player_not_found')})
        return
    end
    
    local identifier = xTarget.getIdentifier()
    local jobCount = countJobs(identifier)
    
    if jobCount >= 3 then
        -- Notify the employer
        cb({success = false, message = _L('job_slot_full')})
        
        -- Notify the target
        TriggerClientEvent('hcyk_multijob:showNotification', targetId, {
            message = _L('employer_slot_full'),
            type = 'error'
        })
        return
    end
    
    cb({success = true})
end)

AddEventHandler('onResourceStart', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
  PerformHttpRequest('https://api.github.com/repos/hatcyk/hcyk_multijob/releases/latest', function(status, responseText)
      if status ~= 200 then
        print('Version check failed, HTTP status:', status)
        return
      end
      local ok, release = pcall(json.decode, responseText)
      if not ok or not release then
        print('Failed to parse version check response')
        return
      end
      local latest = release.tag_name or release.name
      if latest and latest ~= currentVersion then
        print(('^1[hcyk_multijob]^0 Update available: current %s, latest %s'):format(currentVersion, latest))
      end
    end, 'GET')
end)