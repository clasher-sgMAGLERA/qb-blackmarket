local QBCore = exports['qb-core']:GetCoreObject()
local contactNPC = nil

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
    local menuItems = { { header = 'Black Market', isMenuHeader = true } }
    for i = 1, #Config.Items do
        local item = Config.Items[i]
        menuItems[#menuItems + 1] = {
            header = item.label,
            txt = 'Price: $' .. FormatNumber(item.price),
            params = {
                event = 'qb-blackmarket:client:itemNotImplemented',
                args = { label = item.label }
            }
        }
    end
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
    
    Wait(500)
    TaskStartScenarioInPlace(contactNPC, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    
    CreateThread(function()
        while DoesEntityExist(contactNPC) do
            Wait(2000)
            if not IsPedUsingAnyScenario(contactNPC) then
                TaskStartScenarioInPlace(contactNPC, "WORLD_HUMAN_STAND_MOBILE", 0, true)
            end
        end
    end)
    
    exports['qb-target']:AddTargetEntity(contactNPC, {
        options = { { label = 'Talk to Dealer', icon = 'fas fa-comments', action = function() OpenBlackmarketMenu() end } },
        distance = 2.0
    })
end

-- Event ill use to indicate i'm still working on the item
RegisterNetEvent('qb-blackmarket:client:itemNotImplemented', function(data)
    QBCore.Functions.Notify('Not yet implemented', 'error')
end)

CreateThread(function()
    Wait(1000)
    SpawnContactNPC()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if DoesEntityExist(contactNPC) then SetEntityAsMissionEntity(contactNPC, true, true) DeletePed(contactNPC) end
end)
