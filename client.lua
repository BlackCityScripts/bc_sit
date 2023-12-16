local lastsiton = false

CreateThread(function()
    AddTextEntry('bc_sit', Config.Texts["get_up"])
    local modellist = {}
    for k, v in pairs(Config.Objects) do 
        modellist[#modellist+1] = k
    end 

    if GetResourceState("ox_target") ~= "missing" then 
        exports.ox_target:addModel(modellist, {
            {
                name = 'bc_sit:use',
                event = 'bc_sit:use',
                icon = 'fa-solid fa-chair',
                label = Config.Texts["use"],
            }
        })
    elseif GetResourceState("qb-target") ~= "missing" then 
        exports['qb-target']:AddTargetModel(modellist, { 
            options = { 
                { 
                    type = "client",
                    event = "bc_sit:use",
                    icon = 'fas fa-chair',
                    label = Config.Texts["use"], 
                }
            },
            distance = 2.5,
        })
    else 
        print("ERROR There is no supported target system (ox_target or qb-target)!")
    end 
end)

AddEventHandler('bc_sit:use', function(response)
    if lastsiton then return Config.Notify(Config.Texts["already_sit"]) end 
    local entity = response.entity 
    if not DoesEntityExist(entity) then return end 
    local model = GetEntityModel(entity)
    if not Config.Objects[model] then return end 
    local animobj = Config.Anims[Config.Objects[model].type]
    if not animobj then return end 
    local objcoords = GetEntityCoords(entity)
    if not IsSeatFree(objcoords, animobj) then return Config.Notify(Config.Texts["seat_taken"]) end 
    lastsiton = entity
    local ped = PlayerPedId() 
    SetEntityCoords(ped, objcoords+Config.Objects[model].offsets, true, false, false, false)
    if animobj.scenario then 
        TaskStartScenarioAtPosition(ped, animobj.scenario, objcoords+Config.Objects[model].offsets, GetEntityHeading(entity)+Config.Objects[model].heading, 0, true, true)
    else 
        while not HasAnimDictLoaded(animobj.dict) do
            RequestAnimDict(animobj.dict)
            Wait(10)
        end
        TaskPlayAnim(ped, animobj.dict, animobj.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end 

    CreateThread(function()
        while lastsiton do 
            DisplayHelpTextThisFrame('bc_sit', false)
            if IsControlJustReleased(0, Config.GetUpKey) then 
                lastsiton = false 
            end 
            Wait(0)
        end 
        ClearPedTasksImmediately(PlayerPedId())
        if animobj.dict then 
            RemoveAnimDict(animobj.dict)
        end 
    end)
end)

function IsSeatFree(objcoords, animobj)
    for k, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if DoesEntityExist(ped) then
            if #(GetEntityCoords(ped) - objcoords) < 2 then 
                if animobj.scenario and IsPedUsingScenario(ped, animobj.scenario) then 
                    return false 
                elseif IsEntityPlayingAnim(ped, animobj.dict, animobj.anim, 3) then 
                    return false 
                end 
            end 
        end
    end

    return true 
end 
