retries = 0

local travelNPCs = {
    ["thais"] = "Captain Bluebear",
    ["venore"] = "Captain Fearless",
    ["carlin"] = "Captain Greyhound",
    ["edron"] = "Captain Seahorse",
    ["darashia"] = "Captain Kaleb",
    ["ankrahmun"] = "Captain Sinbad",
    ["liberty bay"] = "Captain Jack",
    ["port hope"] = "Captain Charles",
    ["svargrond"] = "Captain Buddel",
    ["yalahar"] = "Captain Max",
    ["gray island"] = "Scrutinon",
    ["farmine"] = "Captain Breezelda",
    ["rathleton"] = "Captain Olli",
    ["krailos"] = "Captain Grog",
    ["issavi"] = "Captain Shira",
    ["oramond"] = "Captain Terramir"
}

function travelToFrom(cityTo, cityFrom)
    local npc = getCreatureByName(travelNPCs[cityFrom])
    if not npc then
        return false
    end
    if retries > 10 then
        info("retries: " .. tostring(retries))
        return false
    end

    local pos = player:getPosition()
    local npcPos = npc:getPosition()
    -- info("npcPos: x:" .. tostring(npcPos.x) .. " - y: " .. tostring(npcPos.y))
    if math.max(math.abs(pos.x - npcPos.x), math.abs(pos.y - npcPos.y)) > 3 then
        info("walking")
        player:autoWalk(npcPos, {
            precision = 3
        })
        delay(400)
        return "retry"
    end

    NPC.say("hi")
    delay(400)
    NPC.say(cityTo)
    delay(400)
    NPC.say("yes")
    delay(2000)

    retries = 0

    return true
end