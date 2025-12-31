-- Constants
local MACRO_DELAY = 1000 -- in milliseconds
local MAX_INACTIVE_TIME = 20 -- in seconds
local KICK_DELAY = 500 -- in milliseconds
local LOCKED_PARTY_STATE = 15 -- in seconds
local INVITE_MESSAGE_COOLDOWN = 20 -- in seconds
local INVITE_REQUEST_COOLDOWN_BY_PLAYER = 5 -- in seconds
local INVITE_REQUEST_COOLDOWN_GENERAL = 5 -- in seconds
local DEFAULT_TAB = "Party"

-- Party Shields:
local SHIELD_ALREADY_INVITED = 2
local SHIELD_NON_SHARING_PARTY = 4
local SHIELD_SHARING = 6
local SHIELD_LEADER_INACTIVE = 8
local SHIELD_MEMBERS_INACTIVE = 10

-- Advice field indexes
local PLAYERS_COUNT_INDEX = 2
local HIGHEST_LEVEL_INDEX = 3
local LOWEST_LEVEL_INDEX = 4
local ACTIVE_PLAYERS_INDEX = 7
local INACTIVE_PLAYERS_INDEX = 8

-- Local variables
local lowestLevel = 0
local highestLevel = 0
local maxLevelToShare = 0
local minLevelToShare = 0
local partyMembersCount = 0
local lastInfoCheck = os.time()
local lastInactiveCheck = os.time()
local lastInviteMessageTime = os.time()
local lastInviteRequestTime = os.time()
local partyState = "idle" -- "idle", "inactivityExceeded", "processingKicks"

local updatingLabels = nil
local pendingKicks = {}
local partyMembers = {}
local lastRequestByPlayer = {}

if not storage.auto_party then
    storage.auto_party = {}
end

storage.auto_party.dynamicMaxLeveling = storage.auto_party.dynamicMaxLeveling or false
storage.auto_party.dynamicMinLeveling = storage.auto_party.dynamicMinLeveling or false
storage.auto_party.maxMembers = storage.auto_party.maxMembers or 30
storage.auto_party.staticMaxLevel = storage.auto_party.staticMaxLevel or 0
storage.auto_party.staticMinLevel = storage.auto_party.staticMinLevel or 0

setDefaultTab(DEFAULT_TAB)

UI.Separator()

local autoPartyWidget = macro(MACRO_DELAY, "Auto Party", function()

    local now = os.time()
    -- info(now .. " - Status: " .. partyState .. "- lastInfo: " .. now - lastInfoCheck .. " - lastInactive: " .. now - lastInactiveCheck)

    if not player:isPartyLeader() then
        partyState = "idle"
        partyMembersCount = 0
        lowestLevel = 0
        highestLevel = 0
        minLevelToShare = 0
        maxLevelToShare = 0
        return
    end

    if partyState ~= "idle" and partyState ~= "processingKicks" and (now - lastInfoCheck > LOCKED_PARTY_STATE) then
        partyState = "idle"
    end

    if partyState ~= "idle" then
        return
    end

    if player:getShield() == SHIELD_MEMBERS_INACTIVE then
        if now - lastInactiveCheck >= MAX_INACTIVE_TIME then
            sayChannel(getChannelId("party"), "!party info")
            partyState = "inactivityExceeded"
            return
        end
    else
        lastInactiveCheck = now
    end
end)

UI.Separator()

local statusWidget = UI.DualLabel("Status:", partyState)
local autoPtStatusLabel = statusWidget.right

local membersWidget = UI.DualLabel("Members:", tostring(partyMembersCount))
local autoPtMembersLabel = membersWidget.right

local lowestLevelWidget = UI.DualLabel("Lowest L:", tostring(lowestLevel))
local autoPtLowestLevelLabel = lowestLevelWidget.right

local highestLevelWidget = UI.DualLabel("Highest L:", tostring(highestLevel))
local autoPtHighestLevelLabel = highestLevelWidget.right

local minLevelWidget = UI.DualLabel("Min Level:", tostring(minLevelToShare))
local autoPtMinLevelLabel = minLevelWidget.right

local maxLevelWidget = UI.DualLabel("Max Level:", tostring(maxLevelToShare))
local autoPtMaxLevelLabel = maxLevelWidget.right

updatingLabels = function()
    if autoPtStatusLabel then
        autoPtStatusLabel:setText(partyState)
        local color = (partyState == "idle") and "green" or "orange"
        if partyState == "processingKicks" then color = "red" end
        autoPtStatusLabel:setColor(color)
    end
    if autoPtMembersLabel then
        autoPtMembersLabel:setText(tostring(partyMembersCount))
    end
    if autoPtLowestLevelLabel then
        autoPtLowestLevelLabel:setText(tostring(lowestLevel))
    end
    if autoPtHighestLevelLabel then
        autoPtHighestLevelLabel:setText(tostring(highestLevel))
    end
    if autoPtMinLevelLabel then
        autoPtMinLevelLabel:setText(tostring(minLevelToShare))
    end
    if autoPtMaxLevelLabel then
        autoPtMaxLevelLabel:setText(tostring(maxLevelToShare))
    end
end

UI.Separator()

-- Painel Unificado de Configuração
local config = setupUI([[
UIWidget
  height: 120
  layout:
    type: verticalBox
    fit-children: true

  Panel
    id: maxMembersRow
    height: 22
    Label
      text: Max Members:
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    BotTextEdit
      id: value
      anchors.right: parent.right
      width: 45
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      margin-right: 6

  Panel
    id: minLevelRow
    height: 22
    margin-top: 2
    Label
      text: Min Level:
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    BotTextEdit
      id: value
      anchors.right: parent.right
      width: 45
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      margin-right: 6

  Panel
    id: maxLevelRow
    height: 22
    margin-top: 2
    Label
      text: Max Level:
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    BotTextEdit
      id: value
      anchors.right: parent.right
      width: 45
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      margin-right: 6

  Panel
    id: dynamicMinRow
    height: 22
    margin-top: 4
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Dynamic Min Leveling
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-left: 7

  Panel
    id: dynamicMaxRow
    height: 22
    margin-top: 2
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Dynamic Max Leveling
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-left: 7
]], setDefaultTab(DEFAULT_TAB))

-- 1. Max Members
config.maxMembersRow.value:setText(tostring(storage.auto_party.maxMembers))
config.maxMembersRow.value.onTextChange = function(widget, text)
    storage.auto_party.maxMembers = tonumber(text) or 30
end

-- 2. Min Level Input
config.minLevelRow.value:setText(tostring(storage.auto_party.staticMinLevel))
config.minLevelRow.value:setEnabled(not storage.auto_party.dynamicMinLeveling)
config.minLevelRow.value.onTextChange = function(widget, text)
    storage.auto_party.staticMinLevel = tonumber(text) or 0
end

-- 3. Max Level Input
config.maxLevelRow.value:setText(tostring(storage.auto_party.staticMaxLevel))
config.maxLevelRow.value:setEnabled(not storage.auto_party.dynamicMaxLeveling)
config.maxLevelRow.value.onTextChange = function(widget, text)
    storage.auto_party.staticMaxLevel = tonumber(text) or 0
end

-- 4. Dynamic Min Checkbox
config.dynamicMinRow.check:setChecked(storage.auto_party.dynamicMinLeveling)
config.dynamicMinRow.check.onClick = function(widget)
    storage.auto_party.dynamicMinLeveling = not storage.auto_party.dynamicMinLeveling
    widget:setChecked(storage.auto_party.dynamicMinLeveling)
    config.minLevelRow.value:setEnabled(not storage.auto_party.dynamicMinLeveling)
end

-- 5. Dynamic Max Checkbox
config.dynamicMaxRow.check:setChecked(storage.auto_party.dynamicMaxLeveling)
config.dynamicMaxRow.check.onClick = function(widget)
    storage.auto_party.dynamicMaxLeveling = not storage.auto_party.dynamicMaxLeveling
    widget:setChecked(storage.auto_party.dynamicMaxLeveling)
    config.maxLevelRow.value:setEnabled(not storage.auto_party.dynamicMaxLeveling)
end

UI.Separator()

local infoButton = UI.Button("Info", function()
    sayChannel(getChannelId("party"), "!party info")
end)

infoButton:setColor("green")

local disbandPartyButton = UI.Button("Disband Party", function()
    if #partyMembers == 0 then
        return
    end

    for i, name in ipairs(partyMembers) do
        if name ~= player:getName() then
            schedule(KICK_DELAY * i, function()
                sayChannel(getChannelId("party"), "!party kick," .. name)
                info("Kicking " .. name .. " from party.")
                if i == #partyMembers then
                    partyMembers = {}
                    autoPartyWidget:setOff()
                end
            end)
        end
    end
end)

disbandPartyButton:setColor("#dd3333")

sayChannel(getChannelId("party"), "!party info")

-- Local functions
local function isPartyRequest(text)
    local t = text:lower()

    t = t:gsub("[!?.:,;]", "")

    for word in t:gmatch("%S+") do
        if word == "pt" or word == "party" then
            return true
        end
    end

    return false
end


onLoginAdvice(function(text)

    -- Text:
    -- * Quantidade de jogadores: 1
    -- * Jogador de maior level: 239
    -- * Jogador de menor level: 239
    -- * Level para compartilhamento de experience: de 359 até 160
    -- * Bonus atual: 21%
    -- * Jogadores na Party: Ayn Rand, 
    -- * Jogadores Inativos:

    if autoPartyWidget:isOff() then
        return
    end

    local adviceRaws = string.explode(text, "*")
    local function fieldValue(idx)
        local part = adviceRaws[idx] or ""
        local v = (string.explode(part, ":")[2] or ""):gsub("^%s*(.-)%s*$", "%1")
        if v == "" then
            return nil
        end
        return v
    end

    lowestLevel = tonumber(fieldValue(LOWEST_LEVEL_INDEX)) or 0
    highestLevel = tonumber(fieldValue(HIGHEST_LEVEL_INDEX)) or 0
    maxLevelToShare = math.ceil(lowestLevel * 3 / 2)
    minLevelToShare = math.floor(highestLevel * 2 / 3)

    partyMembersCount = tonumber(fieldValue(PLAYERS_COUNT_INDEX)) or 0

    partyMembers = {}
    local membersRaw = fieldValue(ACTIVE_PLAYERS_INDEX) or ""
    for part in membersRaw:gmatch("([^,]+)") do
        local n = part:gsub("^%s*(.-)%s*$", "%1")
        if n ~= "" then
            table.insert(partyMembers, n)
        end
    end

    local now = os.time()
    lastInfoCheck = now

    if updatingLabels then
        updatingLabels()
    end

    if partyState ~= "inactivityExceeded" then
        return
    end

    pendingKicks = {}
    local inactiveRaw = fieldValue(INACTIVE_PLAYERS_INDEX) or ""
    for part in inactiveRaw:gmatch("([^,]+)") do
        local n = part:gsub("^%s*(.-)%s*$", "%1")
        if n ~= "" then
            table.insert(pendingKicks, n)
        end
    end

    if #pendingKicks == 0 then
        partyState = "idle"
        return
    end

    partyState = "processingKicks"
    for i, name in ipairs(pendingKicks) do
        schedule(KICK_DELAY * i, function()
            sayChannel(getChannelId("party"), "!party kick," .. name)
            if i == #pendingKicks then
                pendingKicks = {}
                partyState = "idle"
                lastInactiveCheck = os.time()
            end
        end)
    end
end)

onTextMessage(function(mode, text)
    if autoPartyWidget:isOff() then
        return
    end

    local lower = text:lower()
    if lower:find("you are now the leader of the party.") or lower:find("has joined the party.") then
        sayChannel(getChannelId("party"), "!party info")
        if player:getShield() == SHIELD_NON_SHARING_PARTY then
            schedule(500, function()
                sayChannel(getChannelId("party"), "!party share")
            end)
        end
    elseif lower:find("has left the party.") then
        if partyState ~= "processingKicks" then
            sayChannel(getChannelId("party"), "!party info")
        end
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if autoPartyWidget:isOff() then
        return
    end

    if player:isPartyMember() and not player:isPartyLeader() then
        return
    end

    if name == player:getName() then
        return
    end

    if not isPartyRequest(text) then
        return
    end

    for _, spec in ipairs(getSpectators()) do

        if spec:getName() == name then

            if spec:isPartyMember() then
                return
            end

            if os.time() - lastInviteRequestTime < INVITE_REQUEST_COOLDOWN_GENERAL then
                info("General invite request cooldown active. Ignoring invite request from " .. name .. ".")
                return
            end

            if lastRequestByPlayer[name] and os.time() - lastRequestByPlayer[name] < INVITE_REQUEST_COOLDOWN_BY_PLAYER then
                info("Already processed invite request from " .. name .. ".")
                return
            end
            lastRequestByPlayer[name] = os.time()

            if spec:getShield() == SHIELD_ALREADY_INVITED then
                info(name .. " already invited.")
                g_game.talkPrivate(5, name, name .. ", I already invited you")
                return
            end

            local minAllowedLevel, maxAllowedLevel

            if storage.auto_party.dynamicMinLeveling then
                if maxLevelToShare == 0 then
                    local myLevel = player:getLevel()
                    minAllowedLevel = math.floor(myLevel * 2 / 3)
                else
                    minAllowedLevel = minLevelToShare
                end
            else
                minAllowedLevel = storage.auto_party.staticMinLevel
            end

            if storage.auto_party.dynamicMaxLeveling then
                if maxLevelToShare == 0 then
                    local myLevel = player:getLevel()
                    maxAllowedLevel = math.ceil(myLevel * 3 / 2)
                else
                    maxAllowedLevel = maxLevelToShare
                end
            else
                maxAllowedLevel = storage.auto_party.staticMaxLevel
            end

            if level > maxAllowedLevel or level < minAllowedLevel then
                info(name .. " level not in range " .. minAllowedLevel .. " to " .. maxAllowedLevel .. ".")
                g_game.talkPrivate(5, name, name .. ", the allowed range is " .. minAllowedLevel .. " to " .. maxAllowedLevel)
                return
            end

            if partyMembersCount >= storage.auto_party.maxMembers then
                info("Party full. Cannot invite " .. name .. ".")
                g_game.talkPrivate(5, name, name .. ", the party already has " .. storage.auto_party.maxMembers ..
                    " players for a better use of the shared experience.")
                return
            end

            info("Inviting " .. name .. " to party.")
            lastInviteRequestTime = os.time()
            g_game.partyInvite(spec:getId())
        end
    end
end)

onCreatureAppear(function(creature)
    if autoPartyWidget:isOff() then
        return
    end

    if player:isPartyMember() and not player:isPartyLeader() then
        return
    end

    if not creature:isPlayer() then
        return
    end
    
    if creature:isLocalPlayer() then
        return
    end
    
    if creature:getShield() == SHIELD_ALREADY_INVITED then
        return
    end
    
    if creature:isPartyMember() then
        return
    end
    
    if partyMembersCount >= storage.auto_party.maxMembers then
        return
    end

    local now = os.time()
    if now - lastInviteMessageTime < INVITE_MESSAGE_COOLDOWN then
        return
    end

    say("Hello! Say 'pt' for an automatic invite. Level range: " ..
            (storage.auto_party.dynamicMinLeveling and (minLevelToShare) or
                (storage.auto_party.staticMinLevel)) .. " to " ..
            (storage.auto_party.dynamicMaxLeveling and (maxLevelToShare) or
                (storage.auto_party.staticMaxLevel)) ..
            ". Party members: " .. partyMembersCount .. "/" .. storage.auto_party.maxMembers .. ".")

    lastInviteMessageTime = now
end)
