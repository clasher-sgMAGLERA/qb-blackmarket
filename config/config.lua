Config = {}

Config.NPCLocation = vector4(1073.13, -698.3, 57.1, 142.17) -- Contact NPC location
Config.NPCModel = 'g_m_y_mexgang_01'
Config.DeliveryVehicle = 'rumpo'
Config.DeliveryNPCModel = 'g_m_y_mexgang_01'
Config.ContactFee = 500
Config.WaitTime = 30 -- Seconds to wait at delivery location

Config.DeliveryLocations = {
    vector3(751.5, -1224.45, 24.77),
    vector3(1202.98, -1360.77, 35.23),
    vector3(14.0, -1809.39, 25.25),
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
