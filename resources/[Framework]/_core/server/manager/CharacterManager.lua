function API.getNameById(id)
    local rows = API_Database.query("CKF_/GetCharNameByCharId", {charid = id})
    if #rows > 0 then
        return rows[1].characterName
    end
    return "?"
end

--------------------------
-- Save Server Position --
--------------------------

serverPositions	= {}

RegisterServerEvent('updatePosOnServerForPlayer')
AddEventHandler('updatePosOnServerForPlayer', function(newpos)
	serverPositions[source] = newpos
end)

function API.unloadPosForPlayer(source)
	serverPositions[source] = {0.0,0.0,0.0}
end

function API.getPlayerPos(source)
    return table.unpack(serverPositions[source])
end 