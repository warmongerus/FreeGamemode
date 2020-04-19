local Tunnel = module("_core", "libs/Tunnel")
local Proxy = module("_core", "libs/Proxy")

cAPI = {}
Tunnel.bindInterface("API", cAPI)
Proxy.addInterface("API", cAPI)

API = Proxy.getInterface("API")

local drawable_names = {"face", "masks", "hair", "torsos", "legs", "bags", "shoes", "neck", "undershirts", "vest", "decals", "jackets"}
local head_overlays = {"bl","fch","eyebrownhead","ageing","Makeup","Blush","Complexion","SunDamage","Lipstick","moles","chesthair","bodybl","addbodybl"}
local face_features = {"nosew","peaknose","lengthnose","nosehigh","noselowering","nosetwist","eyebrow","eyebrow2","cheeck1","cheeck2","cheeck3","eye1","lip1","jaw1","jaw2","chimp1","chimp2","chimp3","chimp4","neck"}

AddEventHandler(
	"playerSpawned",
	function()
		TriggerServerEvent("pre_playerSpawned")
	end
)

AddEventHandler(
	"onResourceStart",
	function(resourceName)
		if (GetCurrentResourceName() ~= resourceName) then
			return
		end
		TriggerServerEvent("API:addReconnectPlayer")
	end
)

Citizen.CreateThread(
	function()
		SetMinimapHideFow(true)
		--Citizen.InvokeNative(0x63E7279D04160477, true)
	end
)


Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= -1 then
        	TriggerServerEvent('updatePosOnServerForPlayer', { table.unpack(GetEntityCoords(playerPed)) })
        end
        Citizen.Wait(5000)
    end
end)

function cAPI.getPosition()
	local x,y,z = table.unpack(GetEntityCoords(PlayerPedId(), true))
	return x,y,z
end

function cAPI.teleport(x, y, z, spawn)
	SetEntityCoords(PlayerPedId(), x + 0.0001, y + 0.0001, z + 0.0001, 1, 0, 0, 1)
end

function cAPI.teleportSpawn(coordinate)
	local coords = json.decode(coordinate)
	cAPI.CameraWithSpawnEffect(coords)
	--SetEntityCoords(PlayerPedId(), coords.x + 0.0001, coords.y + 0.0001, coords.z + 0.0001, 1, 0, 0, 1)
end

-- return vx,vy,vz
function cAPI.getSpeed()
	local vx, vy, vz = table.unpack(GetEntityVelocity(PlayerPedId()))
	return math.sqrt(vx * vx + vy * vy + vz * vz)
end

function cAPI.setModel(genero)    
	-- Citizen.CreateThread(function()
		RequestModel(genero)
        while not HasModelLoaded(genero) do
			Citizen.Wait(100)	
		end
        SetPlayerModel(PlayerId(), genero)
		SetPedDefaultComponentVariation(PlayerPedId(), true)
    -- end)
    return true    
end 

function cAPI.LoadModel(hash)
	local waiting = 0
	while not HasModelLoaded(hash) do
		waiting = waiting + 100
		Citizen.Wait(100)
		if waiting > 0 then
			break
		end
	end
	return true
end

function cAPI.removeClothes(hash)
end

function cAPI.setClothes(hash)
	local decoded = json.decode(hash)
	cAPI.SetClothing(decoded.drawables, decoded.drawTextures)
	cAPI.SetHairColor(decoded.getHair)
	return true
end

function cAPI.setSkin(hash)
	local decoded = json.decode(hash)
	cAPI.SetPedHeadBlend(decoded.headBlend)
	cAPI.SetHeadOverlayData(decoded.overlayHead)
	cAPI.SetHeadStructure(decoded.headStruct)
	cAPI.EndFade(500)
	return true
end

function cAPI.TargetT(Distance, Ped)
	local Entity = nil
	local camCoords = GetGameplayCamCoord()
	local farCoordsX, farCoordsY, farCoordsZ = cAPI.GetCoordsFromCam(Distance)
	local RayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, farCoordsX, farCoordsY, farCoordsZ, -1, Ped, 0)
	local A,B,C,D,Entity = GetRaycastResult(RayHandle)
	return Entity, farCoordsX, farCoordsY, farCoordsZ
end

function cAPI.GetEntInFrontOfPlayer(Distance, Ped)
	local Ent = nil
	local CoA = GetEntityCoords(Ped, 1)
	local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, Distance, 0.0)
	local RayHandle = StartShapeTestRay(CoA.x, CoA.y, CoA.z, CoB.x, CoB.y, CoB.z, -1, Ped, 0)
	local A,B,C,D,Ent = GetRaycastResult(RayHandle)
	return Ent
end
  
-- Camera's coords
function cAPI.GetCoordsFromCam(distance)
	local rot = GetGameplayCamRot(2)
	local coord = GetGameplayCamCoord()

	local tZ = rot.z * 0.0174532924
	local tX = rot.x * 0.0174532924
	local num = math.abs(math.cos(tX))

	newCoordX = coord.x + (-math.sin(tZ)) * (num + distance)
	newCoordY = coord.y + (math.cos(tZ)) * (num + distance)
	newCoordZ = coord.z + (math.sin(tX) * 8.0)
	return newCoordX, newCoordY, newCoordZ
end
  

function cAPI.getCamDirection()
	local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
	local pitch = GetGameplayCamRelativePitch()
	local x = -math.sin(heading * math.pi / 180.0)
	local y = math.cos(heading * math.pi / 180.0)
	local z = math.sin(pitch * math.pi / 180.0)
	local len = math.sqrt(x * x + y * y + z * z)
	if len ~= 0 then
		x = x / len
		y = y / len
		z = z / len
	end
	return x, y, z
end

function cAPI.getNearestPlayers(radius)
	local r = {}
	local ped = PlayerPedId()
	local pid = PlayerId()
	local pCoords = GetEntityCoords(ped)

	for _, v in pairs(GetActivePlayers()) do
		local player = GetPlayerFromServerId(v)
		local pPed = GetPlayerPed(player)
		local pPCoords = GetEntityCoords(pPed)
		local distance = #(pCoords - pPCoords)
		if distance <= radius then
			r[GetPlayerServerId(player)] = distance
		end
	end
	return r
end

function cAPI.getNearestPlayer(radius)
	local p = nil
	local players = cAPI.getNearestPlayers(radius)
	local min = radius + 10.0
	for k, v in pairs(players) do
		if v < min then
			min = v
			p = k
		end
	end
	return p
end

local weaponModels = {
	"WEAPON_KNIFE",
	"WEAPON_STUNGUN",
	"WEAPON_FLASHLIGHT",
	"WEAPON_NIGHTSTICK",
	"WEAPON_HAMMER",
	"WEAPON_BAT",
	"WEAPON_GOLFCLUB",
	"WEAPON_CROWBAR",
	"WEAPON_PISTOL",
	"WEAPON_COMBATPISTOL",
	"WEAPON_APPISTOL",
	"WEAPON_PISTOL50",
	"WEAPON_MICROSMG",
	"WEAPON_SMG",
	"WEAPON_ASSAULTSMG",
	"WEAPON_ASSAULTRIFLE",
	"WEAPON_CARBINERIFLE",
	"WEAPON_ADVANCEDRIFLE",
	"WEAPON_MG",
	"WEAPON_COMBATMG",
	"WEAPON_PUMPSHOTGUN",
	"WEAPON_SAWNOFFSHOTGUN",
	"WEAPON_ASSAULTSHOTGUN",
	"WEAPON_BULLPUPSHOTGUN",
	"WEAPON_STUNGUN",
	"WEAPON_SNIPERRIFLE",
	"WEAPON_HEAVYSNIPER",
	"WEAPON_REMOTESNIPER",
	"WEAPON_GRENADELAUNCHER",
	"WEAPON_GRENADELAUNCHER_SMOKE",
	"WEAPON_RPG",
	"WEAPON_PASSENGER_ROCKET",
	"WEAPON_AIRSTRIKE_ROCKET",
	"WEAPON_STINGER",
	"WEAPON_MINIGUN",
	"WEAPON_GRENADE",
	"WEAPON_STICKYBOMB",
	"WEAPON_SMOKEGRENADE",
	"WEAPON_BZGAS",
	"WEAPON_MOLOTOV",
	"WEAPON_FIREEXTINGUISHER",
	"WEAPON_PETROLCAN",
	"WEAPON_DIGISCANNER",
	"WEAPON_BRIEFCASE",
	"WEAPON_BRIEFCASE_02",
	"WEAPON_BALL",
	"WEAPON_FLARE"
}

function cAPI.getWeapons()	
	local ped = PlayerPedId()
	local ammo_types = {}
	local weapons = {}
	for k, v in pairs(weaponModels) do
		local hash = GetHashKey(v)
		if HasPedGotWeapon(ped, hash) then
			local atype = GetPedAmmoTypeFromWeapon(ped, hash)
			if ammo_types[atype] == nil then
				ammo_types[atype] = true
				weapons[v] = GetAmmoInPedWeapon(ped, hash)
			else
				weapons[v] = 0
			end
		end
	end

	return weapons
end

function cAPI.replaceWeapons(weapons)
	local old_weapons = cAPI.getWeapons()
	cAPI.giveWeapons(weapons, true)
	return old_weapons
end

function cAPI.giveWeapon(weapon, ammo, clear_before)
	cAPI.giveWeapons(
		{
			weapon = ammo
		},
		clear_before
	)
end

function cAPI.giveWeapons(weapons, clear_before)
	local ped = PlayerPedId()

	if clear_before then
		RemoveAllPedWeapons(ped, true, true)
	end

	for weapon, ammo in pairs(weapons) do
		local hash = GetHashKey(weapon)

		GiveWeaponToPed(
			PlayerPedId(),
			hash,
			ammo or 0,
			false,
			true
		)
		Citizen.InvokeNative(0x5FD1E1F011E76D7E, PlayerPedId(), GetPedAmmoTypeFromWeapon(PlayerPedId(), hash), ammo)
	end
end

function cAPI.setArmour(amount)
	SetPedArmour(PlayerPedId(), amount)
end

function cAPI.getArmour()
	return GetPedArmour(PlayerPedId())
end

function cAPI.setHealth(amount)
	SetEntityHealth(PlayerPedId(), math.floor(amount))
end

function cAPI.getHealth()
	return GetEntityHealth(PlayerPedId())
end

local prompResult = nil

function cAPI.prompt(title, default_text)
	SendNUIMessage({act = "prompt", title = title, text = tostring(default_text)})
	SetNuiFocus(true)
	while prompResult == nil do
		Citizen.Wait(10)
	end
	local _temp = prompResult
	prompResult = nil
	return _temp
end

RegisterNUICallback(
	"prompt",
	function(data, cb)
		if data.act == "close" then
			SetNuiFocus(false)
			prompResult = data.result
		end
	end
)

local requests = {}

function cAPI.request(text, time)
	local id = math.random(999999)
	SendNUIMessage({act = "request", id = id, text = tostring(text), time = time})

	-- !!! OPTIMIZATION
	-- Stop the loop while the time has passed

	while requests[id] == nil do
		Citizen.Wait(10)
	end

	local _temp = requests[id] or false
	requests[id] = nil
	return _temp
end

RegisterNUICallback(
	"request",
	function(data, cb)
		if data.act == "response" then
			requests[data.id] = data.ok
		end
	end
)

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(3)
			if IsControlJustPressed(1, 166) then
				SendNUIMessage({act = "event", event = "yes"})
			end
			if IsControlJustPressed(1, 167) then
				SendNUIMessage({act = "event", event = "no"})
			end
		end
	end
)

local noclip = false
local noclip_speed = 10.0

function cAPI.toggleNoclip()
	noclip = not noclip
	if noclip then
		SetEntityInvincible(PlayerPedId(), true)
		SetEntityVisible(PlayerPedId(), false, false)
		NetworkSetEntityInvisibleToNetwork(PlayerPedId(), true)
	else
		SetEntityInvincible(PlayerPedId(), false)
		SetEntityVisible(PlayerPedId(), true, false)
		NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
	end
end

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(0)
			SetEntityMaxHealth(PlayerPedId(), 150)
			SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
			if noclip then
				local ped = PlayerPedId()
				local x, y, z = cAPI.getPosition()
				local dx, dy, dz = cAPI.getCamDirection()
				local speed = noclip_speed
				SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)

				if IsControlPressed(0, 32) then
					x = x + speed * dx
					y = y + speed * dy
					z = z + speed * dz
				end

				if IsControlPressed(0, 33) then
					x = x - speed * dx
					y = y - speed * dy
					z = z - speed * dz
				end

				if IsControlPressed(0, 21) then -- SHIFT
					noclip_speed = 10.0
				elseif IsControlPressed(0, 32) then -- CTRL
					noclip_speed = 0.2
				else
					noclip_speed = 1.0
				end

				SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
			end
		end
	end
)

function cAPI.teleportToWaypoint()
	if not IsWaypointActive() then
		return
	end

	local waypointBlip = GetFirstBlipInfoId(8)
	local x,y,z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09,waypointBlip,Citizen.ResultAsVector()))
-- 
	local ground
	local groundFound = false
	local groundCheckHeights = {
		0.0,
		50.0,
		100.0,
		150.0,
		200.0,
		250.0,
		300.0,
		350.0,
		400.0,
		450.0,
		500.0,
		550.0,
		600.0,
		650.0,
		700.0,
		750.0,
		800.0,
		850.0,
		900.0,
		950.0,
		1000.0,
		1050.0,
		1100.0
	}

	local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if IsPedInAnyVehicle(ped) then
		ped = veh
	end

	for i, height in ipairs(groundCheckHeights) do
		SetEntityCoordsNoOffset(ped, x, y, height, 0, 0, 1)

		RequestCollisionAtCoord(x, y, z)
		while not HasCollisionLoadedAroundEntity(ped) do
			RequestCollisionAtCoord(x, y, z)
			Citizen.Wait(1)
		end
		Citizen.Wait(20)

		ground, z = GetGroundZFor_3dCoord(x, y, height)
		if ground then
			z = z + 1.0
			groundFound = true
			break
		end
	end

	if not groundFound then
		z = 1200
		GiveDelayedWeaponToPed(PlayerPedId(), 0xFBAB5776, 1, 0)
	end

	RequestCollisionAtCoord(x, y, z)
	while not HasCollisionLoadedAroundEntity(ped) do
		RequestCollisionAtCoord(x, y, z)
		Citizen.Wait(1)
	end

	SetEntityCoordsNoOffset(ped, x, y, z, 0, 0, 1)
end

function cAPI.playAnim(dict, anim, speed)
	if not IsEntityPlayingAnim(PlayerPedId(), dict, anim) then
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(100)
		end
		TaskPlayAnim(PlayerPedId(), dict, anim, speed, 1.0, -1, 0, 0, 0, 0, 0, 0, 0)
	end
end

function cAPI.createVehicle(modelName)
	local modelHash = GetHashKey(modelName)

	if not IsModelValid(modelHash) then
		return
	end

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)
		while not HasModelLoaded(modelHash) do
			Citizen.Wait(10)
		end
	end

	local ped = GetPlayerPed(-1)
	local nveh = CreateVehicle(modelHash, GetEntityCoords(ped), GetEntityHeading(ped), true, false, true)

	SetVehicleOnGroundProperly(nveh)
	SetEntityAsMissionEntity(nveh, true, true)
	TaskWarpPedIntoVehicle(ped, nveh, -1)
	SetModelAsNoLongerNeeded(modelHash)
	SetVehicleDirtLevel(nveh, 0)
end

function cAPI.isPlayingAnimation(dict, anim)
	local ped = PlayerPedId()
	return IsEntityPlayingAnim(ped, dict, anim, 3)
end

function cAPI.clientConnected(bool)
	if bool then
		ShutdownLoadingScreenNui()
		ShutdownLoadingScreen()
	end
end

function cAPI.notify(_message)
	local str = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", _message, Citizen.ResultAsLong())
	SetTextScale(0.25, 0.25)
	SetTextCentre(1)
	Citizen.InvokeNative(0xFA233F8FE190514C, str)
	Citizen.InvokeNative(0xE9990552DEC71600)
end

function cAPI.DrawText(str, x, y, w, h, enableShadow, r, g, b, a, centre, font)
	local str = CreateVarString(10, "LITERAL_STRING", str)
	SetTextScale(w, h)
	SetTextColor(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
	SetTextCentre(centre)
	if enableShadow then
		SetTextDropshadow(1, 0, 0, 0, 255)
	end
	Citizen.InvokeNative(0xADA9255D, font)
	DisplayText(str, x, y)
end

function cAPI.StartFade(timer)
    DoScreenFadeOut(timer)
    while IsScreenFadingOut() do
        Citizen.Wait(1)
    end
end

function cAPI.EndFade(timer)
    ShutdownLoadingScreen()
    DoScreenFadeIn(timer)
    while IsScreenFadingIn() do
        Citizen.Wait(1)
    end
end  

function cAPI.createCamera()
	local ped = PlayerPedId()
	SetEntityCoords(ped, 500.02, 500.02, 250.93) -- POSITION WHEN PLAYER IS CREATING/SELECTING
	FreezeEntityPosition(GetPlayerPed(-1), true)
	SetEntityVisible(PlayerPedId(),false)
    SetTimecycleModifier('Base_modifier')
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 500.02, 500.02, 250.93, 360.00,0.00,0.00, 100.00, false, 0)    
	PointCamAtCoord(cam, 500.02-25, 500.02-70, 250.93-20)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
	DisplayHud(false)
    DisplayRadar(false)    
end

function cAPI.destroyCamera()
	DestroyCam(cam, true)
	DestroyAllCams(true)
	Citizen.Wait(500)
	DisplayHud(true)
	DisplayRadar(true)	
end

function cAPI.CameraWithSpawnEffect(coords)
	DestroyCam(cam, true)
	Citizen.Wait(100)
	cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x+200,coords.y+200,coords.z+200, 300.00,0.00,0.00, 100.00, false, 0) -- CAMERA COORDS
	PointCamAtCoord(cam, coords.x,coords.y,coords.z+200)
	SetCamActive(cam, true)
	cAPI.EndFade(500)
	RenderScriptCams(true, false, 1, true, true)
	Citizen.Wait(500)
	cam3 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x,coords.y,coords.z+200, 300.00,0.00,0.00, 100.00, false, 0)
	PointCamAtCoord(cam3, coords.x,coords.y,coords.z+200)
	SetCamActiveWithInterp(cam3, cam, 3900, true, true)
	Citizen.Wait(3900)
	cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x,coords.y,coords.z+200, 300.00,0.00,0.00, 100.00, false, 0)
	PointCamAtCoord(cam2, coords.x,coords.y,coords.z+2)
	SetCamActiveWithInterp(cam2, cam3, 3700, true, true)
	RenderScriptCams(false, true, 500, true, true)
	SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z+0.5)
	Citizen.Wait(1500)
	DestroyAllCams(true)
	Citizen.Wait(800)
	DisplayHud(true)
	DisplayRadar(true)	
	TriggerEvent('ToogleBackCharacter')
end 

function cAPI.SetPedHeadBlend(data)
	local player = PlayerPedId()
    SetPedHeadBlendData(player,
        tonumber(data['shapeFirst']),
        tonumber(data['shapeSecond']),
        tonumber(data['shapeThird']),
        tonumber(data['skinFirst']),
        tonumber(data['skinSecond']),
        tonumber(data['skinThird']),
        tonumber(data['shapeMix']),
        tonumber(data['skinMix']),
        tonumber(data['thirdMix']),
        false)
end

function cAPI.SetHeadOverlayData(data)
	local player = PlayerPedId()
    if json.encode(data) ~= "[]" then
        for i = 1, #head_overlays do
            SetPedHeadOverlay(player,  i-1, tonumber(data[i].overlayValue),  tonumber(data[i].overlayOpacity))
            -- SetPedHeadOverlayColor(player, i-1, data[i].colourType, data[i].firstColour, data[i].secondColour)
        end

        SetPedHeadOverlayColor(player, 0, 0, tonumber(data[1].firstColour), tonumber(data[1].secondColour))
        SetPedHeadOverlayColor(player, 1, 1, tonumber(data[2].firstColour), tonumber(data[2].secondColour))
        SetPedHeadOverlayColor(player, 2, 1, tonumber(data[3].firstColour), tonumber(data[3].secondColour))
        SetPedHeadOverlayColor(player, 3, 0, tonumber(data[4].firstColour), tonumber(data[4].secondColour))
        SetPedHeadOverlayColor(player, 4, 2, tonumber(data[5].firstColour), tonumber(data[5].secondColour))
        SetPedHeadOverlayColor(player, 5, 2, tonumber(data[6].firstColour), tonumber(data[6].secondColour))
        SetPedHeadOverlayColor(player, 6, 0, tonumber(data[7].firstColour), tonumber(data[7].secondColour))
        SetPedHeadOverlayColor(player, 7, 0, tonumber(data[8].firstColour), tonumber(data[8].secondColour))
        SetPedHeadOverlayColor(player, 8, 2, tonumber(data[9].firstColour), tonumber(data[9].secondColour))
        SetPedHeadOverlayColor(player, 9, 0, tonumber(data[10].firstColour), tonumber(data[10].secondColour))
        SetPedHeadOverlayColor(player, 10, 1, tonumber(data[11].firstColour), tonumber(data[11].secondColour))
        SetPedHeadOverlayColor(player, 11, 0, tonumber(data[12].firstColour), tonumber(data[12].secondColour))
    end
end

function cAPI.SetHeadStructure(data)
	local player = PlayerPedId()
    for i = 1, #face_features do
        SetPedFaceFeature(player, i-1, data[i])
    end
end

function cAPI.SetClothing(drawables, drawTextures)
	local player = PlayerPedId()
    for i = 1, #drawable_names do
        if drawables[0] == nil then
            if drawable_names[i] == "undershirts" and drawables[tostring(i-1)][2] == -1 then
                SetPedComponentVariation(player, i-1, 15, 0, 2)
            else
                SetPedComponentVariation(player, i-1, drawables[tostring(i-1)][2], drawTextures[i][2], 2)
            end
        else
            if drawable_names[i] == "undershirts" and drawables[i-1][2] == -1 then
                SetPedComponentVariation(player, i-1, 15, 0, 2)
            else
                SetPedComponentVariation(player, i-1, drawables[i-1][2], drawTextures[i][2], 2)
            end
        end
    end
end

function cAPI.SetHairColor(data)
	local player = PlayerPedId()
	SetPedHairColor(player, tonumber(data[0]), tonumber(data[1]))
end