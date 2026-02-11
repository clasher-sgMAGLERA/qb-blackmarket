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
    local total = 0
    for itemName, qty in pairs(orderedItems[src]) do
        for i = 1, #Config.Items do
            if Config.Items[i].item == itemName then
                total = total + (Config.Items[i].price * qty)
                exports['qb-inventory']:AddItem(src, itemName, qty)
                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', qty)
                break
            end
        end
    end
    Player.Functions.RemoveMoney('cash', total)
    orderedItems[src] = nil
end)
