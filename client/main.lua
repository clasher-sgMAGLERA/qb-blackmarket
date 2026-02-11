local QBCore = exports['qb-core']:GetCoreObject()
local contactNPC, deliveryNPC = nil, nil
local isWaitingForDelivery = false
local cart = {}
local deliveryLocation = nil
local waitingAtLocation = false
local deliveryThread = nil

local function FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function OpenBlackmarketMenu()
    if isWaitingForDelivery then
        QBCore.Functions.Notify('You already have a delivery on the way', 'error')
        return
    end
    local menuItems = { { header = 'Black Market', isMenuHeader = true } }
    for i = 1, #Config.Items do
        local item = Config.Items[i]
        local cartQty = cart[item.item] or 0
        menuItems[#menuItems + 1] = {
            header = item.label,
            txt = 'Price: $' .. FormatNumber(item.price) .. ' | Order: ' .. cartQty,
            params = {
                event = 'qb-blackmarket:client:addToOrder',
                args = { item = item.item, label = item.label, price = item.price }
            }
        }
    end
    menuItems[#menuItems + 1] = { header = 'View Order', txt = '', params = { event = 'qb-blackmarket:client:viewOrder' } }
    menuItems[#menuItems + 1] = { header = 'Close', txt = '', params = { event = 'qb-menu:client:closeMenu' } }
    exports['qb-menu']:openMenu(menuItems)
end

local function SpawnContactNPC()
    if contactNPC then return end
    local model = GetHashKey(Config.NPCModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    contactNPC = CreatePed(4, model, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1.0, Config.NPCLocation.w, false, true)
    SetEntityAsMissionEntity(contactNPC, true, true)
    SetPedFleeAttributes(contactNPC, 0, false)
    SetPedCombatAttributes(contactNPC, 17, true)
    SetBlockingOfNonTemporaryEvents(contactNPC, true)
    FreezeEntityPosition(contactNPC, true)
    SetEntityInvincible(contactNPC, true)
    Wait(5000)
    TaskStartScenarioInPlace(contactNPC, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    exports['qb-target']:AddTargetEntity(contactNPC, {
        options = { { label = 'Talk to Dealer', icon = 'fas fa-comments', action = function() OpenBlackmarketMenu() end } },
        distance = 2.0
    })
end


RegisterNetEvent('qb-blackmarket:client:addToOrder', function(data)
    local input = exports['qb-input']:ShowInput({
        header = data.label,
        submitText = 'Add',
        inputs = { { type = 'number', name = 'quantity', text = 'Quantity', isRequired = true, default = 1 } }
    })
    if input and input.quantity and tonumber(input.quantity) > 0 then
        cart[data.item] = (cart[data.item] or 0) + tonumber(input.quantity)
        QBCore.Functions.Notify('Added ' .. input.quantity .. 'x ' .. data.label .. ' to order', 'success')
        Wait(100)
        OpenBlackmarketMenu()
    end
end)

RegisterNetEvent('qb-blackmarket:client:viewOrder', function()
    if not next(cart) then
        QBCore.Functions.Notify('Order is empty', 'error')
        return
    end
    local menuItems = { { header = 'Order', isMenuHeader = true } }
    local total = Config.ContactFee
    for itemName, qty in pairs(cart) do
        for i = 1, #Config.Items do
            if Config.Items[i].item == itemName then
                local item = Config.Items[i]
                local itemTotal = item.price * qty
                total = total + itemTotal
                menuItems[#menuItems + 1] = {
                    header = item.label .. ' x' .. qty,
                    txt = '$' .. FormatNumber(itemTotal),
                    params = { event = 'qb-blackmarket:client:removeFromOrder', args = { item = itemName } }
                }
                break
            end
        end
    end
    menuItems[#menuItems + 1] = { header = 'Total: $' .. FormatNumber(total), isMenuHeader = true }
    menuItems[#menuItems + 1] = { header = 'Place Order', txt = 'Contact Fee: $' .. Config.ContactFee, params = { event = 'qb-blackmarket:client:placeOrder' } }
    menuItems[#menuItems + 1] = { header = 'Clear Order', txt = '', params = { event = 'qb-blackmarket:client:clearOrder' } }
    menuItems[#menuItems + 1] = { header = 'Back', txt = '', params = { event = 'qb-blackmarket:client:openMenu' } }
    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('qb-blackmarket:client:removeFromOrder', function(data)
    if cart[data.item] then
        cart[data.item] = nil
        QBCore.Functions.Notify('Removed from order', 'success')
        TriggerEvent('qb-blackmarket:client:viewOrder')
    end
end)

RegisterNetEvent('qb-blackmarket:client:clearOrder', function()
    cart = {}
    QBCore.Functions.Notify('Order cleared', 'success')
end)

RegisterNetEvent('qb-blackmarket:client:openMenu', function()
    OpenBlackmarketMenu()
end)

local function StartDeliveryThread()
    if deliveryThread then return end
    deliveryThread = CreateThread(function()
        while isWaitingForDelivery and deliveryLocation do
            Wait(1000)
            if not waitingAtLocation then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local targetLocation = deliveryLocation.deliveryLocation
                local dist = #(playerCoords - targetLocation)
                if dist < 5.0 then
                    waitingAtLocation = true
                    QBCore.Functions.Notify('Wait here for ' .. Config.WaitTime .. ' seconds...', 'info')
                    -- Still figuring out what to do here
                end
            end
        end
    end)
end

RegisterNetEvent('qb-blackmarket:client:placeOrder', function()
    if not next(cart) then
        QBCore.Functions.Notify('Cart is empty', 'error')
        return
    end
    local total = Config.ContactFee
    for itemName, qty in pairs(cart) do
        for i = 1, #Config.Items do
            if Config.Items[i].item == itemName then
                total = total + (Config.Items[i].price * qty)
                break
            end
        end
    end
    QBCore.Functions.TriggerCallback('qb-blackmarket:server:placeOrder', function(success)
        if success then
            local randomLoc = Config.DeliveryLocations[math.random(1, #Config.DeliveryLocations)]
            deliveryLocation = randomLoc
            SetNewWaypoint(deliveryLocation.deliveryLocation.x, deliveryLocation.deliveryLocation.y)
            QBCore.Functions.Notify('Go to the marked location and wait for delivery', 'success')
            isWaitingForDelivery = true
            cart = {}
            StartDeliveryThread()
        else
            QBCore.Functions.Notify('You don\'t have enough cash', 'error')
        end
    end, cart, total)
end)

CreateThread(function()
    Wait(1000)
    SpawnContactNPC()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if DoesEntityExist(contactNPC) then SetEntityAsMissionEntity(contactNPC, true, true) DeletePed(contactNPC) end
    if DoesEntityExist(deliveryNPC) then SetEntityAsMissionEntity(deliveryNPC, true, true) DeletePed(deliveryNPC) end
end)
