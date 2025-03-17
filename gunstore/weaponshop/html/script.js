// script.js - Optimized NUI Weapon Shop Script
// Handles buying weapons, ammo, and attachments with unified logic

let adminBypass = false; // Admin Mode Toggle
let lastPurchaseTime = 0;
const purchaseCooldown = 3000; // 3 seconds in milliseconds

// Listen for messages from the server
window.addEventListener("message", function (event) {
    const data = event.data;
    const shopContainer = document.getElementById("shop-container");

    if (!shopContainer) {
        console.error("Error: 'shop-container' not found in the DOM!");
        return;
    }

    if (data.action === "openShop") {
        openShop(data.shopName, data.currency, data.weapons, data.ammo, data.attachments, data.isAdmin);
        shopContainer.style.display = "block";
        console.log("[DEBUG] Shop opened:", data.shopName);
    } else if (data.action === "showAlert") {
        showAlert(data.message);
    } else if (data.action === "closeShop") {
        shopContainer.style.display = "none";
        console.log("[DEBUG] Shop closed");
    }
});

// 🏪 Open Shop UI (with Admin Mode detection)
function openShop(shopName, currency, weapons, ammo, attachments, isAdmin) {
    adminBypass = isAdmin;
    document.getElementById("shop-title").innerText = shopName;
    document.getElementById("currency-type").innerText = currency;

    // Optionally toggle admin mode display
    const adminModeElement = document.getElementById("admin-mode");
    if (adminModeElement) {
        adminModeElement.style.display = isAdmin ? "block" : "none";
    }

    populateList("weapon-list", weapons, "weapon", shopName);
    populateList("ammo-list", ammo, "ammo", shopName);
    populateAttachments("attachment-list", attachments, shopName);
}

// Populate Items List (Weapons & Ammo)
function populateList(listId, items, itemType, shopName) {
    const list = document.getElementById(listId);
    if (!list) {
        console.error(`Error: '${listId}' not found in the DOM!`);
        return;
    }
    list.innerHTML = "";

    items.forEach(item => {
        const itemLabel = item.label || "Unknown Item";
        const itemPrice = item.price ? `$${item.price}` : "$0";
        const listItem = document.createElement("li");
        listItem.innerText = `${itemLabel} - ${adminBypass ? "$0" : itemPrice}`;

        const buyButton = document.createElement("button");
        buyButton.innerText = "Buy";
        buyButton.addEventListener("click", () => {
            console.log("[DEBUG] Attempting to buy item:", JSON.stringify(item, null, 2));
            buyItem(shopName, itemType, item.hash || item.weapon || item.type, item.label);
        });
        
        listItem.appendChild(buyButton);
        list.appendChild(listItem);
    });
}

// Populate Attachments List
function populateAttachments(listId, attachments, shopName) {
    const list = document.getElementById(listId);
    if (!list) {
        console.error(`Error: '${listId}' not found in the DOM!`);
        return;
    }
    list.innerHTML = "";

    attachments.forEach(attachmentGroup => {
        const groupHeader = document.createElement("li");
        groupHeader.innerHTML = `<strong>${attachmentGroup.weapon}</strong>`;
        list.appendChild(groupHeader);

        attachmentGroup.attachments.forEach(attachment => {
            const item = document.createElement("li");
            item.innerText = `${attachment.label} - $${adminBypass ? "0" : attachment.price}`;

            const buyButton = document.createElement("button");
            buyButton.innerText = "Buy";
            buyButton.addEventListener("click", () => {
                console.log("[DEBUG] Buying attachment:", attachment);
                buyItem(shopName, "attachment", attachment.hash, attachment.label);
            });
            item.appendChild(buyButton);
            list.appendChild(item);
        });
    });
}

// ------------------------------
// Unified Buy Function
// ------------------------------

function buyItem(shopName, itemType, itemHash, itemLabel) {
    if (preventSpam()) return;

    console.log(`[DEBUG] Sending ${itemType} buy request:`, shopName, itemHash);
    fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            shopName: shopName,
            itemType: itemType,
            itemHash: itemHash
        })
    })
    .then(response => response.json())
    .then(data => {
        console.log(`[DEBUG] ${itemType} buy response:`, data);
        if (data.success) {
            showAlert(`You got ${data.label || itemLabel || itemHash}!`);
        } else {
            showAlert(data.message || `${itemType} purchase failed!`);
        }
    })
    .catch(error => {
        console.error(`[ERROR] ${itemType} purchase failed:`, error);
        showAlert(`${itemType} purchase failed due to server error!`, "error");
    });
}

// ------------------------------
// Utility Functions
// ------------------------------

// Prevent Rapid Purchases (Anti-Spam)
function preventSpam() {
    const currentTime = Date.now();
    if (currentTime - lastPurchaseTime < purchaseCooldown) {
        showAlert("You're purchasing too fast!", "error");
        return true;
    }
    lastPurchaseTime = currentTime;
    return false;
}

// Close Shop UI when Escape is pressed
document.addEventListener("keydown", function(event) {
    if (event.key === "Escape" || event.which === 27) {
        closeShop();
    }
});

// Close Shop UI function
function closeShop() {
    const shopContainer = document.getElementById("shop-container");
    if (!shopContainer) return;
    shopContainer.style.display = "none";
    fetch(`https://${GetParentResourceName()}/closeShop`, { method: "POST" }).catch(console.error);
    console.log("[DEBUG] Shop closed via Escape key.");
}

// Show Alert Messages
function showAlert(message, type = "success") {
    const alertBox = document.getElementById("alert-box");
    if (!alertBox) {
        console.error("Error: 'alert-box' not found in the DOM!");
        return;
    }
    alertBox.innerText = message;
    alertBox.style.display = "block";

    setTimeout(() => {
        alertBox.style.display = "none";
    }, 3000);
    console.log(`[DEBUG] Alert displayed: ${message}`);
}
