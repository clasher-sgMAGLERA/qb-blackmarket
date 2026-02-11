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

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function WaitForNPCToReachPosition(npc, targetCoords, maxDistance, timeout)
    timeout = timeout or 30000
    local startTime = GetGameTimer()
    
    while GetGameTimer() - startTime < timeout do
        if not DoesEntityExist(npc) then return false end
        
        local npcCoords = GetEntityCoords(npc)
        local distance = #(npcCoords - targetCoords)
        
        if distance <= maxDistance then
            Wait(500)
            return true
        end
        
        Wait(100)
    end
    
    return false
end

local function SpawnDeliveryNPC(deliveryData)
    local npcSpawnPos = deliveryData.npcSpawnPos
    local targetLocation = deliveryData.deliveryLocation
    local pedModel = GetHashKey(Config.DeliveryNPCModel)
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(100) end
    
    deliveryNPC = CreatePed(4, pedModel, npcSpawnPos.x, npcSpawnPos.y, npcSpawnPos.z, npcSpawnPos.w, false, true)
    SetEntityAsMissionEntity(deliveryNPC, true, true)
    SetPedFleeAttributes(deliveryNPC, 0, false)
    SetPedCombatAttributes(deliveryNPC, 17, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    SetEntityInvincible(deliveryNPC, true)
    
    LoadAnimDict("anim@heists@box_carry@")
    Wait(500)
    
    local boxModel = GetHashKey('prop_cs_cardbox_01')
    RequestModel(boxModel)
    while not HasModelLoaded(boxModel) do Wait(10) end
    
    local handBoneIndex = GetPedBoneIndex(deliveryNPC, 28422)
    local handCoords = GetWorldPositionOfEntityBone(deliveryNPC, handBoneIndex)
    
    local crateProp = CreateObject(boxModel, handCoords.x, handCoords.y, handCoords.z, true, true, false)
    SetEntityAsMissionEntity(crateProp, true, true)
    SetEntityAlpha(crateProp, 0, false)
    Wait(50)
    
    AttachEntityToEntity(crateProp, deliveryNPC, handBoneIndex, 0.0, -0.1, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetEntityAlpha(crateProp, 255, false)
    
    TaskPlayAnim(deliveryNPC, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    CreateThread(function()
        local animNPC = deliveryNPC
        local animProp = crateProp
        while DoesEntityExist(animProp) and IsEntityAttachedToEntity(animProp, animNPC) do
            if not IsEntityPlayingAnim(animNPC, "anim@heists@box_carry@", "idle", 3) then
                TaskPlayAnim(animNPC, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end
    end)
    
    TaskGoStraightToCoord(deliveryNPC, targetLocation.x, targetLocation.y, targetLocation.z, 1.0, 30000, 0.0, 0)
    
    CreateThread(function()
        local arrivalTimeout = 0
        local maxWaitTime = 300000
        local threadNPC = deliveryNPC
        local threadProp = crateProp
        local threadSpawnPos = npcSpawnPos
        
        while isWaitingForDelivery and arrivalTimeout < maxWaitTime do
            Wait(1000)
            arrivalTimeout = arrivalTimeout + 1000
            
            if threadNPC and DoesEntityExist(threadNPC) then
                local playerPed = PlayerPedId()
                local npcCoords = GetEntityCoords(threadNPC)
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(npcCoords - playerCoords)
                
                if distance < 3.0 then
                    TaskTurnPedToFaceEntity(threadNPC, playerPed, 2000)
                    Wait(2000)
                    
                    if DoesEntityExist(threadProp) then
                        DetachEntity(threadProp, true, true)
                        local propCoords = GetEntityCoords(playerPed)
                        SetEntityCoords(threadProp, propCoords.x, propCoords.y, propCoords.z + 0.3, false, false, false, false)
                        Wait(1000)
                        if DoesEntityExist(threadProp) then
                            DeleteEntity(threadProp)
                        end
                    end
                    
                    ClearPedTasks(threadNPC)
                    Wait(300)
                    
                    QBCore.Functions.Notify('Delivery received', 'success')
                    TriggerServerEvent('qb-blackmarket:server:giveItems')
                    
                    Wait(2000)
                    
                    if DoesEntityExist(threadNPC) then
                        TaskGoStraightToCoord(threadNPC, threadSpawnPos.x, threadSpawnPos.y, threadSpawnPos.z, 1.0, 30000, 0.0, 0)
                        
                        Wait(30000)
                        
                        if DoesEntityExist(threadNPC) then
                            SetEntityAsMissionEntity(threadNPC, true, true)
                            DeleteEntity(threadNPC)
                        end
                        if DoesEntityExist(threadProp) then
                            DeleteEntity(threadProp)
                        end
                    end
                    
                    isWaitingForDelivery = false
                    deliveryNPC = nil
                    break
                end
            else
                isWaitingForDelivery = false
                deliveryNPC = nil
                break
            end
        end
        
        if arrivalTimeout >= maxWaitTime then
            QBCore.Functions.Notify('Delivery timed out', 'error')
            isWaitingForDelivery = false
            if DoesEntityExist(threadNPC) then
                SetEntityAsMissionEntity(threadNPC, true, true)
                DeleteEntity(threadNPC)
            end
            if DoesEntityExist(threadProp) then
                DeleteEntity(threadProp)
            end
            deliveryNPC = nil
        end
    end)
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
                    local waitTime = 0
                    while waitTime < Config.WaitTime do
                        Wait(1000)
                        waitTime = waitTime + 1
                        local currentDist = #(GetEntityCoords(PlayerPedId()) - targetLocation)
                        if currentDist > 10.0 then
                            QBCore.Functions.Notify('You left the delivery location', 'error')
                            waitingAtLocation = false
                            break
                        end
                    end
                    if waitingAtLocation then
                        QBCore.Functions.Notify('Delivery incoming...', 'success')
                        SpawnDeliveryNPC(deliveryLocation)
                        deliveryLocation = nil
                        waitingAtLocation = false
                        deliveryThread = nil
                        break
                    end
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
