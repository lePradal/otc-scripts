local MACRO_DELAY = 1000

setDefaultTab("Main")
local autoJoinPtWidget = macro(MACRO_DELAY, "Auto Join", function()

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
