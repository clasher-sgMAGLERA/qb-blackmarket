local QBCore = exports['qb-core']:GetCoreObject()
local orderedItems = {}

-- Order from the gangster
QBCore.Functions.CreateCallback('qb-blackmarket:server:placeOrder', function(source, cb, cart, total)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    if Player.PlayerData.money.cash < total then cb(false) return end
    Player.Functions.RemoveMoney('cash', Config.ContactFee)
    orderedItems[source] = cart
    cb(true)
end)

-- Give that criminal their goods, lol
RegisterNetEvent('qb-blackmarket:server:giveItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not orderedItems[src] then return end
    local itemLookup = {}
    for i = 1, #Config.Items do
        itemLookup[Config.Items[i].item] = Config.Items[i]
    end
    local total = 0
    local validItems = {}
    for itemName, qty in pairs(orderedItems[src]) do
        local itemConfig = itemLookup[itemName]
        if not itemConfig then
            TriggerClientEvent('QBCore:Notify', src, 'Invalid item in order: ' .. itemName, 'error')
            orderedItems[src] = nil
            return
        end
        total = total + (itemConfig.price * qty)
        validItems[itemName] = qty
    end
    if Player.PlayerData.money.cash < total then
        orderedItems[src] = nil
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough cash', 'error')
        return
    end
    for itemName, qty in pairs(validItems) do
        exports['qb-inventory']:AddItem(src, itemName, qty)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', qty)
    end
    Player.Functions.RemoveMoney('cash', total)
    orderedItems[src] = nil
end)
