local Tunnel = module('_core', 'libs/Tunnel')
local Proxy = module('_core', 'libs/Proxy')

cAPI = Proxy.getInterface('API')
API = Tunnel.getInterface('API')

Inventory = {}
Inventory.Opened = false
Inventory.Delay = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Inventory.Delay == 0 then
            if IsControlJustReleased(1,  183) and Inventory.isOpened() == false then
                TriggerServerEvent('_inventory:showInventory')
            end
        end
        if Inventory.Opened then
            DisableControlAction(0, 1, Inventory.Opened)
            DisableControlAction(0, 2, Inventory.Opened)
            DisableControlAction(0, 142, Inventory.Opened)
            DisableControlAction(0, 106, Inventory.Opened)
            DisableControlAction(0, 16, Inventory.Opened)
            DisableControlAction(0, 17, Inventory.Opened)
        end
    end
end)
-- timer to open this inventory [ 5 seconds ]
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if Inventory.Delay > 0 then
            Inventory.Delay = Inventory.Delay - 1
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
RegisterNetEvent('_inventory:updateItems')
AddEventHandler('_inventory:updateItems', function(items)
    Inventory.updateItems(items)
end)
---------------------------------------------
--FUNCTIONS----------------------------------
---------------------------------------------

function Inventory.showInventory(items) -- this functions is on show inventory NUI
    Inventory.Opened = true
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = "show_primary_inventory",
        items = items
    })     
end

function Inventory.updateItems(items) -- this functions is on show inventory NUI
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = "UpdateItems",
        items = items
    })     
end

function Inventory.closeInventory() -- this func only close inventory 
    SetNuiFocus(false)
    SetNuiFocusKeepInput(false)
    Inventory.Opened = false
    Inventory.Delay = 5 
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