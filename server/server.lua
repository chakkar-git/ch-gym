local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('hud:server:RelieveStress')
AddEventHandler('hud:server:RelieveStress', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not amount or type(amount) ~= "number" then
        return 
    end

    if Player then
        local currentStress = Player.PlayerData.metadata["stress"] or 0 
        local newStress = currentStress - amount

        if newStress < 0 then
            newStress = 0
        end
        Player.Functions.SetMetaData("stress", newStress)
    end
end)