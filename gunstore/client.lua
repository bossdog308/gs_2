local inShopMarker = false
local notificationActive = false
local blips = {}
local playerAmmo = {}

-- Create shop blips from Config.Shops
Citizen.CreateThread(function()
    for _, shop in ipairs(Config.Shops) do -- Loop through all shops
        local blip = AddBlipForCoord(shop.x, shop.y, shop.z) -- Create blip
        SetBlipSprite(blip, 110) -- Gun icon
        SetBlipDisplay(blip, 4) -- Gun icon
        SetBlipScale(blip, 0.8) -- Scale
        SetBlipColour(blip, 1) -- Red color
        SetBlipAsShortRange(blip, true) -- Show on minimap
        BeginTextCommandSetBlipName("STRING") -- Set blip name
        AddTextComponentString("Weapon Shop") -- Blip name
        EndTextCommandSetBlipName(blip) -- Set blip name
        table.insert(blips, blip) -- Add blip to table
    end
end)

-- Marker detection and shop interaction
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearShop = false

        for _, shop in ipairs(Config.Shops) do
            local distance = #(vector3(shop.x, shop.y, shop.z) - playerCoords)

            if distance < 10.0 then
                nearShop = true
                DrawMarker(1, shop.x, shop.y, shop.z - 1.0, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)

                if distance < 2.0 then
                    DrawText3D(shop.x, shop.y, shop.z, "[E] Open Weapon Shop")

                    if not inShopMarker then
                        inShopMarker = true
                        TriggerEvent("weaponshop:enterMarker")
                    end

                    if IsControlJustPressed(0, 38) then -- "E" Key Pressed
                        SetNuiFocus(true, true)
                        SendNUIMessage({ action = "openShop" })
                    end
                end
            end
        end

        if not nearShop and inShopMarker then
            inShopMarker = false
            TriggerEvent("weaponshop:exitMarker")
        end
    end
end)


-- Notification when entering marker
RegisterNetEvent("weaponshop:enterMarker")
AddEventHandler("weaponshop:enterMarker", function()
    if not notificationActive then
        notificationActive = true
        SetNotificationTextEntry("STRING")
        AddTextComponentString("Press ~g~E~w~ to browse weapons.")
        DrawNotification(false, true)
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)

-- Clear notification when exiting marker
RegisterNetEvent("weaponshop:exitMarker")
AddEventHandler("weaponshop:exitMarker", function()
    notificationActive = false
end)

-- Open the NUI shop UI with the current shop's weapons, ammo and attachments
-- Open the NUI shop UI
RegisterNetEvent("weaponshop:openShopUI")
AddEventHandler("weaponshop:openShopUI", function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openShop",
        weapons = Config.Weapons or {},
        ammo = Config.Ammo or {}, 
        attachments = Config.Attachments or {} -- ✅ FIXED TYPO
    })
end)


-- Close the shop
RegisterNUICallback("closeShop", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
end)

-- Retrieve available attachments for the given weapons
function getWeaponAttachments(weapons)
    local attachments = {}
    for _, weapon in ipairs(weapons) do
        if Config.Attachments[weapon.hash] then
            table.insert(attachments, {
                weapon = weapon.label,
                hash = weapon.hash,
                attachments = Config.Attachments[weapon.hash]
            })
        end
    end
    return attachments
end

-- NUI Callbacks

RegisterNUICallback("setNuiFocus", function(data, cb)
    SetNuiFocus(data.focus, data.cursor)
    cb({})
end)

-- Close Shop Function (Ensures UI Hides Properly)
function closeShop()
    SetNuiFocus(false, false) -- Remove UI focus
    SendNUIMessage({ action = "closeShop" }) -- Close UI in NUI
    Citizen.Wait(500)
    TriggerServerEvent("weaponshop:shopClosed") -- Sync with server
end

-- Handle Purchase Success & Auto-Close UI
RegisterNetEvent("weaponshop:purchaseSuccess")
AddEventHandler("weaponshop:purchaseSuccess", function(weapon)
    SendNUIMessage({ action = "showAlert", message = "You purchased " .. weapon .. "!" })
    Citizen.Wait(1000) -- Delay before closing UI
    closeShop()
end)

-- Ensure Shop Closes from NUI Callback
RegisterNUICallback("closeShop", function(data, cb)
    closeShop()
    cb({})
end)


-- Reset UI Focus After Closing
RegisterNetEvent("weaponshop:resetShopState")
AddEventHandler("weaponshop:resetShopState", function()
    Citizen.Wait(500)
    SetNuiFocus(false, false)
end)

RegisterNUICallback("buyWeapon", function(data)
    local weaponHash = GetHashKey(data.weapon)
    local playerPed = PlayerPedId()
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        TriggerEvent("weaponshop:showAlert", "You already own this weapon!", "error")
    else
        TriggerServerEvent("weaponshop:buyWeapon", data.weapon)
    end
end)

RegisterNUICallback("buyAttachment", function(data)
    TriggerServerEvent("weaponshop:buyAttachment", data.weaponHash, data.attachmentHash)
end)

RegisterNUICallback("buyAmmo", function(data, cb)
    if not data or not data.ammoType then
        print("DEBUG ERROR: Invalid ammo data received in NUI callback", json.encode(data))
        cb({ success = false, error = "Invalid data received" })
        return
    end

    local ammoType = data.ammoType
    local ammoAmount = nil

    -- Ensure Config.Ammo exists before looping
    if not Config.Ammo or type(Config.Ammo) ~= "table" then
        print("DEBUG ERROR: Config.Ammo is nil or invalid")
        cb({ success = false, error = "Config.Ammo is not defined" })
        return
    end

    -- Retrieve ammo amount from Config
    for _, ammo in ipairs(Config.Ammo) do
        if ammo.type == ammoType then
            ammoAmount = ammo.amount
            break
        end
    end

    if ammoAmount then
        print("DEBUG: Sending buyAmmo request to server with", ammoType, ammoAmount)
        TriggerServerEvent("weaponshop:buyAmmo", ammoType, ammoAmount)
        cb({ success = true })
    else
        print("DEBUG ERROR: Invalid ammo type received:", ammoType)
        TriggerEvent("weaponshop:showAlert", "Invalid ammo type!", "error")
        cb({ success = false, error = "Invalid ammo type" })
    end
end)




-- Handle giving the player a weapon (called from database)
RegisterNetEvent("weaponshop:giveWeapons")
AddEventHandler("weaponshop:giveWeapons", function(weapons)
    local playerPed = PlayerPedId()

    for _, weaponData in ipairs(weapons) do
        local weaponHash = GetHashKey(weaponData.weapon)
        local ammo = weaponData.ammo or 0

        -- Give weapon with ammo
        GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
    end
end)

-- shop data
RegisterNetEvent("weaponshop:receiveShopData")
AddEventHandler("weaponshop:receiveShopData", function(shopData)
    local weapons = shopData.weapons
    local ammo = shopData.ammo
    local attachments = shopData.attachments
    
    -- Then pass them on to your NUI or do whatever else is needed
    SendNUIMessage({
        type = "openShop",
        weapons     = weapons,
        ammo        = ammo,
        attachments = attachments
    })
end)


-- Request Shop Data When Opening the Shop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 38) then -- Press 'E' to open shop
            TriggerServerEvent("weaponshop:requestShopData")
            Citizen.Wait(500) -- Give time for server response
            TriggerEvent("weaponshop:openShopUI")
        end
        
    end
end)

-- client.lua
function openShop(weapons, attachments)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openShop',
        weapons = weapons,
        attachments = attachments
    })
end



-- Handle giving ammo to the correct weapon
RegisterNetEvent("weaponshop:giveAmmo")
AddEventHandler("weaponshop:giveAmmo", function(ammoType, amount)
    local playerPed = PlayerPedId()
    local weaponHash = nil
    -- Match ammo type to a weapon hash using a simple lookup from Config.Weapons
    for _, weapon in ipairs(Config.Weapons) do
        if string.find(ammoType, weapon.hash:lower()) then
            weaponHash = GetHashKey(weapon.hash)
            break
        end
    end
    if weaponHash and HasPedGotWeapon(playerPed, weaponHash, false) then
        AddAmmoToPed(playerPed, weaponHash, amount)
        TriggerEvent("weaponshop:showAlert", "Restored " .. amount .. " ammo!", "success")
    else
        TriggerEvent("weaponshop:showAlert", "No weapon found for this ammo!", "error")
    end
end)

-- Update ammo count and store locally
RegisterNetEvent("weaponshop:updateAmmo")
AddEventHandler("weaponshop:updateAmmo", function(weapon, ammoCount)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weapon)
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        SetPedAmmo(playerPed, weaponHash, ammoCount)
        playerAmmo[weapon] = ammoCount
    else
        GiveWeaponToPed(playerPed, weaponHash, ammoCount, false, false)
        playerAmmo[weapon] = ammoCount
    end
end)

-- Request to save ammo data to the server
RegisterNetEvent("weaponshop:requestAmmoSave")
AddEventHandler("weaponshop:requestAmmoSave", function()
    for weapon, ammo in pairs(playerAmmo) do
        TriggerServerEvent("weaponshop:saveAmmo", weapon, ammo)
    end
end)

-- Load weapons and ammo when player spawns
AddEventHandler("playerSpawned", function()
    Citizen.Wait(5000) -- Delay to ensure the player fully loads into the game
    TriggerServerEvent("weaponshop:loadPlayerWeapons") -- Load stored weapons
    TriggerServerEvent("weaponshop:loadPlayerAmmo") -- Load stored ammo
end)


-- Periodically update and save ammo count to sync with the server
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local playerPed = PlayerPedId()
        for weapon, _ in pairs(playerAmmo) do
            local weaponHash = GetHashKey(weapon)
            if HasPedGotWeapon(playerPed, weaponHash, false) then
                local currentAmmo = GetAmmoInPedWeapon(playerPed, weaponHash)
                playerAmmo[weapon] = currentAmmo
                TriggerServerEvent("weaponshop:saveAmmo", weapon, currentAmmo)
            end
        end
    end
end)

-- Listen for successful purchase event, then close the NUI
RegisterNetEvent("weaponshop:purchaseSuccess")
AddEventHandler("weaponshop:purchaseSuccess", function(weapon)
    SendNUIMessage({
        action = "showAlert",
        message = "You purchased " .. weapon .. "!"
    })
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
end)

-- 3D Text Drawing Function
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(7)
    SetTextProportional(1)
    SetTextColour(255, 25, 0, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.052 + factor, 0.03, 255, 255, 255, 255)
end
