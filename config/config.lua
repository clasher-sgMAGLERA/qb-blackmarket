Config = {}

Config.NPCLocation = vector4(1073.13, -698.3, 57.1, 142.17) -- Contact NPC location
Config.NPCModel = 'g_m_y_mexgang_01'
Config.DeliveryNPCModel = 'g_m_y_mexgang_01'
Config.ContactFee = 5000
Config.WaitTime = 8 -- Seconds to wait at delivery location

Config.DeliveryLocations = {
    {
        deliveryLocation = vector3(710.52, 4174.86, 40.71),
        npcSpawnPos = vector4(785.35, 4192.43, 40.88, 85.71)
    },
    {
        deliveryLocation = vector3(1963.32, 5163.19, 47.27),
        npcSpawnPos = vector4(1963.94, 5188.54, 47.99, 179.83)
    },
    {
        deliveryLocation = vector3(2853.82, 4485.25, 48.32),
        npcSpawnPos = vector4(2880.42, 4514.49, 47.72, 143.47)
    },
}

Config.Items = {
    {
        item = 'weapon_appistol',
        label = 'Pistol',
        price = 25000
    },
    {
        item = 'weapon_microsmg',
        label = 'Micro SMG',
        price = 40000
    },
    {
        item = 'lockpick',
        label = 'Lockpick',
        price = 500
    },
    {
        item = 'advancedlockpick',
        label = 'Advanced Lockpick',
        price = 1500
    },
    {
        item = 'radio',
        label = 'Radio',
        price = 2000
    },
    {
        item = 'armor',
        label = 'Body Armor',
        price = 3000
    },
    {
        item = 'clip_attachment',
        label = 'Clip Attachment',
        price = 10000
    },
    {
        item = 'suppressor_attachment',
        label = 'Suppressor Attachment',
        price = 10000
    },
    {
        item = 'weapon_tint_05',
        label = 'Red Tint',
        price = 5000
    },
}
