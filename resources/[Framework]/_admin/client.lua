RegisterNetEvent('fc_faroeste:ped')
AddEventHandler('fc_faroeste:ped', function(modelarg)

local Model = modelarg
local characterModel = GetHashKey(Model)
RequestModel(characterModel)

Citizen.CreateThread(function() 
        local waiting = 0
        while not HasModelLoaded(characterModel) do
            waiting = waiting + 100
            Citizen.Wait(100)
            if waiting > 5000 then
                print("Nao e possivel mudar esse ped")
                break
            end
        end
        SetPlayerModel(PlayerId(), characterModel)                    
        print("ok")

    end)
end)

RegisterNetEvent('deletarveiculo')
AddEventHandler('deletarveiculo',function()
	TriggerServerEvent("trydeleteveh",VehToNet(vehicle))
end)

