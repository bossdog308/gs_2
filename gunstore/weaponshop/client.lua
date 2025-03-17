-- client.lua
-- Fully optimized Weapon Shop Client
-- Debug logging included; Black Market functions operate without serial numbers

local inShopMarker = false
local notificationActive = false
local blips = {}
local lastPurchaseTime = 0
local purchaseCooldown = 3000 -- 3 seconds in milliseconds

-- 🏪 Create Blips for All Shops
Citizen.CreateThread(function()
    for _, shop in pairs(Config.Shops) do
        local blip = AddBlipForCoord(shop.location.x, shop.location.y, shop.location.z)
        SetBlipSprite(blip, 110) -- Gun icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, shop.legal and 1 or 6) -- Use red for legal shops, dark for Black Market
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(shop.name)
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end
end)

-- 🔄 Shop Interaction Handling
Citizen.CreateThread(function()
    while true do
        local waitTime = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearShop = false

        for _, shop in pairs(Config.Shops) do
            local distance = #(vector3(shop.location.x, shop.location.y, shop.location.z) - playerCoords)
            if distance < 10.0 then
                waitTime = 0
                nearShop = true
                DrawMarker(25, shop.location.x, shop.location.y, shop.location.z - 0.7, 
                           0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0,
                           255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                if distance < 2.0 then
                    DrawText3D(shop.location.x, shop.location.y, shop.location.z + 0.8, "[E] Open " .. shop.name)
                    if not inShopMarker then
                        inShopMarker = true
                        TriggerEvent("weaponshop:enterMarker")
                    end
                    if IsControlJustPressed(0, 38) then -- "E" key
                        TriggerEvent("weaponshop:openShopUI", shop.name, shop.weapons, shop.ammo, shop.attachments, shop.currency)
                    end
                end
            end
        end

        if not nearShop and inShopMarker then
            inShopMarker = false
            TriggerEvent("weaponshop:exitMarker")
        end

        Citizen.Wait(waitTime)
    end
end)

-- 🛒 Open NUI Shop UI
RegisterNetEvent("weaponshop:openShopUI")
AddEventHandler("weaponshop:openShopUI", function(shopName, weapons, ammo, attachments, currency)
    if inShopMarker then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openShop",
            shopName = shopName,
            weapons = weapons,
            ammo = ammo,
            attachments = getWeaponAttachments(weapons),
            currency = currency
        })
        print("^2[DEBUG] Opened shop UI for: " .. shopName)
    end
end)

RegisterNUICallback("buyItem", function(data, cb)
    print("^3[DEBUG] NUI Buy Request Received: " .. json.encode(data))

    if not data.shopName or not data.itemType or not data.itemHash then
        print("^1[ERROR] Invalid NUI data received!")
        cb({ success = false, message = "Invalid data sent from NUI." })
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastPurchaseTime < purchaseCooldown then
        TriggerEvent("weaponshop:showAlert", "You're purchasing too fast!", "error")
        cb({ success = false, message = "You're purchasing too fast!" })
        return
    end

    lastPurchaseTime = currentTime
    TriggerServerEvent("weaponshop:buyItem", data.shopName, data.itemType, data.itemHash)
    cb({ success = true, message = "Purchase request sent!" })
end)


--[[ NUI Callback: Buy Item (generic handler)
RegisterNUICallback("buyItem", function(data, cb)
    print("^3[DEBUG] NUI Buy Request Received: " .. json.encode(data))
    if not data.shopName or not data.weaponHash then
        print("^1[ERROR] Invalid NUI data received!")
        cb({ success = false, message = "Invalid data sent from NUI." })
        return
    end
    TriggerEvent("weaponshop:buyItem", data.shopName, "weapon", data.weaponHash)
    cb({ success = true, message = "Purchase request sent!" })
end)

-- NUI Callback: Buy Weapon (with spam & blacklist prevention)
RegisterNUICallback("buyWeapon", function(data)
    print("^3[DEBUG] Buy Weapon Request: Shop: " .. tostring(data.shopName) .. " | Weapon: " .. tostring(data.weapon))
    local currentTime = GetGameTimer()
    if currentTime - lastPurchaseTime < purchaseCooldown then
        TriggerEvent("weaponshop:showAlert", "You are purchasing too fast!", "error")
        return
    end
    lastPurchaseTime = currentTime
    if isWeaponBlacklisted(data.weapon) then
        TriggerEvent("weaponshop:showAlert", "This weapon is restricted!", "error")
        return
    end
    TriggerServerEvent("weaponshop:buyItem", data.shopName, "weapon", data.weapon)
end)

-- NUI Callback: Buy Ammo
RegisterNUICallback("buyAmmo", function(data)
    print("^3[DEBUG] Buy Ammo Request: Shop: " .. tostring(data.shopName) .. " | Ammo Type: " .. tostring(data.ammoType))
    local currentTime = GetGameTimer()
    if currentTime - lastPurchaseTime < purchaseCooldown then
        TriggerEvent("weaponshop:showAlert", "You are purchasing too fast!", "error")
        return
    end
    lastPurchaseTime = currentTime
    TriggerServerEvent("weaponshop:buyItem", data.shopName, "ammo", data.ammoType)
end)

-- NUI Callback: Buy Attachment
RegisterNUICallback("buyAttachment", function(data)
    print("^3[DEBUG] Buy Attachment Request: Shop: " .. tostring(data.shopName) .. " | Attachment: " .. tostring(data.attachmentHash))
    if hasAttachment(data.weaponHash, data.attachmentHash) then
        TriggerEvent("weaponshop:showAlert", "You already own this attachment!", "error")
        return
    end
    TriggerServerEvent("weaponshop:buyItem", data.shopName, "attachment", data.attachmentHash)
end)]]

-- NUI Callback: Close Shop
RegisterNUICallback("closeShop", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
end)

-- Get Weapon Attachments for UI Display
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

-- Check if Player Already Has an Attachment
function hasAttachment(weaponHash, attachmentHash)
    local playerPed = PlayerPedId()
    return HasPedGotWeaponComponent(playerPed, GetHashKey(weaponHash), GetHashKey(attachmentHash))
end

-- Check if a Weapon is Blacklisted
function isWeaponBlacklisted(weaponHash)
    for _, restrictedWeapon in ipairs(Config.Blacklist.restrictedWeapons) do
        if restrictedWeapon == weaponHash then
            return true
        end
    end
    return false
end

--[[ 🔫 Give Weapon on Purchase (Regular shops send a serial number; Black Market doesn't)
RegisterNetEvent("weaponshop:giveWeapon")
AddEventHandler("weaponshop:giveWeapon", function(itemHash, serialNumber)
    local playerPed = PlayerPedId()
    
    print("^3[DEBUG] Received giveWeapon event for: " .. tostring(itemHash) .. " | Serial: " .. tostring(serialNumber))

    -- Check if item is a weapon or attachment
    if not itemHash or itemHash == "" then
        print("^1[ERROR] No item provided in event!")
        return
    end

    local weaponHash = GetHashKey(itemHash)

    -- If it's an attachment, add it to the player's weapon instead of trying to equip it
    if IsWeaponComponentAvailable(weaponHash) then
        print("^3[DEBUG] Applying attachment: " .. itemHash)
        GiveWeaponComponentToPed(playerPed, GetSelectedPedWeapon(playerPed), weaponHash)
        TriggerEvent("chat:addMessage", { args = { "^2[Weapon Shop] ^7Attachment applied: " .. itemHash }})
        return
    end

    -- Otherwise, treat it as a weapon
    if not HasPedGotWeapon(playerPed, weaponHash, false) then
        GiveWeaponToPed(playerPed, weaponHash, 50, false, true)

        if HasPedGotWeapon(playerPed, weaponHash, false) then
            print("^2[DEBUG] Successfully given weapon: " .. itemHash)
            SetCurrentPedWeapon(playerPed, weaponHash, true)

            if serialNumber and serialNumber ~= "" then
                TriggerEvent("chat:addMessage", { args = { "^2[Weapon Shop] ^7You received a " .. itemHash .. " (Serial: " .. serialNumber .. ")!" }})
            else
                TriggerEvent("chat:addMessage", { args = { "^2[Weapon Shop] ^7You received a " .. itemHash .. " from Black Market!" }})
            end
        else
            print("^1[ERROR] Failed to give weapon: " .. itemHash)
            TriggerEvent("chat:addMessage", { args = { "^1[Weapon Shop] ^7Failed to receive the weapon!" }})
        end
    else
        print("^1[ERROR] Player already has weapon: " .. itemHash)
        TriggerEvent("chat:addMessage", { args = { "^1[Weapon Shop] ^7You already have this weapon!" }})
    end
end)

-- Function to check if an item is an attachment
function IsWeaponComponentAvailable(componentHash)
    return HasPedGotWeaponComponent(PlayerPedId(), GetSelectedPedWeapon(PlayerPedId()), componentHash)
end



-- 🔄 Give Ammo
RegisterNetEvent("weaponshop:giveAmmo")
AddEventHandler("weaponshop:giveAmmo", function(ammoType, amount)
    local playerPed = PlayerPedId()
    local weaponHash = nil
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

-- 🔧 Give Attachment
RegisterNetEvent("weaponshop:giveAttachment")
AddEventHandler("weaponshop:giveAttachment", function(weapon, attachment)
    local playerPed = PlayerPedId()
    if HasPedGotWeapon(playerPed, GetHashKey(weapon), false) then
        if not HasPedGotWeaponComponent(playerPed, GetHashKey(weapon), GetHashKey(attachment)) then
            GiveWeaponComponentToPed(playerPed, GetHashKey(weapon), GetHashKey(attachment))
            TriggerEvent("chat:addMessage", { args = { "^2[Weapon Shop] ^7Attachment applied to " .. weapon .. "!" }})
        else
            TriggerEvent("chat:addMessage", { args = { "^1[Error] ^7You already have this attachment!" }})
        end
    else
        TriggerEvent("chat:addMessage", { args = { "^1[Error] ^7You do not have the weapon for this attachment!" }})
    end
end)]]

RegisterNetEvent("weaponshop:giveItem")
AddEventHandler("weaponshop:giveItem", function(itemType, itemHash, amountOrSerial)
    local playerPed = PlayerPedId()
    
    if not itemHash or itemHash == "" then
        print("^1[ERROR] No item provided in event!")
        return
    end

    local itemKey = GetHashKey(itemHash)

    if itemType == "weapon" then
        if not HasPedGotWeapon(playerPed, itemKey, false) then
            GiveWeaponToPed(playerPed, itemKey, 50, false, true)
            SetCurrentPedWeapon(playerPed, itemKey, true)
        end

    elseif itemType == "ammo" then
        local weaponHash = findWeaponForAmmo(itemHash)
        if weaponHash then
            AddAmmoToPed(playerPed, weaponHash, amountOrSerial)
        else
            print("^1[ERROR] No matching weapon found for ammo type!")
        end

    elseif itemType == "attachment" then
        local equippedWeapon = GetSelectedPedWeapon(playerPed)
        if HasPedGotWeapon(playerPed, equippedWeapon, false) then
            GiveWeaponComponentToPed(playerPed, equippedWeapon, itemKey)
        else
            print("^1[ERROR] Cannot apply attachment, weapon not equipped.")
        end
    end
end)


RegisterNetEvent("weaponshop:giveItem")
AddEventHandler("weaponshop:giveItem", function(itemType, itemHash, amountOrSerial)
    local playerPed = PlayerPedId()
    local equippedWeapon = GetSelectedPedWeapon(playerPed)

    if itemType == "attachment" then
        if HasPedGotWeapon(playerPed, equippedWeapon, false) then
            GiveWeaponComponentToPed(playerPed, equippedWeapon, GetHashKey(itemHash))
        else
            print("^1[ERROR] Cannot apply attachment, weapon not equipped.")
        end
    end
end)


-- ✅ Purchase Success Notification
RegisterNetEvent("weaponshop:purchaseSuccess")
AddEventHandler("weaponshop:purchaseSuccess", function(itemLabel)
    SendNUIMessage({ action = "showAlert", message = "You purchased " .. itemLabel .. "!" })
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
    print("^2[DEBUG] Purchase success: " .. itemLabel)
end)

-- 🎭 Draw 3D Text with Background
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFont(7)
    SetTextProportional(1)
    SetTextColour(255, 25, 0, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end
