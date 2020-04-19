local Tunnel = module('_core', 'libs/Tunnel')
local Proxy = module('_core', 'libs/Proxy')

cAPI = Proxy.getInterface('API')
API = Tunnel.getInterface('API')

Inventory = {}
Inventory.Opened = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(1,  183) and Inventory.isOpened() == false then
            TriggerServerEvent('_inventory:showInventory')
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Inventory.Opened then
            SetNuiFocus(Inventory.Opened)
            DisableControlAction(0, 1, Inventory.Opened)
            DisableControlAction(0, 2, Inventory.Opened)
            DisableControlAction(0, 142, Inventory.Opened)
            DisableControlAction(0, 106, Inventory.Opened)
            SendNUIMessage({
                action = "mouseUI"
            })
        end
    end
end)

---------------------------------------------
--EVENTS-------------------------------------
---------------------------------------------
RegisterNetEvent('_inventory:clientReceived')
AddEventHandler('_inventory:clientReceived', function(items)
    Inventory.showInventory(items)
end)

---------------------------------------------
--FUNCTIONS----------------------------------
---------------------------------------------

function Inventory.showInventory(items) -- this functions is on show inventory NUI
    Inventory.Opened = true
    SendNUIMessage({
        action = "show_primary_inventory",
        items = items
    })     
end

function Inventory.closeInventory() -- this func only close inventory 
    Inventory.Opened = false
end

function Inventory.isOpened() -- get if inventory is opened :O
    return Inventory.Opened 
end
-------------------------------------------------
--REGISTER NUI CALLBACKS-------------------------
-------------------------------------------------
RegisterNUICallback('_inventoryClose', function()
    Inventory.closeInventory()
end)