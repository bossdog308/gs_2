Config = {}

-- Debug: Global Config Loaded
print("^2[DEBUG] Config file loaded successfully.")

-- 🔫 Global Weapon Definitions
Config.Weapons = {
    ["WEAPON_PISTOL"] = { label = "Pistol", ammo_type = "pistol_ammo", mag_size = 12 },
    ["WEAPON_SMG"] = { label = "SMG", ammo_type = "smg_ammo", mag_size = 30 },
    ["WEAPON_ASSAULTRIFLE"] = { label = "AK-47 Rifle", ammo_type = "rifle_ammo", mag_size = 30 },
    ["WEAPON_MICROSMG"] = { label = "Micro SMG", ammo_type = "smg_ammo", mag_size = 30 },
    ["WEAPON_PUMPSHOTGUN"] = { label = "Shotgun", ammo_type = "shotgun_ammo", mag_size = 8 },
    ["WEAPON_CM_GLOCC27"] = { label = "Glock 27", ammo_type = "pistol_ammo", mag_size = 15 },
    ["WEAPON_CM_GLOCC26"] = { label = "Glock 26", ammo_type = "pistol_ammo", mag_size = 15 }
}

-- 🔄 Ammo Types
Config.AmmoTypes = {
    ["pistol_ammo"] = { label = "Pistol Ammo", amount = 30 },
    ["smg_ammo"] = { label = "SMG Ammo", amount = 45 },
    ["rifle_ammo"] = { label = "Rifle Ammo", amount = 60 },
    ["shotgun_ammo"] = { label = "Shotgun Ammo", amount = 12 }
}

-- 🎯 Attachments (Global)
Config.Attachments = {
    ["WEAPON_PISTOL"] = {
        { label = "Suppressor", hash = "COMPONENT_AT_PI_SUPP_02", price = 200 },
        { label = "Extended Clip", hash = "COMPONENT_PISTOL_CLIP_02", price = 300 }
    },
    ["WEAPON_SMG"] = {
        { label = "Flashlight", hash = "COMPONENT_AT_AR_FLSH", price = 100 },
        { label = "Grip", hash = "COMPONENT_AT_AR_AFGRIP", price = 150 }
    }
}

-- 🏪 Gun Stores (Legal)
Config.Shops = {
    ["Downtown Gun Store"] = {
        name = "Downtown Gun Store",
        location = { x = 22.0, y = -1107.0, z = 29.6 },
        currency = "cash",
        weapons = {
            { hash = "WEAPON_PISTOL", label = "Pistol", price = 1500 },
            { hash = "WEAPON_SMG", label = "SMG", price = 3000 },
            { hash = "WEAPON_ASSAULTRIFLE", label = "AK-47 Rifle", price = 7500 },
            { hash = "WEAPON_MICROSMG", label = "Micro SMG", price = 2500 },
            { hash = "WEAPON_PUMPSHOTGUN", label = "Shotgun", price = 5000 }
        },
        ammo = {
            { type = "pistol_ammo", label = "Pistol Ammo", price = 50 },
            { type = "smg_ammo", label = "SMG Ammo", price = 100 },
            { type = "rifle_ammo", label = "Rifle Ammo", price = 150 },
            { type = "shotgun_ammo", label = "Shotgun Ammo", price = 80 }
        },
        attachments = {
            { weapon = "WEAPON_PISTOL", hash = "COMPONENT_AT_PI_SUPP_02", label = "Suppressor", price = 200 },
            { weapon = "WEAPON_PISTOL", hash = "COMPONENT_PISTOL_CLIP_02", label = "PISTOL 30RD", price = 200 },
            { weapon = "WEAPON_SMG", hash = "COMPONENT_AT_AR_AFGRIP", label = "Grip", price = 300 }
        }
    }
}

-- 🖤 Black Market (Illegal)
-- Black Market purchases do not generate serial numbers.
Config.BlackMarket = Config.BlackMarket or { 
    name = "Black Market",
    location = { x = 9.0, y = -1106.0, z = 29.5 },
    currency = "Durty Dollaz / Blood Dianondz",
    rotationTime = 6 * 3600, -- Refreshes every 6 hours
    maxWeapons = 3,
    maxAmmoTypes = 2,
    maxAttachments = 2,
    restrictedWeapons = {
        { hash = "WEAPON_COMBATMG", label = "Combat MG", price = 10000 },
        { hash = "WEAPON_HEAVYSNIPER", label = "Heavy Sniper", price = 15000 },
        { hash = "WEAPON_MINIGUN", label = "Minigun", price = 50000 }
    },
    weapons = {
        { hash = "WEAPON_ASSAULTRIFLE", label = "AK-47 Rifle", price = 7500 }
    },
    ammo = {},
    attachments = {}
}

-- 🚫 Blacklist System
Config.Blacklist = Config.Blacklist or {
    restrictedWeapons = { "WEAPON_MINIGUN", "WEAPON_RPG" },
    restrictedShops = { "BlackMarket" } -- Blocks some players from accessing the Black Market
}

-- ✅ Ensure Black Market is in Shops List
Config.Shops = Config.Shops or {}
Config.Shops["BlackMarket"] = {
    name = Config.BlackMarket.name,
    location = Config.BlackMarket.location,
    currency = Config.BlackMarket.currency,
    weapons = Config.BlackMarket.weapons,
    ammo = Config.BlackMarket.ammo,
    attachments = Config.BlackMarket.attachments
}

-- 💰 Exploit Prevention & Cooldowns
Config.PurchaseLimits = {
    weaponCooldown = 3600, -- 1-hour cooldown for buying weapons
    maxAmmoPurchase = 1000, -- Max ammo per purchase
    ammoCooldown = 3 * 3600  -- 3-hour cooldown
}

-- 🔥 Default Ammo on Purchase
Config.DefaultAmmo = 3
