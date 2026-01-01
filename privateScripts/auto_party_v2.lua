local MACRO_VERSION = "1.1.0"
print("Autoparty v" .. MACRO_VERSION .. " loaded.")
-- Last release:
--  - checkboxes to dynamic leveling
--  - applying cooldowns
--  - notifyng check system

-- Constants ---------------------------------------------------
local MACRO_DELAY = 1000 -- in milliseconds
local MAX_INACTIVE_TIME = 20 -- in seconds
local KICK_DELAY = 500 -- in milliseconds
local LOCKED_PARTY_STATE = 15 -- in seconds
local INVITE_MESSAGE_COOLDOWN = 20 -- in seconds
local INDIVIDUAL_COOLDOWN_INVITE_REQUEST = 5 -- in seconds
local GENERAL_COOLDOWN_INVITE_REQUEST = 3 -- in seconds
local WORLD_CHAT_INVITE_COOLDOWN = 40 -- in seconds
local DEFAULT_TAB = "Party"
local ICON_ID = 28722

-- Party Shields: ----------------------------------------------
local SHIELD_ALREADY_INVITED = 2
local SHIELD_NON_SHARING_PARTY = 4
local SHIELD_SHARING = 6
local SHIELD_LEADER_INACTIVE = 8
local SHIELD_MEMBERS_INACTIVE = 10

-- Advice field indexes ----------------------------------------
local PLAYERS_COUNT_INDEX = 2
local HIGHEST_LEVEL_INDEX = 3
local LOWEST_LEVEL_INDEX = 4
local CURRENT_BONUS_INDEX = 6
local ACTIVE_PLAYERS_INDEX = 7
local INACTIVE_PLAYERS_INDEX = 8

-- Local variables ---------------------------------------------
local lowestLevel = 0
local highestLevel = 0
local maxLevelToShare = 0
local minLevelToShare = 0
local minAllowedLevel = 0
local maxAllowedLevel = 0
local partyMembersCount = 0
local expPerHour = 0
local currentBonus = 0
local lastInfoCheck = os.time()
local lastInactiveCheck = os.time()
local lastInviteMessageTime = os.time()
local lastInviteRequestTime = os.time()
local lastWorldChatMessageTime = 0
local partyState = "idle" -- "idle", "inactivityExceeded", "processingKicks"

local autoPartyWidget = nil
local updatingLabels = nil
local pendingKicks = {}
local partyMembers = {}
local lastRequestByPlayer = {}

-- Storage -----------------------------------------------------
if not storage.auto_party then
    storage.auto_party = {}
end

if storage.auto_party.dynamicMaxLeveling == nil then
    storage.auto_party.dynamicMaxLeveling = true
end
if storage.auto_party.dynamicMinLeveling == nil then
    storage.auto_party.dynamicMinLeveling = true
end
if storage.auto_party.maxMembers == nil then
    storage.auto_party.maxMembers = 30
end
if storage.auto_party.staticMaxLevel == nil then
    storage.auto_party.staticMaxLevel = 300
end
if storage.auto_party.staticMinLevel == nil then
    storage.auto_party.staticMinLevel = 100
end
if storage.auto_party.partyBlockedPlayers == nil then
    storage.auto_party.partyBlockedPlayers = {}
end
if storage.auto_party.huntArea == nil or not storage.auto_party.huntArea then
    storage.auto_party.huntArea = ""
end
if storage.auto_party.callMembersInChatChecked == nil then
    storage.auto_party.callMembersInChatChecked = false
end
if storage.auto_party.notifyWhenAlreadyInvitedChecked == nil then
    storage.auto_party.notifyWhenAlreadyInvitedChecked = false
end
if storage.auto_party.notifyWhenLevelNotAllowedChecked == nil then
    storage.auto_party.notifyWhenLevelNotAllowedChecked = false
end
if storage.auto_party.notifyWhenPartyFullChecked == nil then
    storage.auto_party.notifyWhenPartyFullChecked = false
end
if storage.auto_party.notifyWhenPlayerBlockedChecked == nil then
    storage.auto_party.notifyWhenPlayerBlockedChecked = false
end
if storage.auto_party.membersInMessageInfoChecked == nil then
    storage.auto_party.membersInMessageInfoChecked = false
end
if storage.auto_party.experienceInMessageInfoChecked == nil then
    storage.auto_party.experienceInMessageInfoChecked = false
end
if storage.auto_party.bonusInMessageInfoChecked == nil then
    storage.auto_party.bonusInMessageInfoChecked = false
end
if storage.auto_party.maxAndMinLevelInMessageInfoChecked == nil then
    storage.auto_party.maxAndMinLevelInMessageInfoChecked = false
end

-- Local functions ---------------------------------------------
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

local function fieldValue(adviceRaws, idx)
    local part = adviceRaws[idx] or ""
    local v = (string.explode(part, ":")[2] or ""):gsub("^%s*(.-)%s*$", "%1")
    if v == "" then
        return nil
    end
    return v
end

local function getAdviceRaws(text)
    local adviceRaws = string.explode(text, "*")
    return adviceRaws
end

local function extractValueFromInfo(text, idx)
    local adviceRaws = getAdviceRaws(text)
    return fieldValue(adviceRaws, idx) or ""
end

local function extractNumberFromInfo(text, idx)
    local adviceRaws = getAdviceRaws(text)
    return tonumber(fieldValue(adviceRaws, idx)) or 0
end

local function getLowestLevel(text)
    return extractNumberFromInfo(text, LOWEST_LEVEL_INDEX)
end

local function getHighestLevel(text)
    return extractNumberFromInfo(text, HIGHEST_LEVEL_INDEX)
end

local function getMaxLevelToShare(lowestLevel)
    return math.ceil(lowestLevel * 3 / 2)
end

local function getMinLevelToShare(highestLevel)
    return math.floor(highestLevel * 2 / 3)
end

local function getPartyMembersCount(text)
    return extractNumberFromInfo(text, PLAYERS_COUNT_INDEX)
end

local function getMembersRaw(text)
    return extractValueFromInfo(text, ACTIVE_PLAYERS_INDEX)
end

local function getInactiveMembersRaw(text)
    return extractValueFromInfo(text, INACTIVE_PLAYERS_INDEX)
end

local function getCurrentBonus(text)
    return extractNumberFromInfo(text, CURRENT_BONUS_INDEX)
end

local function getExpPerHour()
    if g_game.getLocalPlayer().expSpeed == nil or not g_game.getLocalPlayer().expSpeed or
        g_game.getLocalPlayer().expSpeed == 0 then
        return 0
    end
    local expPerHourLoc = math.floor(g_game.getLocalPlayer().expSpeed * 3600)
    local expPerHourConv = string.format("%.1f", expPerHourLoc / 1000000)
    return expPerHourConv
end

local function getPartyMembers(text)
    local partyMembers = {}
    local membersRaw = getMembersRaw(text)

    for part in membersRaw:gmatch("([^,]+)") do
        local n = part:gsub("^%s*(.-)%s*$", "%1")
        if n ~= "" then
            table.insert(partyMembers, n)
        end
    end
    return partyMembers
end

local function getPendingKicks(text)
    local pendingKicks = {}
    local inactiveRaw = getInactiveMembersRaw(text)

    for part in inactiveRaw:gmatch("([^,]+)") do
        local n = part:gsub("^%s*(.-)%s*$", "%1")
        if n ~= "" then
            table.insert(pendingKicks, n)
        end
    end
    return pendingKicks
end

local function kickInactivePlayers(text)
    if partyState ~= "inactivityExceeded" then
        return
    end

    pendingKicks = getPendingKicks(text)

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
end

local function getMinAllowedLevel()
    local minAllowedLevel
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

    return minAllowedLevel
end

local function getMaxAllowedLevel()
    local maxAllowedLevel
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

    return maxAllowedLevel
end

local function inviteMessageComplement(rootMessage)
    local localMessage = rootMessage

    if storage.auto_party.membersInMessageInfoChecked then
        localMessage = localMessage .. " - Members: " .. partyMembersCount .. "/" .. storage.auto_party.maxMembers
    end

    if storage.auto_party.experienceInMessageInfoChecked then
        localMessage = localMessage .. " - Exp/h: " .. expPerHour .. "kk"
    end

    if storage.auto_party.bonusInMessageInfoChecked then
        localMessage = localMessage .. " - Bonus: " .. currentBonus .. "%"
    end

    if storage.auto_party.maxAndMinLevelInMessageInfoChecked then
        localMessage = localMessage .. " - Min level: " .. minAllowedLevel .. " - Max level: " .. maxAllowedLevel
    end

    return localMessage
end

local function getInviteMessage()
    local localMessage = "If you want to join the party, say 'pt' so I can invite you"

    localMessage = inviteMessageComplement(localMessage)

    return localMessage
end

local function getWorldInviteMessage()
    if storage.auto_party.huntArea == "" then
        return nil
    end

    local localMessage = "Join the party in " .. storage.auto_party.huntArea .. "."

    localMessage = inviteMessageComplement(localMessage)

    return localMessage:upper()
end

local function isPlayerBlocked(name)
    if not storage.auto_party.partyBlockedPlayers then
        return false
    end
    local searchName = name:lower():trim()
    for _, blockedName in ipairs(storage.auto_party.partyBlockedPlayers) do
        if blockedName == searchName then
            return true
        end
    end
    return false
end

local function sendMessageInWorldChat()
    if not storage.auto_party.callMembersInChatChecked then
        return
    end

    local IS_PARTY_FULL = partyMembersCount >= storage.auto_party.maxMembers
    if IS_PARTY_FULL then
        return
    end

    local IS_PARTY_MEMBER = player:isPartyMember()
    local IS_NOT_PARTY_LEADER = not player:isPartyLeader()
    if IS_PARTY_MEMBER and IS_NOT_PARTY_LEADER then
        return
    end

    local IS_IN_WOLRD_CHAT_MESSAGE_COLLDOWN = os.time() - lastWorldChatMessageTime < WORLD_CHAT_INVITE_COOLDOWN
    if IS_IN_WOLRD_CHAT_MESSAGE_COLLDOWN then
        return
    end

    local chat = getChannelId("World Chat")
    if not chat then
        info("Chat not found.")
        return
    end

    local chatMessage = getWorldInviteMessage()

    if not chatMessage then
        return
    end

    sayChannel(chat, chatMessage)
    lastWorldChatMessageTime = os.time()
end

-- Macro -------------------------------------------------------

setDefaultTab(DEFAULT_TAB)

UI.Separator()

local autoPartyWidget = macro(MACRO_DELAY, "Auto Party", function()

    local now = os.time()

    if not player:isPartyLeader() then
        partyState = "idle"
        partyMembersCount = 0
        lowestLevel = 0
        highestLevel = 0
        minLevelToShare = 0
        maxLevelToShare = 0
        return
    end

    sendMessageInWorldChat()

    local PARTY_SHARING_IS_NOT_ENABLED = not player:isPartySharedExperienceActive()
    if PARTY_SHARING_IS_NOT_ENABLED then
        g_game.partyShareExperience(true)
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

-- Icon --------------------------------------------------------
local autoPartyIcon = addIcon("Auto Party", {
    item = {
        id = ICON_ID
    },
    text = "AutoPt",
    movable = true
}, autoPartyWidget)

autoPartyIcon:setSize({
    height = 50,
    width = 250
})
autoPartyIcon:breakAnchors()
autoPartyIcon:move(80, 280)

-- Events ------------------------------------------------------
onLoginAdvice(function(text)
    -- Text:
    -- * Quantidade de jogadores: 1
    -- * Jogador de maior level: 239
    -- * Jogador de menor level: 239
    -- * Level para compartilhamento de experience: de 359 até 160
    -- * Bonus atual: 21%
    -- * Jogadores na Party: Ayn Rand, 
    -- * Jogadores Inativos:

    local MACRO_IS_DISABLED = autoPartyWidget:isOff()
    if MACRO_IS_DISABLED then
        return
    end

    local IS_PARTY_MEMBER = player:isPartyMember()
    local IS_NOT_PARTY_LEADER = not player:isPartyLeader()
    if IS_PARTY_MEMBER and IS_NOT_PARTY_LEADER then
        return
    end

    lowestLevel = getLowestLevel(text)
    highestLevel = getHighestLevel(text)
    minLevelToShare = getMinLevelToShare(highestLevel)
    maxLevelToShare = getMaxLevelToShare(lowestLevel)
    partyMembersCount = getPartyMembersCount(text)
    partyMembers = getPartyMembers(text)
    minAllowedLevel = getMinAllowedLevel()
    maxAllowedLevel = getMaxAllowedLevel()
    currentBonus = getCurrentBonus(text)
    expPerHour = getExpPerHour()

    if updatingLabels then
        updatingLabels()
    end

    local now = os.time()
    lastInfoCheck = now

    kickInactivePlayers(text)
end)

onTextMessage(function(mode, text)

    local MACRO_IS_DISABLED = autoPartyWidget:isOff()
    if MACRO_IS_DISABLED then
        return
    end

    local lower = text:lower()

    if not lower:find("party") then
        return
    end

    local isJoinOrLeader = lower:find("you are now the leader") or lower:find("has joined")
    local isLeft = lower:find("has left")

    if isLeft and partyState == "processingKicks" then
        return
    end

    if isJoinOrLeader or isLeft then
        sayChannel(getChannelId("party"), "!party info")
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    local MACRO_IS_DISABLED = autoPartyWidget:isOff()
    if MACRO_IS_DISABLED then
        return
    end

    local IS_PARTY_MEMBER = player:isPartyMember()
    local IS_NOT_PARTY_LEADER = not player:isPartyLeader()
    if IS_PARTY_MEMBER and IS_NOT_PARTY_LEADER then
        return
    end

    local IS_YOURSELF = name == player:getName()
    if IS_YOURSELF then
        return
    end

    local IS_NOT_ASKING_PARTY = not isPartyRequest(text)
    if IS_NOT_ASKING_PARTY then
        return
    end

    local IS_PLAYER_BLOCKED = isPlayerBlocked(name)
    if IS_PLAYER_BLOCKED then
        if storage.auto_party.notifyWhenPlayerBlockedChecked then
            g_game.talkPrivate(5, name,
                name .. ", you are blocked for this party. Send a private message to " .. player:getName() ..
                    " to resolve the situation.")
        end
        return
    end

    for _, spec in ipairs(getSpectators()) do

        if not spec or not spec.getName or not spec.isPartyMember then
            goto continue
        end

        local PLAYERS_IS_NEXT = spec:getName() == name
        if not PLAYERS_IS_NEXT then
            goto continue
        end

        local IS_ALREADY_PARTY_MEMBER = spec:isPartyMember()
        if IS_ALREADY_PARTY_MEMBER then
            return
        end

        local IS_IN_GENERAL_COOLDOWN = os.time() - lastInviteRequestTime < GENERAL_COOLDOWN_INVITE_REQUEST
        if IS_IN_GENERAL_COOLDOWN then
            return
        end

        local IS_INDIVIDUAL_COOLDOWN = lastRequestByPlayer[name] and os.time() - lastRequestByPlayer[name] <
                                           INDIVIDUAL_COOLDOWN_INVITE_REQUEST
        if IS_INDIVIDUAL_COOLDOWN then
            return
        end
        lastRequestByPlayer[name] = os.time()

        local IS_ALREADY_INVITED = spec:getShield() == SHIELD_ALREADY_INVITED
        if IS_ALREADY_INVITED then
            if storage.auto_party.notifyWhenAlreadyInvitedChecked then
                g_game.talkPrivate(5, name, name .. ", I already invited you.")
            end
            return
        end

        local IS_NOT_WITHIN_ALLOWED_RANGE = level > maxAllowedLevel or level < minAllowedLevel
        if IS_NOT_WITHIN_ALLOWED_RANGE then
            if storage.auto_party.notifyWhenLevelNotAllowedChecked then
                g_game.talkPrivate(5, name,
                    name .. ", the allowed range is " .. minAllowedLevel .. " to " .. maxAllowedLevel)
            end
            return
        end

        local IS_PARTY_FULL = partyMembersCount >= storage.auto_party.maxMembers
        if IS_PARTY_FULL then
            if storage.auto_party.notifyWhenPartyFullChecked then
                g_game.talkPrivate(5, name, name .. ", the party already has " .. storage.auto_party.maxMembers ..
                    " players for a better use of the shared experience.")
            end
            return
        end

        lastInviteRequestTime = os.time()
        g_game.partyInvite(spec:getId())

        ::continue::
    end
end)

onCreatureAppear(function(creature)
    local MACRO_IS_DISABLED = autoPartyWidget:isOff()
    if MACRO_IS_DISABLED then
        return
    end

    local IS_PARTY_MEMBER = player:isPartyMember()
    local IS_NOT_PARTY_LEADER = not player:isPartyLeader()
    if IS_PARTY_MEMBER and IS_NOT_PARTY_LEADER then
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

    local localMessage = getInviteMessage()
    say(localMessage)

    lastInviteMessageTime = now
end)

-- UI ----------------------------------------------------------
UI.Separator()

local autoPartyUI = setupUI([[
UIWidget
  layout:
    type: verticalBox
    fit-children: true

  DualLabel
    height: 15
    id: statusLabel
    text: Status:
    margin-top: 5

  DualLabel
    height: 15
    id: membersLabel
    text: Members:

  DualLabel
    height: 15
    id: lowestLevelLabel
    text: Lowest Level:

  DualLabel
    height: 15
    id: highestLevelLabel
    text: Highest Level:

  DualLabel
    height: 15
    id: minLevelLabel
    text: Min Level:

  DualLabel
    height: 15
    id: maxLevelLabel
    text: Max Level:

  HorizontalSeparator
    margin-top: 8
    margin-bottom: 8

  Label
    id: levelingLabel
    text: Leveling:
    text-align: center
    margin-top: 2
    margin-bottom: 5

  Panel
    id: maxMembersRow
    height: 18
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
    height: 18
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
    height: 18
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
    height: 18
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
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: dynamicMaxRow
    height: 18
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
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  HorizontalSeparator
    margin-top: 8
    margin-bottom: 8

  Label
    text: Notifying Settings:
    margin-bottom: 5
    text-align: center

  Panel
    id: alreadInvited
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Notify when already invited
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: levelNotAllowed
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Notify when level not allowed
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: partyIsFull
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Notify when party is full
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: playerBlocked
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Notify when player is blocked
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  HorizontalSeparator
    margin-top: 8
    margin-bottom: 8

  Label
    text: Message Settings:
    margin-bottom: 5
    text-align: center

  Panel
    id: worldChat
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Send invite in World chat
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: showMembers
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Show Members info
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: showExp
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Show Experience/h
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: showBonus
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Show bonus info
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont

  Panel
    id: showRange
    height: 18
    CheckBox
      id: check
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
    Label
      text: Show Max/Min levels
      anchors.left: prev.right
      anchors.verticalCenter: prev.verticalCenter
      margin-top: 3
      margin-left: 7
      font: cipsoftFont
  
  Panel
    id: huntAreaLabelPanel
    height: 18
    margin-top: 8
    Label
      id: huntLabel
      text: Hunt Area:
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
      color: #dfdfdf

  Panel
    id: huntAreaInputPanel
    height: 18
    BotTextEdit
      id: value
      anchors.fill: parent
      margin-left: 5
      margin-right: 5
]], setDefaultTab(DEFAULT_TAB))

-- Lógica da UI ------------------------------------------------

-- Labels informativas
updatingLabels = function()
    autoPartyUI.statusLabel.value:setText(partyState)
    local color = (partyState == "idle") and "green" or "orange"
    if partyState == "processingKicks" then
        color = "red"
    end
    autoPartyUI.statusLabel.value:setColor(color)

    autoPartyUI.membersLabel.value:setText(tostring(partyMembersCount))

    autoPartyUI.lowestLevelLabel.value:setText(tostring(lowestLevel))

    autoPartyUI.highestLevelLabel.value:setText(tostring(highestLevel))

    autoPartyUI.minLevelLabel.value:setText(tostring(minLevelToShare))

    autoPartyUI.maxLevelLabel.value:setText(tostring(maxLevelToShare))
end

-- Configurações de membros
autoPartyUI.maxMembersRow.value:setText(tostring(storage.auto_party.maxMembers))
autoPartyUI.maxMembersRow.value.onTextChange = function(widget, text)
    storage.auto_party.maxMembers = tonumber(text) or 30
end

-- Configurações de Level
autoPartyUI.minLevelRow.value:setText(tostring(storage.auto_party.staticMinLevel))
autoPartyUI.minLevelRow.value:setEnabled(not storage.auto_party.dynamicMinLeveling)
autoPartyUI.minLevelRow.value.onTextChange = function(widget, text)
    storage.auto_party.staticMinLevel = tonumber(text) or 0
end

autoPartyUI.maxLevelRow.value:setText(tostring(storage.auto_party.staticMaxLevel))
autoPartyUI.maxLevelRow.value:setEnabled(not storage.auto_party.dynamicMaxLeveling)
autoPartyUI.maxLevelRow.value.onTextChange = function(widget, text)
    storage.auto_party.staticMaxLevel = tonumber(text) or 0
end

autoPartyUI.dynamicMinRow.check:setChecked(storage.auto_party.dynamicMinLeveling)
autoPartyUI.dynamicMinRow.check.onClick = function(widget)
    storage.auto_party.dynamicMinLeveling = not storage.auto_party.dynamicMinLeveling
    widget:setChecked(storage.auto_party.dynamicMinLeveling)
    autoPartyUI.minLevelRow.value:setEnabled(not storage.auto_party.dynamicMinLeveling)
    minAllowedLevel = getMinAllowedLevel()
end

autoPartyUI.dynamicMaxRow.check:setChecked(storage.auto_party.dynamicMaxLeveling)
autoPartyUI.dynamicMaxRow.check.onClick = function(widget)
    storage.auto_party.dynamicMaxLeveling = not storage.auto_party.dynamicMaxLeveling
    widget:setChecked(storage.auto_party.dynamicMaxLeveling)
    autoPartyUI.maxLevelRow.value:setEnabled(not storage.auto_party.dynamicMaxLeveling)
    maxAllowedLevel = getMaxAllowedLevel()
end

-- Configurações de Mensagem
local function setupCheckboxes(row, storageKey)
    row.check:setChecked(storage.auto_party[storageKey])
    row.check.onClick = function(widget)
        storage.auto_party[storageKey] = not storage.auto_party[storageKey]
        widget:setChecked(storage.auto_party[storageKey])
    end
end

-- Sistema de notificações
setupCheckboxes(autoPartyUI.alreadInvited, "notifyWhenAlreadyInvitedChecked")
setupCheckboxes(autoPartyUI.levelNotAllowed, "notifyWhenLevelNotAllowedChecked")
setupCheckboxes(autoPartyUI.partyIsFull, "notifyWhenPartyFullChecked")
setupCheckboxes(autoPartyUI.playerBlocked, "notifyWhenPlayerBlockedChecked")

-- Sistema de informações nas mensagens
setupCheckboxes(autoPartyUI.worldChat, "callMembersInChatChecked")
setupCheckboxes(autoPartyUI.showMembers, "membersInMessageInfoChecked")
setupCheckboxes(autoPartyUI.showExp, "experienceInMessageInfoChecked")
setupCheckboxes(autoPartyUI.showBonus, "bonusInMessageInfoChecked")
setupCheckboxes(autoPartyUI.showRange, "maxAndMinLevelInMessageInfoChecked")

autoPartyUI.huntAreaInputPanel.value:setText(tostring(storage.auto_party.huntArea))
autoPartyUI.huntAreaInputPanel.value.onTextChange = function(widget, text)
    storage.auto_party.huntArea = text:trim()
end

UI.Separator()

-- Blocked Players List
UI.Button("Blocked Players", function()
    local currentList = ""
    if type(storage.auto_party.partyBlockedPlayers) == "table" then
        currentList = table.concat(storage.auto_party.partyBlockedPlayers, "\n")
    end

    UI.MultilineEditorWindow(currentList, {
        title = "Blocked Players List",
        description = "Add one name per line:",
        width = 250,
        height = 200
    }, function(text)
        local tmpList = {}

        local lines = string.explode(text, "\n")
        for _, line in ipairs(lines) do
            local name = line:trim()
            if name ~= "" then
                table.insert(tmpList, name:lower()) -- Salvamos em minúsculo para facilitar a busca
            end
        end
        storage.auto_party.partyBlockedPlayers = tmpList
    end)
end)

-- Info Button
local infoButton = UI.Button("Info", function()
    sayChannel(getChannelId("party"), "!party info")
end)

infoButton:setColor("green")

-- Disband Party
local disbandPartyButton = UI.Button("Disband Party", function()
    if #partyMembers <= 2 then
        sayChannel(getChannelId("party"), "!party exit")
        return
    end

    for i, name in ipairs(partyMembers) do
        if name ~= player:getName() then
            schedule(KICK_DELAY * i, function()
                sayChannel(getChannelId("party"), "!party kick," .. name)
                info("Kicking " .. name .. " from party.")
                if i == #partyMembers then
                    sayChannel(getChannelId("party"), "!party exit")
                    partyMembers = {}
                    autoPartyWidget:setOff()
                end
            end)
        end
    end
end)

disbandPartyButton:setColor("#dd3333")

-- Start up ----------------------------------------------------
sayChannel(getChannelId("party"), "!party info")

minAllowedLevel = getMinAllowedLevel()
maxAllowedLevel = getMaxAllowedLevel()
