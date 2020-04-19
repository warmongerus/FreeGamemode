local Tunnel = module("_core","libs/Tunnel")
local Proxy = module("_core","libs/Proxy")

API = Proxy.getInterface("API")
cAPI = Tunnel.getInterface("API")

RegisterServerEvent('CKF_identity:charList')
AddEventHandler('CKF_identity:charList', function(source)
    local _source = source

    if _source == nil then
        return
    end

    local User = API.getUserFromSource(_source)
 
    if User:getId() then
        TriggerClientEvent('CKF_identity:charList', _source, User:getCharacters())
    end
end)

RegisterServerEvent('CKF_identity:charListWithUser')
AddEventHandler('CKF_identity:charListWithUser', function(User)
    if User:getId() then
        TriggerClientEvent('CKF_identity:charList', User:getSource(), User:getCharacters())
    end
end)

RegisterServerEvent('CKF_identity:selectCharacter')
AddEventHandler('CKF_identity:selectCharacter', function(cid) 
    print('server  selectcharacter')
    local _source = source
    local User = API.getUserFromSource(_source) 
    User:setCharacter(cid) 
end)

RegisterServerEvent('CKF_identity:deleteCharacter')
AddEventHandler('CKF_identity:deleteCharacter', function(cid)
    local _source = source
    local User = API.getUserFromSource(_source)
    User:deleteCharacter(cid)
    TriggerEvent('CKF_identity:charList', _source, _source)
end)
