Config = {}

-- Centralized weapon catalog (source of truth)
Config.Weapons = {
    { label = "Pistol", hash = "WEAPON_PISTOL", price = 500 },
    { label = "SMG", hash = "WEAPON_SMG", price = 1200 },
    { label = "Micro SMG", hash = "WEAPON_MICROSMG", price = 0 },
    { label = "AK-47 Rifle", hash = "WEAPON_ASSAULTRIFLE", price = 2500 },
    { label = "Shotgun", hash = "WEAPON_PUMPSHOTGUN", price = 1500 },
    { label = "Glock 27", hash = "WEAPON_CM_GLOCC27", price = 1500 },
    { label = "Glock 26", hash = "WEAPON_CM_GLOCC26", price = 1500 },
}

-- Shops configuration where weapons can be purchased.
Config.Shops = {
    {
        x = 22.0, y = -1107.0, z = 29.6,
        weapons = {
            -- Using the same structure as Config.Weapons for consistency.
            { label = "Pistol", hash = "WEAPON_PISTOL", price = 500 },
            { label = "SMG", hash = "WEAPON_SMG", price = 1200 },
            { label = "AK-47 Rifle", hash = "WEAPON_ASSAULTRIFLE", price = 2500 },
            { label = "Micro SMG", hash = "WEAPON_MICROSMG", price = 0 },
            { label = "Shotgun", hash = "WEAPON_PUMPSHOTGUN", price = 1500 },
            { label = "Glock 27", hash = "WEAPON_CM_GLOCC27", price = 1500 },
            { label = "Glock 26", hash = "WEAPON_CM_GLOCC26", price = 1500 },
        }
    },
    {
        x = 252.0, y = -50.0, z = 70.0,
        weapons = {
            -- Override price if needed, or reference catalog items
            { label = "SMG", hash = "WEAPON_SMG", price = 5000 },
            { label = "Bat", hash = "weapon_bat", price = 500 } -- Not in main catalog, kept separate.
        }
    }
}

-- Ammo types available in the shop.
Config.Ammo = {
    { label = "Pistol Ammo", type = "pistol_ammo", price = 50, amount = 30 },
    { label = "SMG Ammo", type = "smg_ammo", price = 100, amount = 45 },
    { label = "Rifle Ammo", type = "rifle_ammo", price = 150, amount = 60 },
    { label = "Shotgun Ammo", type = "shotgun_ammo", price = 80, amount = 12 }
}

-- Weapon attachments configuration.
Config.Attachments = {
    WEAPON_PISTOL = {
        { label = "Suppressor", hash = "COMPONENT_AT_PI_SUPP_02", price = 150 },
        { label = "Extended Clip", hash = "COMPONENT_PISTOL_CLIP_02", price = 200 }
    },
    WEAPON_CM_GLOCC27 = {
        { label = "G27 Suppressor", hash = "GLOCC27_SUPP", price = 150 },
        { label = "G27 Extended Clip", hash = "GLOCC27_CLIP_02", price = 200 }
    },
    WEAPON_SMG = {
        { label = "Flashlight", hash = "COMPONENT_AT_AR_FLSH", price = 100 },
        { label = "Grip", hash = "COMPONENT_AT_AR_AFGRIP", price = 120 }
    }
}
