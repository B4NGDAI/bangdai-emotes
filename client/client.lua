local Gabungan = {}
MenuIndexes = {}
for i=1, #Config.AnimationEmotes.dance do
    Gabungan[Config.AnimationEmotes.dance[i].command] = Config.AnimationEmotes.dance[i]
end

for i=1, #Config.AnimationEmotes.emotes do
    Gabungan[Config.AnimationEmotes.emotes[i].command] = Config.AnimationEmotes.emotes[i]
end

for i=1, #Config.AnimationEmotes.scenario do
    Gabungan[Config.AnimationEmotes.scenario[i].command] = Config.AnimationEmotes.scenario[i]
end

local em = {}
for i=1, #Config.EmoteList do
    em[Config.EmoteList[i].command] = Config.EmoteList[i]
end

local jalan = {}
for i=1, #Config.AnimationEmotes.walkstyle do
    jalan[(Config.AnimationEmotes.walkstyle[i].title):lower()] = Config.AnimationEmotes.walkstyle[i]
end

local GetHashKey = joaat
local default = nil

local function pen(data)
    Citizen.InvokeNative(0xB31A277C1AC7B7FF, cache.ped, data.category, 2, GetHashKey(data.emoteType), 0, 0, 0, 0, 0)
end

local function rwt(data)
    lib.requestAnimDict(data.animDict)
    TaskPlayAnim(cache.ped, data.animDict, data.animname, data.speed, data.speedX, data.duration, data.flags, 0, data.allowwalk, 0, false, 0, false)
end

local function sortByTitle(a, b)
    return a.label < b.label
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
        {label = 'Search', description = 'Searching for something emotes?', icon = 'fas fa-magnifying-glass', args = {'cari'}},
        {label = "Emote", description = "List of Dance, Emotes and Task Emotes", icon = 'fas fa-icons', args = {'ip_emote'}},
        {label = "Scenario", description = "List of Scenarios", icon = 'fas fa-icons', args = {'ip_scenario'}},
        {label = "Mood", description = "List of Moods", icon = 'fas fa-smile', args = {'ip_emote_mood'}},
        {label = "Walkstyle", description = "List of Walkstyles", icon = 'fas fa-walking', args = {'ip_emote_walkstyle'}},
    }
}, function(_, _, args)
    if args[1] == 'cari' then
        CloseMenu(true)
        local input = lib.inputDialog('Search Emotes', {
            { type = 'input', label = 'Name of Emotes' },
        })
        if input then
            local dpt = {}
            local counts = 0
            for a,b in pairs(Gabungan) do
                if string.find((a):lower(), input[1]) then
                    counts +=1
                    dpt[counts] = {label = b.title, description = '/e '..b.command, args = {b.command}}
                end
            end
            if #dpt < 1 then
                lib.notify({
                    title = 'No emotes found for '..input[1],
                    description = 'but you can try another one!',
                    type = 'error'
                })
                return
            else
                table.sort(dpt, sortByTitle)
                lib.registerMenu({
                    id = 'pencarian',
                    title = 'Search Results for '..input[1],
                    position = 'top-right',
                    onClose = function(keyPressed)
                        CloseMenu(false, keyPressed, 'ip_animations')
                    end,
                    onSelected = function(selected)
                        MenuIndexes['pencarian'] = selected
                    end,
                    options = dpt,
                }, function (selected, scrollIndex, args, checked)
                    ExecuteCommand('e '..args[1])
                    lib.showMenu('pencarian', MenuIndexes['pencarian'] or 1)
                end)
                lib.showMenu('pencarian', MenuIndexes['pencarian'] or 1)
            end
        end
    elseif args[1] == 'ip_emote_walkstyle' then
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
            description = ('/walk %s'):format(v.title == 'Remove Walkstyle' and 'default' or v.title:lower()),
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
        Citizen.InvokeNative(0xA6F67BEC53379A32, cache.ped, default)
    end
    Citizen.InvokeNative(0xCB9401F918CB0F75, cache.ped, animation, 1, -1)
    default = animation
    TriggerServerEvent("ip_walkanim:setwalk", animation)
end)

RegisterNetEvent("ip-walkanim:getwalk")
AddEventHandler("ip-walkanim:getwalk", function(walk)
    local animation = walk
    if animation == "default" then
        Citizen.InvokeNative(0xA6F67BEC53379A32, cache.ped, "MP_Style_Casual")
        return
    end
    Citizen.InvokeNative(0xCB9401F918CB0F75, cache.ped, animation, 1, -1)
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
    lib.requestAnimDict(anim[1])
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
    for i, v in pairs(babi[id].items) do
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
            {label = 'Dance Emotes', description = 'List of Dance Emotes'},
            {label = 'Emotes', description = 'List of Emotes'},
            {label = 'Task Emotes', description = 'List of Task Emotes'},
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
            args = { i }
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
                TaskStartScenarioInPlace(cache.ped, GetHashKey(Config.AnimationEmotes.scenario[v.args[1]].scenario), Config.AnimationEmotes.scenario[v.args[1]].time, 0, false, false, false)
                lib.showMenu('scenario', MenuIndexes['scenario'])
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
            args = {i}
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
                rwt(Config.AnimationEmotes.dance[v.args[1]])
                lib.showMenu('ip_emote_dance', MenuIndexes['ip_emote_dance'])
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
            args = {i}
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
                rwt(Config.AnimationEmotes.emotes[v.args[1]])
                lib.showMenu('ip_emote_1', MenuIndexes['ip_emote_1'])
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
            args = {i}
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
                pen(Config.EmoteList[v.args[1]])
                lib.showMenu('ip_emote_kit1', MenuIndexes['ip_emote_kit1'])
                break
            end
        end
    end)
    lib.showMenu('ip_emote_kit1', MenuIndexes['ip_emote_kit1'])
end)



RegisterCommand('e', function(source, args)
    if not args[1] then
        lib.notify({
            type = 'error',
            title = 'Usage: /e [emote_command]'
        })
        return
    end

    local emoteCommand = args[1]

    if Gabungan[emoteCommand] then
        if Gabungan[emoteCommand].scenario then
            TaskStartScenarioInPlace(cache.ped, GetHashKey(Gabungan[emoteCommand].scenario), Gabungan[emoteCommand].time, 0, false, false, false)
            return
        else
            rwt(Gabungan[emoteCommand])
            return
        end
    else
        if em[emoteCommand] then
            pen(em[emoteCommand])
            return
        else
            lib.notify({
                type = 'error',
                title = 'No emotes found for '..args[1]
            })
            return
        end
    end
end)

RegisterCommand('walk', function (source, args, raw)
    if not args[1] then
        lib.notify({
            type = 'error',
            title = 'Usage: /walk [walkstyle_command]'
        })
        return
    end
    if args[1] == 'default' then
        TriggerEvent("ip_walkanim:setAnim", args[1])
    else
        if jalan[args[1]] then
            TriggerEvent("ip_walkanim:setAnim", args[1])
            return
        else
            lib.notify({
                type = 'error',
                title = 'No walking styles found for '..args[1]
            })
            return
        end
    end
end)
