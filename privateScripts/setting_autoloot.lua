-- !autoloot add,listtype,itemname1;itemname2...
-- !autoloot remove,listtype,itemname1;itemname2...
-- !autoloot clear,listtype
-- !autoloot filter,typelist
-- !autoloot containers
-- !autoloot itemlist,typelist
-- typelist: acceptlist ou skiplist

-- ex: !autoloot itemlist, acceptlist

dofile("/privateScripts/vocation.lua")

local ACCEPT_LIST = "acceptlist"
local SKIP_LIST = "skiplist"
local CHUNK_SIZE = 10

if not storage.settingAutoLoot then
    storage.settingAutoLoot = {}
end

if not storage.settingAutoLoot.status then
    storage.settingAutoLoot.status = {}
end

-- Descomente para resetar o cooldown
-- storage.settingAutoLoot.status = {}

local itemsDesiredList = {
-- Personal loot
"gold coin", "platinum coin", "crystal coin", "ring of healing",

-- Creature loot (insects)
"buggy backpack", "calopteryx cape", "grasshopper legs", "carapace shield",

-- Pequenas Gemas
"small amethyst", "small emerald", "small ruby", "small sapphire", "small diamond", "small topaz",
"small enchanted amethyst", "small enchanted emerald", "small enchanted ruby", "small enchanted sapphire",

-- Shards (Estilhaços)
"blue crystal shard", "green crystal shard", "violet crystal shard",

-- Fragmentos e Splinters
"blue crystal splinter", "cyan crystal fragment", "green crystal fragment", "red crystal fragment",

-- Gemas
"violet gem", "green gem", "yellow gem", "red gem",

-- Outros valuables
"giant shimmering pearl", "giant shimmering pearl", "gold ingot",

-- Essenciais (Market/Imbuement)
"rope belt", "protective charm", "sabretooth", "bloody pincers", "vampire teeth", "cultish mask", "cultish robe",
"piece of dead brain", "brown piece of cloth",

-- Elementais e Utilidades
"silencer claws", "broken shamanic staff", "bonelord eye", "little bowl of myrrh",
"flask of embalming fluid", "gloom wolf fur", "marsh stalker beak"
}

local itemsByVocation = {
    ["knight"] = { "life ring", "sword ring", "strong mana potion", "great health potion", "ultimate health potion", "supreme health potion"},
    ["paladin"] = { "great mana potion","great spirit potion", "ultimate spirit potion"},
    ["sorcerer"] = { "strong mana potion", "great mana potion", "ultimate mana potion"},
    ["druid"] = { "strong mana potion", "great mana potion", "ultimate mana potion"},
    ["monk"] = { "great mana potion" }
}

local function getItemsByVocation()
    local vocationId = player:getVocation()
    local base = getVocationBase(vocationId)
    
    return itemsByVocation[base]
end

local function clearList(listType)
    if listType ~= ACCEPT_LIST and listType ~= SKIP_LIST then
        return
    end
    local message = "!autoloot clear, " .. listType

    say(message)
end

local function addItemsTo(listType, itemsList)
    if not itemsList or #itemsList == 0 then
        return
    end

    local chunkSize = CHUNK_SIZE

    for i = 1, #itemsList, chunkSize do
        local chunk = table.concat(itemsList, ";", i, math.min(i + chunkSize - 1, #itemsList))

        schedule(300 * i, function()
            say("!autoloot add," .. listType .. "," .. chunk)
        end)
    end
end

local function mergeOrderedLists(t1, t2)
    local result = {}

    local function insertFrom(t)
        local maxIndex = 0
        for k in pairs(t) do
            if type(k) == "number" and k > maxIndex then maxIndex = k end
        end

        for i = 1, maxIndex do
            if t[i] then
                table.insert(result, t[i])
            end
        end
    end

    insertFrom(t1)
    insertFrom(t2)
    return result
end

local function refreshAutoLoot()
    local charName = player:getName()
    local currentTime = os.time()
    local lastExecution = storage.settingAutoLoot.status[charName] or 0
    
    local secondsIn24h = 86400
    local timeDiff = currentTime - lastExecution

    if timeDiff >= secondsIn24h then
        info("Autoloot: Updating AutoLoot list to " .. charName)
        
        clearList(ACCEPT_LIST)

        local vocationItems = getItemsByVocation()
        local mergedLists = mergeOrderedLists(vocationItems, itemsDesiredList)

        schedule(350, function() 
            addItemsTo(ACCEPT_LIST, mergedLists) 
        end)

        storage.settingAutoLoot.status[charName] = currentTime
    else
        local hoursRemaining = math.floor((secondsIn24h - timeDiff) / 3600)
        info("Autoloot: AutoLoot already updated to " .. charName .. ". Next update in ~" .. hoursRemaining .. "h.")
    end
end

refreshAutoLoot()
