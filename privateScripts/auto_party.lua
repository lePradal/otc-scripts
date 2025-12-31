-- Constants
local MACRO_DELAY = 1000 -- in milliseconds
local MAX_INACTIVE_TIME = 20 -- in seconds
local KICK_DELAY = 500 -- in milliseconds
local LOCKED_PARTY_STATE = 15 -- in seconds
local INVITE_MESSAGE_COOLDOWN = 20 -- in seconds
local INVITE_REQUEST_COOLDOWN = 2 -- in seconds
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

-- Max members in party
local maxMembersPanel = setupUI([[
MaxMembersPanel < Panel
  height: 20
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: Max. members:
    margin-left: 5

  BotTextEdit
    id: value
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-right: 6
    width: 30

Panel
  id: maxMembersPanel
  layout: 
    type: verticalBox
    fit-children: true
]], setDefaultTab(DEFAULT_TAB))

local maxMembersInput = UI.createWidget("MaxMembersPanel", maxMembersPanel.maxMembersPanel).value
maxMembersInput:setText(tostring(storage.auto_party.maxMembers))
maxMembersInput.onTextChange = function(widget, text)
    local v = tonumber(text)
    if v and v > 0 then
        storage.auto_party.maxMembers = v
    end
    widget:setText(tostring(storage.auto_party.maxMembers))
end

local maxLevelPanel = setupUI([[
MaxLevelPanel < Panel
  height: 20
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: Max Level:
    margin-left: 5

  BotTextEdit
    id: value
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-right: 6
    width: 30

Panel
  id: maxLevelPanel
  layout: 
    type: verticalBox
    fit-children: true
]], setDefaultTab(DEFAULT_TAB))

local maxLevelInput = UI.createWidget("MaxLevelPanel", maxLevelPanel.maxLevelPanel).value
maxLevelInput:setText(tostring(storage.auto_party.staticMaxLevel))
maxLevelInput.onTextChange = function(widget, text)
    local v = tonumber(text)
    if v and v >= 0 then
        storage.auto_party.staticMaxLevel = v
    end
    widget:setText(tostring(storage.auto_party.staticMaxLevel))
end
maxLevelInput:setEnabled(not storage.auto_party.dynamicMaxLeveling)

local minLevelPanel = setupUI([[
MinLevelPanel < Panel
  height: 20
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: Min Level:
    margin-left: 5

  BotTextEdit
    id: value
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-right: 6
    width: 30

Panel
  id: minLevelPanel
  layout: 
    type: verticalBox
    fit-children: true
]], setDefaultTab(DEFAULT_TAB))

local minLevelInput = UI.createWidget("MinLevelPanel", minLevelPanel.minLevelPanel).value
minLevelInput:setText(tostring(storage.auto_party.staticMinLevel))
minLevelInput.onTextChange = function(widget, text)
    local v = tonumber(text)
    if v and v >= 0 then
        storage.auto_party.staticMinLevel = v
    end
    widget:setText(tostring(storage.auto_party.staticMinLevel))
end
minLevelInput:setEnabled(not storage.auto_party.dynamicMinLeveling)

local ui = setupUI([[
TestPanel < UIWidget
  padding: 1
  height: 45

  CheckBox
    id: checkMinLevel
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 5
    margin-top: 5

  UIWidget
    id: labelMin
    anchors.verticalCenter: checkMinLevel.verticalCenter
    anchors.left: checkMinLevel.right
    !text: tr('Dynamic Min Leveling')
    margin-left: 7

  CheckBox
    id: checkMaxLevel
    anchors.top: checkMinLevel.bottom
    anchors.left: parent.left
    margin-left: 5
    margin-top: 8

  UIWidget
    id: labelMax
    anchors.verticalCenter: checkMaxLevel.verticalCenter
    anchors.left: checkMaxLevel.right
    !text: tr('Dynamic Max Leveling')
    margin-left: 7

Panel
  id: dynamicLevelingPanel
]], setDefaultTab(DEFAULT_TAB))

local checkBox = UI.createWidget("TestPanel", ui.dynamicLevelingPanel)
checkBox.checkMinLevel:setChecked(storage.auto_party.dynamicMinLeveling)
checkBox.checkMaxLevel:setChecked(storage.auto_party.dynamicMaxLeveling)

checkBox.checkMinLevel.onClick = function(widget)
    storage.auto_party.dynamicMinLeveling = not storage.auto_party.dynamicMinLeveling
    widget:setChecked(storage.auto_party.dynamicMinLeveling)
    minLevelInput:setEnabled(not storage.auto_party.dynamicMinLeveling)
end

checkBox.checkMaxLevel.onClick = function(widget)
    storage.auto_party.dynamicMaxLeveling = not storage.auto_party.dynamicMaxLeveling
    widget:setChecked(storage.auto_party.dynamicMaxLeveling)
    maxLevelInput:setEnabled(not storage.auto_party.dynamicMaxLeveling)
end

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

    if name == player:getName() then
        return
    end

    if not text:lower():find("pt") and not (text:lower():find("party") and not text:lower():find("!party")) then
        return
    end

    for _, spec in ipairs(getSpectators()) do

        if spec:getName() == name then

            if spec:isPartyMember() then
                return
            end

            if os.time() - lastInviteRequestTime < INVITE_REQUEST_COOLDOWN then
                info("Invite request cooldown. Cannot invite " .. name .. " yet.")
                return
            end

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
