setDefaultTab("Party")

local MACRO_DELAY = 5000
local BREAK_LINE = "\n"
local ALREADY_INVITED_SHIELD = 2
local GRAY_SHIELD_ID = 11

if storage.invitingPartySentenceSnippets == nil or not storage.invitingPartySentenceSnippets then
    storage.invitingPartySentenceSnippets = "invite"
end

local function hasPartyPlayersNearby()
    for _, spec in ipairs(getSpectators()) do
        if spec:isPlayer() and spec:getShield() == GRAY_SHIELD_ID then
            return true
        end
    end

    return false
end

local function askPt()
    if player:isPartyMember() then
        return
    end
    if player:getShield() == ALREADY_INVITED_SHIELD then
        return
    end

    say("pt")
end

local function isInvitingToParty(text)
    if not storage.invitingPartySentenceSnippets then
        return false
    end
    local invitingSnippets = string.split(storage.invitingPartySentenceSnippets, BREAK_LINE)

    for i = 1, #invitingSnippets do
        if text:lower():find(invitingSnippets[i]:lower()) then
            return true
        end
    end
    return false
end

UI.Separator()
local autoAskPtWidget = macro(MACRO_DELAY, "Auto Ask Party", function()
    askPt()
end)

local autoJoinPtWidget = macro(MACRO_DELAY, "Auto Join Party", function()

end)

onTalk(function(name, level, mode, text, channelId, pos)
    local IS_YOURSELF = name == player:getName()
    if IS_YOURSELF then
        return
    end

    local isInviting = isInvitingToParty(text)
    if isInviting then
        info("is inviting!")
    end
    local isAskingParty = text:lower():find("pt") or (text:lower():find("party") and not text:lower():find("!party"))

    if not isInviting and not isAskingParty then
        return
    end

    askPt()
end)

onTextMessage(function(mode, text)

    local MACRO_IS_DISABLED = autoJoinPtWidget:isOff()
    if MACRO_IS_DISABLED then
        return
    end

    local lower = text:lower()

    local isInvited = lower:find("invited you to his party")

    if isInvited then
        info("is invited message")
        for s, spec in pairs(getSpectators(false)) do

            if spec:getShield() == 1 then
                g_game.partyJoin(spec:getId())
            end
        end
    end

end)
