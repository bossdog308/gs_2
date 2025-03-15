local MySQL = exports['oxmysql']

-- Shop Data Request
RegisterServerEvent("weaponshop:requestShopData")
AddEventHandler("weaponshop:requestShopData", function()
    local _source = source
    
    local formattedAttachments = {}
    for weaponHash, attachmentList in pairs(Config.Attachments or {}) do
        table.insert(formattedAttachments, {
            weapon = weaponHash,
            attachments = attachmentList
        })
    end

    local shopData = {
        weapons     = Config.Weapons or {},
        ammo        = Config.Ammo or {},
        attachments = formattedAttachments  -- <--- Use the table you built
    }

    TriggerClientEvent("weaponshop:receiveShopData", _source, shopData)
end)


    
RegisterNetEvent("weaponshop:shopClosed")
AddEventHandler("weaponshop:shopClosed", function()
    local _source = source
    if _source then
        -- Instead of broadcasting an event, only send it to the specific player
        TriggerClientEvent("weaponshop:resetShopState", _source)
    end
end)





-- Buy Weapon Event
RegisterServerEvent("weaponshop:buyWeapon")
AddEventHandler("weaponshop:buyWeapon", function(weaponHash)
    local _source = source
    local playerPed = GetPlayerPed(_source)
    local identifier = GetPlayerIdentifier(_source, 0)

    if not weaponHash then
        return TriggerClientEvent("weaponshop:showAlert", _source, "Invalid weapon!", "error")
    end

    MySQL.execute('SELECT COUNT(*) as count FROM player_weapons WHERE identifier = ? AND weapon = ?', 
        {identifier, weaponHash}, function(result)
        if result and result[1].count > 0 then
            TriggerClientEvent("weaponshop:showAlert", _source, "You already own this weapon!", "error")
        else
            GiveWeaponToPed(playerPed, weaponHash, 100, false, false)
            MySQL.execute('INSERT INTO player_weapons (identifier, weapon, ammo) VALUES (?, ?, ?)', 
                {identifier, weaponHash, 100}, function(success)
                if success then
                    TriggerClientEvent("weaponshop:purchaseSuccess", _source, weaponHash)
                else
                    TriggerClientEvent("weaponshop:showAlert", _source, "Database error: Could not save weapon!", "error")
                end
            end)
        end
    end)
end)

-- Save Weapons & Ammo on Disconnect
AddEventHandler("playerDropped", function()
    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    if identifier then
        -- Request client-side ammo data before saving
        TriggerClientEvent("weaponshop:requestWeaponAndAmmoSave", _source)
    end
end)

-- Save Weapons & Ammo from Client
RegisterNetEvent("weaponshop:saveWeaponsAndAmmo")
AddEventHandler("weaponshop:saveWeaponsAndAmmo", function(weaponData)
    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    if weaponData and identifier then
        for _, weapon in ipairs(weaponData) do
            local weaponHash = weapon.weapon
            local ammoCount = weapon.ammo

            MySQL.update("UPDATE player_weapons SET ammo = ? WHERE identifier = ? AND weapon = ?", 
                {tonumber(ammoCount), identifier, weaponHash})
        end
    end
end)

-- Buy Ammo Event
RegisterServerEvent("weaponshop:buyAmmo")
AddEventHandler("weaponshop:buyAmmo", function(ammoType, ammoCount)
    local _source = source
    local identifiers = GetPlayerIdentifiers(_source)
    local identifier = identifiers[1] or nil

    if not identifier then
        print("ERROR: No identifier found for player", _source)
        return TriggerClientEvent("weaponshop:showAlert", _source, "Server error!", "error")
    end

    if not ammoType or not ammoCount or type(ammoCount) ~= "number" then
        print("DEBUG ERROR: Invalid ammo purchase request from", _source)
        return TriggerClientEvent("weaponshop:showAlert", _source, "Invalid ammo input!", "error")
    end

    -- Check if the player owns a weapon that can use this ammo
    exports.oxmysql:execute('SELECT COUNT(*) as count FROM player_weapons WHERE identifier = ?', {identifier}, function(result)
        if result and result[1].count > 0 then
            exports.oxmysql:execute("UPDATE player_weapons SET ammo = ammo + ? WHERE identifier = ?", 
                {ammoCount, identifier}, function(success)
                if success then
                    TriggerClientEvent("weaponshop:giveAmmo", _source, ammoType, ammoCount)
                    TriggerClientEvent("weaponshop:showAlert", _source, "Ammo purchased!", "success")
                else
                    TriggerClientEvent("weaponshop:showAlert", _source, "Database error: Could not save ammo!", "error")
                end
            end)
        else
            TriggerClientEvent("weaponshop:showAlert", _source, "You do not own a weapon for this ammo!", "error")
        end
    end)
end)

-- Buy Weapon Attachment
RegisterServerEvent("weaponshop:buyAttachment")
AddEventHandler("weaponshop:buyAttachment", function(weaponHash, attachmentHash)
    local _source = source
    local playerPed = GetPlayerPed(_source)
    local identifiers = GetPlayerIdentifiers(_source)
    local identifier = identifiers[1] or nil

    if not identifier then
        print("ERROR: No identifier found for player", _source)
        return TriggerClientEvent("weaponshop:showAlert", _source, "Server error!", "error")
    end

    -- Check if player owns the weapon
    exports.oxmysql:execute('SELECT COUNT(*) as count FROM player_weapons WHERE identifier = ? AND weapon = ?', 
        {identifier, weaponHash}, function(result)
        if result and result[1] and result[1].count > 0 then
            local attachmentLabel = findAttachmentLabel(weaponHash, attachmentHash)

            if attachmentLabel then
                GiveWeaponComponentToPed(playerPed, GetHashKey(weaponHash), GetHashKey(attachmentHash))

                -- Save attachment to the database
                exports.oxmysql:execute('INSERT INTO player_attachments (identifier, weapon, attachment) VALUES (?, ?, ?)',
                    {identifier, weaponHash, attachmentHash}, function(success)
                    if success then
                        TriggerClientEvent("weaponshop:purchaseSuccess", _source, "Attachment: " .. attachmentLabel)
                    else
                        TriggerClientEvent("weaponshop:showAlert", _source, "Database error: Could not save attachment!", "error")
                    end
                end)
            else
                TriggerClientEvent("weaponshop:showAlert", _source, "Invalid attachment!", "error")
            end
        else
            TriggerClientEvent("weaponshop:showAlert", _source, "You do not own this weapon!", "error")
        end
    end)
end)


-- Remove Weapon
RegisterServerEvent("weaponshop:removeWeapon")
AddEventHandler("weaponshop:removeWeapon", function(weaponHash)
    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    MySQL.execute('DELETE FROM player_weapons WHERE identifier = ? AND weapon = ?', {identifier, weaponHash})
    TriggerClientEvent("weaponshop:showAlert", _source, "Weapon removed from database!", "success")
end)

-- Load Player Weapons
RegisterServerEvent("weaponshop:loadPlayerWeapons")
AddEventHandler("weaponshop:loadPlayerWeapons", function()
    local _source = source
    local identifiers = GetPlayerIdentifiers(_source)
    local identifier = identifiers[1] or nil

    if not identifier then
        print("ERROR: No identifier found for player", _source)
        return
    end

    exports.oxmysql:execute('SELECT weapon, ammo FROM player_weapons WHERE identifier = ?', {identifier}, function(result)
        if result and #result > 0 then
            TriggerClientEvent("weaponshop:giveWeapons", _source, result) -- Send all weapons at once
        else
            TriggerClientEvent("weaponshop:showAlert", _source, "No weapons found!", "error")
        end
    end)
end)


-- Helper Function for Attachments
function findAttachmentLabel(weaponHash, attachmentHash)
    if not Config.Attachments or not Config.Attachments[weaponHash] then
        print("DEBUG ERROR: No attachments found for weapon", weaponHash)
        return nil
    end

    for _, attachment in ipairs(Config.Attachments[weaponHash]) do
        if attachment.hash == attachmentHash then
            return attachment.label
        end
    end

    print("DEBUG WARNING: Attachment not found for", weaponHash, "with hash", attachmentHash)
    return nil
end
