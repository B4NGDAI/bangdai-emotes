if Config.FrameWork == 'rsg-core' then
    AddEventHandler("RSGCore:Client:OnPlayerLoaded", function()
        TriggerServerEvent("ip_walkanim:getwalk")
    end)
elseif Config.FrameWork == 'qr-core' then
    AddEventHandler("QRCore:Client:OnPlayerLoaded", function()
        TriggerServerEvent("ip_walkanim:getwalk")
    end)
end

RegisterCommand(Config.OpemMenuCommand, function ()
    lib.showMenu('ip_animations', MenuIndexes['ip_animations'])
end)

CreateThread(function()
    while true do
        local sleep = 10
        if IsControlJustReleased(0, Config.Key.OpenEmotes) then
            sleep = 0
            lib.showMenu('ip_animations', MenuIndexes['ip_animations'])
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 10
        if IsControlJustReleased(0, Config.Key.CancelEmote) then
            sleep = 0
            ClearPedSecondaryTask(cache.ped)
            ClearPedTasks(cache.ped)
            FreezeEntityPosition(cache.ped, false)
            SetCurrentPedWeapon(cache.ped, 0xA2719263, true)
        end
        Wait(sleep)
    end
end)
