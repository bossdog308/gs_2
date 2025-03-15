document.addEventListener("DOMContentLoaded", () => {
    const shopContainer = document.getElementById("shop-container");
    const alertBox = document.getElementById("alert-box");

    // Listen for NUI messages from FiveM
    window.addEventListener("message", (event) => {
        const { action, weapons, ammo, attachments, message } = event.data;

        switch (action) {
            case "openShop":
                openShop(weapons, ammo, attachments);
                break;
            case "showAlert":
                showAlert(message);
                break;
            case "closeShop":
                closeShop();
                break;
        }
    });

    function openShop(weapons = [], ammo = [], attachments = []) {
        populateShop(weapons, ammo, attachments);
        shopContainer.style.display = "block";
        setNuiFocus(true, true);
    }

    function populateShop(weapons, ammo, attachments) {
        updateList("weapon-list", weapons, buyWeapon);
        updateList("ammo-list", ammo, buyAmmo);
        updateAttachments("attachment-list", attachments);
    }

    function updateList(listId, items, buyFunction) {
        const list = document.getElementById(listId);
        list.innerHTML = "";

        if (!Array.isArray(items) || items.length === 0) {
            list.innerHTML = "<li>No items available</li>";
            return;
        }

        items.forEach(({ label, price, type, hash }) => {
            const listItem = document.createElement("li");
            listItem.innerHTML = `<span>${label} - $${price}</span>`;

            const button = document.createElement("button");
            button.textContent = "Buy";
            button.addEventListener("click", () => buyFunction(type || hash));

            listItem.appendChild(button);
            list.appendChild(listItem);
        });
    }

    function updateAttachments(listId, attachments) {
        const list = document.getElementById(listId);
        list.innerHTML = "";

        if (!Array.isArray(attachments) || attachments.length === 0) {
            list.innerHTML = "<li>No attachments available</li>";
            return;
        }

        attachments.forEach(({ weapon, attachments }) => {
            const groupHeader = document.createElement("li");
            groupHeader.innerHTML = `<strong>${weapon}</strong>`;
            list.appendChild(groupHeader);

            attachments.forEach(({ label, price, hash }) => {
                const item = document.createElement("li");
                item.innerHTML = `<span>${label} - $${price}</span>`;

                const button = document.createElement("button");
                button.textContent = "Buy";
                button.addEventListener("click", () => buyAttachment(weapon, hash));

                item.appendChild(button);
                list.appendChild(item);
            });
        });
    }

    function buyWeapon(weapon) {
        sendPurchaseRequest("buyWeapon", { weapon });
    }

    function buyAmmo(ammoType) {
        if (!ammoType) {
            showAlert("Invalid ammo type!", "red");
            return;
        }
        sendPurchaseRequest("buyAmmo", { ammoType, ammoCount: getAmmoCount(ammoType) });
    }

    function buyAttachment(weaponHash, attachmentHash) {
        sendPurchaseRequest("buyAttachment", { weaponHash, attachmentHash });
    }

    function sendPurchaseRequest(endpoint, data) {
        fetch(`https://gunstore/${endpoint}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(data),
        })
        .then(response => response.json())
        .then(({ success }) => {
            showAlert(success ? "Purchase Successful!" : "Purchase Failed!", success ? "green" : "red");
        })
        .catch(error => console.error("Fetch Error:", error));
    }

    function setNuiFocus(focus, cursor) {
        try {
            fetch(`https://${GetParentResourceName()}/setNuiFocus`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ focus, cursor }),
            }).catch(error => console.error("NUI Focus Error:", error));
        } catch (error) {
            console.error("NUI Focus Call Failed:", error);
        }
    }

    function closeShop() {
        if (!shopContainer || shopContainer.style.display === "none") return;

        shopContainer.style.display = "none";

        setTimeout(() => {
            setNuiFocus(false, false);
            fetch(`https://${GetParentResourceName()}/closeShop`, { method: "POST" }).catch(console.error);
        }, 200);
    }

    function showAlert(message, color = "green") {
        alertBox.innerText = message;
        alertBox.style.display = "block";
        alertBox.style.backgroundColor = color;

        setTimeout(() => {
            alertBox.style.display = "none";
        }, 3000);
    }

    function getAmmoCount(type) {
        const ammoDefaults = {
            pistol_ammo: 30,
            smg_ammo: 60,
            rifle_ammo: 90,
            shotgun_ammo: 20,
        };
        return ammoDefaults[type] || 30;
    }

    // Ensure the close button is properly initialized
    const closeButton = document.getElementById("close-shop-button");
    if (closeButton) {
        closeButton.addEventListener("click", closeShop);
    }
});
