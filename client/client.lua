
MenuIndexes = {}
local GetHashKey = joaat
local default = nil

local function PlayEmoteNative(category, emoteType)
    Citizen.InvokeNative(0xB31A277C1AC7B7FF, cache.ped, category, 2, GetHashKey(emoteType), 0, 0, 0, 0, 0)
end

local function AhRuwet(animDict, animname, speed, speedX, duration, flags, allowwalk)
    lib.requestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    TaskPlayAnim(cache.ped, animDict, animname, speed, speedX, duration, flags, 0, allowwalk, 0, false, 0, false)
end

lib.registerMenu({
    id = 'ip_animations',
    title = 'Emote Menu',
    position = 'top-right',
    onClose = function()
        CloseMenu(true)
    end,
    onSelected = function(selected)
        MenuIndexes['ip_animations'] = selected
    end,
    options = {
        {label = "Emote", description = "", icon = 'fas fa-icons', args = {'ip_emote'}},
        {label = "scenario", description = "", icon = 'fas fa-icons', args = {'ip_scenario'}},
        {label = "Mood", description = "", icon = 'fas fa-smile', args = {'ip_emote_mood'}},
        {label = "Walkstyle", description = "", icon = 'fas fa-walking', args = {'ip_emote_walkstyle'}},
    }
}, function(_, _, args)
    if args[1] == 'ip_emote_walkstyle' then
        GenerateWalkstyleMenu()
    elseif args[1] == 'ip_emote_mood' then
        GenerateMoodStyleMenu()
    elseif args[1] == 'ip_emote' then
        GenerateEmoteMenu()
    elseif args[1] == 'ip_scenario' then
        TriggerEvent('ip:emotes:client:menuscenario')
    end
end)

function CloseMenu(isFullMenuClose, keyPressed, previousMenu)
    if isFullMenuClose or not keyPressed or keyPressed == 'Escape' then
        lib.hideMenu(false)
        return
    end

    lib.showMenu(previousMenu, MenuIndexes[previousMenu])
end

function GenerateWalkstyleMenu()
    local optionsList = {}
    for i, v in pairs (Config.AnimationEmotes.walkstyle) do
        optionsList[#optionsList + 1] = {
            label = string.format('%s', v.title),
            description = '',
            args = {v.anim}
        }
    end
    lib.registerMenu({
        id = 'ip_emote_walkstyle',
        title = 'Walkstyle Menu',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_animations')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_walkstyle'] = selected
        end,
        options = optionsList
    }, function(selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                TriggerEvent("ip_walkanim:setAnim", v.args[1])
                lib.showMenu('ip_emote_walkstyle', MenuIndexes['ip_emote_walkstyle'])
            end
        end
    end)
    lib.showMenu('ip_emote_walkstyle', MenuIndexes['ip_emote_walkstyle'])
end

AddEventHandler("ip_walkanim:setAnim", function(animation)
    if default then
        Citizen.InvokeNative(0xA6F67BEC53379A32, PlayerPedId(), default)
    end
    Citizen.InvokeNative(0xCB9401F918CB0F75, PlayerPedId(), animation, 1, -1)
    default = animation
    TriggerServerEvent("ip_walkanim:setwalk", animation)
end)

RegisterNetEvent("ip-walkanim:getwalk")
AddEventHandler("ip-walkanim:getwalk", function(walk)
    local animation = walk
    local player = PlayerPedId()
    if animation == "default" then
        Citizen.InvokeNative(0xA6F67BEC53379A32, PlayerPedId(), "MP_Style_Casual")
        return
    end
    Citizen.InvokeNative(0xCB9401F918CB0F75, player, animation, 1, -1)
end)

local babi = {}
local function CreateFacialAnims()
    for i,v in pairs(Config.facial_anims) do 
        if not babi[v[2]] then 
            babi[v[2]] = {
                id = v[2],
                items = {}
            }
        end
        babi[v[2]].items[#babi[v[2]].items+1] = v[1]
    end
end

CreateThread(function()
    CreateFacialAnims()
end)

local function StartFacialAnim(anim)
    RequestAnimDict(anim[1])
    while not HasAnimDictLoaded(anim[1]) do 
        Wait(1)
    end
    SetFacialIdleAnimOverride(cache.ped, anim[2], anim[1])
end

local function GetFacialAnimDictLabel(dict)
    return Config.animDicts[dict] or dict
end

function GenerateMoodStyleMenu()
    local optionsList = {}
    for i, v in pairs(babi) do
        optionsList[#optionsList + 1] = {
            label = GetFacialAnimDictLabel(v.id),
            description = 'Open Category',
            args = {v.id}
        }
    end
    optionsList[#optionsList + 1] = {
        label = 'Clear Animation',
        description = 'Reset Mood Animation',
        args = {'clear'}
    }
    lib.registerMenu({
        id = 'ip_emote_mood',
        title = 'Mood Menu',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_animations')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_mood'] = selected
        end,
        options = optionsList
    }, function(_, _, args)
        if args[1] ~= "clear" then
            TriggerEvent("ip_mood:menu_category", args[1])
        else
            ClearFacialIdleAnimOverride(cache.ped)
        end
    end)
    lib.showMenu('ip_emote_mood', MenuIndexes['ip_emote_mood'])
end

RegisterNetEvent("ip_mood:menu_category", function(id)
    local optionsList = {}
    for i, v in pairs(fa[id].items) do
        optionsList[#optionsList + 1] = {
            label = Config.VariationLabels[v] or v,
            description = 'Open Category',
            args = { id, v }
        }
    end

    lib.registerMenu({
        id = 'ip_emote_mood2',
        title = 'Mood Menu',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_emote_mood')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_mood2'] = selected
        end,
        options = optionsList
    }, function(selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                -- print(v.args[1])
                StartFacialAnim({v.args[1],v.args[2]})
                lib.showMenu('ip_emote_mood2', MenuIndexes['ip_emote_mood2'])
            end
        end
    end)
    lib.showMenu('ip_emote_mood2', MenuIndexes['ip_emote_mood2'])
end)

local function sortByTitle(a, b)
    return a.label < b.label
end

function GenerateEmoteMenu()
    lib.registerMenu({
        id = 'ip_emotes',
        title = 'Animation Menu',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_animations')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emotes'] = selected
        end,
        options = {
            {label = 'Dance Emotes'},
            {label = 'Emotes'},
            {label = 'Task Emotes'},
        }
    }, function(selected)
        if selected == 1 then
            TriggerEvent('ip:emotes:client:menushowdance')
        elseif selected == 2 then
            TriggerEvent('ip:emotes:client:menushowemote')
        elseif selected == 3 then
            TriggerEvent('ip:emotes:client:menushowkitemote1')
        end
    end)
    lib.showMenu('ip_emotes', MenuIndexes['ip_emotes'])
end

RegisterNetEvent("ip:emotes:client:menuscenario", function()
    local optionsList = {}
    for i, v in pairs(Config.AnimationEmotes.scenario) do
        optionsList[#optionsList + 1] = {
            label = v.title,
            description = ('/e %s'):format(string.gsub(v.command, "%s", "-")),
            args = { v.scenario, v.time }
        }
    end
    table.sort(optionsList, sortByTitle)

    lib.registerMenu({
        id = 'scenario',
        title = 'Scenario List',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_animations')
        end,
        onSelected = function(selected)
            MenuIndexes['scenario'] = selected
        end,
        options = optionsList
    }, function(selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                TaskStartScenarioInPlace(cache.ped, joaat(v.args[1]), v.args[2], 0, false, false, false)
                break
            end
        end
    end)
    lib.showMenu('scenario', MenuIndexes['scenario'])
end)

RegisterNetEvent("ip:emotes:client:menushowdance", function()
    local optionsList = {}
    for i, v in pairs(Config.AnimationEmotes.dance) do
        optionsList[#optionsList + 1] = {
            label = v.title,
            description = ('/e %s'):format(string.gsub(v.command, "%s", "-")),
            args = { v.animDict, v.animname, v.speed, v.speedX, v.duration, v.flags, v.allowwalk}
        }
    end
    table.sort(optionsList, sortByTitle)

    lib.registerMenu({
        id = 'ip_emote_dance',
        title = 'Dance Menu',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_emotes')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_dance'] = selected
        end,
        options = optionsList
    },function (selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                AhRuwet(v.args[1], v.args[2], v.args[3], v.args[4], v.args[5], v.args[6], v.args[7])
                break
            end
        end
    end)
    lib.showMenu('ip_emote_dance', MenuIndexes['ip_emote_dance'])
end)

RegisterNetEvent("ip:emotes:client:menushowemote", function()
    local optionsList = {}
    for i, v in pairs(Config.AnimationEmotes.emotes) do
        optionsList[#optionsList + 1] = {
            label = v.title,
            description = ('/e %s'):format(string.gsub(v.command, "%s", "-")),
            args = { v.animDict, v.animname, v.speed, v.speedX, v.duration, v.flags, v.allowwalk }
        }
    end
    table.sort(optionsList, sortByTitle)

    lib.registerMenu({
        id = 'ip_emote_1',
        title = 'Emote List',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_emotes')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_1'] = selected
        end,
        options = optionsList
    }, function(selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                AhRuwet(v.args[1], v.args[2], v.args[3], v.args[4], v.args[5], v.args[6], v.args[7])
                break
            end
        end
    end)
    lib.showMenu('ip_emote_1', MenuIndexes['ip_emote_1'])
end)


RegisterNetEvent("ip:emotes:client:menushowkitemote1", function()
    local optionsList = {}
    for i, v in pairs(Config.EmoteList) do
        optionsList[#optionsList + 1] = {
            label = v.title,
            description = ('/e %s'):format(string.gsub(v.command, "%s", "-")),
            args = {v.category, v.emoteType}
        }
    end
    
    table.sort(optionsList, sortByTitle)

    lib.registerMenu({
        id = 'ip_emote_kit1',
        title = 'Action',
        position = 'top-right',
        onClose = function(keyPressed)
            CloseMenu(false, keyPressed, 'ip_emotes')
        end,
        onSelected = function(selected)
            MenuIndexes['ip_emote_kit1'] = selected
        end,
        options = optionsList
    }, function (selected)
        for i, v in pairs(optionsList) do
            if selected == i then
                PlayEmoteNative(v.args[1], v.args[2])
                break
            end
        end
    end)
    lib.showMenu('ip_emote_kit1', MenuIndexes['ip_emote_kit1'])
end)

RegisterCommand('e', function(source, args)
    if not args[1] then
        print('Usage: /e [emote_command]')
        return
    end

    local emoteCommand = args[1]

    for category, emotes in pairs(Config.EmoteList) do
        for _, emoteData in ipairs(emotes) do
            if emoteData.command == emoteCommand then
                PlayEmoteNative(emoteData.category, emoteData.emoteType)
                return
            end
        end
    end

    for category, emotes in pairs(Config.AnimationEmotes) do
        for _, emoteData in ipairs(emotes) do
            if emoteData.command == emoteCommand then
                if emoteData.scenario then
                    local ped = cache.ped
                    local scenarioHash = GetHashKey(emoteData.scenario)
                    TaskStartScenarioInPlace(ped, scenarioHash, emoteData.time, 0, false, false, false)
                    return
                else
                    AhRuwet(emoteData.animDict, emoteData.animname, emoteData.speed, emoteData.speedX, emoteData.duration, emoteData.flags)
                    return
                end
            end
        end
    end

end)