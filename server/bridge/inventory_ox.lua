if InventoryType ~= 'ox' then return end

inv = {}

function inv.usesMoneyItem()
    return true
end

function inv.addItem(source, item, quantity)
    exports.ox_inventory:AddItem(source, item, quantity)
end

function inv.removeItem(source, item, quantity)
    exports.ox_inventory:RemoveItem(source, item, quantity)
end

function inv.clearPlayerInventory(source)
    exports.ox_inventory:ClearInventory(source)
end

function inv.getItemCount(source, item)
    return exports.ox_inventory:GetItemCount(source, item) or 0
end

function inv.getItemByName(source, name)
    local item = exports.ox_inventory:GetSlotWithItem(source, name)
    if not item then return nil end

    return {
        slot = item.slot,
        metadata = item.metadata,
    }
end

function inv.setItemDurability(source, itemName, consumeValue)
    local item = exports.ox_inventory:GetSlotWithItem(source, itemName)
    if not item then return end

    local durability = item.metadata?.durability and (item.metadata.durability - consumeValue) or (100 - consumeValue)
    exports.ox_inventory:SetDurability(source, item.slot, durability)
end

function inv.openMedicalBag(source)
    local stashId = 'medicalBag_' .. source
    local success, err = pcall(function()
        exports.ox_inventory:RegisterStash(stashId, 'Medical Bag', 10, 50 * 1000)
    end)
    if not success then
        print(("^1[dg_emsjob] Failed to register medical bag stash dynamically: %s^0"):format(err))
    end
    return stashId
end

function inv.openStash(source, id)
    TriggerClientEvent('dg_emsjob:openInventory', source, 'stash', id)
end

function inv.openShop(source, name)
    TriggerClientEvent('dg_emsjob:openInventory', source, 'shop', name)
end

function inv.registerHospitalInventories()
    for _, hospital in pairs(Config.Hospitals) do
        for id, stash in pairs(hospital.stash) do
            local success, err = pcall(function()
                exports.ox_inventory:RegisterStash(id, stash.label, stash.slots, stash.weight * 1000, stash.shared and true or nil)
            end)
            if not success then
                print(("^1[dg_emsjob] Failed to register stash '%s' via ox_inventory export. If you are using an older version, add it manually to ox_inventory/data/stashes.lua. Error: %s^0"):format(id, err))
            end
        end

        for id, pharmacy in pairs(hospital.pharmacy) do
            local success, err = pcall(function()
                exports.ox_inventory:RegisterShop(id, {
                    name = pharmacy.label,
                    inventory = pharmacy.items,
                })
            end)
            if not success then
                print(("^1[dg_emsjob] Failed to register shop '%s' via ox_inventory export. Error: %s^0"):format(id, err))
            end
        end
    end
end

function inv.registerMedicalBagProtection()
    local success, err = pcall(function()
        exports.ox_inventory:registerHook('swapItems', function(payload)
            if string.find(payload.toInventory, 'medicalBag_') then
                if payload.fromSlot.name == Config.MedicBagItem then return false end
            end
        end, {})
    end)
    if not success then
        print(("^1[dg_emsjob] Failed to register medical bag protection hook: %s^0"):format(err))
    end
end

function inv.payForTreatment(source, amount)
    if inv.usesMoneyItem() then
        if inv.getItemCount(source, 'money') < amount then return false end
        inv.removeItem(source, 'money', amount)
        return true
    end

    if type(removePlayerMoney) == 'function' then
        return removePlayerMoney(source, amount)
    end

    return false
end
