local Tunnel = module('_core', 'libs/Tunnel')
local Proxy = module('_core', 'libs/Proxy')

API = Proxy.getInterface('API')
cAPI = Tunnel.getInterface('API')

RegisterServerEvent('_inventory:showInventory')
AddEventHandler('_inventory:showInventory', function()
    local _source = source
    local User = API.getUserFromSource(_source)
    User:viewInventory()
end)