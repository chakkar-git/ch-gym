local QBCore = exports['qb-core']:GetCoreObject()
local Config = {
    TargetingSystem = 'qb-target' 
}

local stressRemovalAmount = GetStressRemovalAmount()

local isLiftWeightsPlaying = false
local leftDumbbellProp = nil
local rightDumbbellProp = nil

local chinUpLocations = {
    vector3(-1205.08, -1563.87, 4.61),
    vector3(-1199.65, -1571.6, 4.61)
}

local chinUpTeleportLocations = {
    vector4(-1204.93, -1564.12, 3, 212.16),
    vector4(-1199.5, -1571.39, 3, 35)
}

local pushupSitupLocations = {
    vector3(-1201.68, -1570.35, 4),
    vector3(-1204.96, -1560.92, 4)
}

local dumbbellLocations = {
    vector3(-1202.68, -1573.37, 4.61), 
    vector3(-1197.97, -1565.4, 4.62), 
    vector3(-1209.69, -1559.07, 4.61)
}


local function createDumbbellProps()
    local model = GetHashKey("v_res_tre_weight")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end

    local playerPed = PlayerPedId()
    local leftBoneIndex = GetPedBoneIndex(playerPed, 18905)
    local rightBoneIndex = GetPedBoneIndex(playerPed, 57005)

    if leftDumbbellProp then
        DeleteObject(leftDumbbellProp)
    end
    if rightDumbbellProp then
        DeleteObject(rightDumbbellProp)
    end

    leftDumbbellProp = CreateObject(model, 0, 0, 0, true, true, true)
    AttachEntityToEntity(leftDumbbellProp, playerPed, leftBoneIndex, 0.1, 0, -0.001, 0, 0, 0, true, true, false, true, 1, true)
    
    rightDumbbellProp = CreateObject(model, 0, 0, 0, true, true, true)
    AttachEntityToEntity(rightDumbbellProp, playerPed, rightBoneIndex, 0.1, 0.0, -0.09, 0, 0, 0, true, true, false, true, 1, true)
end

local function deleteDumbbellProps()
    if leftDumbbellProp and DoesEntityExist(leftDumbbellProp) then
        DeleteObject(leftDumbbellProp)
        leftDumbbellProp = nil
    end
    if rightDumbbellProp and DoesEntityExist(rightDumbbellProp) then
        DeleteObject(rightDumbbellProp)
        rightDumbbellProp = nil
    end
end

local function playWorkoutAnimation(coords, animDict, animName, duration, heading)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), heading or 0) 
    ClearPedTasksImmediately(PlayerPedId())

    RequestAnimDict(animDict)
    local waitTime = 0
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
        waitTime = waitTime + 100
        if waitTime > 5000 then 
            return
        end
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 8.0, duration, 1, 0, false, false, false)
end

local function doChinUps(locationIndex)
    local isChinUpsPlaying = true
    local wasCancelled = false
    local coords = chinUpTeleportLocations[locationIndex]
    local heading = coords.w or 0
    local duration = 15000  

    QBCore.Functions.Progressbar("chin_ups_progress", "Doing Chin-Ups", duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() 
        if not wasCancelled then
            ClearPedTasksImmediately(PlayerPedId())
            isChinUpsPlaying = false
            TriggerServerEvent('hud:server:RelieveStress', stressRemovalAmount)
        end
    end, function()  -- On cancel
        ClearPedTasksImmediately(PlayerPedId())
        isChinUpsPlaying = false
        wasCancelled = true
    end)

    playWorkoutAnimation(coords, "amb@prop_human_muscle_chin_ups@male@base", "base", duration, heading)

    Citizen.CreateThread(function()
        while isChinUpsPlaying do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 73) then  
                QBCore.Functions.Notify("Cancelling Chin-Ups...", "error")
                wasCancelled = true
                TriggerEvent('QBCore:Client:OnProgressCancel')
                TriggerEvent('progressbar:client:cancel')
                isChinUpsPlaying = false
                break
            end
        end
    end)
end

local function doPushUps()
    local isPushUpsPlaying = true
    local wasCancelled = false
    local animDict = "amb@world_human_push_ups@male@base"
    local animName = "base"
    local duration = 15000

    QBCore.Functions.Progressbar("push_ups_progress", "Doing Push-Ups", duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        if not wasCancelled then
            ClearPedTasksImmediately(PlayerPedId())
            isPushUpsPlaying = false
            TriggerServerEvent('hud:server:RelieveStress', stressRemovalAmount)
        end
    end, function() 
        ClearPedTasksImmediately(PlayerPedId())
        isPushUpsPlaying = false
        wasCancelled = true
    end)

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 8.0, duration, 1, 0, false, false, false)

    Citizen.CreateThread(function()
        while isPushUpsPlaying do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 73) then
                QBCore.Functions.Notify("Cancelling Push-Ups...", "error")
                wasCancelled = true
                TriggerEvent('QBCore:Client:OnProgressCancel')
                TriggerEvent('progressbar:client:cancel')
                isPushUpsPlaying = false
                break
            end
        end
    end)
end

local function doSitUps()
    local isSitUpsPlaying = true
    local wasCancelled = false 
    local animDict = "amb@world_human_sit_ups@male@base"
    local animName = "base"
    local duration = 15000 

    QBCore.Functions.Progressbar("sit_ups_progress", "Doing Sit-Ups", duration, false, true, 
        {}, {}, {}, {}, 
        function()  
            if not wasCancelled then
                ClearPedTasksImmediately(PlayerPedId())
                isSitUpsPlaying = false
                TriggerServerEvent('hud:server:RelieveStress', stressRemovalAmount)
            end
        end, 
        function()  
            ClearPedTasksImmediately(PlayerPedId())
            isSitUpsPlaying = false
            wasCancelled = true
        end
    )

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 8.0, duration, 1, 0, false, false, false)

    Citizen.CreateThread(function()
        while isSitUpsPlaying do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 73) then 
                QBCore.Functions.Notify("Cancelling Sit-Ups...", "error")
                wasCancelled = true  
                TriggerEvent('QBCore:Client:OnProgressCancel')
                TriggerEvent('progressbar:client:cancel')
                isSitUpsPlaying = false
                break
            end
        end
    end)
end


local function doLiftWeights()
    isLiftWeightsPlaying = true
    local wasCancelled = false
    local animDict = "amb@world_human_muscle_free_weights@male@barbell@base"
    local animName = "base"
    local duration = 15000  

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    createDumbbellProps()

    QBCore.Functions.Progressbar("lifting_weights_progress", "Lifting Weights", duration, false, true, 
        {}, {}, {}, {}, 
        function()  -- On success
            if not wasCancelled then
            ClearPedTasksImmediately(PlayerPedId())
            deleteDumbbellProps()
            isLiftWeightsPlaying = false
            TriggerServerEvent('hud:server:RelieveStress', stressRemovalAmount)
            end
    end, function()  
            ClearPedTasksImmediately(PlayerPedId())
            deleteDumbbellProps()
            isLiftWeightsPlaying = false
            wasCancelled = true
        end
    )

    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8, duration, 1, 0, false, false, false)

    Citizen.CreateThread(function()
        while isLiftWeightsPlaying do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 73) then
                QBCore.Functions.Notify("Cancelling Workout...", "error") 
                wasCancelled = true
                deleteDumbbellProps()
                TriggerEvent('QBCore:Client:OnProgressCancel')  
                TriggerEvent('progressbar:client:cancel')
                isLiftWeightsPlaying = false
                break
            end
        end
    end)
end

local function setupTargeting()
    if Config.TargetingSystem == 'qb-target' then
        for i, location in ipairs(chinUpLocations) do
            exports['qb-target']:AddBoxZone("ChinUp" .. i, location, 2, 2, {
                name="ChinUp",
                heading=0,
                debugPoly=false, 
                minZ=location.z - 1,
                maxZ=location.z + 1,
            }, {
                options = {
                    {
                        event = "ch-gym:doChinUps",
                        icon = "fas fa-dumbbell",
                        label = "Do Chin Ups",
                        locationIndex = i,
                    },
                },
                distance = 2.5,
            })
        end

        for i, location in ipairs(pushupSitupLocations) do
            exports['qb-target']:AddBoxZone("Workout" .. i, location, 3, 3, {
                name="Workout",
                heading=0,
                debugPoly=false,
                minZ=location.z - 1,
                maxZ=location.z + 1,
            }, {
                options = {
                    {
                        event = "ch-gym:doSitUps",
                        icon = "fas fa-dumbbell",
                        label = "Do Sit Ups",
                    },
                    {
                        event = "ch-gym:doPushUps",
                        icon = "fas fa-dumbbell",
                        label = "Do Push Ups",
                    },

                },
                    
                distance = 2.5,
            })
         end

         for i, location in ipairs(dumbbellLocations) do
            exports['qb-target']:AddBoxZone("Dumbbell" .. i, location, 2, 2, {
                name="Dumbbell",
                heading=0,
                debugPoly=false,
                minZ=location.z - 1,
                maxZ=location.z + 1,
            }, {
                options = {
                    {
                        event = "ch-gym:doLiftWeights",
                        icon = "fas fa-dumbbell",
                        label = "Lift Weights",
                    },
                },
                distance = 2.5,
            })
        end
    end
end

setupTargeting()

RegisterNetEvent('ch-gym:doChinUps', function(data)
    doChinUps(data.locationIndex)
end)

RegisterNetEvent('ch-gym:doSitUps', function()
    doSitUps()
end)

RegisterNetEvent('ch-gym:doPushUps', function()
    doPushUps()
end)

RegisterNetEvent('ch-gym:doLiftWeights', function()
    doLiftWeights()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteDumbbellProps()
    end
end)
