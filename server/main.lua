player = {}
distressCalls = {}

RegisterNetEvent("dg_emsjob:updateDeathStatus", function(death)
    local data = {}
    data.target = source
    data.status = death.isDead
    data.killedBy = death?.weapon or false

    updateStatus(data)
end)

RegisterNetEvent("dg_emsjob:revivePlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        print(source .. ' probile modder')
    else
        local dataToSend = {}
        dataToSend.revive = true

        TriggerClientEvent('dg_emsjob:healPlayer', tonumber(data.targetServerId), dataToSend)
    end
end)

RegisterNetEvent("dg_emsjob:healPlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end


    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        return print(source .. ' probile modder')
    end


    if data.injury then
        TriggerClientEvent('dg_emsjob:healPlayer', tonumber(data.targetServerId), data)
    else
        data.anim = "medic"
        TriggerClientEvent("dg_emsjob:playHealAnim", source, data)
        data.anim = "dead"
        TriggerClientEvent("dg_emsjob:playHealAnim", data.targetServerId, data)
    end
end)

RegisterNetEvent("dg_emsjob:createDistressCall", function(data)
    if not source or source < 1 then return end
    distressCalls[#distressCalls + 1] = {
        msg = data.msg,
        gps = data.gps,
        location = data.location,
        name = getPlayerName(source)
    }

    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            TriggerClientEvent("dg_emsjob:createDistressCall", id, getPlayerName(source))
        end
    end
end)

RegisterNetEvent("dg_emsjob:callCompleted", function(call)
    for i = #distressCalls, 1, -1 do
        if distressCalls[i].gps == call.gps and distressCalls[i].msg == call.msg then
            table.remove(distressCalls, i)
            break
        end
    end
end)

RegisterNetEvent("dg_emsjob:removAddItem", function(data)
    if not inv then return end

    if data.toggle then
        inv.removeItem(source, data.item, data.quantity)
    else
        inv.addItem(source, data.item, data.quantity)
    end
end)

RegisterNetEvent("dg_emsjob:useItem", function(data)
    if not hasJob(source, Config.EmsJobs) or not inv then return end

    inv.setItemDurability(source, data.item, data.value)
end)

RegisterNetEvent("dg_emsjob:removeInventory", function()
    if not inv then return end
    if player[source] and player[source].isDead and Config.RemoveItemsOnRespawn then
        inv.clearPlayerInventory(source)
    end
end)

RegisterNetEvent("dg_emsjob:putOnStretcher", function(data)
    if not player[data.target].isDead then return end
    TriggerClientEvent("dg_emsjob:putOnStretcher", data.target, data.toggle)
end)

RegisterNetEvent("dg_emsjob:togglePatientFromVehicle", function(data)
    if not player[data.target].isDead then return end

    TriggerClientEvent("dg_emsjob:togglePatientFromVehicle", data.target, data.vehicle)
end)

RegisterNetEvent('dg_emsjob:openStash', function(id)
    if not inv then return end
    inv.openStash(source, id)
end)

RegisterNetEvent('dg_emsjob:openShop', function(name)
    if not inv then return end
    inv.openShop(source, name)
end)

lib.callback.register('dg_emsjob:getDeathStatus', function(source, target)
    return player[target] and player[target] or getDeathStatus(target or source)
end)

lib.callback.register('dg_emsjob:getData', function(source, target)
    local data = {}
    if not target or target < 1 then
        return { injuries = false, status = { isDead = false }, killedBy = false }
    end

    data.injuries = Player(target).state.injuries or false

    local status = getDeathStatus(target)
    if type(status) ~= 'table' then
        status = { isDead = status == true }
    elseif status.isDead == nil then
        status.isDead = false
    end

    data.status = status
    data.killedBy = player[target]?.killedBy or false

    return data
end)

lib.callback.register('dg_emsjob:getDistressCalls', function(source)
    return distressCalls
end)

lib.callback.register('dg_emsjob:openMedicalBag', function(source)
    if not inv then return nil end
    return inv.openMedicalBag(source)
end)

lib.callback.register('dg_emsjob:getItem', function(source, name)
    if not inv then return nil end
    return inv.getItemByName(source, name)
end)

lib.callback.register('dg_emsjob:getItemCount', function(source, item)
    if not inv then return 0 end
    return inv.getItemCount(source, item)
end)

lib.callback.register('dg_emsjob:payParamedic', function(source, amount)
    if not inv then return false end
    return inv.payForTreatment(source, amount)
end)

lib.callback.register('dg_emsjob:getMedicsOniline', function(source)
    local count = 0
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            count += 1
        end
    end
    return count
end)

local function registerInventories()
    if not inv then return end
    local ok, err = pcall(function()
        if type(inv.registerHospitalInventories) == 'function' then
            inv.registerHospitalInventories()
        end
        if type(inv.registerMedicalBagProtection) == 'function' then
            inv.registerMedicalBagProtection()
        end
    end)
    if not ok then
        print('^1[dg_emsjob] Failed to register inventories: ' .. tostring(err) .. '^0')
    end
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if not inv then return end
        
        local isOx = (InventoryType == 'ox')
        local targetResource = isOx and 'ox_inventory' or 'qb-inventory'
        
        if GetResourceState(targetResource) == 'started' then
            registerInventories()
        else
            SetTimeout(2000, function()
                if GetResourceState(targetResource) == 'started' then
                    registerInventories()
                end
            end)
        end
    elseif (InventoryType == 'ox' and resourceName == 'ox_inventory') or (InventoryType == 'qb' and resourceName == 'qb-inventory') then
        registerInventories()
    end
end)

local dutyStartTimes = {}

local function sendWebhook(embed)
    local webhook = Config.DutyWebhook
    if not webhook or webhook == "" or webhook == "YOUR_WEBHOOK_URL_HERE" then return end

    PerformHttpRequest(webhook, function(statusCode, response, headers)
        if statusCode ~= 200 and statusCode ~= 204 then
            print(("^1[dg_emsjob] Discord Webhook failed with status code %s^0"):format(statusCode))
        end
    end, 'POST', json.encode({
        embeds = { embed }
    }), { ['Content-Type'] = 'application/json' })
end

local function sendOnDutyWebhook(source, name)
    local embed = {
        title = "EMS Duty Update",
        description = ("**%s** is now **On Duty**."):format(name),
        color = 3066993, -- Green
        fields = {
            { name = "Player Name", value = name, inline = true },
            { name = "Server ID", value = tostring(source), inline = true },
            { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false }
        },
        footer = { text = "dg_emsjob Duty Logger" }
    }
    sendWebhook(embed)
end

local function sendOffDutyWebhook(source, name, startTime)
    local durationStr = "Unknown"
    if startTime then
        local durationSec = os.time() - startTime
        local hours = math.floor(durationSec / 3600)
        local minutes = math.floor((durationSec % 3600) / 60)
        local seconds = durationSec % 60
        durationStr = string.format("%dh %dm %ds", hours, minutes, seconds)
    end

    local embed = {
        title = "EMS Duty Update",
        description = ("**%s** is now **Off Duty**."):format(name),
        color = 15158332, -- Red
        fields = {
            { name = "Player Name", value = name, inline = true },
            { name = "Server ID", value = tostring(source), inline = true },
            { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false },
            { name = "Session Duration", value = durationStr, inline = false }
        },
        footer = { text = "dg_emsjob Duty Logger" }
    }
    sendWebhook(embed)
end

RegisterNetEvent('dg_emsjob:toggleDuty', function()
    local source = source
    if toggleDuty then
        local onDuty, jobName = toggleDuty(source)
        if onDuty ~= nil then
            local name = getPlayerName(source)
            if onDuty then
                dutyStartTimes[source] = os.time()
                TriggerClientEvent('dg_emsjob:showNotification', source, "You are now ON Duty", "success")
                sendOnDutyWebhook(source, name)
            else
                local startTime = dutyStartTimes[source]
                TriggerClientEvent('dg_emsjob:showNotification', source, "You are now OFF Duty", "error")
                sendOffDutyWebhook(source, name, startTime)
                dutyStartTimes[source] = nil
            end
        else
            TriggerClientEvent('dg_emsjob:showNotification', source, "Failed to toggle duty status", "error")
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if dutyStartTimes[source] then
        local name = getPlayerName(source)
        sendOffDutyWebhook(source, name, dutyStartTimes[source])
        dutyStartTimes[source] = nil
    end
end)

