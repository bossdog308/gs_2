-- server.lua
local oxmysql = exports.oxmysql
local blackMarketTimer = 0

----------------------------------------------------------
-- Utility Functions
----------------------------------------------------------

local function getIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    return (identifiers and identifiers[1]) or nil
end

local function generateSerialNumber()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local serial = ''
    for i = 1, 12 do
        local randIndex = math.random(1, #chars)
        serial = serial .. chars:sub(randIndex, randIndex)
    end
    return serial
end

local function findItemInShop(list, hash)
    if not list or not hash then return nil end
    for _, item in ipairs(list) do
        if item.hash and item.hash:upper() == hash:upper() then
            return item
        end
    end
    return nil
end

----------------------------------------------------------
-- 🔄 Shop & Black Market Rotation
----------------------------------------------------------

RegisterServerEvent("weaponshop:openShop")
AddEventHandler("weaponshop:openShop", function(shopName)
    local _source = source
    local identifier = getIdentifier(_source)
    
    if not identifier then
        TriggerClientEvent("weaponshop:showAlert", _source, "Identifier not found!", "error")
        return
    end

    if shopName == "BlackMarket" and os.time() > blackMarketTimer then
        rotateBlackMarketStock()
    end
    
    local shop = Config.Shops[shopName] or Config.BlackMarket
    if not shop then
        TriggerClientEvent("weaponshop:showAlert", _source, "Shop not found!", "error")
        return
    end

    TriggerClientEvent("weaponshop:openShop", _source, {
        shopName = shop.name,
        currency = shop.currency or "cash",
        weapons = shop.weapons or {},
        ammo = shop.ammo or {},
        attachments = shop.attachments or {}
    })
end)

function rotateBlackMarketStock()
    if not Config.BlackMarket then
        Config.BlackMarket = { weapons = {}, ammo = {}, attachments = {} }
    end

    local availableWeapons, availableAmmo, availableAttachments = {}, {}, {}

    if Config.BlackMarket.restrictedWeapons then
        local shuffledWeapons = shuffleTable(Config.BlackMarket.restrictedWeapons)
        for i = 1, Config.BlackMarket.maxWeapons do
            if shuffledWeapons[i] then
                table.insert(availableWeapons, shuffledWeapons[i])
            end
        end
    end

    if Config.AmmoTypes then
        local shuffledAmmo = shuffleTable(Config.AmmoTypes)
        for i = 1, Config.BlackMarket.maxAmmoTypes do
            if shuffledAmmo[i] then
                table.insert(availableAmmo, shuffledAmmo[i])
            end
        end
    end

    if Config.Attachments then
        for weapon, attachmentList in pairs(Config.Attachments) do
            for i = 1, math.min(#attachmentList, Config.BlackMarket.maxAttachments) do
                table.insert(availableAttachments, attachmentList[i])
            end
        end
    end

    Config.Shops["BlackMarket"].weapons = availableWeapons
    Config.Shops["BlackMarket"].ammo = availableAmmo
    Config.Shops["BlackMarket"].attachments = availableAttachments

    blackMarketTimer = os.time() + Config.BlackMarket.rotationTime
    TriggerClientEvent("weaponshop:blackMarketUpdated", -1)
end

----------------------------------------------------------
-- 🛒 Unified Purchase Event (Weapons, Ammo, Attachments)
----------------------------------------------------------

RegisterServerEvent("weaponshop:buyItem")
AddEventHandler("weaponshop:buyItem", function(shopName, itemType, itemHash)
    local _source = source
    local identifier = getIdentifier(_source)
    
    if not identifier then
        TriggerClientEvent("weaponshop:showAlert", _source, "Identifier not found!", "error")
        return
    end

    local shop = Config.Shops[shopName] or Config.BlackMarket
    if not shop then
        TriggerClientEvent("weaponshop:showAlert", _source, "Invalid shop!", "error")
        return
    end

    local itemData = findItemInShop(shop[itemType == "weapon" and "weapons" or itemType == "ammo" and "ammo" or "attachments"], itemHash)
    if not itemData then
        TriggerClientEvent("weaponshop:showAlert", _source, "Item not available!", "error")
        return
    end

    if itemType == "weapon" then
        local serialNumber = shopName ~= "BlackMarket" and generateSerialNumber() or ""
        oxmysql:execute("INSERT INTO player_weapons (identifier, weapon, serial_number, ammo_amount, attachments) " ..
                        "VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE ammo_amount = VALUES(ammo_amount)",
                        { identifier, itemHash, serialNumber, Config.DefaultAmmo, "[]" })
        TriggerClientEvent("weaponshop:giveItem", _source, itemType, itemHash, serialNumber)

    elseif itemType == "ammo" then
        TriggerClientEvent("weaponshop:giveItem", _source, itemType, itemHash, Config.AmmoTypes[itemHash].amount)

    elseif itemType == "attachment" then
        TriggerClientEvent("weaponshop:giveItem", _source, itemType, itemHash)
    end

    TriggerClientEvent("weaponshop:purchaseSuccess", _source, itemData.label)
end)

----------------------------------------------------------
-- 🔧 Admin & Debugging Commands
----------------------------------------------------------

RegisterCommand("giveitem", function(source, args)
    local player, shopName, itemType, itemHash = tonumber(args[1]), args[2], args[3], args[4]
    local identifier = getIdentifier(source)
    
    if identifier and IsPlayerAdmin(identifier) then
        TriggerEvent("weaponshop:buyItem", shopName, itemType, itemHash)
        TriggerClientEvent("weaponshop:showAlert", player, "Admin has given you an item!", "success")
    end
end, false)

----------------------------------------------------------
-- ⚡ Auto-Refresh, Player Join, and Death Handling
----------------------------------------------------------

CreateThread(function()
    while true do
        Wait(Config.BlackMarket.rotationTime * 1000)
        rotateBlackMarketStock()
    end
end)

RegisterServerEvent("weaponshop:playerDied")
AddEventHandler("weaponshop:playerDied", function()
    local _source = source
    local identifier = getIdentifier(_source)

    if identifier then
        oxmysql:execute("DELETE FROM player_weapons WHERE identifier = ?", {identifier}, function()
            TriggerClientEvent("weaponshop:clearWeapons", _source)
        end)
    end
end)

RegisterServerEvent("weaponshop:loadPlayerWeapons")
AddEventHandler("weaponshop:loadPlayerWeapons", function()
    local _source = source
    local identifier = getIdentifier(_source)

    if identifier then
        oxmysql:execute("SELECT * FROM player_weapons WHERE identifier = ?", {identifier}, function(weapons)
            if weapons and #weapons > 0 then
                for _, weapon in ipairs(weapons) do
                    TriggerClientEvent("weaponshop:giveWeapon", _source, weapon.weapon, weapon.serial_number or "")

                    local attachments = json.decode(weapon.attachments) or {}
                    for _, attachment in ipairs(attachments) do
                        TriggerClientEvent("weaponshop:giveAttachment", _source, weapon.weapon, attachment)
                    end
                end
            end
        end)
    end
end)

AddEventHandler("playerSpawned", function()
    local _source = source
    TriggerEvent("weaponshop:loadPlayerWeapons", _source)
end)
