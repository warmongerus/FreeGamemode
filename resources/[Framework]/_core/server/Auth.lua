LoginCooldown = {}

function connectUser(source, user_id)
    if API.users[user_id] then
        return
    end

    local steamID = GetPlayerIdentifiers(source)[1]

    local User = API.User(source, user_id, GetPlayerEndpoint(source))

    API.users[user_id] = User
    API.sources[source] = user_id
    API.identifiers[steamID] = user_id
    cAPI.clientConnected(source, true)

    print(GetPlayerName(source) .. ' (' .. User:getIpAddress() .. ') entrou (user_id = ' .. user_id .. ')')
    TriggerEvent('CKF_identity:charList', source, source)
    return User
end

AddEventHandler(
    'playerConnecting',
    function(playerName, kickReason, deferrals)
        local _source = source
        local ids = GetPlayerIdentifiers(_source)

        if ids[1] == nil then
            deferrals.done('Abra a Steam.')
            CancelEvent()
            return
        end

        if LoginCooldown[ids[1]] == nil then
            deferrals.update('Verificando sua whitelist...')
            if API.isWhitelisted(ids[1]) then
                local user_id = API.getUserIdByIdentifiers(ids, playerName)
                if user_id then
                    deferrals.update('Checando lista de banimentos...')
                    if API.isBanned(user_id) == 0 then
                        if API.users[user_id] == nil then
                            deferrals.update('Tudo encontrado, carregando seus dados...')
                            API.onFirstSpawn[user_id] = true
                            deferrals.done()
                        end
                    else
                        deferrals.done('Você está banido do servidor.')
                        CancelEvent()
                    end
                end
            else
                LoginCooldown[ids[1]] = true

                Citizen.CreateThread(
                    function()
                        Citizen.Wait(60000)
                        LoginCooldown[ids[1]] = nil
                    end
                )

                print(playerName .. ' (' .. ids[1] .. ') tentou conectar sem whitelist')
                deferrals.done('Você não está permitido para entrar no servidor. HEX: ' .. ids[1])
                CancelEvent()
            end
        else
            deferrals.done('Aguarde um minuto para ser removido da lista de não-whitelist.')
        end
    end
)

AddEventHandler(
    'playerDropped',
    function(reason)
        local _source = source
        local User = API.getUserFromSource(_source)
        -- Salvar arma a munição quando o User desconectar do servidor
        -- Por enquanto executa a query para cada arma
        if User ~= nil and User:getCharacter() ~= nil then
                -- travando aqui //////////////////////
          --  local weapons = cAPI.getWeapons(_source)
          --  User:getCharacter():setWeapons(weapons)
        end      
        cAPI._clientConnected(_source, false)
        API.dropPlayer(_source, reason)
    end
)

RegisterNetEvent('pre_playerSpawned')
AddEventHandler(
    'pre_playerSpawned',
    function()
        local _source = source
        local user_id = API.getUserIdByIdentifiers(GetPlayerIdentifiers(_source), GetPlayerName(_source))
        if user_id then
            local isFirstSpawn = API.onFirstSpawn[user_id]
            if isFirstSpawn then
                API.onFirstSpawn[user_id] = nil
            end
            TriggerEvent('API:playerSpawned', _source, user_id, isFirstSpawn)
        end
    end
)

RegisterNetEvent('API:playerSpawned') -- Use this one !!!!!!!!!!!!!!!!!
AddEventHandler(
    'API:playerSpawned',
    function(source, user_id, isFirstSpawn)
        if isFirstSpawn then
            connectUser(source, user_id)
        end
    end
)

RegisterNetEvent('API:addReconnectPlayer')
AddEventHandler(
    'API:addReconnectPlayer',
    function()
        local _source = source
        local ids = GetPlayerIdentifiers(_source)
        local user_id = API.getUserIdByIdentifiers(ids, GetPlayerName(_source))
        if user_id then
            connectUser(_source, user_id)
        end
    end
)
