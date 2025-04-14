local ESX = exports["es_extended"]:getSharedObject()

local function getJobLabel(jobName)
    local result = MySQL.Sync.fetchAll('SELECT label FROM jobs WHERE name = ?', {jobName})
    return result[1] and result[1].label or jobName
end

local function getGradeLabel(jobName, grade)
    local result = MySQL.Sync.fetchAll('SELECT label FROM job_grades WHERE job_name = ? AND grade = ?', {jobName, grade})
    return result[1] and result[1].label or 'Neznámá'
end

local function getPlayerJobs(identifier)
    if not identifier then return {} end
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM hcyk_multijob WHERE identifier = ?', {identifier})
    local jobs = {}
    
    for _, jobData in ipairs(result) do
        table.insert(jobs, {
            job = jobData.job,
            label = getJobLabel(jobData.job),
            grade = jobData.grade,
            grade_label = getGradeLabel(jobData.job, jobData.grade),
            removeable = jobData.removeable == 1
        })
    end
    
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

local function saveJob(identifier, jobName, grade, removeable)
    if not identifier or not jobName then return false, "Invalid data" end
    
    -- If job exists, update it (always allowed)
    if hasJob(identifier, jobName) then
        MySQL.Sync.execute('UPDATE hcyk_multijob SET grade = ?, removeable = ? WHERE identifier = ? AND job = ?',
            {grade, removeable, identifier, jobName})
        return true
    else
        -- For new jobs, check the limit first
        local jobCount = countJobs(identifier)
        if jobCount >= 3 then
            return false, "Nemáš volný slot pro další práci"
        end
        
        MySQL.Sync.execute('INSERT INTO hcyk_multijob (identifier, job, grade, removeable) VALUES (?, ?, ?, ?)',
            {identifier, jobName, grade, removeable})
        return true
    end
end

local function removeJob(identifier, jobName)
    if not identifier or not jobName then return false end
    
    MySQL.Sync.execute('DELETE FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    return true
end

local function countJobs(identifier)
    local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM hcyk_multijob WHERE identifier = ?', {identifier})
    return result
end

ESX.RegisterServerCallback('hcyk_multijob:getJobs', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({success = false, message = "Hráč nenalezen"})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local jobs = getPlayerJobs(identifier)
    local activeJob = getActiveJob(source)
    
    for i, job in ipairs(jobs) do
        jobs[i].active = job.job == activeJob
    end
    
    cb({success = true, jobs = jobs})
end)

ESX.RegisterServerCallback('hcyk_multijob:switchJob', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({success = false, message = "Hráč nenalezen"})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local jobName = data.job
    
    if not hasJob(identifier, jobName) then
        cb({success = false, message = "Tuto práci nemáš uloženou"})
        return
    end
    
    local result = MySQL.Sync.fetchAll('SELECT grade FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    
    if not result or #result == 0 then
        cb({success = false, message = "Data o práci nebyla nalezena"})
        return
    end
    
    local grade = result[1].grade
    
    local currentJob = xPlayer.getJob()
    
    -- Only try to save the current job if it's not already saved and we have room
    if not hasJob(identifier, currentJob.name) and countJobs(identifier) < 3 then
        saveJob(identifier, currentJob.name, currentJob.grade, 1)
    end
    
    xPlayer.setJob(jobName, grade)
    
    TriggerClientEvent('hcyk_multijob:jobChanged', source)
    
    cb({success = true, message = "Práce úspěšně změněna"})
end)

ESX.RegisterServerCallback('hcyk_multijob:removeJob', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({success = false, message = "Hráč nenalezen"})
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local jobName = data.job
    
    if not hasJob(identifier, jobName) then
        cb({success = false, message = "Tuto práci nemáš uloženou"})
        return
    end
    
    local result = MySQL.Sync.fetchAll('SELECT removeable FROM hcyk_multijob WHERE identifier = ? AND job = ?', {identifier, jobName})
    
    if not result or #result == 0 or result[1].removeable == 0 then
        cb({success = false, message = "Tuto práci nelze odebrat"})
        return
    end
    
    if xPlayer.getJob().name == jobName then
        cb({success = false, message = "Nelze odebrat aktivní práci"})
        return
    end
    
    removeJob(identifier, jobName)
    
    cb({success = true, message = "Práce úspěšně odebrána"})
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
        local success, message = saveJob(identifier, job.name, job.grade, 0)
        if not success and message then
            TriggerClientEvent('hcyk_multijob:showNotification', source, {
                message = "Zkusil jsi si dát jobu, ale již nemáš slot.",
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
        saveJob(identifier, currentJob.name, currentJob.grade, 0)
    end
end)

-- New callback for checking if a player has a job slot available
ESX.RegisterServerCallback('hcyk_multijob:checkJobSlot', function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        cb({success = false, message = "Hráč nenalezen"})
        return
    end
    
    local identifier = xTarget.getIdentifier()
    local jobCount = countJobs(identifier)
    
    if jobCount >= 3 then
        -- Notify the employer
        cb({success = false, message = "Hráč " .. GetPlayerName(targetId) .. " nemá volný slot pro další práci"})
        
        -- Notify the target
        TriggerClientEvent('hcyk_multijob:showNotification', targetId, {
            message = "Hráč " .. GetPlayerName(source) .. " se tě pokusil zaměstnat, ale nemáš volný slot.",
            type = 'error'
        })
        return
    end
    
    cb({success = true})
end)