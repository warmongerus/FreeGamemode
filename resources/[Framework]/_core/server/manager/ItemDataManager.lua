local itemDatas = {}
local names = {}

local defaultItemData = API.ItemData('????????', '????????', 0.1)

function API.getItemDataFromId(id)
    return itemDatas[id] or defaultItemData
end

function API.getItemDataFromName(name)
    if names[name] ~= nil then
        return itemDatas[names[name]] or defaultItemData
    end
    return defaultItemData
end

function API.getAmmoTypeFromWeaponType(weapon)
    weapon = weapon:upper()

    local ammo = nil

    if weapon == 'WEAPON_MOONSHINEJUG' then
        ammo = 'AMMO_MOONSHINEJUG'
    end

    if weapon == 'WEAPON_FISHINGROD' then
        ammo = 'AMMO_FISHINGROD'
    end

    if weapon == 'WEAPON_THROWN_THROWING_KNIVES' then
        ammo = 'AMMO_THROWING_KNIVES'
    end

    if weapon == 'WEAPON_THROWN_TOMAHAWK' then
        ammo = 'AMMO_TOMAHAWK'
    end

    if weapon == 'WEAPON_THROWN_TOMAHAWK_ANCIENT' then
        ammo = 'AMMO_TOMAHAWK_ANCIENT'
    end

    if weapon == 'WEAPON_MOONSHINEJUG' then
        ammo = 'AMMO_MOONSHINEJUG'
    end

    if weapon:find('_PISTOL_') then
        ammo = 'AMMO_PISTOL'
    end

    if weapon:find('_REPEATER_') or weapon:find('WEAPON_RIFLE_VARMINT') then
        ammo = 'AMMO_REPEATER'
    end

    if weapon:find('_REVOLVER_') then
        ammo = 'AMMO_REVOLVER'
    end

    if weapon:find('RIFLE_') then
        ammo = 'AMMO_RIFLE'
    end

    if weapon:find('_SHOTGUN_') then
        ammo = 'AMMO_SHOTGUN'
    end

    if weapon:find('WEAPON_BOW') then
        ammo = 'AMMO_ARROW'
    end

    if weapon:find('WEAPON_THROWN_DYNAMITE') then
        ammo = 'AMMO_DYNAMITE'
    end

    if weapon:find('WEAPON_THROWN_MOLOTOV') then
        ammo = 'AMMO_MOLOTOV'
    end

    return ammo
end

Citizen.CreateThread(
    function()
        for id, values in pairs(ItemList) do
            local ItemData = API.ItemData(id, values.name, values.weight or 0.1, values.subtitle)

            if id:find('weapon_') then
                ItemData:onUse(
                    function(this, User, amount)
                        local source = User:getSource()
                        local uWeapons = cAPI.getWeapons(source)

                        if uWeapons[id:toupper()] then
                            User:notify('Arma já está equipada')
                            return false
                        end

                        Citizen.CreateThread(
                            function()
                                User:giveWeapon(id, 0)
                            end
                        )
                        return true
                    end
                )
            end

            if id:find('ammo_') then
                ItemData:onUse(
                    function(this, User, amount)
                        local source = User:getSource()
                        local uWeapons = cAPI.getWeapons(source)
                        local formattedId = id:gsub('ammo_', ''):toupper()

                        if uWeapons[formattedId] == nil then
                            User:notify('Nenhuma arma equipada suporta este tipo de munição!')
                            return false
                        end

                        local equipedAmmo = uWeapons[formattedId]

                        Citizen.CreateThread(
                            function()
                                User:giveWeapon(formattedId, equipedAmmo + amount)
                            end
                        )
                        return true
                    end
                )
            end

            if values.type == 'food' then
                ItemData:onUse(
                    function(this, User, amount)
                        local hungerVar = values.hungerVar

                        API.varyHunger(User:getSource(), hungerVar)
                        -- TaskPlayScenario eating
                        -- Wait for Scenario to end
                        -- varyHunger

                        return true
                    end
                )
            end

            if values.type == 'beverage' then
                ItemData:onUse(
                    function(this, User, amount)
                        local thirstVar = values.thirstVar

                        API.varyThirst(User:getSource(), thirstVar)
                        -- TaskPlayScenario drinkin
                        -- Wait for Scenario to end
                        -- varyThirst

                        return true
                    end
                )
            end

            if id:find('tonic_') then
                ItemData:onUse(
                    function(this, User, amount)
                        local var = values.var
                        if id == 'medicine' or id == 'tonic' or id == 'potent_medicine' then
                            cAPI.varyHealth(User:getSource(), var)
                        end

                        if id == 'special_tonic' or id == 'special_medicine' or id == 'special_horse_stimulant_crafted' then
                            cAPI.varyStamina(User:getSource(), var)
                        end

                        return true
                    end
                )
            end

            itemDatas[id] = ItemData
            names[values.name] = id
        end
    end
)